#!/usr/bin/env bash
set -euo pipefail
APP="${1:?usage: validate_android_release_secrets.sh passenger_flutter|driver_flutter|partner_flutter}"
ENVIRONMENT="${2:-production}"

case "$APP" in passenger_flutter|driver_flutter|partner_flutter) ;; *) echo "Unsupported app: $APP" >&2; exit 2;; esac
required=(ANDROID_KEYSTORE_BASE64 ANDROID_STORE_PASSWORD ANDROID_KEY_PASSWORD ANDROID_KEY_ALIAS)
if [[ "$ENVIRONMENT" == production ]]; then required+=(PRODUCTION_API_BASE_URL PRODUCTION_WS_BASE_URL); else required+=(STAGING_API_BASE_URL STAGING_WS_BASE_URL); fi
missing=()
for key in "${required[@]}"; do [[ -n "${!key:-}" ]] || missing+=("$key"); done
if ((${#missing[@]})); then
  printf 'Missing required release secrets/variables:\n' >&2
  printf ' - %s\n' "${missing[@]}" >&2
  exit 3
fi
[[ ${#ANDROID_STORE_PASSWORD} -ge 6 ]] || { echo 'ANDROID_STORE_PASSWORD is unexpectedly short' >&2; exit 4; }
[[ ${#ANDROID_KEY_PASSWORD} -ge 6 ]] || { echo 'ANDROID_KEY_PASSWORD is unexpectedly short' >&2; exit 4; }
if [[ -n "${GOOGLE_MAPS_ANDROID_KEY:-}" && ${#GOOGLE_MAPS_ANDROID_KEY} -lt 20 ]]; then echo 'GOOGLE_MAPS_ANDROID_KEY is unexpectedly short' >&2; exit 4; fi
printf '%s' "$ANDROID_KEYSTORE_BASE64" | base64 --decode >/tmp/astride-keystore-validation.jks
[[ -s /tmp/astride-keystore-validation.jks ]] || { echo 'Decoded keystore is empty' >&2; exit 5; }
rm -f /tmp/astride-keystore-validation.jks
echo "Release inputs validated for $APP ($ENVIRONMENT)"
