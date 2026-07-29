#!/bin/sh
set -eu

# Debug is intentionally configured with Google's official test IDs. This check
# protects only distribution builds from shipping a missing, malformed, or test
# identifier.
if [ "${CONFIGURATION:-}" != "Release" ]; then
  exit 0
fi

app_id="${ADMOB_APP_ID:-}"
unit_id="${ADMOB_BANNER_AD_UNIT_ID:-}"
test_app_id="ca-app-pub-3940256099942544~1458002511"
test_unit_id="ca-app-pub-3940256099942544/2435281174"

fail() {
  echo "error: AdMob Release configuration invalid: $1" >&2
  exit 1
}

[ -n "$app_id" ] || fail "ADMOB_APP_ID is empty"
[ -n "$unit_id" ] || fail "ADMOB_BANNER_AD_UNIT_ID is empty"
[ "$app_id" != "$test_app_id" ] || fail "ADMOB_APP_ID must not be Google's test app ID"
[ "$unit_id" != "$test_unit_id" ] || fail "ADMOB_BANNER_AD_UNIT_ID must not be Google's test unit ID"
case "$app_id" in *__*|*PRODUCTION*|*PLACEHOLDER*) fail "ADMOB_APP_ID is a placeholder";; esac
case "$unit_id" in *__*|*PRODUCTION*|*PLACEHOLDER*) fail "ADMOB_BANNER_AD_UNIT_ID is a placeholder";; esac
echo "$app_id" | grep -Eq '^ca-app-pub-[0-9]+~[0-9]+$' || fail "ADMOB_APP_ID has the wrong format"
echo "$unit_id" | grep -Eq '^ca-app-pub-[0-9]+/[0-9]+$' || fail "ADMOB_BANNER_AD_UNIT_ID has the wrong format"
