-- ASTRIDE v3.11 Offer & Campaign Module
CREATE TABLE IF NOT EXISTS campaigns (
  id uuid PRIMARY KEY,
  offer_name text NOT NULL,
  offer_code text UNIQUE,
  target_user text NOT NULL CHECK (target_user IN ('DRIVER','PASSENGER','PROMOTER','AREA_PROMOTER')),
  status text NOT NULL CHECK (status IN ('DRAFT','SCHEDULED','ACTIVE','PAUSED','EXPIRED')),
  start_date timestamptz,
  end_date timestamptz,
  area_ids jsonb NOT NULL DEFAULT '[]'::jsonb,
  city_ids jsonb NOT NULL DEFAULT '[]'::jsonb,
  ride_types jsonb NOT NULL DEFAULT '[]'::jsonb,
  terms_and_conditions text NOT NULL DEFAULT '',
  reward_type text NOT NULL,
  reward_value numeric(12,2) NOT NULL DEFAULT 0,
  maximum_reward numeric(12,2),
  required_count integer NOT NULL DEFAULT 1,
  metric text NOT NULL DEFAULT 'RIDE_COMPLETED',
  per_user_limit integer NOT NULL DEFAULT 1,
  minimum_amount numeric(12,2) NOT NULL DEFAULT 0,
  maximum_payout numeric(14,2),
  payout_amount numeric(14,2) NOT NULL DEFAULT 0,
  redemption_count integer NOT NULL DEFAULT 0,
  new_users_only boolean NOT NULL DEFAULT false,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_by text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS campaign_redemptions (
  id uuid PRIMARY KEY,
  campaign_id uuid NOT NULL REFERENCES campaigns(id),
  actor_type text NOT NULL,
  actor_id text NOT NULL,
  event_id text NOT NULL,
  booking_id text,
  amount numeric(12,2) NOT NULL,
  status text NOT NULL DEFAULT 'APPROVED',
  metric text NOT NULL,
  progress integer NOT NULL DEFAULT 1,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(campaign_id,actor_id,event_id)
);
CREATE INDEX IF NOT EXISTS idx_campaign_active_window ON campaigns(status,start_date,end_date);
CREATE INDEX IF NOT EXISTS idx_campaign_target_area ON campaigns(target_user);
CREATE INDEX IF NOT EXISTS idx_campaign_redemption_actor ON campaign_redemptions(actor_type,actor_id,created_at DESC);
