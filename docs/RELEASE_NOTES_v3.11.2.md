# ASTRIDE v3.11.2 — Flutter CI Compile Fix

Fixed issues found by GitHub Actions in v3.11.1 RC1:

- Added `AppConfig.requestTimeout` to Passenger and Driver apps.
- Replaced invalid `ApiClient.post(...)` calls with `postJson(...)` in Passenger/Driver push registration.
- Fixed unbalanced widget parentheses in Driver dashboard action card.
- Rewrote Passenger login screen with balanced widget structure and controller disposal.
- Added `flutter_launcher_icons` and `flutter_native_splash` dependencies/configuration to Partner app.
- Included Partner app in release validation and native build compatibility checks.
- Ran Node UI contracts, locale parity, release-structure validation, and a delimiter scan over all Flutter Dart sources.

The definitive compile verification remains GitHub Actions (`Android Compile Check` and `Mobile Quality Gate`).
