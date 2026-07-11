# ASTRIDE v3.9.2 Security Hardening

This release closes unauthenticated HTTP object access in addition to the v3.9.1 WebSocket fix.

- Passenger bearer sessions are mandatory for passenger profile, places, bookings, payments, complaints, ratings, devices and passenger GPS.
- Object ownership is checked server-side; request-body `passengerId` is never trusted by itself.
- Driver bearer sessions are issued only after OTP-authenticated mobile ownership and are mandatory for driver profile, documents, online status, wallet, settlements, devices and GPS.
- Ride reads, events and tracking are limited to the booking passenger, assigned driver, or authorized admin.
- Internal notification dispatch, matching, refunds, reviews and settlement actions are admin-protected.
- Legacy unscoped promoter routes are admin-protected; partner apps must use `/v1/partner/*`.
- WebSocket subscriptions allow the booking passenger, assigned driver, or an admin with `rides.read`.
