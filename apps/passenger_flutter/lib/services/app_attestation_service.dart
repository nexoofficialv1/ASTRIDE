import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AppAttestationService {
  AppAttestationService._();

  static final AppAttestationService instance =
      AppAttestationService._();

  bool _initialized = false;
  String? _cachedToken;
  DateTime? _cachedAt;

  Future<void> initialize() async {
    if (_initialized) return;
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider:
          kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
    );
    _initialized = true;
  }

  Future<String?> token({bool forceRefresh = false}) async {
    try {
      await initialize();
      if (!forceRefresh &&
          _cachedToken != null &&
          _cachedAt != null &&
          DateTime.now().difference(_cachedAt!) <
              const Duration(minutes: 20)) {
        return _cachedToken;
      }
      final token = await FirebaseAppCheck.instance.getToken(forceRefresh);
      if (token != null && token.isNotEmpty) {
        _cachedToken = token;
        _cachedAt = DateTime.now();
      }
      return token;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('ASTRIDE App Check unavailable: ${error.runtimeType}');
      }
      return null;
    }
  }
}
