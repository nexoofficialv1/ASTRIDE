# ASTRIDE Share Toto Pooling Engine v3.10

A Share Toto runs as one continuous route session. Passenger bookings reserve seats only on the segments between their pickup and drop stops.

## Eligibility
- Driver has active SHARE_TOTO permission for the selected route and zones.
- Driver is online, GPS-fresh and physically inside an allowed zone.
- Pickup and drop are stops on the same approved route and direction.
- Every traversed segment has sufficient capacity.

## Example
Route: Nibhuji → Hospital More → Kalna Bus Stand → Chawkbazar → Kalna Ferry Ghat.
The five example bookings produce occupancy 2, 3, 3 and 2 on successive segments. Seats released at a drop stop may be reused by passengers boarding at that stop.

## Full vs Share
FULL_TOTO remains exclusive and follows primary-zone/cross-border rules. SHARE_TOTO follows multi-zone route permissions, stop order, direction and segment capacity. One vehicle may offer BOTH while idle, but an active Full ride and Share session cannot coexist.
