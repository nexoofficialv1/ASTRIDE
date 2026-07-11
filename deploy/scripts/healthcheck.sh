#!/bin/sh
set -eu
. ./.env.production
TRIES=30
while [ "$TRIES" -gt 0 ]; do
  if wget -qO- "https://${API_DOMAIN}/health" >/tmp/localride-health.json 2>/dev/null; then
    grep -q '"ok"' /tmp/localride-health.json && { echo "API healthy"; exit 0; }
  fi
  TRIES=$((TRIES-1)); sleep 2
done
echo "Health check failed"; docker compose -f docker-compose.production.yml logs --tail=100 api; exit 1
