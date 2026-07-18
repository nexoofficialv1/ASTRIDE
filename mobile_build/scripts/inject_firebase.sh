#!/usr/bin/env bash
set -euo pipefail

APP="${1:?usage: inject_firebase.sh passenger_flutter|driver_flutter|partner_flutter}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP_DIR="$ROOT/apps/$APP"
TARGET="$APP_DIR/android/app/google-services.json"
FALLBACK="$ROOT/mobile_build/firebase/$APP/google-services.json"

mkdir -p "$APP_DIR/android/app" "$APP_DIR/ios/Runner"

case "$APP" in
  passenger_flutter|driver_flutter) ;;
  partner_flutter)
    if [[ -z "${FIREBASE_ANDROID_CONFIG_BASE64:-}" && ! -s "$FALLBACK" ]]; then
      echo "Partner Firebase is optional; building without FCM."
      exit 0
    fi
    ;;
  *)
    echo "Unsupported app: $APP" >&2
    exit 2
    ;;
esac

rm -f "$TARGET"

if [[ -n "${FIREBASE_ANDROID_CONFIG_BASE64:-}" ]]; then
  if ! printf '%s' "$FIREBASE_ANDROID_CONFIG_BASE64" | base64 --decode > "$TARGET"; then
    echo "Invalid FIREBASE_ANDROID_CONFIG_BASE64 for $APP" >&2
    rm -f "$TARGET"
    exit 3
  fi
  echo "Injected Firebase config for $APP from GitHub secret."
elif [[ -s "$FALLBACK" ]]; then
  cp "$FALLBACK" "$TARGET"
  echo "Injected Firebase config for $APP from repository fallback."
elif [[ "${FIREBASE_REQUIRED:-false}" == "true" || "$APP" != "partner_flutter" ]]; then
  echo "Missing Android Firebase config for $APP" >&2
  echo "Expected GitHub secret or fallback file: mobile_build/firebase/$APP/google-services.json" >&2
  exit 4
else
  echo "Firebase Android config not supplied; continuing without Firebase."
  exit 0
fi

[[ -s "$TARGET" ]] || {
  echo "Firebase config was created but is empty for $APP" >&2
  exit 5
}

python3 "$ROOT/mobile_build/scripts/validate_firebase_package.py" "$APP" "$TARGET"
echo "Firebase config ready: $TARGET"
