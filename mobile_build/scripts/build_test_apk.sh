#!/usr/bin/env bash
set -euo pipefail
APP="${1:?usage: build_test_apk.sh passenger_flutter|driver_flutter|partner_flutter [environment]}"
ENVIRONMENT="${2:-production}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ENV_FILE="$ROOT/mobile_build/environments/$ENVIRONMENT.json"
[[ -f "$ENV_FILE" ]] || { echo "Environment file not found: $ENV_FILE" >&2; exit 2; }
bash "$ROOT/mobile_build/scripts/bootstrap_mobile.sh" "$APP"
if [[ "$APP" != partner_flutter ]]; then
  bash "$ROOT/mobile_build/scripts/inject_firebase.sh" "$APP"
  bash "$ROOT/mobile_build/scripts/inject_maps_key.sh" "$APP"
fi
cd "$ROOT/apps/$APP"
flutter pub get
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file="$ENV_FILE"
