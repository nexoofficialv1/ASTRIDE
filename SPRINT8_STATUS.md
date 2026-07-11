# ASTRIDE v3.5 Sprint 8 — Map, Zone & Navigation Integration

## Implemented
- Provider-neutral route calculation contract with Mappls/Google/OSM adapters.
- Non-zero route distance, duration and geometry fallback estimation for test mode.
- Service-area, high-risk and dynamic-fare polygon evaluation.
- Outside-area detection and Full Toto-only enforcement.
- 29 km maximum Toto distance enforcement.
- Admin zone CRUD API and auditable zone changes.
- Passenger map-zone API client and Driver navigation API client.
- PostgreSQL migration for service zones and route decisions.

## API
- `GET /v1/zones`
- `POST /v1/maps/context`
- `GET /v1/admin/zones`
- `POST /v1/admin/zones`
- `DELETE /v1/admin/zones/:code`
- Existing `POST /v1/maps/route` now returns usable test-mode estimates.

## Validated
- Point-in-polygon logic.
- Local/outside classification.
- High-risk-zone detection.
- Share Toto outside-area rejection.
- Full Toto outside-area acceptance up to 29 km.
- Map route distance and ETA output.
- Sprint 2, Sprint 3 and Sprint 7 regression contracts.

## Not yet live-provider tested
Real Mappls/Google geocoding, traffic, turn-by-turn navigation and polygon rendering require live credentials and native Flutter builds.
