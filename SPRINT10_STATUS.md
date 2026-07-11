# ASTRIDE v3.7 Sprint 10 — Production Readiness

## Completed
- Strict production startup gate for database, Redis, domains, secrets and live provider readiness.
- Separate `/health` liveness and `/ready` dependency/readiness endpoints.
- Native Android driver foreground-location service template with persistent notification.
- Flutter MethodChannel bridge starts/stops the service with driver tracking.
- Native patch pipeline copies Kotlin service code and declares foreground service metadata.
- Release environment documentation and Sprint 10 regression test.

## Required before field trial
1. Replace every `CHANGE_ME` value in `.env.production`.
2. Store live OTP, Razorpay, Firebase and map credentials in the provider vault.
3. Switch provider modes to `live` from Admin Control only after provider tests pass.
4. Build signed Passenger and Driver APKs through GitHub Actions.
5. Test Android 13–16 permission flow and disable battery optimisation for the Driver app.
6. Run one cash ride and one online-payment ride end-to-end in Kalna.

## Known boundary
The service keeps the Android process in foreground-service mode. Actual GPS delivery still uses the Flutter geolocation stream; OEM force-stop, revoked permission, or aggressive battery policy can stop tracking and must be tested on physical devices.
