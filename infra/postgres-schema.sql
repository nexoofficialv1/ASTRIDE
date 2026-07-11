CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TYPE user_role AS ENUM ('PASSENGER','DRIVER','ADMIN','SUPPORT','FINANCE','SAFETY');
CREATE TYPE booking_status AS ENUM ('DRAFT','SEARCHING','DRIVER_ASSIGNED','DRIVER_ARRIVING','DRIVER_ARRIVED','OTP_VERIFIED','IN_PROGRESS','COMPLETED','CANCELLED_BY_PASSENGER','CANCELLED_BY_DRIVER','CANCELLED_BY_ADMIN','NO_DRIVER_FOUND','NO_SHOW');
CREATE TABLE users(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),mobile varchar(20) UNIQUE NOT NULL,role user_role NOT NULL,preferred_language char(2) NOT NULL CHECK(preferred_language IN('en','bn','hi')),is_active boolean NOT NULL DEFAULT true,created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE passenger_profiles(user_id uuid PRIMARY KEY REFERENCES users(id),full_name text,emergency_mobile varchar(20),rating numeric(3,2) DEFAULT 5.00);
CREATE TABLE driver_profiles(user_id uuid PRIMARY KEY REFERENCES users(id),full_name text NOT NULL,approval_status text NOT NULL DEFAULT 'PENDING',online boolean NOT NULL DEFAULT false,rating numeric(3,2) DEFAULT 5.00,current_lat numeric,current_lng numeric,last_location_at timestamptz);
CREATE TABLE vehicles(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),driver_id uuid NOT NULL REFERENCES driver_profiles(user_id),registration_no text UNIQUE NOT NULL,vehicle_type text NOT NULL DEFAULT 'TOTO',is_active boolean NOT NULL DEFAULT true);
CREATE TABLE bookings(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),passenger_id uuid NOT NULL REFERENCES passenger_profiles(user_id),driver_id uuid REFERENCES driver_profiles(user_id),status booking_status NOT NULL DEFAULT 'DRAFT',pickup_lat numeric NOT NULL,pickup_lng numeric NOT NULL,pickup_address text,destination_lat numeric NOT NULL,destination_lng numeric NOT NULL,destination_address text,estimated_fare numeric(10,2),final_fare numeric(10,2),ride_otp_hash text,created_at timestamptz NOT NULL DEFAULT now(),started_at timestamptz,completed_at timestamptz);
CREATE TABLE ride_events(id bigserial PRIMARY KEY,booking_id uuid NOT NULL REFERENCES bookings(id),event_type text NOT NULL,payload jsonb NOT NULL DEFAULT '{}',created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE driver_locations(id bigserial PRIMARY KEY,driver_id uuid NOT NULL REFERENCES driver_profiles(user_id),booking_id uuid REFERENCES bookings(id),lat numeric NOT NULL,lng numeric NOT NULL,heading numeric,speed numeric,recorded_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE payments(id uuid PRIMARY KEY DEFAULT gen_random_uuid(),booking_id uuid UNIQUE NOT NULL REFERENCES bookings(id),method text NOT NULL,status text NOT NULL,amount numeric(10,2) NOT NULL,gateway_reference text,created_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE audit_logs(id bigserial PRIMARY KEY,actor_user_id uuid REFERENCES users(id),action text NOT NULL,entity_type text NOT NULL,entity_id text,metadata jsonb NOT NULL DEFAULT '{}',created_at timestamptz NOT NULL DEFAULT now());
CREATE INDEX idx_bookings_status ON bookings(status);CREATE INDEX idx_driver_online ON driver_profiles(online,approval_status);CREATE INDEX idx_driver_locations_latest ON driver_locations(driver_id,recorded_at DESC);

-- Remote configuration and provider control
CREATE TABLE IF NOT EXISTS service_provider_configs (
  id BIGSERIAL PRIMARY KEY,
  service_type TEXT NOT NULL,
  provider_code TEXT NOT NULL,
  environment TEXT NOT NULL DEFAULT 'test',
  is_active BOOLEAN NOT NULL DEFAULT FALSE,
  is_fallback BOOLEAN NOT NULL DEFAULT FALSE,
  encrypted_credentials JSONB NOT NULL DEFAULT '{}'::jsonb,
  public_options JSONB NOT NULL DEFAULT '{}'::jsonb,
  updated_by BIGINT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(service_type, provider_code, environment)
);

CREATE TABLE IF NOT EXISTS remote_app_config (
  id BIGSERIAL PRIMARY KEY,
  config_version BIGINT NOT NULL,
  config_key TEXT NOT NULL,
  config_value JSONB NOT NULL,
  audience TEXT NOT NULL DEFAULT 'all',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  updated_by BIGINT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(config_key, audience)
);

CREATE TABLE IF NOT EXISTS configuration_audit_log (
  id BIGSERIAL PRIMARY KEY,
  actor_admin_id BIGINT,
  action TEXT NOT NULL,
  before_value JSONB,
  after_value JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- v0.4 Passenger experience
CREATE TABLE IF NOT EXISTS passenger_saved_places (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  passenger_id UUID NOT NULL REFERENCES passenger_profiles(user_id) ON DELETE CASCADE,
  label TEXT NOT NULL,
  address TEXT NOT NULL,
  lat NUMERIC NOT NULL,
  lng NUMERIC NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS otp_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), mobile VARCHAR(20) NOT NULL,
  code_hash TEXT NOT NULL, provider_code TEXT NOT NULL, expires_at TIMESTAMPTZ NOT NULL,
  verified_at TIMESTAMPTZ, attempts INT NOT NULL DEFAULT 0, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS ride_ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), booking_id UUID NOT NULL REFERENCES bookings(id),
  passenger_id UUID NOT NULL REFERENCES passenger_profiles(user_id), score INT NOT NULL CHECK(score BETWEEN 1 AND 5),
  comment TEXT, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS support_complaints (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), booking_id UUID REFERENCES bookings(id),
  passenger_id UUID REFERENCES passenger_profiles(user_id), category TEXT NOT NULL, description TEXT NOT NULL,
  priority TEXT NOT NULL DEFAULT 'NORMAL', status TEXT NOT NULL DEFAULT 'OPEN', created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE TABLE IF NOT EXISTS fare_rules (
  id BIGSERIAL PRIMARY KEY, city_code TEXT NOT NULL DEFAULT 'DEFAULT', currency CHAR(3) NOT NULL DEFAULT 'INR',
  base_fare NUMERIC(10,2) NOT NULL, per_km NUMERIC(10,2) NOT NULL, booking_fee NUMERIC(10,2) NOT NULL DEFAULT 0,
  minimum_fare NUMERIC(10,2) NOT NULL, active_from TIMESTAMPTZ NOT NULL DEFAULT NOW(), is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- v0.7 Payment, refund, wallet and settlement engine
CREATE TYPE IF NOT EXISTS payment_status AS ENUM ('CREATED','PENDING','AUTHORIZED','CAPTURED','CASH_DUE','CASH_COLLECTED','PARTIALLY_REFUNDED','REFUNDED','FAILED','CANCELLED');
ALTER TABLE payments ADD COLUMN IF NOT EXISTS provider_code TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS provider_order_id TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS provider_payment_id TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS idempotency_key TEXT;
ALTER TABLE payments ADD COLUMN IF NOT EXISTS refunded_amount NUMERIC(10,2) NOT NULL DEFAULT 0;
CREATE UNIQUE INDEX IF NOT EXISTS idx_payments_idempotency ON payments(idempotency_key) WHERE idempotency_key IS NOT NULL;
CREATE TABLE IF NOT EXISTS payment_refunds(id UUID PRIMARY KEY DEFAULT gen_random_uuid(),payment_id UUID NOT NULL REFERENCES payments(id),amount NUMERIC(10,2) NOT NULL CHECK(amount>0),reason TEXT,status TEXT NOT NULL,provider_reference TEXT,created_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
CREATE TABLE IF NOT EXISTS payment_ledger(id BIGSERIAL PRIMARY KEY,payment_id UUID REFERENCES payments(id),driver_id UUID REFERENCES driver_profiles(user_id),entry_type TEXT NOT NULL,amount NUMERIC(10,2) NOT NULL,currency CHAR(3) NOT NULL DEFAULT 'INR',metadata JSONB NOT NULL DEFAULT '{}',created_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
CREATE TABLE IF NOT EXISTS driver_wallets(driver_id UUID PRIMARY KEY REFERENCES driver_profiles(user_id),available_balance NUMERIC(12,2) NOT NULL DEFAULT 0,lifetime_earnings NUMERIC(12,2) NOT NULL DEFAULT 0,commission_paid NUMERIC(12,2) NOT NULL DEFAULT 0,updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
CREATE TABLE IF NOT EXISTS driver_settlements(id UUID PRIMARY KEY DEFAULT gen_random_uuid(),driver_id UUID NOT NULL REFERENCES driver_profiles(user_id),amount NUMERIC(12,2) NOT NULL CHECK(amount>0),status TEXT NOT NULL DEFAULT 'REQUESTED',provider_reference TEXT,rejection_reason TEXT,created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW());


-- v0.9 Safety, SOS, notifications and fraud controls
CREATE TABLE IF NOT EXISTS sos_incidents(id UUID PRIMARY KEY DEFAULT gen_random_uuid(),booking_id UUID REFERENCES bookings(id),actor_type TEXT NOT NULL,actor_id UUID NOT NULL,lat NUMERIC NOT NULL,lng NUMERIC NOT NULL,status TEXT NOT NULL DEFAULT 'OPEN',priority TEXT NOT NULL DEFAULT 'CRITICAL',notes TEXT,created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
CREATE TABLE IF NOT EXISTS notification_outbox(id UUID PRIMARY KEY DEFAULT gen_random_uuid(),audience TEXT NOT NULL,type TEXT NOT NULL,payload JSONB NOT NULL,status TEXT NOT NULL DEFAULT 'QUEUED',provider_code TEXT,attempts INT NOT NULL DEFAULT 0,last_error TEXT,created_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
CREATE TABLE IF NOT EXISTS fraud_risk_events(id UUID PRIMARY KEY DEFAULT gen_random_uuid(),event_type TEXT NOT NULL,severity TEXT NOT NULL,actor_id UUID,booking_id UUID REFERENCES bookings(id),metadata JSONB NOT NULL DEFAULT '{}',status TEXT NOT NULL DEFAULT 'OPEN',created_at TIMESTAMPTZ NOT NULL DEFAULT NOW());
CREATE INDEX IF NOT EXISTS idx_sos_status ON sos_incidents(status,created_at DESC);
CREATE INDEX IF NOT EXISTS idx_risk_status ON fraud_risk_events(status,severity,created_at DESC);
