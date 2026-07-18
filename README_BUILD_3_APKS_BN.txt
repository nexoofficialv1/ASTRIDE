ASTRIDE Passenger + Driver + Partner — Security Build 347
========================================================

Apps:
1. Passenger — com.nexo.astride.passenger
2. Driver — com.nexo.astride.driver
3. Partner — com.nexo.astride.partner

Backend required:
https://astaride.nexoofficial.in
Version: 3.21.0-security-reconstruction-p2

একটি GitHub Actions workflow থেকে তিনটি আলাদা APK তৈরি হবে।

Existing repo update
--------------------
1. ZIP extract করে existing private ASTRIDE repo root-এ overwrite করুন।
2. .env, Firebase Admin service-account, signing keystore বা backend private credential commit করবেন না।
3. Commit/push করুন।
4. GitHub → Actions → ASTRIDE Three APK Build → Run workflow.

Debug inputs
------------
environment = production
mode = debug
version = 3.21.0
build_number = 346

Output
------
- ASTRIDE Passenger debug APK
- ASTRIDE Driver debug APK
- ASTRIDE Partner debug APK

Security behavior
-----------------
- Passenger/Driver secure chat device-side E2EE.
- Direct Passenger–Driver phone/SMS action removed.
- Passenger/Driver Firebase App Check token backend-এ পাঠায়।
- Passenger/Driver/Partner API and WebSocket restricted certificate trust context ব্যবহার করে।
- Build script live ASTRIDE domain থেকে verified certificate chain নেয়।
- Private server credentials mobile package-এ নেই।

Firebase
--------
Passenger/Driver google-services.json GitHub encrypted secrets দিয়ে inject হবে:
- PASSENGER_FIREBASE_ANDROID_BASE64
- DRIVER_FIREBASE_ANDROID_BASE64

Partner Firebase ছাড়া build হবে। Partner-এর core login/dashboard functionality চলবে, কিন্তু background push এবং App Check থাকবে না।

Release
-------
Debug real-device security/ride test pass করার পরে mode=release চালান। Release signing secrets এবং immutable upload keystore নিরাপদে সংরক্ষণ করুন।
