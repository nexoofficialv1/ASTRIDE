# ASTRIDE Mobile Build 347 — Route Scan & Go / Tap & Go

## Passenger App

- Home থেকে `Scan & Go` entry
- Vehicle QR scanner
- fresh high-accuracy GPS capture
- active route service/seat/NFC badge view
- scan-in, same-QR scan-out এবং proximity End Ride
- idempotency key এবং duplicate-scan feedback
- Wallet hold/fare receipt display
- Firebase App Check token header

## Driver App

- assigned route/vehicle status
- UP/DOWN trip start
- 15-second route heartbeat
- active digital Passenger list
- trip close guard while Passenger active
- NFC hardware detection
- backend `cardTapGoReady` gate
- Card button hidden/disabled until secure DESFire verifier is ready

## Partner App

Existing partner/promoter functions remain unchanged; version aligned to `3.21.0+347`.

## Build workflow

Use `.github/workflows/android-three-apps-build.yml` with version `3.21.0`, build number `347`.

The local audit environment has no Flutter/Dart SDK, so no APK binary is included in the source ZIP. GitHub Actions must complete `flutter analyze`, `flutter test`, APK build, signing and artifact SHA-256 generation.
