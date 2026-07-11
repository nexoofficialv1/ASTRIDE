# ASTRIDE Offer & Campaign Module — v3.11

Admin Web Panel controls campaigns for DRIVER, PASSENGER, PROMOTER and AREA_PROMOTER.

## Supported campaign examples

- Zero Commission Month (`ZERO_COMMISSION`)
- Launch / Night / Peak / Weekend / Festival bonus
- Complete N rides and receive a fixed target bonus
- First ride discount, flat discount, percentage discount and cashback
- Promo code and referral bonus
- Driver onboarding target for Promoters
- Active-driver and area-growth target for Area Promoters

## Safety and financial controls

- Draft, scheduled, active, paused and expired lifecycle
- Server-derived effective status from start/end dates
- Area/city and ride-type targeting
- Per-user redemption limit
- Required event count / target progression
- Maximum reward and campaign payout budget
- Atomic idempotency key using campaign + actor + event
- Automatic stop when budget is exhausted
- Complete audit trail and persistent campaign state

## Runtime integration

Completed bookings trigger campaign evaluation for Passenger, Driver and the linked Promoter/Area Promoter. Other business events such as `DRIVER_ONBOARDED`, `REFERRAL_COMPLETED` and `AREA_DRIVER_ACTIVE` can be submitted through the protected admin/internal campaign-event endpoint.
