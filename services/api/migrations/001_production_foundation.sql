BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TABLE IF NOT EXISTS schema_migrations(version text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now());
CREATE TABLE IF NOT EXISTS admin_users(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), username text NOT NULL UNIQUE, display_name text NOT NULL,
 role text NOT NULL CHECK(role IN ('SUPER_ADMIN','OPERATIONS','FINANCE','AUDITOR')),
 password_hash text NOT NULL, password_salt text NOT NULL, is_active boolean NOT NULL DEFAULT true,
 failed_login_count integer NOT NULL DEFAULT 0, locked_until timestamptz, last_login_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS admin_sessions(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), admin_user_id uuid NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
 token_hash text NOT NULL UNIQUE, expires_at timestamptz NOT NULL, revoked_at timestamptz,
 ip_address inet, user_agent text, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_admin_sessions_active ON admin_sessions(admin_user_id,expires_at) WHERE revoked_at IS NULL;
CREATE TABLE IF NOT EXISTS audit_logs(
 id bigserial PRIMARY KEY, actor_type text NOT NULL, actor_id text, action text NOT NULL,
 entity_type text, entity_id text, payload jsonb NOT NULL DEFAULT '{}'::jsonb,
 ip_address inet, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_audit_logs_created ON audit_logs(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs(entity_type,entity_id);
CREATE TABLE IF NOT EXISTS runtime_config_versions(
 id bigserial PRIMARY KEY, version integer NOT NULL UNIQUE, config jsonb NOT NULL,
 changed_by uuid REFERENCES admin_users(id), change_note text, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS provider_credentials(
 id uuid PRIMARY KEY DEFAULT gen_random_uuid(), provider_type text NOT NULL, provider_name text NOT NULL,
 environment text NOT NULL CHECK(environment IN ('TEST','LIVE')), encrypted_payload text NOT NULL,
 key_version integer NOT NULL DEFAULT 1, is_active boolean NOT NULL DEFAULT true,
 created_by uuid REFERENCES admin_users(id), created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(provider_type,provider_name,environment)
);
INSERT INTO schema_migrations(version) VALUES('001_production_foundation') ON CONFLICT DO NOTHING;
COMMIT;
