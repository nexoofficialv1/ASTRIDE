#!/usr/bin/env bash
set -euo pipefail

APP="${1:?usage: fetch_api_certificate.sh passenger_flutter|driver_flutter|partner_flutter}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
HOST="${ASTRIDE_API_PIN_HOST:-astaride.nexoofficial.in}"
PORT="${ASTRIDE_API_PIN_PORT:-443}"
TARGET="$ROOT/apps/$APP/assets/security/astride_api_chain.pem"
TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

command -v openssl >/dev/null 2>&1 || {
  echo "openssl is required to obtain the production certificate chain" >&2
  exit 2
}

set +e
if command -v timeout >/dev/null 2>&1; then
  timeout 25 openssl s_client \
    -showcerts \
    -verify_return_error \
    -servername "$HOST" \
    -connect "$HOST:$PORT" </dev/null 2>/dev/null |
    awk '/-----BEGIN CERTIFICATE-----/{capture=1} capture{print} /-----END CERTIFICATE-----/{capture=0}' > "$TMP"
  STATUS=$?
else
  openssl s_client \
    -showcerts \
    -verify_return_error \
    -servername "$HOST" \
    -connect "$HOST:$PORT" </dev/null 2>/dev/null |
    awk '/-----BEGIN CERTIFICATE-----/{capture=1} capture{print} /-----END CERTIFICATE-----/{capture=0}' > "$TMP"
  STATUS=$?
fi
set -e

if [[ $STATUS -ne 0 ]] || ! grep -q -- '-----BEGIN CERTIFICATE-----' "$TMP" || ! grep -q -- '-----END CERTIFICATE-----' "$TMP"; then
  echo "Unable to obtain a verified TLS certificate chain from $HOST:$PORT" >&2
  exit 3
fi

mkdir -p "$(dirname "$TARGET")"
install -m 0644 "$TMP" "$TARGET"
openssl crl2pkcs7 -nocrl -certfile "$TARGET" | openssl pkcs7 -print_certs -noout >/dev/null

echo "Pinned TLS certificate chain prepared for $APP ($HOST)"
