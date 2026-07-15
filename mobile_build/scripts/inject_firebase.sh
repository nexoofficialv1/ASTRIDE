#!/usr/bin/env bash
set -euo pipefail
APP="${1:?usage: inject_firebase.sh passenger_flutter|driver_flutter|partner_flutter}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP_DIR="$ROOT/apps/$APP"
mkdir -p "$APP_DIR/android/app" "$APP_DIR/ios/Runner"

if [[ "$APP" == "partner_flutter" && -z "${FIREBASE_ANDROID_CONFIG_BASE64:-}" && ! -f "$ROOT/mobile_build/firebase/$APP/google-services.json" ]]; then
  echo "Partner Firebase is optional; building without FCM."
  exit 0
fi

if [[ -n "${FIREBASE_ANDROID_CONFIG_BASE64:-}" ]]; then
  printf '%s' "$FIREBASE_ANDROID_CONFIG_BASE64" | base64 --decode > "$APP_DIR/android/app/google-services.json"
elif [[ -f "$ROOT/mobile_build/firebase/$APP/google-services.json" ]]; then
  cp "$ROOT/mobile_build/firebase/$APP/google-services.json" "$APP_DIR/android/app/google-services.json"
elif [[ "${FIREBASE_REQUIRED:-false}" == "true" ]]; then
  echo "Missing Android Firebase config for $APP" >&2
  exit 2
else
  echo "Firebase Android config not supplied; continuing without Firebase."
fi

if [[ -f "$APP_DIR/android/app/google-services.json" ]]; then
  python3 "$ROOT/mobile_build/scripts/validate_firebase_package.py" "$APP" "$APP_DIR/android/app/google-services.json"
fi
