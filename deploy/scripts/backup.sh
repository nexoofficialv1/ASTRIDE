#!/bin/sh
set -eu
cd "$(dirname "$0")/../.."
. ./.env.production
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
OUT="deploy/backups/localride_${STAMP}.dump.gz"
mkdir -p deploy/backups
docker compose -f docker-compose.production.yml exec -T postgres pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" -Fc | gzip -9 > "$OUT"
sha256sum "$OUT" > "$OUT.sha256"
find deploy/backups -type f -mtime +14 -delete
echo "$OUT"
