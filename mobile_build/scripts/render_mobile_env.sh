#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:?usage: render_mobile_env.sh staging|production [output-file]}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
OUTPUT="${2:-$ROOT/mobile_build/environments/$ENVIRONMENT.json}"

existing_value() {
  python3 - "$1" "$2" <<'PYREAD'
import json,sys
from pathlib import Path
p=Path(sys.argv[1])
try:
    data=json.loads(p.read_text(encoding='utf-8'))
    print(data.get(sys.argv[2],''))
except Exception:
    print('')
PYREAD
}

EXISTING_API="$(existing_value "$OUTPUT" API_BASE_URL)"
EXISTING_WS="$(existing_value "$OUTPUT" WS_BASE_URL)"

case "$ENVIRONMENT" in
  production)
    API_URL="${PRODUCTION_API_BASE_URL:-${API_BASE_URL:-$EXISTING_API}}"
    WS_URL="${PRODUCTION_WS_BASE_URL:-${WS_BASE_URL:-$EXISTING_WS}}"
    DEBUG_LOGS=false
    ;;
  staging)
    API_URL="${STAGING_API_BASE_URL:-${API_BASE_URL:-$EXISTING_API}}"
    WS_URL="${STAGING_WS_BASE_URL:-${WS_BASE_URL:-$EXISTING_WS}}"
    DEBUG_LOGS=true
    ;;
  *) echo "Unsupported environment: $ENVIRONMENT" >&2; exit 2 ;;
esac

python3 - "$ENVIRONMENT" "$API_URL" "$WS_URL" "$DEBUG_LOGS" "$OUTPUT" <<'PY'
from __future__ import annotations
import json, re, sys
from pathlib import Path
from urllib.parse import urlparse

env, api, ws, debug, output = sys.argv[1:]
errors=[]
if not api: errors.append('API base URL is missing')
if not ws: errors.append('WebSocket base URL is missing')
for label, value, schemes in [('API', api, {'https'}), ('WebSocket', ws, {'wss'})]:
    if value:
        parsed=urlparse(value)
        if parsed.scheme not in schemes: errors.append(f'{label} URL must use {"/".join(sorted(schemes))}')
        if not parsed.netloc: errors.append(f'{label} URL has no hostname')
        host=(parsed.hostname or '').lower()
        if env == 'production' and (host.endswith('.example') or host in {'example.com','localhost','127.0.0.1'}):
            errors.append(f'{label} URL still uses a placeholder/local hostname')
        if parsed.path not in ('', '/') or parsed.params or parsed.query or parsed.fragment:
            errors.append(f'{label} URL must be an origin without path/query/fragment')
if errors:
    print('Mobile environment validation failed:', file=sys.stderr)
    for e in errors: print(f' - {e}', file=sys.stderr)
    raise SystemExit(3)
Path(output).parent.mkdir(parents=True, exist_ok=True)
Path(output).write_text(json.dumps({
    'APP_ENV': env,
    'API_BASE_URL': api.rstrip('/'),
    'WS_BASE_URL': ws.rstrip('/'),
    'ENABLE_DEBUG_LOGS': debug.lower(),
    'ALLOW_INSECURE_HTTP': 'false',
}, indent=2) + '\n', encoding='utf-8')
print(f'Rendered validated {env} mobile environment: {output}')
PY
