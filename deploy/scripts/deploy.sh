#!/bin/sh
set -eu
cd "$(dirname "$0")/../.."
./deploy/scripts/preflight.sh
mkdir -p releases
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
printf '%s\n' "$STAMP" > releases/current-release.txt
docker compose -f docker-compose.production.yml --env-file .env.production build --pull
docker compose -f docker-compose.production.yml --env-file .env.production up -d --remove-orphans
./deploy/scripts/healthcheck.sh
printf '%s\n' "$STAMP" > releases/last-good-release.txt
echo "Deployment successful: $STAMP"
