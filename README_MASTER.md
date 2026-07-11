> Current milestone: **v3.0 Sprint 2 — Business API & Promoter Wiring**

# ASTRIDE Master Platform

One repository containing:

- `apps/passenger_flutter` — Passenger Android/iOS app
- `apps/driver_flutter` — Driver Android/iOS app
- `apps/admin_control_console` — Internal operations console
- `services/api` — Backend API, WebSocket and provider adapters
- `services/api/migrations` — PostgreSQL migrations
- `deploy` / `docker-compose.production.yml` — Server deployment and backup
- `.github/workflows` — Test and release pipelines

Use this master package only. See `MASTER_BUILD_STATUS.md` for verified and pending release gates.

## v2.6: first real Android compile gate

Run the GitHub workflow **Android Compile Check**. It bootstraps, analyzes, tests, and compiles both Passenger and Driver debug APKs without production signing or Firebase credentials. This is the first authoritative native compilation gate; a green workflow is required before calling either APK build-ready.
