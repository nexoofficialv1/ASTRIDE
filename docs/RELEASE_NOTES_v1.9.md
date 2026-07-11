# v1.9 Production Deployment Stack

Adds hardened production containers, PostgreSQL and Redis health gates, Caddy-managed HTTPS, separate API/admin domains, Docker secrets, read-only API container, bounded logs, preflight validation, database backup/restore scripts, health verification, and systemd backup scheduling.

## Release boundary
This package prepares deployment infrastructure. A real domain, DNS, server, secrets and live provider credentials are still required. Production deployment must pass preflight, migrations, health checks, backup/restore rehearsal and real-device tests.
