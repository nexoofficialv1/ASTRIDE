CREATE TABLE IF NOT EXISTS share_routes (
  id uuid PRIMARY KEY, code text UNIQUE NOT NULL, name text NOT NULL,
  default_capacity integer NOT NULL DEFAULT 4, allowed_zone_ids jsonb NOT NULL DEFAULT '[]',
  corridor_geojson jsonb, enabled boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS share_route_stops (
  id uuid PRIMARY KEY, route_id uuid NOT NULL REFERENCES share_routes(id) ON DELETE CASCADE,
  name text NOT NULL, sequence_no integer NOT NULL, latitude double precision NOT NULL,
  longitude double precision NOT NULL, zone_id uuid, enabled boolean NOT NULL DEFAULT true,
  UNIQUE(route_id, sequence_no)
);
CREATE TABLE IF NOT EXISTS driver_zone_permissions (
  id uuid PRIMARY KEY, driver_id text NOT NULL, zone_id uuid, route_id uuid REFERENCES share_routes(id),
  service_type text NOT NULL CHECK(service_type IN ('SHARE_TOTO','FULL_TOTO','BOTH')),
  is_primary boolean NOT NULL DEFAULT false, active boolean NOT NULL DEFAULT true,
  valid_from timestamptz, valid_until timestamptz, approved_by text, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS share_trip_sessions (
  id uuid PRIMARY KEY, driver_id text NOT NULL, route_id uuid NOT NULL REFERENCES share_routes(id),
  direction text NOT NULL CHECK(direction IN ('FORWARD','REVERSE')), capacity integer NOT NULL,
  status text NOT NULL, created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS share_trip_bookings (
  id uuid PRIMARY KEY, session_id uuid NOT NULL REFERENCES share_trip_sessions(id), booking_id uuid NOT NULL,
  passenger_id text NOT NULL, pickup_stop_id uuid NOT NULL, drop_stop_id uuid NOT NULL,
  seats integer NOT NULL CHECK(seats > 0), status text NOT NULL, segment_keys jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(session_id, booking_id)
);
CREATE INDEX IF NOT EXISTS idx_share_sessions_driver_status ON share_trip_sessions(driver_id,status);
CREATE INDEX IF NOT EXISTS idx_driver_zone_permissions_driver ON driver_zone_permissions(driver_id,active);
