BEGIN;
CREATE TABLE IF NOT EXISTS payment_webhook_events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), provider TEXT NOT NULL, provider_event_id TEXT NOT NULL,
  event_type TEXT NOT NULL, verified BOOLEAN NOT NULL DEFAULT FALSE, payload_hash TEXT NOT NULL,
  processing_status TEXT NOT NULL, received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(), processed_at TIMESTAMPTZ,
  UNIQUE(provider, provider_event_id)
);
CREATE TABLE IF NOT EXISTS payment_reconciliations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), payment_id TEXT NOT NULL, provider TEXT NOT NULL,
  local_status TEXT NOT NULL, provider_status TEXT NOT NULL, matched BOOLEAN NOT NULL,
  details JSONB NOT NULL DEFAULT '{}'::jsonb, created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_payment_webhook_received ON payment_webhook_events(received_at DESC);
CREATE INDEX IF NOT EXISTS idx_payment_reconciliation_created ON payment_reconciliations(created_at DESC);
COMMIT;
