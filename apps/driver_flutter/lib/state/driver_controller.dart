import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/app_locale.dart';
import '../models/runtime_config.dart';
import '../models/session.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';

class DriverController extends ChangeNotifier {
  DriverController(this.api, this.store);
  final ApiClient api;
  final SessionStore store;

  AppLocale? locale;
  Session? session;
  RuntimeConfig config = RuntimeConfig.fallback;
  bool loading = true;
  bool online = false;
  bool busy = false;
  String approval = 'PENDING';
  String onboardingStep = 'PROFILE';
  Map<String, dynamic>? request;
  Map<String, dynamic>? activeRide;
  double walletBalance = 0;
  double todayEarnings = 0;

  bool get mustChangePassword => session?.mustChangePassword == true;
  String t(String key) => locale?.t(key) ?? key;

  Future<void> bootstrap() async {
    final code = await store.language();
    if (code != null) locale = await AppLocale.load(code);
    session = await store.read();
    api.token = session?.token;
    try {
      final response =
          await api.getJson('/v1/mobile/config?app=DRIVER&version=3.14.0');
      config = RuntimeConfig.fromJson(
        (response['config'] ?? response).cast<String, dynamic>(),
      );
      if (session != null && !mustChangePassword) await refreshDriver();
    } catch (_) {
      // Keep the encrypted session during temporary network problems.
    }
    loading = false;
    notifyListeners();
  }

  Future<void> language(String code) async {
    await store.saveLanguage(code);
    locale = await AppLocale.load(code);
    notifyListeners();
  }

  Future<void> loginWithPassword(String identity, String password) async {
    busy = true;
    notifyListeners();
    try {
      final response = await api.postJson('/v1/staff-auth/login', {
        'identity': identity.trim(),
        'password': password,
        'expectedRole': 'DRIVER',
      });
      final staff =
          ((response['staff'] ?? response['user']) as Map? ?? const {})
              .cast<String, dynamic>();
      final token =
          (response['accessToken'] ?? response['token']).toString();
      if (token.isEmpty || token == 'null') {
        throw ApiException('Login token was not returned.');
      }
      session = Session(
        userId: (staff['id'] ?? response['userId']).toString(),
        token: token,
        mobile: (staff['mobile'] ?? identity).toString(),
        role: (staff['role'] ?? 'DRIVER').toString(),
        mustChangePassword:
            response['mustChangePassword'] == true ||
            staff['mustChangePassword'] == true,
      );
      api.token = token;
      await store.save(session!);
      if (!mustChangePassword) await refreshDriver();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    busy = true;
    notifyListeners();
    try {
      await api.postJson('/v1/staff-auth/change-password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      session = session!.copyWith(mustChangePassword: false);
      await store.save(session!);
      await refreshDriver();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> requestPasswordReset(String identity) async {
    await api.postJson('/v1/staff-auth/forgot-password/request', {
      'identity': identity.trim(),
      'expectedRole': 'DRIVER',
    });
  }

  Future<void> resetPassword({
    required String identity,
    required String code,
    required String newPassword,
  }) async {
    await api.postJson('/v1/staff-auth/forgot-password/verify', {
      'identity': identity.trim(),
      'code': code.trim(),
      'newPassword': newPassword,
      'expectedRole': 'DRIVER',
    });
  }

  Future<void> refreshDriver() async {
    if (session == null) return;
    final response =
        await api.getJson('/v1/driver-profiles/${session!.userId}');
    approval =
        (response['status'] ?? response['approvalStatus'] ?? approval)
            .toString();
    onboardingStep =
        (response['onboardingStep'] ?? onboardingStep).toString();
    walletBalance =
        double.tryParse('${response['walletBalance'] ?? walletBalance}') ??
            walletBalance;
    todayEarnings =
        double.tryParse('${response['todayEarnings'] ?? todayEarnings}') ??
            todayEarnings;
    notifyListeners();
  }

  Future<void> saveProfile(Map<String, dynamic> data) async {
    await api.patchJson('/v1/driver-profiles/${session!.userId}', data);
    onboardingStep = 'DOCUMENTS';
    notifyListeners();
  }

  Future<void> submitDocuments(Map<String, dynamic> data) async {
    await api.postJson(
      '/v1/driver-profiles/${session!.userId}/documents',
      data,
    );
    onboardingStep = 'REVIEW';
    approval = 'PENDING';
    notifyListeners();
  }

  Future<void> setOnline(bool value) async {
    if (mustChangePassword) {
      throw StateError('Change your temporary password first.');
    }
    if (approval != 'APPROVED') return;

    Map<String, dynamic>? location;
    if (value) {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Please turn on location services.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Location permission is required.');
      }
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      location = {
        'lat': p.latitude,
        'lng': p.longitude,
        'accuracy': p.accuracy,
      };
    }

    await api.putJson('/v1/driver-profiles/${session!.userId}/online', {
      'online': value,
      'location': location,
    });
    online = value;
    notifyListeners();
  }

  Future<void> acceptRequest() async {
    if (mustChangePassword) {
      throw StateError('Change your temporary password first.');
    }
    if (request == null) return;
    final bookingId = request!['id'].toString();
    await api.postJson('/v1/bookings/$bookingId/assign', {
      'driverId': session!.userId,
    });
    activeRide = Map<String, dynamic>.from(request!);
    activeRide!['status'] = 'DRIVER_ASSIGNED';
    request = null;
    notifyListeners();
  }

  void rejectRequest() {
    request = null;
    notifyListeners();
  }

  Future<void> updateRideStatus(String status, {String? otp}) async {
    if (activeRide == null) return;
    final bookingId = activeRide!['id'];
    await api.postJson('/v1/bookings/$bookingId/status', {
      'status': status,
      if (otp != null) 'otp': otp,
    });
    activeRide!['status'] = status;
    if (status == 'COMPLETED') activeRide = null;
    notifyListeners();
  }

  Future<void> requestSettlement(double amount) async {
    await api.postJson(
      '/v1/driver-profiles/${session!.userId}/settlements',
      {'amountPaise': (amount * 100).round()},
    );
  }

  Future<void> logout() async {
    await store.clear();
    api.token = null;
    session = null;
    online = false;
    notifyListeners();
  }
}
