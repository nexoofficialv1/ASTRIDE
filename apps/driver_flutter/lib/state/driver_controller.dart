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
  String? _otpSessionId;
  bool online = false;
  bool busy = false;
  String approval = 'PENDING';
  String onboardingStep = 'PROFILE';
  Map<String, dynamic>? request;
  Map<String, dynamic>? activeRide;
  double walletBalance = 685;
  double todayEarnings = 685;

  String t(String key) => locale?.t(key) ?? key;

  Future<void> bootstrap() async {
    final code = await store.language();
    if (code != null) locale = await AppLocale.load(code);
    session = await store.read();
    api.token = session?.token;
    try {
      final response = await api.getJson('/v1/mobile/config?app=DRIVER&version=2.2.0');
      config = RuntimeConfig.fromJson((response['config'] ?? response).cast<String, dynamic>());
      if (session != null) await refreshDriver();
    } catch (_) {}
    loading = false;
    notifyListeners();
  }

  Future<void> language(String code) async {
    await store.saveLanguage(code);
    locale = await AppLocale.load(code);
    notifyListeners();
  }

  Future<void> requestOtp(String mobile) async {
    final response = await api.postJson(
      '/v1/auth/otp/request',
      {'mobile': _normalizeMobile(mobile)},
    );
    final id = response['sessionId']?.toString();
    if (id == null || id.isEmpty) {
      throw ApiException('OTP session was not returned by the server.');
    }
    _otpSessionId = id;
  }

  String _normalizeMobile(String value) {
    final digits = value.replaceAll(RegExp(r'\\D'), '');
    if (digits.length == 10) return '91$digits';
    if (digits.length == 12 && digits.startsWith('91')) return digits;
    return digits;
  }

  Future<void> login(String mobile, String otp) async {
    busy = true;
    notifyListeners();
    try {
      if (_otpSessionId == null) throw StateError('OTP session missing');
      final passengerAuth = await api.postJson('/v1/auth/otp/verify', {'sessionId': _otpSessionId, 'code': otp});
      api.token = passengerAuth['accessToken']?.toString();
      final response = await api.postJson('/v1/drivers/register', {'mobile': _normalizeMobile(mobile)});
      final driver = (response['driver'] as Map).cast<String, dynamic>();
      session = Session(
        userId: driver['id'].toString(),
        token: response['accessToken'].toString(),
        mobile: mobile,
      );
      api.token = session!.token;
      await store.save(session!);
      await refreshDriver();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> refreshDriver() async {
    if (session == null) return;
    try {
      final response = await api.getJson('/v1/driver-profiles/${session!.userId}');
      approval = (response['status'] ?? response['approvalStatus'] ?? approval).toString();
      onboardingStep = (response['onboardingStep'] ?? onboardingStep).toString();
      walletBalance = double.tryParse('${response['walletBalance'] ?? walletBalance}') ?? walletBalance;
      todayEarnings = double.tryParse('${response['todayEarnings'] ?? todayEarnings}') ?? todayEarnings;
    } catch (_) {}
    notifyListeners();
  }

  Future<void> saveProfile(Map<String, dynamic> data) async {
    await api.patchJson('/v1/driver-profiles/${session!.userId}', data);
    onboardingStep = 'DOCUMENTS';
    notifyListeners();
  }

  Future<void> submitDocuments(Map<String, dynamic> data) async {
    await api.postJson('/v1/driver-profiles/${session!.userId}/documents', data);
    onboardingStep = 'REVIEW';
    approval = 'PENDING';
    notifyListeners();
  }

  Future<void> setOnline(bool value) async {
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
        throw StateError('Location permission is required to go online.');
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
        'recordedAt': DateTime.now().toUtc().toIso8601String(),
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
    if (request == null) return;
    final bookingId = request!['id'].toString();
    await api.postJson('/v1/bookings/$bookingId/assign', {'driverId': session!.userId});
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
    if (status == 'COMPLETED') {
      todayEarnings += double.tryParse('${activeRide!['fare'] ?? 0}') ?? 0;
      activeRide = null;
    }
    notifyListeners();
  }

  Future<void> requestSettlement(double amount) async {
    await api.postJson('/v1/driver-profiles/${session!.userId}/settlements', {'amountPaise': (amount * 100).round()});
  }

  Future<void> logout() async {
    await store.clear();
    session = null;
    online = false;
    notifyListeners();
  }
}
