# Sprint 7 — Admin Business Modules

Implemented in the internal ASTRIDE Admin Control Console:

- Fare and commission management for Full Toto, Share Toto and Motorcycle
- Outside-area, return compensation and waiting-charge controls
- Dynamic pricing zones, peak windows and multiplier cap
- Night-service window and ride-type surcharge controls
- Provider-neutral service/risk-zone manager foundation
- Promoter and Area Promoter directory with role filters
- Late-arrival compensation policy and calculation simulator
- SafeRide controls for visibility, night suggestion, risk prompts and trusted-driver priority
- Monthly promoter/area-promoter earnings release workflow

All mutable rules are saved through `PATCH /v1/admin/config`, so mobile applications do not require a rebuild when business values change.

## Current boundary

The zone editor is UI-ready but real polygon drawing requires the live Mappls/Google SDK and persistent zone API, which remain an integration gate. This sprint does not claim that map polygon editing is production-complete.
