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

screenshot_count=$(find AppStore/Screenshots/generated -name '*.png' -type f | wc -l | tr -d ' ')
[ "$screenshot_count" = "8" ] || fail 'Expected 8 generated App Store screenshots'
for screenshot in AppStore/Screenshots/generated/*.png
do
  screenshot_info=$(sips -g pixelWidth -g pixelHeight "$screenshot")
  echo "$screenshot_info" | grep -Fq 'pixelWidth: 1320' || fail "$screenshot must be 1320px wide"
  echo "$screenshot_info" | grep -Fq 'pixelHeight: 2868' || fail "$screenshot must be 2868px tall"
done

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
