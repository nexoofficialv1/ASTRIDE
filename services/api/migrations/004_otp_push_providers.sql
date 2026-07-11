BEGIN;
CREATE TABLE IF NOT EXISTS device_registrations(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), actor_type text NOT NULL, actor_id text NOT NULL,
 device_id text NOT NULL, platform text NOT NULL CHECK(platform IN ('android','ios')),
 push_token text NOT NULL, locale text NOT NULL DEFAULT 'en', app_version text,
 active boolean NOT NULL DEFAULT true, last_seen_at timestamptz NOT NULL DEFAULT now(),
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(actor_type,actor_id,device_id)
);
CREATE INDEX IF NOT EXISTS idx_device_actor_active ON device_registrations(actor_type,actor_id) WHERE active=true;
CREATE TABLE IF NOT EXISTS otp_delivery_attempts(
 id bigserial PRIMARY KEY, session_id uuid, mobile_hash text NOT NULL, provider text NOT NULL,
 provider_message_id text, status text NOT NULL, error_code text, created_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO schema_migrations(version) VALUES('004_otp_push_providers') ON CONFLICT DO NOTHING;
COMMIT;
