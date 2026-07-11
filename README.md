# ASTRIDE Platform v2.4

Mobile-first local ride platform by Astra Technologies. Passenger and Driver are native Flutter applications; the web component is an internal Admin Control Console only.

## v2.4 milestone

- GitHub-ready monorepo hygiene
- Separate staging and production runtime environments
- Firebase configuration injected only during CI/build
- Manual Passenger/Driver Android test APK workflow
- Secure production endpoint validation
- Android release AAB/split-APK pipeline retained
- English, বাংলা and हिंदी localization retained

## First GitHub test APK

1. Create a private GitHub repository and upload this project.
2. In GitHub repository settings, add either or both secrets:
   - `PASSENGER_FIREBASE_ANDROID_BASE64`
   - `DRIVER_FIREBASE_ANDROID_BASE64`
3. Base64-encode the relevant Firebase `google-services.json` without line wrapping and save it as the matching secret.
4. Open **Actions → Android Test APK → Run workflow**.
5. Select Passenger or Driver and the `staging` environment.
6. Download the generated APK from the workflow artifact.

The staging/production URLs in `mobile_build/environments/*.json` are placeholders and must be replaced with the actual HTTPS API domains before field testing.

See `docs/RELEASE_NOTES_v2.4.md` for details.


## v3.3 Sprint 6 — Partner App UI Completion

The Promoter/Area Promoter app now includes a production-oriented role-based dashboard, custom date-range analytics, driver search and performance filters, driver coaching actions, monthly earnings/settlement controls, and English/Bengali/Hindi UI switching. See `SPRINT6_STATUS.md`.

## v3.4 Sprint 7 — Admin Business Modules

The internal Admin Control Console now includes configurable Fare & Commission, Dynamic Pricing, Night Service, Zone Manager foundation, Promoter Management, Compensation Center, SafeRide controls and monthly Partner Settlement release. See `docs/SPRINT7_ADMIN_BUSINESS_MODULES.md` for the tested scope and remaining map-SDK boundary.


## Latest milestone
ASTRIDE v3.5 Sprint 8 adds map-zone evaluation, outside-area enforcement, admin zone APIs and mobile navigation service clients. See `SPRINT8_STATUS.md`.

## v3.8 Sprint 10B — Android signed release

Use `.github/workflows/android-release.yml` to create signed Passenger or Driver AAB/APKs. Configure the GitHub secrets and variables listed in `mobile_build/signing/android/README.md`. Production endpoints are rendered during CI and validated before compilation.
