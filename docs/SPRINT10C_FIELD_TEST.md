# ASTRIDE Sprint 10C — Staging and Field-Test Runbook

## Purpose
Validate the complete passenger-to-driver ride path against the staging backend before distributing APKs to field testers.

## Required staging values
- `STAGING_API_BASE_URL` and `STAGING_WS_BASE_URL` as GitHub repository variables.
- `FIELD_TEST_MOBILE` as a dedicated test number.
- `FIELD_TEST_OTP_CODE` only when the OTP provider uses a fixed staging code. For real SMS, run the script locally and enter the received code through the environment.
- Existing Firebase, Maps and Android signing secrets from Sprint 10B.

## Safe execution
The runner refuses to mutate any environment unless `ALLOW_MUTATING_FIELD_TEST=true`. It also refuses a production-looking URL unless `ALLOW_PRODUCTION_FIELD_TEST=true`. Production testing should remain disabled during the Kalna pilot.

## GitHub execution
Run **ASTRIDE Staging Field Test**. The `staging-field-test` GitHub Environment should require manual approval. Start with `cash`; use `online` only after Razorpay staging checkout is available.

## Local/Termux execution
```bash
export ASTRIDE_BASE_URL="https://staging-api.example.com"
export FIELD_TEST_MOBILE="9198XXXXXXXX"
export FIELD_TEST_OTP_CODE="123456"
export FIELD_TEST_PAYMENT_MODE="cash"
export ALLOW_MUTATING_FIELD_TEST="true"
node tools/field-test/staging-e2e.mjs
```

## Pass criteria
Health/config endpoints respond, OTP verifies, a nearby driver is assigned, push dispatch is accepted, tracking samples are persisted/read back, the ride reaches `COMPLETED`, and the ride event trail is complete. Online payment capture remains a real provider/manual checkout step and is never faked by the runner.

## Physical-device checklist
1. Passenger receives OTP and logs in.
2. Driver receives booking push while app is foreground, background and screen-locked.
3. Driver location updates every configured interval with the foreground-service notification visible.
4. Passenger map follows driver without manual refresh.
5. Ride start OTP cannot be reused.
6. Cash completion records the ride; online mode opens Razorpay and verifies the provider response.
7. Airplane-mode GPS samples queue and flush after reconnection.
8. Battery optimization instructions are tested on Xiaomi/Redmi, Realme, Vivo and Samsung where available.
9. Force-stop behavior is documented as unsupported by Android.
10. Admin dashboard reflects live ride, payment state, GPS freshness and notification status.
