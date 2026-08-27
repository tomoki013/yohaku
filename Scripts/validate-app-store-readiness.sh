#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$repo_dir"

fail() {
  echo "error: $1" >&2
  exit 1
}

check_contains() {
  file=$1
  expected=$2
  grep -Fq "$expected" "$file" || fail "$file is missing: $expected"
}

plutil -lint Yohaku/Info.plist >/dev/null
plutil -lint Yohaku/PrivacyInfo.xcprivacy >/dev/null
jq -e . Yohaku/Resources/Localizable.xcstrings >/dev/null
jq -e . Yohaku/Resources/Yohaku.storekit >/dev/null

check_contains project.yml 'PRODUCT_BUNDLE_IDENTIFIER: io.tmkch.yohaku'
check_contains project.yml 'TARGETED_DEVICE_FAMILY: "1"'
check_contains project.yml 'ITSAppUsesNonExemptEncryption: false'
check_contains project.yml 'NSUserTrackingUsageDescription:'
check_contains Yohaku/Utilities/SupportPurchaseStore.swift 'io.tmkch.yohaku.removeads'
check_contains Yohaku/Resources/Yohaku.storekit 'io.tmkch.yohaku.removeads'
check_contains Yohaku/Services/AdConsentManager.swift 'requestTrackingAuthorization'
check_contains Yohaku/Services/AdConsentManager.swift 'ConsentInformation.shared.canRequestAds'

icon_info=$(sips -g pixelWidth -g pixelHeight -g hasAlpha Yohaku/Assets.xcassets/AppIcon.appiconset/AppIcon.png)
echo "$icon_info" | grep -Fq 'pixelWidth: 1024' || fail 'App icon width must be 1024'
echo "$icon_info" | grep -Fq 'pixelHeight: 1024' || fail 'App icon height must be 1024'
echo "$icon_info" | grep -Fq 'hasAlpha: no' || fail 'App icon must not have alpha'

# Every shipping language needs the full set of shots. Both lists are read
# from the files that define them, so adding a locale to the string catalog or
# a shot to the UI test extends this check instead of silently passing.
locales=$(jq -r '[.strings[].localizations // {} | keys[]] | unique[]' Yohaku/Resources/Localizable.xcstrings)
shots=$(grep -oE '\(prefix\)-[a-z0-9-]+' YohakuUITests/AppStoreScreenshotTests.swift | sed 's/^(prefix)-//' | sort -u)
[ -n "$locales" ] || fail 'Could not read locales from Localizable.xcstrings'
[ -n "$shots" ] || fail 'Could not read screenshot names from AppStoreScreenshotTests.swift'

expected_count=0
missing=''
for locale in $locales
do
  for shot in $shots
  do
    expected_count=$((expected_count + 1))
    [ -f "AppStore/Screenshots/generated/$locale-$shot.png" ] || missing="$missing $locale-$shot"
  done
done
[ -z "$missing" ] || fail "Missing generated App Store screenshots:$missing"

screenshot_count=$(find AppStore/Screenshots/generated -name '*.png' -type f | wc -l | tr -d ' ')
[ "$screenshot_count" = "$expected_count" ] ||
  fail "Expected $expected_count generated App Store screenshots, found $screenshot_count"

wrong_size=$(sips -g pixelWidth -g pixelHeight AppStore/Screenshots/generated/*.png |
  awk '/^\//{file=$0} /pixelWidth:/{w=$2} /pixelHeight:/{h=$2; if (w != 1320 || h != 2868) print file}')
[ -z "$wrong_size" ] || fail "Generated screenshots must be 1320x2868: $wrong_size"

CONFIGURATION=Release \
ADMOB_APP_ID=ca-app-pub-8687520805381056~6166567024 \
ADMOB_BANNER_AD_UNIT_ID=ca-app-pub-8687520805381056/6272975863 \
  Scripts/validate-admob-release.sh

if [ "${1:-}" = "--online" ]; then
  for url in \
    https://yohaku.tmkch.io/ \
    https://yohaku.tmkch.io/privacy \
    https://yohaku.tmkch.io/terms \
    https://yohaku.tmkch.io/commercial-transactions \
    https://tmkch.io/app-ads.txt \
    https://yohaku.tmkch.io/app-ads.txt
  do
    status=$(curl -L -sS -o /dev/null -w '%{http_code}' --max-time 15 "$url")
    [ "$status" = "200" ] || fail "$url returned HTTP $status"
  done
fi

echo 'App Store readiness checks passed.'
