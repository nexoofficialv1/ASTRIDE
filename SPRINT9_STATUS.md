# ASTRIDE v3.6 Sprint 9 — OTP, Payment, Push, Live Tracking & Maps

## Completed in code
- OTP: cryptographically generated 6-digit codes, hashed server-side storage, expiry, attempt lockout, 30-second resend cooldown, and 5 requests/15-minute mobile rate limit.
- Payment: Razorpay live order creation, signature verification, webhook verification, refund API, payment fetch/reconciliation, while retaining test and cash fallback modes.
- Push: Firebase Cloud Messaging HTTP v1 with service-account JWT/OAuth token generation, high-priority Android ride channel, OneSignal and mock fallback.
- Maps: live Mappls, Google Routes/Geocoding, and OSM/OSRM adapters plus provider-neutral fallback and `/v1/maps/geocode`.
- Live tracking: existing WebSocket ride channel, server location ingestion, offline queue and driver foreground/background permission foundation retained and validated.
- Android: background location, foreground-service location and Android 13+ notification permissions are declared in the driver app.

## Credentials required for live mode
- OTP/MSG91: `authKey`, `templateId`.
- Razorpay: `keyId`, `keySecret`, `webhookSecret`.
- Firebase: `projectId`, `clientEmail`, `privateKey` from a service account; mobile apps also need their own `google-services.json`.
- Mappls: `restApiKey`; Google Maps: `apiKey` and Android SDK key.

## Important native-build gate
Continuous tracking after the driver app is swiped away requires a native Android foreground-location service implementation and OEM battery-optimization guidance during the final APK build. Current code supports foreground tracking, offline queueing and Android permission declarations, but must be field-tested on physical devices before production launch.
