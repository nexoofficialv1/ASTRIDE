#!/bin/sh
set -eu
[ $# -eq 1 ] || { echo "Usage: $0 backup.dump.gz"; exit 1; }
cd "$(dirname "$0")/../.."
. ./.env.production
FILE=$1
[ -f "$FILE" ] || { echo "Backup not found"; exit 1; }
gzip -dc "$FILE" | docker compose -f docker-compose.production.yml exec -T postgres pg_restore -U "$POSTGRES_USER" -d "$POSTGRES_DB" --clean --if-exists
