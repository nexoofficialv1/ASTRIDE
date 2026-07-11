#!/usr/bin/env bash
set -euo pipefail
APP="${1:?usage: inject_maps_key.sh passenger_flutter|driver_flutter}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
FILE="$ROOT/apps/$APP/android/app/src/main/res/values/astride_keys.xml"
[[ -f "$FILE" ]] || { echo "Map key resource not found. Bootstrap first." >&2; exit 2; }
KEY="${GOOGLE_MAPS_ANDROID_KEY:-}"
python3 - "$FILE" "$KEY" <<'PY'
from pathlib import Path
import sys
p=Path(sys.argv[1]); key=sys.argv[2]
s=p.read_text(encoding='utf-8').replace('${GOOGLE_MAPS_ANDROID_KEY}', key)
p.write_text(s, encoding='utf-8')
PY
