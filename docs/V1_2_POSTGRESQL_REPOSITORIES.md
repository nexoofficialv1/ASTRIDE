# v1.2 PostgreSQL Repository Migration

v1.2 introduces a durable operational repository layer for Passenger, Driver, Booking/Runtime Driver, Tracking, Payment, Settlement, Complaint, SOS, Risk and Notification state.

## Runtime modes

- `DATABASE_URL` absent: deterministic in-memory mode for local smoke tests.
- `DATABASE_URL` present: PostgreSQL durable mode.

The HTTP/domain API remains synchronous and stable while a write-behind repository coordinator persists module snapshots transactionally. On production boot, state is hydrated before the server starts accepting traffic. Each completed request schedules a short, coalesced persistence flush; operators can also force a flush and inspect storage status from the secured Admin API.

## Admin endpoints

- `GET /v1/admin/storage/status`
- `POST /v1/admin/storage/flush`

Both require privileged admin access.

## Durability and integrity

- JSONB payloads are revisioned per module namespace.
- Every write records a SHA-256 checksum in `repository_write_log`.
- Writes use PostgreSQL transactions.
- Failed flushes keep the state marked dirty and expose the error in storage status.
- Test mode remains isolated from production data.

## Next normalization step

The repository boundary is now stable. High-volume tables such as GPS samples, booking events and payment ledger entries can be normalized and partitioned later without changing mobile API contracts.
