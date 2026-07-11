# ASTRIDE v2.3 — Native Build & Release Pipeline

## Included
- Reproducible Android and iOS platform bootstrap from Flutter source.
- Passenger and Driver app identifiers under `in.astride`.
- Android signed AAB and split APK GitHub Actions workflow.
- iOS signed IPA workflow for a macOS runner.
- Generated ASTRIDE app icon and splash assets.
- `flutter_launcher_icons` and `flutter_native_splash` configuration.
- Pull-request quality gate with analyze, tests and locale validation.
- Signing templates with no production secrets committed.

## Required repository secrets
### Android
`ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`.

### iOS
`IOS_CERTIFICATE_P12_BASE64`, `IOS_CERTIFICATE_PASSWORD`, `IOS_PROVISIONING_PROFILE_BASE64`.

## Important
Real builds require Flutter/Android SDK; iOS requires macOS, Xcode and an Apple Developer account. Provider configuration files such as `google-services.json` and `GoogleService-Info.plist` must be injected securely per app/environment.
