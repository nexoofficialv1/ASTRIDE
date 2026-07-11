import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'api_client.dart';

class PushNotificationService {
  PushNotificationService(this.api);
  final ApiClient api;

  Future<String?> initialize({required String actorType, required String actorId, required String deviceId, required String locale, required String appVersion}) async {
    try {
      final runtime = await api.getJson('/v1/public/mobile-config?app=${actorType == 'driver' ? 'driver' : 'passenger'}');
      final raw = (runtime['clientProviders'] as Map?)?['firebase'] as Map?;
      if (raw == null) return null;
      await Firebase.initializeApp(options: FirebaseOptions(apiKey: raw['apiKey'].toString(), appId: raw['appId'].toString(), messagingSenderId: raw['messagingSenderId'].toString(), projectId: raw['projectId'].toString(), authDomain: raw['authDomain']?.toString(), storageBucket: raw['storageBucket']?.toString(), measurementId: raw['measurementId']?.toString()));
    } catch (_) { return null; }
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await messaging.getToken();
    if (token != null) {
      await api.post('/v1/devices/register', {
        'actorType': actorType,
        'actorId': actorId,
        'deviceId': deviceId,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'pushToken': token,
        'locale': locale,
        'appVersion': appVersion,
      });
    }
    messaging.onTokenRefresh.listen((next) async {
      await api.post('/v1/devices/register', {
        'actorType': actorType,
        'actorId': actorId,
        'deviceId': deviceId,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'pushToken': next,
        'locale': locale,
        'appVersion': appVersion,
      });
    });
    return token;
  }
}
