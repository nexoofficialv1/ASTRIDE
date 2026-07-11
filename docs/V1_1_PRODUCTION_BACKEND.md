# v1.1 Production Backend Foundation

## Added
- PostgreSQL connection pool with health reporting.
- Ordered SQL migrations and migration runner.
- Production tables for admin users, sessions, audit logs, runtime config versions and encrypted provider credentials.
- Scrypt-based admin password verification with configurable pepper.
- Random 256-bit session tokens, expiry, logout and brute-force lockout.
- Production safety gate: default/demo credentials are rejected when `NODE_ENV=production`.
- Docker Compose baseline for PostgreSQL and API.

## Storage transition status
The schema and PostgreSQL infrastructure are production-capable, but legacy booking/driver/payment repositories still use the compatibility memory stores in this milestone. They will be replaced module-by-module with PostgreSQL repositories in v1.2. This preserves v1.0 regression behavior while the persistence layer is migrated safely.

## First production setup
1. Copy `.env.example` to `.env`.
2. Replace every `CHANGE_...` value.
3. Set a strong `POSTGRES_PASSWORD`.
4. Run `docker compose up`.
5. Confirm `/health` reports `database.mode=postgres`, `connected=true`, and `adminSecurity.productionSafe=true`.
