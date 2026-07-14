import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';

import '../core/app_config.dart';
import '../core/app_locale.dart';
import '../models/runtime_config.dart';
import '../models/session.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';
import '../services/payment_gateway.dart';
import '../services/push_notification_service.dart';

class PassengerController extends ChangeNotifier {
  PassengerController(this.api, this.store);

  final ApiClient api;
  final SessionStore store;

  AppLocale? locale;
  Session? session;
  RuntimeConfig config = RuntimeConfig.fallback;
  Map<String, dynamic> profile = {};

  bool loading = true;
  String? error;
  Map<String, dynamic>? activeBooking;
  String? _otpSessionId;
  String profileName = '';
  String? profilePhotoUrl;
  StreamSubscription<RemoteMessage>? _pushMessageSubscription;
  StreamSubscription<RemoteMessage>? _pushOpenedSubscription;
  bool _pushInitialized = false;

  Future<void> bootstrap() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final code = await store.language();
      if (code != null) {
        locale = await AppLocale.load(code);
      }

      session = await store.read();
      profileName = (await store.profileName()) ?? '';
      api.token = session?.token;

      final response = await api.getJson(
        '/v1/public/mobile-config?app=passenger&version=${AppConfig.appVersion}',
      );
      config = RuntimeConfig.fromJson(
        (response['config'] ?? response).cast<String, dynamic>(),
      );

      if (session != null) {
        await refreshProfile();
        await restoreActiveBooking();
        await _initializePush();

        if ('${profile['fullName'] ?? ''}'.trim().isEmpty &&
            profileName.trim().isNotEmpty) {
          await updateProfileName(profileName);
        }
      }
    } catch (e) {
      error = e.toString();
    }

    loading = false;
    notifyListeners();
  }

  Future<void> selectLanguage(String code) async {
    await changeLanguage(code);
  }

  Future<void> requestOtp(String mobile) async {
    final response = await api.postJson(
      '/v1/auth/otp/request',
      {'mobile': _normalizeMobile(mobile)},
    );

    final id = response['sessionId']?.toString();
    if (id == null || id.isEmpty) {
      throw ApiException(
        'OTP session was not returned by the server.',
      );
    }
    _otpSessionId = id;
  }

  Future<void> login(String mobile, String otp) async {
    final sessionId = _otpSessionId;
    if (sessionId == null || sessionId.isEmpty) {
      throw ApiException('Please request a new OTP.');
    }

    final response = await api.postJson(
      '/v1/auth/otp/verify',
      {
        'sessionId': sessionId,
        'code': otp.trim(),
      },
    );

    final passenger = response['passenger'] is Map
        ? (response['passenger'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    final token = (response['accessToken'] ??
            response['token'] ??
            response['jwt'])
        ?.toString();

    if (token == null || token.isEmpty) {
      throw ApiException('Login token was not returned.');
    }

    final normalizedMobile = _normalizeMobile(mobile);
    session = Session(
      userId: '${passenger['id'] ??
          response['passengerId'] ??
          response['userId'] ??
          normalizedMobile}',
      token: token,
      mobile: normalizedMobile,
    );

    api.token = token;
    await store.save(session!);
    _otpSessionId = null;
    profile = passenger;
    profileName = '${passenger['fullName'] ?? ''}';
    profilePhotoUrl = passenger['photoUrl']?.toString();
    await restoreActiveBooking();
    await _initializePush();
    notifyListeners();
  }

  String _normalizeMobile(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 10) return '91$digits';
    if (digits.length == 12 && digits.startsWith('91')) {
      return digits;
    }
    return digits;
  }

  Future<void> refreshProfile() async {
    if (session == null) return;

    final response = await api.getJson(
      '/v1/passengers/${session!.userId}',
    );
    profile = Map<String, dynamic>.from(response);
    profileName = '${profile['fullName'] ?? ''}';
    profilePhotoUrl = profile['photoUrl']?.toString();

    if (profileName.isNotEmpty) {
      await store.saveProfileName(profileName);
    }

    notifyListeners();
  }

  Future<void> updateProfileName(String value) async {
    final clean = value.trim();
    if (clean.isEmpty || session == null) return;

    final response = await api.patchJson(
      '/v1/passengers/${session!.userId}',
      {'fullName': clean},
    );

    profile = Map<String, dynamic>.from(response);
    profileName = '${profile['fullName'] ?? clean}';
    await store.saveProfileName(profileName);
    notifyListeners();
  }

  Future<void> changeLanguage(String code) async {
    await store.saveLanguage(code);
    locale = await AppLocale.load(code);

    if (session != null) {
      try {
        final response = await api.patchJson(
          '/v1/passengers/${session!.userId}',
          {'preferredLanguage': code},
        );
        profile = Map<String, dynamic>.from(response);
      } catch (_) {}
    }

    notifyListeners();
  }

  Future<String> uploadFile({
    required String fileName,
    required String mimeType,
    required String base64,
    required String category,
  }) async {
    final response = await api.postJson('/v1/uploads', {
      'fileName': fileName,
      'mimeType': mimeType,
      'base64': base64,
      'category': category,
    });

    final url = '${response['url'] ?? ''}';
    if (url.isEmpty) {
      throw ApiException('Uploaded file URL was not returned.');
    }
    return url;
  }

  Future<void> uploadProfilePhoto({
    required String fileName,
    required String mimeType,
    required String base64,
  }) async {
    if (session == null) return;

    final url = await uploadFile(
      fileName: fileName,
      mimeType: mimeType,
      base64: base64,
      category: 'profile',
    );

    final response = await api.patchJson(
      '/v1/passengers/${session!.userId}',
      {'photoUrl': url},
    );

    profile = Map<String, dynamic>.from(response);
    profilePhotoUrl = '${profile['photoUrl'] ?? url}';
    notifyListeners();
  }

  Future<Map<String, dynamic>> estimate(
    Map<String, dynamic> pickup,
    Map<String, dynamic> destination,
  ) async =>
      api.postJson('/v1/fares/estimate', {
        'pickup': pickup,
        'destination': destination,
      });

  Future<void> book(
    Map<String, dynamic> pickup,
    Map<String, dynamic> destination,
    String method, {
    String? pickupAddress,
    String? destinationAddress,
    String rideType = 'FULL_TOTO',
    double? distanceKm,
    bool saferideEnabled = false,
  }) async {
    activeBooking = await api.postJson('/v1/bookings', {
      'passengerId': session!.userId,
      'pickup': pickup,
      'destination': destination,
      'pickupAddress': pickupAddress,
      'destinationAddress': destinationAddress,
      'paymentMethod': method,
      'paymentPreference': method,
      'rideType': rideType,
      'saferideEnabled': saferideEnabled,
      if (distanceKm != null) 'distanceKm': distanceKm,
    });
    notifyListeners();
  }


  Future<void> payPendingUpi(PaymentGateway gateway) async {
    final booking = activeBooking;
    final passengerSession = session;
    if (booking == null || passengerSession == null) {
      throw ApiException('No pending booking is available for payment.');
    }
    final bookingId = '${booking['id'] ?? ''}';
    if (bookingId.isEmpty) {
      throw ApiException('Booking ID is missing.');
    }
    final preference =
        '${booking['paymentPreference'] ?? booking['paymentMethod'] ?? ''}'
            .toUpperCase();
    if (preference != 'UPI') {
      throw ApiException('This booking does not require UPI pre-payment.');
    }

    final fare = booking['fareEstimate'] is Map
        ? (booking['fareEstimate'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    final amountPaise = (num.tryParse('${fare['totalPaise']}') ??
            ((num.tryParse('${fare['amount'] ?? fare['total'] ?? 0}') ?? 0) *
                100))
        .round();
    if (amountPaise <= 0) {
      throw ApiException('The payable fare is unavailable.');
    }

    final payment = await api.postJson('/v1/payments/orders', {
      'bookingId': bookingId,
      'passengerId': passengerSession.userId,
      'method': 'UPI',
      'amountPaise': amountPaise,
      'idempotencyKey': 'mobile:$bookingId:$amountPaise',
    });
    final paymentId = '${payment['id'] ?? ''}';
    final providerOrderId = '${payment['providerOrderId'] ?? ''}';
    if (paymentId.isEmpty || providerOrderId.isEmpty) {
      throw ApiException('Payment order was not returned by the server.');
    }

    String keyId = AppConfig.razorpayKeyId;
    try {
      final publicConfig = await api.getJson(
        '/v1/public/mobile-config?app=passenger',
      );
      final clientProviders = publicConfig['clientProviders'];
      final payments = clientProviders is Map
          ? clientProviders['payments']
          : null;
      if (payments is Map) {
        keyId = '${payments['razorpayKeyId'] ?? keyId}';
      }
    } catch (_) {
      // The compile-time public key remains the secure fallback.
    }

    final result = await gateway.open(
      keyId: keyId,
      orderId: providerOrderId,
      amountPaise: amountPaise,
      passengerName: '${profile['fullName'] ?? (profileName.isNotEmpty ? profileName : 'Passenger')}',
      passengerMobile: passengerSession.mobile,
      description: 'ASTRIDE ride $bookingId',
    );
    final verification = await api.postJson(
      '/v1/payments/$paymentId/verify',
      {
        'providerPaymentId': result.paymentId,
        'providerOrderId': result.orderId,
        'signature': result.signature,
      },
    );
    final synchronized = verification['booking'];
    if (synchronized is Map) {
      activeBooking = synchronized.cast<String, dynamic>();
    } else {
      await restoreActiveBooking();
    }
    notifyListeners();
  }

  Future<void> restoreActiveBooking() async {
    if (session == null) return;
    try {
      final response = await api.getJson('/v1/passenger/active-booking');
      final booking = response['booking'];
      activeBooking = booking is Map
          ? booking.cast<String, dynamic>()
          : null;
      notifyListeners();
    } catch (_) {
      // Do not block login when no active booking can be restored.
    }
  }

  Future<void> _initializePush() async {
    if (_pushInitialized || session == null) return;
    _pushInitialized = true;

    final service = PushNotificationService(api);
    final token = await service.initialize(
      actorType: 'passenger',
      actorId: session!.userId,
      deviceId: 'passenger-${session!.userId}',
      locale: locale?.code ?? 'en',
      appVersion: AppConfig.appVersion,
    );

    if (token == null) {
      _pushInitialized = false;
      return;
    }

    _pushMessageSubscription ??=
        FirebaseMessaging.onMessage.listen((message) {
      unawaited(restoreActiveBooking());
    });
    _pushOpenedSubscription ??=
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(restoreActiveBooking());
    });

    final initial =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      await restoreActiveBooking();
    }
  }

  void resumeBooking(Map<String, dynamic> booking) {
    activeBooking = Map<String, dynamic>.from(booking);
    notifyListeners();
  }

  Future<Map<String, dynamic>> triggerSos({
    String? bookingId,
  }) async {
    if (session == null) {
      throw ApiException('Please sign in before using SOS.');
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw ApiException('Turn on location services to send SOS.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw ApiException('Location permission is required for SOS.');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return api.postJson('/v1/safety/sos', {
      'actorType': 'passenger',
      'actorId': session!.userId,
      'bookingId': bookingId ?? activeBooking?['id'],
      'location': {
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy': position.accuracy,
      },
    });
  }

  Future<void> cancel() async {
    if (activeBooking == null) return;

    await api.postJson(
      '/v1/bookings/${activeBooking!['id']}/cancel',
      {'reason': 'PASSENGER_REQUEST'},
    );
    activeBooking = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>> wallet() =>
      api.getJson('/v1/passenger/wallet');

  Future<Map<String, dynamic>> walletTransactions() =>
      api.getJson('/v1/passenger/wallet/transactions');

  Future<Map<String, dynamic>> referral() =>
      api.getJson('/v1/passenger/referral');

  Future<Map<String, dynamic>> referralHistory() =>
      api.getJson('/v1/passenger/referral/history');

  Future<Map<String, dynamic>> referralRewards() =>
      api.getJson('/v1/passenger/referral/rewards');

  Future<Map<String, dynamic>> applyReferral(String code) =>
      api.postJson(
        '/v1/passenger/referral/apply',
        {'code': code.trim()},
      );

  Future<Map<String, dynamic>> offers() =>
      api.getJson('/v1/passenger/offers');

  Future<Map<String, dynamic>> validateOffer(String code) =>
      api.postJson(
        '/v1/offers/validate-code',
        {'code': code.trim()},
      );

  Future<Map<String, dynamic>> submitIssue({
    required String category,
    required String description,
    String? rideId,
    String? attachmentUrl,
  }) =>
      api.postJson('/v1/support/issues', {
        'category': category,
        'description': description,
        if (rideId != null && rideId.isNotEmpty)
          'rideId': rideId,
        if (attachmentUrl != null && attachmentUrl.isNotEmpty)
          'attachmentUrl': attachmentUrl,
      });

  Future<void> logout() async {
    try {
      await api.postJson('/v1/auth/logout', const {});
    } catch (_) {}

    await _pushMessageSubscription?.cancel();
    await _pushOpenedSubscription?.cancel();
    _pushMessageSubscription = null;
    _pushOpenedSubscription = null;
    _pushInitialized = false;
    await store.clear();
    api.token = null;
    session = null;
    profile = {};
    profileName = '';
    profilePhotoUrl = null;
    activeBooking = null;
    _otpSessionId = null;
    notifyListeners();
  }

  String t(String key) => locale?.t(key) ?? key;
  @override
  void dispose() {
    _pushMessageSubscription?.cancel();
    _pushOpenedSubscription?.cancel();
    super.dispose();
  }

}
