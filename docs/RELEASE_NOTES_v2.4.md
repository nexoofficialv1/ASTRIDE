# ASTRIDE v2.4 — GitHub-ready Repository & Test APK Pipeline

## Added
- Staging and production Dart define files.
- Runtime URL validation with HTTPS/WSS enforcement in production.
- Secure Firebase Android/iOS configuration injection.
- Manual GitHub Actions workflow for Passenger or Driver test APK.
- Environment-aware Android release builds.
- Secret-safe `.gitignore` and repository cleanup rules.
- CI contract test for environment, Firebase, version, and workflow structure.

## Required GitHub secrets
- `PASSENGER_FIREBASE_ANDROID_BASE64`
- `DRIVER_FIREBASE_ANDROID_BASE64`
- Existing Android signing secrets for release AAB/APK.

The Firebase secrets must contain the Base64 encoding of each app's own `google-services.json` file.
