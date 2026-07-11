# Architecture

## Product surfaces
1. Passenger App: booking, map, fare, driver tracking, OTP start, payment, safety and support.
2. Driver App: verification, availability, incoming request, navigation, ride lifecycle, earnings and support.
3. Admin Panel: live operations, verification, fares, zones, payments, complaints, SOS and reports.
4. API Platform: authentication, booking state machine, driver matching, pricing, tracking, payments, notifications and audit.

## Booking state machine
DRAFT -> SEARCHING -> DRIVER_ASSIGNED -> DRIVER_ARRIVING -> DRIVER_ARRIVED -> OTP_VERIFIED -> IN_PROGRESS -> COMPLETED
Terminal alternatives: CANCELLED_BY_PASSENGER, CANCELLED_BY_DRIVER, CANCELLED_BY_ADMIN, NO_DRIVER_FOUND, NO_SHOW.

## Non-negotiable rules
- Backend is the source of truth for booking status, fare and payment.
- Every state transition is validated and audit logged.
- Driver cannot go online without approval, valid documents, GPS and notification permission.
- Passenger and driver apps never display raw server pages or internal error messages.
- Live tracking automatically reconnects and records last known location.
- Map opens at current location and always provides a My Location control.
- Search uses address autocomplete plus local landmark index.
- All user-facing text comes from locale files; no hard-coded UI labels.
