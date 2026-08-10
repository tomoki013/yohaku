# App Store screenshots

`AppStoreScreenshotTests` generates seven screens for each of the 18 shipped
localizations on iPhone 17 Pro Max, at the real 1320x2868 submission size.

Navigation uses accessibility identifiers (`settings-button`, `add-button`,
`close-button`, `reflection-question`) rather than translated labels, so one run
covers Arabic and Thai without a table of button names. Demo data comes from the
localized `name.pool.N` catalog, so nothing is left in Japanese or English
inside another store's screenshots.

Pin the status bar first, or captures carry the host clock and battery:

```sh
xcrun simctl boot "iPhone 17 Pro Max"
xcrun simctl status_bar "iPhone 17 Pro Max" override \
  --time "9:41" --batteryState discharging --batteryLevel 100 \
  --cellularMode active --cellularBars 4 --wifiMode active --wifiBars 3
```

```sh
xcodegen generate
xcodebuild -project Yohaku.xcodeproj -scheme Yohaku \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -resultBundlePath /tmp/YohakuShots.xcresult \
  -only-testing:YohakuUITests/AppStoreScreenshotTests test

xcrun xcresulttool export attachments \
  --path /tmp/YohakuShots.xcresult \
  --output-path AppStore/Screenshots/generated
```

`xcresulttool` writes UUID filenames; the readable name is in its
`manifest.json` under `suggestedHumanReadableName`, as `<lang>-<nn>-<screen>`.

The run shows no test ads and no ATT/UMP prompt — only demo data — so these are
submittable as-is. The brand site imports a bilingual subset of the same files
via `scripts/import-app-screenshots.mjs` in the app-studio monorepo.
