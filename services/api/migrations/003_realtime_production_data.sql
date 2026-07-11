BEGIN;
CREATE TABLE IF NOT EXISTS bookings (
  id text PRIMARY KEY, passenger_id text NOT NULL, driver_id text,
  status text NOT NULL, pickup jsonb NOT NULL, destination jsonb NOT NULL,
  fare_estimate jsonb, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_bookings_status_updated ON bookings(status, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_bookings_passenger_created ON bookings(passenger_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bookings_driver_status ON bookings(driver_id, status) WHERE driver_id IS NOT NULL;

CREATE TABLE IF NOT EXISTS ride_events (
  id bigserial PRIMARY KEY, booking_id text NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  event_type text NOT NULL, actor_type text, actor_id text, payload jsonb NOT NULL DEFAULT '{}'::jsonb,
  idempotency_key text, occurred_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (booking_id, idempotency_key)
);
CREATE INDEX IF NOT EXISTS idx_ride_events_booking_time ON ride_events(booking_id, occurred_at, id);

CREATE TABLE IF NOT EXISTS gps_tracking_points (
  id bigserial NOT NULL, booking_id text NOT NULL, actor_type text NOT NULL, actor_id text NOT NULL,
  recorded_at timestamptz NOT NULL, received_at timestamptz NOT NULL DEFAULT now(),
  lat double precision NOT NULL CHECK(lat BETWEEN -90 AND 90),
  lng double precision NOT NULL CHECK(lng BETWEEN -180 AND 180),
  accuracy_m real, speed_mps real, heading_deg real,
  source_event_id text NOT NULL,
  PRIMARY KEY(id, recorded_at), UNIQUE(actor_id, source_event_id, recorded_at)
) PARTITION BY RANGE(recorded_at);
CREATE TABLE IF NOT EXISTS gps_tracking_points_default PARTITION OF gps_tracking_points DEFAULT;
CREATE INDEX IF NOT EXISTS idx_gps_booking_time ON gps_tracking_points(booking_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_gps_actor_time ON gps_tracking_points(actor_id, recorded_at DESC);

CREATE TABLE IF NOT EXISTS payment_ledger_entries (
  id text PRIMARY KEY, payment_id text NOT NULL, booking_id text NOT NULL,
  entry_type text NOT NULL, amount_paise bigint NOT NULL CHECK(amount_paise >= 0),
  currency char(3) NOT NULL DEFAULT 'INR', provider text, provider_reference text,
  idempotency_key text NOT NULL UNIQUE, metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_payment_ledger_booking ON payment_ledger_entries(booking_id, created_at DESC);

CREATE TABLE IF NOT EXISTS notification_deliveries (
  id text PRIMARY KEY, notification_id text NOT NULL, audience text NOT NULL, channel text NOT NULL,
  provider text, status text NOT NULL, attempts integer NOT NULL DEFAULT 0,
  next_attempt_at timestamptz, provider_reference text, last_error text,
  payload jsonb NOT NULL DEFAULT '{}'::jsonb, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_notification_due ON notification_deliveries(status, next_attempt_at) WHERE status IN ('QUEUED','RETRY');

CREATE TABLE IF NOT EXISTS active_ride_snapshots (
  booking_id text PRIMARY KEY, status text NOT NULL, passenger_id text NOT NULL, driver_id text,
  last_driver_location jsonb, last_passenger_location jsonb,
  revision bigint NOT NULL DEFAULT 1, updated_at timestamptz NOT NULL DEFAULT now()
);
COMMIT;
