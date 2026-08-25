#!/usr/bin/env node

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { spawn } from "node:child_process";

const [, , chromePath, tasksPath] = process.argv;
if (!chromePath || !tasksPath) {
  throw new Error("usage: render-marketing-pages.mjs <chrome> <tasks.json>");
}

const tasks = JSON.parse(fs.readFileSync(tasksPath, "utf8"));
const profile = fs.mkdtempSync(path.join(os.tmpdir(), "yohaku-chrome-"));
const chrome = spawn(chromePath, [
  "--headless",
  "--no-sandbox",
  "--disable-gpu",
  "--disable-dev-shm-usage",
  "--disable-background-networking",
  "--allow-file-access-from-files",
  "--hide-scrollbars",
  "--no-first-run",
  "--no-default-browser-check",
  "--remote-debugging-port=0",
  `--user-data-dir=${profile}`,
  "about:blank",
], { stdio: ["ignore", "ignore", "pipe"] });

let stderr = "";
const websocketUrl = await new Promise((resolve, reject) => {
  const timer = setTimeout(() => reject(new Error(`Chrome did not expose DevTools: ${stderr}`)), 30000);
  chrome.stderr.setEncoding("utf8");
  chrome.stderr.on("data", chunk => {
    stderr += chunk;
    const match = stderr.match(/DevTools listening on (ws:\/\/[^\s]+)/);
    if (match) {
      clearTimeout(timer);
      resolve(match[1]);
    }
  });
  chrome.once("exit", code => {
    clearTimeout(timer);
    reject(new Error(`Chrome exited before DevTools was ready (${code}): ${stderr}`));
  });
});

const ws = new WebSocket(websocketUrl);
await new Promise((resolve, reject) => {
  ws.addEventListener("open", resolve, { once: true });
  ws.addEventListener("error", reject, { once: true });
});

let messageId = 0;
const pending = new Map();
const eventWaiters = [];

ws.addEventListener("message", event => {
  const message = JSON.parse(event.data);
  if (message.id && pending.has(message.id)) {
    const { resolve, reject } = pending.get(message.id);
    pending.delete(message.id);
    if (message.error) reject(new Error(JSON.stringify(message.error)));
    else resolve(message.result);
    return;
  }
  for (let index = eventWaiters.length - 1; index >= 0; index -= 1) {
    const waiter = eventWaiters[index];
    if (message.method === waiter.method && (!waiter.sessionId || message.sessionId === waiter.sessionId)) {
      eventWaiters.splice(index, 1);
      waiter.resolve(message.params);
    }
  }
});

function send(method, params = {}, sessionId = undefined) {
  const id = ++messageId;
  const payload = { id, method, params };
  if (sessionId) payload.sessionId = sessionId;
  ws.send(JSON.stringify(payload));
  return new Promise((resolve, reject) => pending.set(id, { resolve, reject }));
}

function waitFor(method, sessionId) {
  return new Promise(resolve => eventWaiters.push({ method, sessionId, resolve }));
}

try {
  const { targetId } = await send("Target.createTarget", { url: "about:blank" });
  const attached = await send("Target.attachToTarget", { targetId, flatten: true });
  const sessionId = attached.sessionId;
  await send("Page.enable", {}, sessionId);
  await send("Emulation.setDeviceMetricsOverride", {
    width: 1320,
    height: 2868,
    deviceScaleFactor: 1,
    mobile: false,
    screenWidth: 1320,
    screenHeight: 2868,
  }, sessionId);

  for (let index = 0; index < tasks.length; index += 1) {
    const task = tasks[index];
    const loaded = waitFor("Page.loadEventFired", sessionId);
    await send("Page.navigate", { url: task.url }, sessionId);
    await loaded;
    await send("Runtime.evaluate", {
      expression: "document.fonts.ready",
      awaitPromise: true,
      returnByValue: true,
    }, sessionId);
    const { data } = await send("Page.captureScreenshot", {
      format: "png",
      fromSurface: true,
      captureBeyondViewport: false,
    }, sessionId);
    fs.mkdirSync(path.dirname(task.output), { recursive: true });
    fs.writeFileSync(task.output, Buffer.from(data, "base64"));
    if ((index + 1) % 10 === 0) {
      process.stdout.write(`rendered ${index + 1}/${tasks.length}\n`);
    }
  }
  await send("Browser.close");
} finally {
  try { ws.close(); } catch {}
  try { chrome.kill("SIGTERM"); } catch {}
  try {
    fs.rmSync(profile, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 });
  } catch {
    // Chrome can keep a transient profile file open for a moment after Browser.close.
    // The OS owns this temporary directory and will clean it up independently.
  }
}
