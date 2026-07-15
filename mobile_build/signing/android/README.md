# ASTRIDE Android signing and GitHub build setup

Debug APK build করতে signing secret লাগে না। Final release APK/AAB-এর জন্য একই upload keystore তিনটি app-এ ব্যবহার করা যাবে।

## Create the upload keystore once

```bash
keytool -genkeypair -v \
  -keystore astride-upload.jks \
  -alias astride-upload \
  -keyalg RSA -keysize 2048 -validity 10000
```

Keystore এবং password-এর অন্তত দুইটি secure backup রাখুন।

## GitHub release secrets

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_STORE_PASSWORD`
- `ANDROID_KEY_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `GOOGLE_MAPS_ANDROID_KEY` — Google provider চালালে প্রয়োজন; OSM/Mappls fallback build-এ blank থাকতে পারে
- `PASSENGER_FIREBASE_ANDROID_BASE64` — optional override; package-এ private config bundled আছে
- `DRIVER_FIREBASE_ANDROID_BASE64` — optional override; package-এ private config bundled আছে

Partner app বর্তমানে Firebase ছাড়া build হয়। Partner push notification পরে যোগ করতে Firebase-এ `com.nexo.astride.partner` client তৈরি করতে হবে।

## Repository variables

- `PRODUCTION_API_BASE_URL=https://astaride.nexoofficial.in`
- `PRODUCTION_WS_BASE_URL=wss://astaride.nexoofficial.in`
- `STAGING_API_BASE_URL`
- `STAGING_WS_BASE_URL`

## Build

GitHub → **Actions → ASTRIDE Three APK Build → Run workflow**।

Testing-এর জন্য প্রথমে:

- environment: `production`
- mode: `debug`
- version: `3.18.2`
- build number: `340`

একবার workflow চালালে Passenger, Driver এবং Partner—তিনটি পৃথক artifact তৈরি হবে।
