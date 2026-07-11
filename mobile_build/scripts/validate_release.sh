#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
for app in passenger_flutter driver_flutter; do
  test -f "$ROOT/apps/$app/assets/brand/app_icon.png"
  test -f "$ROOT/apps/$app/assets/brand/splash_logo.png"
  grep -q 'flutter_launcher_icons' "$ROOT/apps/$app/pubspec.yaml"
  grep -q 'flutter_native_splash' "$ROOT/apps/$app/pubspec.yaml"
done
for f in android-release.yml ios-release.yml quality-gate.yml; do test -f "$ROOT/.github/workflows/$f"; done
echo 'v2.3 native release structure passed'
