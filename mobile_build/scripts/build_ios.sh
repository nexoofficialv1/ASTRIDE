#!/usr/bin/env bash
set -euo pipefail
APP="${1:?passenger_flutter or driver_flutter}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT/apps/$APP"
flutter pub get
flutter analyze --no-fatal-infos
flutter test
flutter build ipa --release --export-options-plist="$ROOT/mobile_build/signing/ios/ExportOptions.plist" --dart-define=APP_ENV=production
