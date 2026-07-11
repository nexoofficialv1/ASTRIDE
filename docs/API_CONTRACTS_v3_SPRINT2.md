# ASTRIDE v3 Sprint 2 API Contracts

## Fare and availability
- `POST /v1/fares/quote-v3`
- `POST /v1/service/availability`

The quote request supports `FULL_TOTO`, `SHARE_TOTO`, `MOTORCYCLE`, `distanceKm`, `outsideDistanceKm`, `isOutsideArea`, `isNight`, `dynamicMultiplier`, `waitingMinutes`, `paymentPreference`, `saferideEnabled`, and promoter attribution.

## Driver preferences
- `PATCH /v1/drivers/{driverId}/service-preferences`

Fields: `acceptsCash`, `acceptsUpi`, `acceptsOutsideArea`, `nightServiceEnabled`, `saferideEligible`.

## Late arrival
- `POST /v1/late-arrival/evaluate`

Calculates grace-adjusted delay, driver penalty and passenger wallet credit. Production application of money remains ledger-controlled and reviewable.

## Promoter network
- `POST /v1/promoters`
- `POST /v1/promoters/link-driver`
- `GET /v1/promoters/{id}/dashboard?from=&to=`
- `GET /v1/promoters/{id}/drivers`
- `POST /v1/promoters/{id}/coaching`
- `GET /v1/promoters/{id}/coaching`
- `GET /v1/promoters/{id}/earnings?month=`
- `POST /v1/promoters/{id}/withdrawals`

Promoter scope is enforced by driver linkage. Local promoters see their own drivers. Area promoters see drivers linked to their area.

## Admin
- `GET /v1/admin/promoters`
- `POST /v1/admin/promoter-earnings/release`

Monthly earnings remain non-withdrawable until an authorised release action changes them to `WITHDRAWABLE`.
