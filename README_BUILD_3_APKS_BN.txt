ASTRIDE Passenger + Driver + Partner — Build 341
=================================================

Apps:
1. Passenger — com.nexo.astride.passenger
2. Driver — com.nexo.astride.driver
3. Partner — com.nexo.astride.partner

Production backend:
https://astaride.nexoofficial.in
WebSocket:
wss://astaride.nexoofficial.in

এই source package-এ একবার GitHub Actions চালালে তিনটি APK build হবে।

দ্রুত test APK বানানোর নিয়ম
---------------------------
1. ZIP extract করুন।
2. Extract করা সব files একটি private GitHub repository-র root-এ upload/push করুন।
3. GitHub repository → Actions খুলুন।
4. “ASTRIDE Three APK Build” নির্বাচন করুন।
5. Run workflow চাপুন।
6. দিন:
   environment = production
   mode = debug
   version = 3.18.2
   build_number = 341
7. Workflow শেষ হলে তিনটি artifact download করুন:
   - ASTRIDE-passenger_flutter-debug...
   - ASTRIDE-driver_flutter-debug...
   - ASTRIDE-partner_flutter-debug...

Debug build-এর জন্য keystore বা signing secret লাগবে না। Passenger ও Driver Firebase client config private source package-এ আছে। Partner app Firebase ছাড়া build হবে; login/dashboard/drivers/earnings/profile চলবে, কিন্তু app বন্ধ থাকলে Partner push notification পাওয়া যাবে না।

Final signed release
--------------------
Field test pass হওয়ার পরে Android upload keystore তৈরি করে GitHub secrets দিন। তারপর mode=release চালালে split APK এবং AAB তৈরি হবে। তিনটি app-এ একই keystore ব্যবহার করা যাবে, কিন্তু keystore হারানো যাবে না।

Map behavior
------------
Backend routing/geocoding provider Mappls live। Passenger/Driver map display-এ Google provider হলে Google Map, আর Mappls/OSM provider হলে OpenStreetMap tile fallback দেখাবে। আগের placeholder map সরানো হয়েছে।

Security
--------
- Firebase Admin service-account private key mobile package-এ নেই।
- 2Factor/Mappls/Razorpay/server credentials mobile package-এ নেই।
- Included google-services.json Android client configuration; Google API restrictions package name এবং release SHA fingerprints দিয়ে সীমাবদ্ধ করুন।
- Repository private রাখুন।
