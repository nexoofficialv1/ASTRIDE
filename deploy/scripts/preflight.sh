#!/bin/sh
set -eu
command -v docker >/dev/null
[ -f .env.production ] || { echo "Missing .env.production"; exit 1; }
[ -s secrets/postgres_password.txt ] || { echo "Missing postgres password secret"; exit 1; }
for key in API_DOMAIN ADMIN_DOMAIN POSTGRES_DB POSTGRES_USER DATABASE_URL REDIS_URL ADMIN_PASSWORD OPS_PASSWORD FINANCE_PASSWORD ADMIN_PASSWORD_PEPPER PROVIDER_CREDENTIALS_MASTER_KEY; do
  grep -q "^${key}=" .env.production || { echo "Missing $key"; exit 1; }
done
if grep -Eq 'CHANGE_ME|example\.com' .env.production secrets/postgres_password.txt; then
  echo "Unsafe placeholder detected"; exit 1
fi
docker compose -f docker-compose.production.yml --env-file .env.production config >/dev/null
echo "Preflight passed"
