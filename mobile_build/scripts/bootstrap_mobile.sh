#!/usr/bin/env bash
set -euo pipefail

APP="${1:?usage: bootstrap_mobile.sh passenger_flutter|driver_flutter|partner_flutter}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP_DIR="$ROOT/apps/$APP"

case "$APP" in
  passenger_flutter)
    PROJECT_NAME="astride_passenger"
    ORG="com.nexo.astride"
    ;;
  driver_flutter)
    PROJECT_NAME="astride_driver"
    ORG="com.nexo.astride"
    ;;
  partner_flutter)
    PROJECT_NAME="astride_partner"
    ORG="com.nexo.astride"
    ;;
  *)
    echo "Unsupported app: $APP" >&2
    exit 2
    ;;
esac

command -v flutter >/dev/null 2>&1 || {
  echo "Flutter SDK is required but was not found in PATH." >&2
  exit 3
}

[[ -f "$APP_DIR/pubspec.yaml" && -f "$APP_DIR/lib/main.dart" ]] || {
  echo "Flutter source is incomplete for $APP" >&2
  exit 4
}

# Generate platform scaffolding in a temporary directory so `flutter create`
# cannot overwrite the maintained lib/, assets/, or pubspec.yaml files.
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
flutter create \
  --platforms=android,ios \
  --org "$ORG" \
  --project-name "$PROJECT_NAME" \
  "$TMP_DIR/generated" >/dev/null

rm -rf "$APP_DIR/android" "$APP_DIR/ios"
cp -a "$TMP_DIR/generated/android" "$APP_DIR/android"
cp -a "$TMP_DIR/generated/ios" "$APP_DIR/ios"

# Patch the generated native files instead of replacing them. Replacing the
# manifest/plist would remove Flutter's MainActivity and mandatory bundle keys.
python3 "$ROOT/mobile_build/scripts/patch_native.py" "$ROOT" "$APP"
python3 "$ROOT/mobile_build/scripts/patch_android_signing.py" "$APP_DIR"

cd "$APP_DIR"
flutter pub get
flutter pub run flutter_launcher_icons
flutter pub run flutter_native_splash:create

echo "Bootstrapped native Android/iOS projects for $APP"
