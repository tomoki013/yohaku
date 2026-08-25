#!/usr/bin/env python3
"""Generate localized App Store marketing screenshots for Yohaku.

The render is deliberately deterministic: translated copy and the app's real
localized UI screenshots are composed in HTML, then rasterized by headless
Chrome at Apple's 6.7-inch 1320x2868 submission size.
"""

from __future__ import annotations

import argparse
import html
import json
import re
import shutil
import subprocess
import tempfile
import urllib.parse
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SCREENSHOTS = ROOT / "AppStore" / "Screenshots"
OUTPUT = SCREENSHOTS / "marketing"
BACKGROUND = OUTPUT / "assets" / "ivory-paper-background.png"
TRANSLATIONS = OUTPUT / "translations.json"
CHROME = Path("/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")

LOCALES = {
    "ar": "ar",
    "de": "de",
    "en": "en",
    "es": "es",
    "fr": "fr",
    "hi": "hi",
    "id": "id",
    "it": "it",
    "ja": "ja",
    "ko": "ko",
    "nl": "nl",
    "pl": "pl",
    "pt-BR": "pt-BR",
    "th": "th",
    "tr": "tr",
    "vi": "vi",
    "zh-Hans": "zh-CN",
    "zh-Hant": "zh-TW",
}

SLIDES = [
    {
        "slug": "overview",
        "screen": "01-today",
        "label": "Today",
        "headline": "Plan less. Make space.",
        "body": "Name a quiet moment and time. Look back gently across today, week, and month.",
    },
    {
        "slug": "today",
        "screen": "01-today",
        "label": "Today",
        "headline": "A name and time become space.",
        "body": "Give ‘doing nothing’ a name. Keep a small quiet moment in your day.",
    },
    {
        "slug": "week",
        "screen": "02-week",
        "label": "Week",
        "headline": "See your week at a glance.",
        "body": "Days with space line up quietly. Look back without cramming in more.",
    },
    {
        "slug": "month",
        "screen": "03-month",
        "label": "Month",
        "headline": "Your month keeps its rhythm.",
        "body": "Days with space remain as quiet marks. See your pace, not perfection.",
    },
    {
        "slug": "reflection",
        "screen": "06-reflection",
        "label": "Reflection",
        "headline": "A gentle reflection, only once.",
        "body": "A quiet check-in appears before space begins and once after it ends.",
    },
    {
        "slug": "create",
        "screen": "05-add",
        "label": "Create",
        "headline": "Place a little space, right away.",
        "body": "Choose a name, date, and time. Add nothing else to your schedule.",
    },
    {
        "slug": "no-pressure",
        "screen": "03-month",
        "label": "No pressure",
        "headline": "No streaks. No pressure.",
        "body": "There are no goals or completion rates. Return whenever it feels right.",
    },
    {
        "slug": "privacy",
        "screen": "04-settings-iap",
        "label": "Privacy",
        "headline": "No account required.",
        "body": "Your spaces stay on this device. Privacy comes first.",
    },
    {
        "slug": "pricing",
        "screen": "04-settings-iap",
        "label": "Pricing",
        "headline": "Core features stay free.",
        "body": "Today, Week, Month, notifications, and reflections are free. Removing ads is a one-time purchase.",
    },
    {
        "slug": "examples",
        "screen": "01-today",
        "label": "Examples",
        "headline": "Give ‘doing nothing’ a name.",
        "body": "Do nothing. Have tea slowly. Take a short walk. Your space can be your own.",
    },
]

JA_COPY = [
    ("今日", "予定を増やさない。余白をつくる。", "何もしない時間に名前と時間をつけるだけ。Yohakuは、今日・週・月で静かに振り返る小さなアプリです。"),
    ("今日", "名前と時間だけで、余白になる。", "「何もしない時間」に、名前と時間をつけるだけ。その日の余白をやさしく残せます。"),
    ("週", "一週間を、ひと目で。", "余白を置いた日が静かに並びます。詰め込まずに過ごせた一週間を、あとから見渡せます。"),
    ("月", "月のリズムが、残っていく。", "余白をつくれた日が静かな印として残ります。完璧さではなく、自分らしいペースを見返せます。"),
    ("振り返り", "通知はやさしく、一度だけ。", "余白が始まる前にそっと知らせて、終わったあとに一度だけ振り返ります。"),
    ("作成", "余白は、すぐ置ける。", "名前・日付・時間を決めるだけ。やることを増やさず、何もしない予定を静かに置けます。"),
    ("プレッシャーなし", "続けなくていい。それでも、残る。", "連続記録も、達成率もありません。空いた日に戻ってきて、そのままのペースで使えます。"),
    ("プライバシー", "アカウント不要。余白は手元に。", "登録なしですぐ使えます。記録はこの端末に保存され、プライバシーを大切にします。"),
    ("料金", "大事な機能は、ずっと無料。", "Today・Week・Month、通知、振り返りは無料。広告削除だけ、一度きりの買い切りです。"),
    ("例", "『何もしない』にも、名前をつける。", "「ぼーっとする」「お茶をゆっくり」「散歩する」。小さな余白が、一日に残ります。"),
]


def google_translate(text: str, target: str) -> str:
    url = "https://translate.google.com/m?" + urllib.parse.urlencode(
        {"sl": "en", "tl": target, "q": text}
    )
    request = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(request, timeout=30) as response:
        page = response.read().decode("utf-8")
    match = re.search(r'<div class="result-container">(.*?)</div>', page, re.S)
    if not match:
        raise RuntimeError(f"Translation response for {target} had no result")
    return html.unescape(re.sub(r"<[^>]+>", "", match.group(1))).strip()


def build_translations(refresh: bool) -> dict[str, list[dict[str, str]]]:
    if TRANSLATIONS.exists() and not refresh:
        return json.loads(TRANSLATIONS.read_text(encoding="utf-8"))

    translations: dict[str, list[dict[str, str]]] = {}
    translations["en"] = [
        {"label": slide["label"], "headline": slide["headline"], "body": slide["body"]}
        for slide in SLIDES
    ]
    translations["ja"] = [
        {"label": label, "headline": headline, "body": body}
        for label, headline, body in JA_COPY
    ]

    separator = "\n§§§\n"
    source = []
    for slide in SLIDES:
        source.extend((slide["label"], slide["headline"], slide["body"]))
    joined = separator.join(source)

    for locale, google_locale in LOCALES.items():
        if locale in translations:
            continue
        translated = google_translate(joined, google_locale)
        parts = [part.strip() for part in translated.split("§§§")]
        if len(parts) != len(source):
            raise RuntimeError(
                f"Expected {len(source)} translated fields for {locale}, got {len(parts)}"
            )
        translations[locale] = [
            {"label": parts[i * 3], "headline": parts[i * 3 + 1], "body": parts[i * 3 + 2]}
            for i in range(len(SLIDES))
        ]
        print(f"translated {locale}", flush=True)

    TRANSLATIONS.write_text(
        json.dumps(translations, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return translations


def file_uri(path: Path) -> str:
    return path.resolve().as_uri()


def render_html(locale: str, slide: dict[str, str], copy: dict[str, str]) -> str:
    rtl = locale == "ar"
    direction = "rtl" if rtl else "ltr"
    headline_length = len(copy["headline"])
    headline_size = 82 if headline_length < 34 else 72 if headline_length < 52 else 62
    screen = SCREENSHOTS / "generated" / f"{locale}-{slide['screen']}.png"
    if not screen.exists():
        raise FileNotFoundError(screen)
    return f"""<!doctype html>
<html lang="{html.escape(locale)}" dir="{direction}">
<head><meta charset="utf-8"><style>
* {{ box-sizing: border-box; }}
html, body {{ margin: 0; width: 1320px; height: 2868px; overflow: hidden; }}
body {{
  position: relative; color: #171717;
  background: #f4f0e8 url('{file_uri(BACKGROUND)}') center center / cover no-repeat;
  font-family: -apple-system, BlinkMacSystemFont, 'Helvetica Neue', 'Hiragino Sans',
    'Apple SD Gothic Neo', 'PingFang SC', 'Geeza Pro', 'Kohinoor Devanagari', sans-serif;
}}
.brand {{
  position: absolute; top: 118px; left: 92px; right: 92px;
  font: 700 40px/1.1 'New York', 'Times New Roman', 'Hiragino Mincho ProN', serif;
  letter-spacing: 3px; direction: ltr; text-align: left;
}}
.copy {{ position: absolute; top: 330px; left: 92px; right: 92px; text-align: {'right' if rtl else 'left'}; }}
.headline {{
  max-width: 1120px; margin: 0; font-size: {headline_size}px; line-height: 1.34; font-weight: 500;
  letter-spacing: .015em; font-family: 'New York', 'Times New Roman', 'Hiragino Mincho ProN',
    'Songti SC', 'AppleMyungjo', 'Geeza Pro', serif; text-wrap: balance;
}}
.body {{
  margin-top: 54px; max-width: 1040px; font-size: 34px; line-height: 1.75;
  font-weight: 400; letter-spacing: .04em; color: #43413e; text-wrap: balance;
}}
.tag {{
  position: absolute; top: 1660px; {'right' if rtl else 'left'}: 112px; width: 330px;
  text-align: {'right' if rtl else 'left'};
}}
.tag-title {{
  margin: 0; font: 600 51px/1.25 'New York', 'Times New Roman', 'Hiragino Mincho ProN', serif;
}}
.tag-rule {{ width: 70px; height: 1px; background: #77736b; margin: 28px 0 31px {'auto' if rtl else '0'}; }}
.tag-note {{ font-size: 29px; line-height: 1.65; color: #4f4b45; }}
.device {{
  position: absolute; top: 1125px; {'left' if rtl else 'right'}: 62px; width: 735px; height: 1598px;
  padding: 16px; border-radius: 98px; background: linear-gradient(145deg,#111,#4b4b4b 42%,#050505 70%);
  box-shadow: 0 34px 54px rgba(61,49,37,.24), 0 5px 7px rgba(0,0,0,.35);
}}
.screen {{ width: 100%; height: 100%; object-fit: cover; display: block; border-radius: 82px; background: #fff; }}
.device::after {{
  content: ''; position: absolute; inset: 8px; border-radius: 91px;
  border: 2px solid rgba(255,255,255,.45); pointer-events: none;
}}
</style></head>
<body>
  <div class="brand">Yohaku</div>
  <section class="copy">
    <h1 class="headline">{html.escape(copy['headline'])}</h1>
    <div class="body">{html.escape(copy['body'])}</div>
  </section>
  <aside class="tag">
    <h2 class="tag-title">{html.escape(copy['label'])}</h2>
    <div class="tag-rule"></div>
    <div class="tag-note">Yohaku</div>
  </aside>
  <div class="device"><img class="screen" src="{file_uri(screen)}"></div>
</body></html>"""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--refresh-translations", action="store_true")
    args = parser.parse_args()

    if not BACKGROUND.exists():
        raise SystemExit(f"Missing background: {BACKGROUND}")
    if not CHROME.exists():
        raise SystemExit(f"Missing Chrome renderer: {CHROME}")

    translations = build_translations(args.refresh_translations)
    render_root = Path(tempfile.mkdtemp(prefix="yohaku-marketing-"))
    try:
        tasks = []
        for locale in LOCALES:
            locale_output = OUTPUT / locale
            locale_output.mkdir(parents=True, exist_ok=True)
            for index, slide in enumerate(SLIDES, start=1):
                output_path = locale_output / f"{index:02d}-{slide['slug']}.png"
                html_path = render_root / f"{locale}-{index:02d}.html"
                html_path.write_text(
                    render_html(locale, slide, translations[locale][index - 1]), encoding="utf-8"
                )
                tasks.append((html_path, output_path))

        task_manifest = render_root / "tasks.json"
        task_manifest.write_text(
            json.dumps(
                [{"url": html_path.resolve().as_uri(), "output": str(output_path.resolve())}
                 for html_path, output_path in tasks],
                ensure_ascii=False,
            ),
            encoding="utf-8",
        )
        renderer = ROOT / "Scripts" / "render-marketing-pages.mjs"
        subprocess.run(
            ["node", str(renderer), str(CHROME), str(task_manifest)], check=True
        )

        invalid = []
        from PIL import Image

        for _, output_path in tasks:
            with Image.open(output_path) as image:
                if image.size != (1320, 2868):
                    invalid.append(f"{output_path}: {image.size}")
        if invalid:
            raise RuntimeError("Invalid output dimensions:\n" + "\n".join(invalid))
        print(f"complete: {len(tasks)} screenshots", flush=True)
    finally:
        shutil.rmtree(render_root, ignore_errors=True)


if __name__ == "__main__":
    main()
