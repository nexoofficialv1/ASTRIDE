CREATE TABLE IF NOT EXISTS partner_accounts (
  id UUID PRIMARY KEY,
  role TEXT NOT NULL CHECK (role IN ('PROMOTER','AREA_PROMOTER')),
  name TEXT NOT NULL,
  mobile TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  password_salt TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'ACTIVE',
  area_promoter_id UUID NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS partner_sessions (
  token_hash TEXT PRIMARY KEY,
  partner_id UUID NOT NULL REFERENCES partner_accounts(id),
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS partner_withdrawals (
  id UUID PRIMARY KEY,
  beneficiary_id UUID NOT NULL,
  amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
  status TEXT NOT NULL DEFAULT 'REQUESTED',
  requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  processed_at TIMESTAMPTZ NULL
);
CREATE INDEX IF NOT EXISTS idx_partner_withdrawals_beneficiary ON partner_withdrawals(beneficiary_id, requested_at DESC);
