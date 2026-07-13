#!/usr/bin/env bash
set -euo pipefail
APP="${1:?usage: package_android_artifacts.sh passenger_flutter|driver_flutter version environment output-dir}"
VERSION="${2:?version required}"
ENVIRONMENT="${3:?environment required}"
OUTPUT="${4:?output dir required}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SOURCE="$ROOT/apps/$APP/build/app/outputs"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?$ ]] || { echo "Invalid version: $VERSION" >&2; exit 2; }
mkdir -p "$OUTPUT"
APP_SHORT="${APP%_flutter}"
found=0
while IFS= read -r -d '' file; do
  ext="${file##*.}"
  base="$(basename "$file" ."$ext")"
  abi="${base#app-}"
  abi="${abi%-release}"
  [[ "$abi" == "release" || "$abi" == "app" ]] && abi="universal"
  target="ASTRIDE-${APP_SHORT}-${VERSION}-${ENVIRONMENT}-${abi}.${ext}"
  cp "$file" "$OUTPUT/$target"
  found=1
done < <(find "$SOURCE" -type f \( -name '*.apk' -o -name '*.aab' \) -print0 2>/dev/null)
[[ $found -eq 1 ]] || { echo "No APK/AAB artifacts found under $SOURCE" >&2; exit 3; }
(
  cd "$OUTPUT"
  sha256sum ./*.apk ./*.aab 2>/dev/null | sort > SHA256SUMS.txt
  python3 - "$APP" "$VERSION" "$ENVIRONMENT" > release-manifest.json <<'PY'
import json, os, platform, sys
from datetime import datetime, timezone
app, version, env = sys.argv[1:]
print(json.dumps({
  'schemaVersion': 1,
  'product': 'ASTRIDE',
  'app': app,
  'version': version,
  'environment': env,
  'generatedAt': datetime.now(timezone.utc).isoformat(),
  'gitCommit': os.getenv('GITHUB_SHA', 'local'),
  'gitRef': os.getenv('GITHUB_REF_NAME', 'local'),
  'buildNumber': os.getenv('RELEASE_BUILD_NUMBER', ''),
}, indent=2))
PY
)
echo "Packaged Android release artifacts in $OUTPUT"
