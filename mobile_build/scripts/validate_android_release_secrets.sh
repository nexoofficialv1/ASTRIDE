#!/usr/bin/env bash
set -euo pipefail
APP="${1:?usage: validate_android_release_secrets.sh passenger_flutter|driver_flutter|partner_flutter}"
ENVIRONMENT="${2:-production}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
case "$APP" in passenger_flutter|driver_flutter|partner_flutter) ;; *) echo "Unsupported app: $APP" >&2; exit 2;; esac
required=(ANDROID_KEYSTORE_BASE64 ANDROID_STORE_PASSWORD ANDROID_KEY_PASSWORD ANDROID_KEY_ALIAS)
if [[ "$ENVIRONMENT" == production ]]; then required+=(PRODUCTION_API_BASE_URL PRODUCTION_WS_BASE_URL); else required+=(STAGING_API_BASE_URL STAGING_WS_BASE_URL); fi
if [[ "$APP" != partner_flutter ]]; then
  if [[ -z "${FIREBASE_ANDROID_CONFIG_BASE64:-}" && ! -f "$ROOT/mobile_build/firebase/$APP/google-services.json" ]]; then required+=(FIREBASE_ANDROID_CONFIG_BASE64); fi
fi
missing=()
for key in "${required[@]}"; do [[ -n "${!key:-}" ]] || missing+=("$key"); done
if ((${#missing[@]})); then printf 'Missing required release inputs:\n' >&2; printf ' - %s\n' "${missing[@]}" >&2; exit 3; fi
[[ ${#ANDROID_STORE_PASSWORD} -ge 6 ]] || { echo 'ANDROID_STORE_PASSWORD is unexpectedly short' >&2; exit 4; }
[[ ${#ANDROID_KEY_PASSWORD} -ge 6 ]] || { echo 'ANDROID_KEY_PASSWORD is unexpectedly short' >&2; exit 4; }
printf '%s' "$ANDROID_KEYSTORE_BASE64" | base64 --decode >/tmp/astride-keystore-validation.jks
[[ -s /tmp/astride-keystore-validation.jks ]] || { echo 'Decoded keystore is empty' >&2; exit 5; }
rm -f /tmp/astride-keystore-validation.jks
api_key="${PRODUCTION_API_BASE_URL:-${STAGING_API_BASE_URL:-}}"
ws_key="${PRODUCTION_WS_BASE_URL:-${STAGING_WS_BASE_URL:-}}"
[[ "$api_key" == https://* ]] || { echo 'API URL must use HTTPS' >&2; exit 6; }
[[ "$ws_key" == wss://* ]] || { echo 'WebSocket URL must use WSS' >&2; exit 6; }
echo "Release inputs validated for $APP ($ENVIRONMENT)"
