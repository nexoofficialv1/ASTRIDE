BEGIN;
CREATE TABLE IF NOT EXISTS app_state_snapshots(
 namespace text PRIMARY KEY,
 revision bigint NOT NULL DEFAULT 1,
 payload jsonb NOT NULL DEFAULT '{}'::jsonb,
 updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS repository_write_log(
 id bigserial PRIMARY KEY,
 namespace text NOT NULL,
 revision bigint NOT NULL,
 checksum text NOT NULL,
 written_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_repository_write_log_namespace ON repository_write_log(namespace,written_at DESC);
INSERT INTO schema_migrations(version) VALUES('002_operational_repositories') ON CONFLICT DO NOTHING;
COMMIT;
