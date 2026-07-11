#!/bin/sh
set -eu
cd "$(dirname "$0")/../.."
echo "Container rollback requires the previous immutable image tag/release checkout."
echo "Database rollback is intentionally not automatic; restore a verified backup only after review."
docker compose -f docker-compose.production.yml --env-file .env.production ps
