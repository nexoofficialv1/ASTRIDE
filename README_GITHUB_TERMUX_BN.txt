ASTRIDE Passenger + Driver APK Build Source — v3.17.0 (Build 336)

এই ZIP-এ আছে:
- Passenger Flutter source
- Driver Flutter source
- Android/iOS native project bootstrap scripts
- GitHub Actions workflow: .github/workflows/android-passenger-driver-build.yml
- Production/Staging runtime environment files
- Signing, Firebase এবং Google Maps injection scripts

GitHub-এ Termux দিয়ে Push
-------------------------
1) Termux-এ চালান:
   pkg update -y
   pkg install git unzip -y

2) ZIP extract করুন এবং folder-এ যান।

3) Git repository তৈরি করে push করুন:
   git init
   git branch -M main
   git config user.name "YOUR_GITHUB_USERNAME"
   git config user.email "YOUR_EMAIL"
   git add .
   git commit -m "ASTRIDE Passenger Driver v3.17.0 build source"
   git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
   git push -u origin main

GitHub Actions দিয়ে Debug APK
------------------------------
1) GitHub repository → Actions খুলুন।
2) “ASTRIDE Passenger and Driver APK Build” নির্বাচন করুন।
3) Run workflow চাপুন।
4) environment=production, mode=debug, version=3.17.0, build_number=336 দিন।
5) Build শেষ হলে Passenger ও Driver artifact আলাদাভাবে download করুন।

Production URL
--------------
mobile_build/environments/production.json-এ বর্তমানে:
API_BASE_URL=https://astaride.nexoofficial.in
WS_BASE_URL=wss://astaride.nexoofficial.in
Backend-এর public domain আলাদা হলে push করার আগে এই দুইটি value বদলান।
GitHub Repository Variables PRODUCTION_API_BASE_URL এবং PRODUCTION_WS_BASE_URL সেট করলে workflow সেগুলো ব্যবহার করবে। Variables না থাকলে production.json-এর value ব্যবহার করবে।

Signed Release APK/AAB-এর Secrets
----------------------------------
Repository Settings → Secrets and variables → Actions → Secrets:
- ANDROID_KEYSTORE_BASE64
- ANDROID_STORE_PASSWORD
- ANDROID_KEY_PASSWORD
- ANDROID_KEY_ALIAS
- GOOGLE_MAPS_ANDROID_KEY
- PASSENGER_FIREBASE_ANDROID_BASE64
- DRIVER_FIREBASE_ANDROID_BASE64

Keystore base64 বানাতে Termux/Linux:
   base64 -w 0 your-upload-key.jks > keystore-base64.txt
Android Termux-এ -w support না থাকলে:
   base64 your-upload-key.jks | tr -d '\n' > keystore-base64.txt

Firebase config base64:
   base64 google-services.json | tr -d '\n'
Passenger ও Driver-এর Firebase project/config আলাদা হলে আলাদা secret দিন।

Build Notes
-----------
- GitHub workflow Flutter 3.41.6 এবং Java 17 ব্যবহার করে।
- Native android/ios folders workflow চলার সময় cleanভাবে generate হয়।
- flutter analyze ও flutter test pass হওয়ার পরেই APK build শুরু হয়।
- Debug APK signing secret ছাড়াই build করা যায়।
- Release build-এর জন্য signing secret আবশ্যক।
- কোনো live API key বা password source ZIP-এর মধ্যে রাখা হয়নি।
