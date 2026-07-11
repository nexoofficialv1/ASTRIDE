BEGIN;
CREATE TABLE IF NOT EXISTS driver_service_preferences (
 driver_id uuid PRIMARY KEY, accepts_cash boolean NOT NULL DEFAULT true, accepts_upi boolean NOT NULL DEFAULT true,
 accepts_outside_area boolean NOT NULL DEFAULT false, night_service_enabled boolean NOT NULL DEFAULT false,
 saferide_eligible boolean NOT NULL DEFAULT false, updated_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS fare_quotes_v3 (
 id uuid PRIMARY KEY, passenger_id uuid, ride_type text NOT NULL, distance_km numeric(8,2) NOT NULL,
 payment_preference text NOT NULL, is_outside_area boolean NOT NULL DEFAULT false, is_night boolean NOT NULL DEFAULT false,
 saferide_enabled boolean NOT NULL DEFAULT false, quote jsonb NOT NULL, expires_at timestamptz NOT NULL, created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS promoter_withdrawal_requests (
 id uuid PRIMARY KEY, beneficiary_id uuid NOT NULL, amount numeric(12,2) NOT NULL, status text NOT NULL DEFAULT 'REQUESTED',
 requested_at timestamptz NOT NULL DEFAULT now(), processed_at timestamptz, reference text);
CREATE INDEX IF NOT EXISTS idx_fare_quotes_v3_expiry ON fare_quotes_v3(expires_at);
COMMIT;
