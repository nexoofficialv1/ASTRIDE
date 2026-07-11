# v1.0 Release Candidate Integration

## Included
- Passenger, Driver, Admin, booking, fare, matching, tracking, payment, settlement, SOS, fraud/risk and remote configuration contracts integrated.
- Provider-neutral adapters and backend-controlled provider switching.
- English, Bengali and Hindi locale parity gate.
- Full end-to-end release-candidate smoke journey.
- Docker Compose deployment baseline for API, PostgreSQL and Redis.
- Environment variable template with no production secrets committed.

## Important production blockers
This RC remains a runnable integration baseline, not a store-ready commercial release. Before launch, replace in-memory stores with PostgreSQL repositories, mock providers with certified live integrations, demo admin authentication with database-backed hashed credentials/MFA, and Flutter shells with signed native builds and real device permission handling.

## Release gates
1. `cd services/api && npm test`
2. No secrets committed.
3. Live provider webhooks verified.
4. Database migration and rollback tested.
5. Android/iOS real-device field test completed.
6. Load, security, backup/restore and disaster-recovery tests passed.
