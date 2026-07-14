import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'api_client.dart';

class PushNotificationService {
  PushNotificationService(this.api);

  final ApiClient api;

  Future<String?> initialize({
    required String actorType,
    required String actorId,
    required String deviceId,
    required String locale,
    required String appVersion,
  }) async {
    try {
      final runtime = await api.getJson(
        '/v1/public/mobile-config'
        '?app=${actorType == 'driver' ? 'driver' : 'passenger'}',
      );
      final providers = runtime['clientProviders'];
      final raw = providers is Map
          ? providers['firebase']
          : null;
      if (raw is! Map) return null;

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: '${raw['apiKey']}',
            appId: '${raw['appId']}',
            messagingSenderId: '${raw['messagingSenderId']}',
            projectId: '${raw['projectId']}',
            authDomain: raw['authDomain']?.toString(),
            storageBucket: raw['storageBucket']?.toString(),
            measurementId: raw['measurementId']?.toString(),
          ),
        );
      }

      final messaging = FirebaseMessaging.instance;
      await messaging.setAutoInitEnabled(true);
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _register(
          actorType: actorType,
          actorId: actorId,
          deviceId: deviceId,
          token: token,
          locale: locale,
          appVersion: appVersion,
        );
      }

      messaging.onTokenRefresh.listen((next) async {
        try {
          await _register(
            actorType: actorType,
            actorId: actorId,
            deviceId: deviceId,
            token: next,
            locale: locale,
            appVersion: appVersion,
          );
        } catch (_) {}
      });

      return token;
    } catch (_) {
      // Foreground synchronization remains available without Firebase.
      return null;
    }
  }

  Future<void> _register({
    required String actorType,
    required String actorId,
    required String deviceId,
    required String token,
    required String locale,
    required String appVersion,
  }) =>
      api.postJson('/v1/devices/register', {
        'actorType': actorType,
        'actorId': actorId,
        'deviceId': deviceId,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'pushToken': token,
        'locale': locale,
        'appVersion': appVersion,
      });
}
