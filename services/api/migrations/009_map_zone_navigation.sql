CREATE TABLE IF NOT EXISTS service_zones (
  id uuid PRIMARY KEY,
  code text UNIQUE NOT NULL,
  name text NOT NULL,
  zone_type text NOT NULL CHECK (zone_type IN ('SERVICE_AREA','HIGH_RISK','DYNAMIC_FARE','PICKUP_ONLY','DROP_ONLY')),
  polygon jsonb NOT NULL,
  enabled boolean NOT NULL DEFAULT true,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS service_zones_type_idx ON service_zones(zone_type, enabled);
CREATE TABLE IF NOT EXISTS route_decisions (
  id bigserial PRIMARY KEY,
  booking_id uuid,
  map_provider text NOT NULL,
  origin jsonb NOT NULL,
  destination jsonb NOT NULL,
  distance_m integer NOT NULL,
  duration_s integer NOT NULL,
  zone_context jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
