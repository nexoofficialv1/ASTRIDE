#!/usr/bin/env bash
set -euo pipefail
APP="${1:?usage: build_android.sh passenger_flutter|driver_flutter [release|debug] [environment]}"
MODE="${2:-release}"
ENVIRONMENT="${3:-production}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ENV_FILE="$ROOT/mobile_build/environments/$ENVIRONMENT.json"
[[ -f "$ENV_FILE" ]] || { echo "Environment file not found: $ENV_FILE" >&2; exit 2; }
if [[ ! -f "$ROOT/apps/$APP/android/app/build.gradle" && ! -f "$ROOT/apps/$APP/android/app/build.gradle.kts" ]]; then
  bash "$ROOT/mobile_build/scripts/bootstrap_mobile.sh" "$APP"
fi
bash "$ROOT/mobile_build/scripts/inject_maps_key.sh" "$APP"
cd "$ROOT/apps/$APP"
flutter pub get
flutter analyze
flutter test
if [[ "$MODE" == "release" ]]; then
  VERSION_ARGS=()
  [[ -n "${RELEASE_VERSION:-}" ]] && VERSION_ARGS+=(--build-name="$RELEASE_VERSION")
  [[ -n "${RELEASE_BUILD_NUMBER:-}" ]] && VERSION_ARGS+=(--build-number="$RELEASE_BUILD_NUMBER")
  flutter build appbundle --release "${VERSION_ARGS[@]}" --dart-define-from-file="$ENV_FILE"
  flutter build apk --release --split-per-abi "${VERSION_ARGS[@]}" --dart-define-from-file="$ENV_FILE"
else
  flutter build apk --debug --dart-define-from-file="$ENV_FILE"
fi
