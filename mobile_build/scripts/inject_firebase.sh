#!/usr/bin/env bash
set -euo pipefail
APP="${1:?usage: inject_firebase.sh passenger_flutter|driver_flutter}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP_DIR="$ROOT/apps/$APP"
mkdir -p "$APP_DIR/android/app" "$APP_DIR/ios/Runner"

if [[ -n "${FIREBASE_ANDROID_CONFIG_BASE64:-}" ]]; then
  printf '%s' "$FIREBASE_ANDROID_CONFIG_BASE64" | base64 --decode > "$APP_DIR/android/app/google-services.json"
elif [[ -f "$ROOT/mobile_build/firebase/$APP/google-services.json" ]]; then
  cp "$ROOT/mobile_build/firebase/$APP/google-services.json" "$APP_DIR/android/app/google-services.json"
elif [[ "${FIREBASE_REQUIRED:-false}" == "true" ]]; then
  echo "Missing Android Firebase config for $APP" >&2
  exit 2
else
  echo "Firebase Android config not supplied; continuing with compile-only build."
fi

if [[ "${INJECT_IOS_FIREBASE:-false}" == "true" ]]; then
  if [[ -n "${FIREBASE_IOS_CONFIG_BASE64:-}" ]]; then
    printf '%s' "$FIREBASE_IOS_CONFIG_BASE64" | base64 --decode > "$APP_DIR/ios/Runner/GoogleService-Info.plist"
  elif [[ -f "$ROOT/mobile_build/firebase/$APP/GoogleService-Info.plist" ]]; then
    cp "$ROOT/mobile_build/firebase/$APP/GoogleService-Info.plist" "$APP_DIR/ios/Runner/GoogleService-Info.plist"
  else
    echo "Missing iOS Firebase config for $APP" >&2
    exit 3
  fi
fi
