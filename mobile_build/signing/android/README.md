# ASTRIDE Android signing and GitHub release setup

Never commit `.jks`, `key.properties`, Firebase JSON, API keys, passwords, or base64 secrets.

## 1. Create the upload keystore once

```bash
keytool -genkeypair -v \
  -keystore astride-upload.jks \
  -alias astride-upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

Keep the original keystore and passwords in two secure backups. Losing it may prevent future app updates.

## 2. Convert files to GitHub secrets

Linux/Termux:

```bash
base64 -w 0 astride-upload.jks > keystore.base64
base64 -w 0 google-services.json > firebase.base64
```

If `base64 -w` is unavailable:

```bash
base64 astride-upload.jks | tr -d '\n' > keystore.base64
```

## 3. Repository secrets

Create these under **Settings → Secrets and variables → Actions → Secrets**:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_STORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `GOOGLE_MAPS_ANDROID_KEY`
- `PASSENGER_FIREBASE_ANDROID_BASE64`
- `DRIVER_FIREBASE_ANDROID_BASE64`

## 4. Repository variables

Create these under **Actions → Variables**:

- `PRODUCTION_API_BASE_URL` — for example `https://api.yourdomain.in`
- `PRODUCTION_WS_BASE_URL` — for example `wss://api.yourdomain.in`
- `STAGING_API_BASE_URL`
- `STAGING_WS_BASE_URL`

Production validation rejects HTTP, WS, localhost, and `.example` hosts.

## 5. Build

Open **Actions → ASTRIDE Android Signed Release → Run workflow**. Select Passenger or Driver, environment, semantic version, and an always-increasing Android build number. The workflow creates signed AAB/APKs, SHA-256 checksums, and a release manifest. GitHub Release publication is optional.
