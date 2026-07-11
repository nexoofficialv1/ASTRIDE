# Production deployment

1. Use a Linux VPS with Docker Engine and Compose v2.
2. Point `API_DOMAIN` and `ADMIN_DOMAIN` DNS A/AAAA records to the server.
3. Copy `.env.production.example` to `.env.production` and replace every placeholder.
4. Create `secrets/postgres_password.txt` with a long random password and restrict permissions to 600.
5. Run `./deploy/scripts/preflight.sh`.
6. Run `./deploy/scripts/deploy.sh`.
7. Verify `https://API_DOMAIN/health` and Admin Console login.
8. Run `./deploy/scripts/backup.sh`, then rehearse restoration on a separate test database/server.

Do not expose PostgreSQL or Redis ports publicly. Do not commit `.env.production`, secrets, provider keys or production backups.
