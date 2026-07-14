import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';

import '../core/app_locale.dart';
import '../models/runtime_config.dart';
import '../models/session.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';
import '../services/push_notification_service.dart';

class DriverController extends ChangeNotifier {
  DriverController(this.api, this.store);

  final ApiClient api;
  final SessionStore store;

  AppLocale? locale;
  Session? session;
  RuntimeConfig config = RuntimeConfig.fallback;
  Map<String, dynamic> profile = {};
  List<Map<String, dynamic>> documents = [];

  bool loading = true;
  bool online = false;
  bool busy = false;
  String? error;
  String approval = 'PENDING';
  String onboardingStep = 'PROFILE';
  Map<String, dynamic>? request;
  Map<String, dynamic>? activeRide;
  double walletBalance = 0;
  double todayEarnings = 0;

  Timer? _requestPoller;
  Timer? _presenceTimer;
  StreamSubscription<RemoteMessage>? _pushMessageSubscription;
  StreamSubscription<RemoteMessage>? _pushOpenedSubscription;
  bool _pollInFlight = false;
  bool _presenceInFlight = false;
  bool _pushInitialized = false;
  final Set<String> _rejectedRequestIds = <String>{};

  bool get mustChangePassword => session?.mustChangePassword == true;
  String t(String key) => locale?.t(key) ?? key;

  Future<void> bootstrap() async {
    loading = true;
    notifyListeners();

    final code = await store.language();
    if (code != null) {
      locale = await AppLocale.load(code);
    }

    session = await store.read();
    api.token = session?.token;

    try {
      final response = await api.getJson(
        '/v1/mobile/config?app=DRIVER&version=3.15.1',
      );
      config = RuntimeConfig.fromJson(
        (response['config'] ?? response).cast<String, dynamic>(),
      );
    } catch (_) {
      // Runtime config failure must not delete a valid encrypted session.
    }

    if (session != null) {
      try {
        await _migrateLinkedIdentity();
        if (!mustChangePassword) {
          await refreshDriver();
          await _initializePush();
        }
      } catch (e) {
        error = e.toString();
      }
    }

    loading = false;
    notifyListeners();
  }

  Future<void> _migrateLinkedIdentity() async {
    final response = await api.getJson('/v1/staff-auth/me');
    final staff =
        ((response['staff'] ?? const {}) as Map).cast<String, dynamic>();
    final linked = '${staff['linkedEntityId'] ?? ''}';

    if (linked.isEmpty) {
      throw ApiException('Driver profile is not linked to this account.');
    }

    session = session!.copyWith(
      userId: linked,
      staffId: '${staff['id'] ?? session!.staffId}',
      mobile: '${staff['mobile'] ?? session!.mobile}',
      role: '${staff['role'] ?? 'DRIVER'}',
      mustChangePassword: staff['mustChangePassword'] == true,
    );
    await store.save(session!);
  }

  Future<void> language(String code) async {
    await store.saveLanguage(code);
    locale = await AppLocale.load(code);
    notifyListeners();

    if (session != null && !mustChangePassword) {
      try {
        await updateProfile({'preferredLanguage': code});
      } catch (_) {}
    }
  }

  Future<void> loginWithPassword(
    String identity,
    String password,
  ) async {
    busy = true;
    error = null;
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
      final driverId = '${staff['linkedEntityId'] ?? ''}';

      if (token.isEmpty || token == 'null') {
        throw ApiException('Login token was not returned.');
      }
      if (driverId.isEmpty) {
        throw ApiException('Driver profile is not linked to this account.');
      }

      session = Session(
        userId: driverId,
        staffId: '${staff['id'] ?? ''}',
        token: token,
        mobile: '${staff['mobile'] ?? identity}',
        role: '${staff['role'] ?? 'DRIVER'}',
        mustChangePassword:
            response['mustChangePassword'] == true ||
            staff['mustChangePassword'] == true,
      );

      api.token = token;
      await store.save(session!);

      if (!mustChangePassword) {
        await refreshDriver();
        await _initializePush();
      }
    } catch (e) {
      error = e.toString();
      rethrow;
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
    error = null;
    notifyListeners();

    try {
      await api.postJson('/v1/staff-auth/change-password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      session = session!.copyWith(mustChangePassword: false);
      await store.save(session!);
      await refreshDriver();
      await _initializePush();
    } catch (e) {
      error = e.toString();
      rethrow;
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
    required String challengeId,
    required String code,
    required String newPassword,
  }) async {
    await api.postJson('/v1/staff-auth/forgot-password/verify', {
      'identity': identity.trim(),
      'challengeId': challengeId.trim(),
      'code': code.trim(),
      'newPassword': newPassword,
      'expectedRole': 'DRIVER',
    });
  }

  Future<void> refreshDriver() async {
    if (session == null) return;

    final output = await Future.wait([
      api.getJson('/v1/driver-profiles/${session!.userId}'),
      api.getJson(
        '/v1/driver-profiles/${session!.userId}/documents',
      ),
      api.getJson(
        '/v1/driver-profiles/${session!.userId}/wallet',
      ),
    ]);
    profile = Map<String, dynamic>.from(output[0]);
    documents = ((output[1]['items'] ?? const []) as List)
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
    final wallet = output[2];
    walletBalance =
        (num.tryParse('${wallet['balancePaise'] ?? 0}') ?? 0) /
            100;
    final transactions =
        ((wallet['transactions'] ?? const []) as List)
            .whereType<Map>();
    final today = DateTime.now();
    todayEarnings = transactions
        .where((item) {
          final created =
              DateTime.tryParse('${item['createdAt']}')?.toLocal();
          return created != null &&
              created.year == today.year &&
              created.month == today.month &&
              created.day == today.day;
        })
        .fold<double>(
          0,
          (total, item) =>
              total +
              ((num.tryParse('${item['netPaise'] ?? 0}') ?? 0) /
                  100),
        );
    approval =
        '${profile['status'] ?? profile['approvalStatus'] ?? 'PENDING'}';
    onboardingStep = '${profile['onboardingStep'] ?? 'PROFILE'}';
    online = profile['online'] == true;
    if (online && approval == 'APPROVED') {
      _startPresenceHeartbeat();
      if (activeRide == null) {
        _startRequestPolling();
      } else {
        _stopRequestPolling();
      }
    } else {
      _stopRequestPolling();
      _stopPresenceHeartbeat();
    }

    notifyListeners();
  }

  Future<void> saveProfile(Map<String, dynamic> data) async {
    busy = true;
    error = null;
    notifyListeners();

    try {
      final response = await api.patchJson(
        '/v1/driver-profiles/${session!.userId}',
        {
          ...data,
          'onboardingStep': 'DOCUMENTS',
        },
      );
      profile = Map<String, dynamic>.from(response);
      onboardingStep = 'DOCUMENTS';
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    busy = true;
    error = null;
    notifyListeners();

    try {
      final response = await api.patchJson(
        '/v1/driver-profiles/${session!.userId}',
        data,
      );
      profile = Map<String, dynamic>.from(response);
      approval = '${profile['status'] ?? approval}';
      onboardingStep =
          '${profile['onboardingStep'] ?? onboardingStep}';
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
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
    final url = await uploadFile(
      fileName: fileName,
      mimeType: mimeType,
      base64: base64,
      category: 'profile',
    );
    await updateProfile({'photoUrl': url});
  }

  Future<Map<String, dynamic>> uploadDocument({
    required String type,
    required String fileName,
    required String mimeType,
    required String base64,
  }) async {
    final url = await uploadFile(
      fileName: fileName,
      mimeType: mimeType,
      base64: base64,
      category: type.toLowerCase(),
    );

    final document = await api.postJson(
      '/v1/driver-profiles/${session!.userId}/documents',
      {
        'type': type,
        'fileUrl': url,
      },
    );
    documents = [
      document,
      ...documents.where((item) => item['type'] != type),
    ];

    if (type == 'PROFILE_PHOTO') {
      await updateProfile({'photoUrl': url});
    }

    return document;
  }

  Future<void> completeDocuments() async {
    await updateProfile({'onboardingStep': 'REVIEW'});
    onboardingStep = 'REVIEW';
    approval = '${profile['status'] ?? 'DRAFT'}';
    notifyListeners();
  }

  void _startRequestPolling() {
    _requestPoller?.cancel();
    unawaited(pollRequests());
    _requestPoller = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(pollRequests()),
    );
    _startPresenceHeartbeat();
  }

  void _stopRequestPolling() {
    _requestPoller?.cancel();
    _requestPoller = null;
    request = null;
  }

  void _startPresenceHeartbeat() {
    if (!online || session == null) return;
    _presenceTimer?.cancel();
    unawaited(_syncPresence());
    _presenceTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(_syncPresence()),
    );
  }

  void _stopPresenceHeartbeat() {
    _presenceTimer?.cancel();
    _presenceTimer = null;
  }

  Future<void> _syncPresence() async {
    if (!online ||
        session == null ||
        _presenceInFlight) {
      return;
    }
    _presenceInFlight = true;
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final response = await api.putJson(
        '/v1/driver-profiles/${session!.userId}/online',
        {
          'online': true,
          'location': {
            'lat': position.latitude,
            'lng': position.longitude,
            'accuracy': position.accuracy,
          },
        },
      );
      profile = {...profile, ...response};
      online = response['online'] == true;
    } catch (_) {
      // The next heartbeat will retry.
    } finally {
      _presenceInFlight = false;
    }
  }

  Future<void> pollRequests() async {
    if (!online ||
        approval != 'APPROVED' ||
        session == null ||
        _pollInFlight) {
      return;
    }
    _pollInFlight = true;
    try {
      final response = await api.getJson('/v1/driver/sync');
      final assigned = response['activeRide'];
      if (assigned is Map) {
        activeRide = assigned.cast<String, dynamic>();
        request = null;
        _requestPoller?.cancel();
        _requestPoller = null;
        notifyListeners();
        return;
      }

      if (activeRide != null) {
        activeRide = null;
      }

      final incoming = response['request'];
      final nextRequest = incoming is Map
          ? incoming.cast<String, dynamic>()
          : null;
      if (nextRequest != null &&
          _rejectedRequestIds.contains('${nextRequest['id']}')) {
        request = null;
      } else {
        request = nextRequest;
      }
      notifyListeners();
    } catch (_) {
      // Polling failure never logs the Driver out.
    } finally {
      _pollInFlight = false;
    }
  }

  Future<void> resumeRealtime() async {
    if (session == null || mustChangePassword) return;
    try {
      await refreshDriver();
      if (online) {
        await _syncPresence();
        await pollRequests();
      }
    } catch (_) {
      // A later heartbeat/poll will retry.
    }
  }

  Future<void> _initializePush() async {
    if (_pushInitialized || session == null) return;
    _pushInitialized = true;

    final service = PushNotificationService(api);
    final token = await service.initialize(
      actorType: 'driver',
      actorId: session!.userId,
      deviceId: 'driver-${session!.staffId.isNotEmpty
          ? session!.staffId
          : session!.userId}',
      locale: locale?.code ?? 'en',
      appVersion: '3.16.0+335',
    );

    if (token == null) {
      _pushInitialized = false;
      return;
    }

    _pushMessageSubscription ??=
        FirebaseMessaging.onMessage.listen((message) {
      unawaited(pollRequests());
    });
    _pushOpenedSubscription ??=
        FirebaseMessaging.onMessageOpenedApp.listen((message) {
      unawaited(resumeRealtime());
    });

    final initial =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      await resumeRealtime();
    }
  }

  Future<void> setOnline(bool value) async {
    if (mustChangePassword) {
      throw StateError('Change your temporary password first.');
    }
    if (approval != 'APPROVED') {
      throw StateError('Driver approval is still pending.');
    }

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

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      location = {
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy': position.accuracy,
      };
    }

    final response = await api.putJson(
      '/v1/driver-profiles/${session!.userId}/online',
      {
        'online': value,
        'location': location,
      },
    );

    online = response['online'] == true;
    profile = {
      ...profile,
      ...response,
    };
    if (online) {
      _startRequestPolling();
    } else {
      _stopRequestPolling();
      _stopPresenceHeartbeat();
    }
    notifyListeners();
  }

  Future<void> acceptRequest() async {
    if (mustChangePassword) {
      throw StateError('Change your temporary password first.');
    }
    if (request == null) return;

    final bookingId = '${request!['id']}';
    final response = await api.postJson(
      '/v1/bookings/$bookingId/accept',
      const {},
    );
    activeRide = ((response['booking'] ?? response) as Map)
        .cast<String, dynamic>();
    request = null;
    _requestPoller?.cancel();
    _requestPoller = null;
    notifyListeners();
  }

  void rejectRequest() {
    final id = '${request?['id'] ?? ''}';
    if (id.isNotEmpty) _rejectedRequestIds.add(id);
    request = null;
    notifyListeners();
  }

  Future<void> updateRideStatus(
    String status, {
    String? otp,
  }) async {
    if (activeRide == null) return;

    final bookingId = '${activeRide!['id']}';
    Map<String, dynamic> response;

    if (status == 'IN_PROGRESS') {
      if (otp == null || otp.trim().length < 4) {
        throw ApiException('Enter the passenger ride OTP.');
      }

      await api.postJson(
        '/v1/bookings/$bookingId/transition',
        {
          'status': 'OTP_VERIFIED',
          'otp': otp.trim(),
        },
      );
      response = await api.postJson(
        '/v1/bookings/$bookingId/transition',
        {'status': 'IN_PROGRESS'},
      );
    } else {
      response = await api.postJson(
        '/v1/bookings/$bookingId/transition',
        {'status': status},
      );
    }

    activeRide = Map<String, dynamic>.from(response);
    if (status == 'COMPLETED') {
      activeRide = null;
      if (online) _startRequestPolling();
    }
    notifyListeners();
  }

  Future<void> cancelActiveRide(String reason) async {
    if (activeRide == null) return;
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      throw ApiException('Select or write a cancellation reason.');
    }

    busy = true;
    error = null;
    notifyListeners();

    try {
      final bookingId = '${activeRide!['id']}';
      await api.postJson(
        '/v1/bookings/$bookingId/driver-cancel',
        {'reason': cleanReason},
      );
      activeRide = null;
      request = null;
      if (online) _startRequestPolling();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> submitSupportIssue({
    required String category,
    required String description,
    String? rideId,
  }) =>
      api.postJson('/v1/support/issues', {
        'category': category,
        'description': description.trim(),
        if (rideId != null && rideId.isNotEmpty)
          'rideId': rideId,
      });

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
      'actorType': 'driver',
      'actorId': session!.userId,
      'bookingId': bookingId ?? activeRide?['id'],
      'location': {
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy': position.accuracy,
      },
    });
  }

  Future<void> requestSettlement(double amount) async {
    await api.postJson(
      '/v1/driver-profiles/${session!.userId}/settlements',
      {
        'amountPaise': (amount * 100).round(),
      },
    );
  }

  Future<void> logout() async {
    try {
      await api.postJson('/v1/staff-auth/logout', const {});
    } catch (_) {}

    _stopRequestPolling();
    _stopPresenceHeartbeat();
    await _pushMessageSubscription?.cancel();
    await _pushOpenedSubscription?.cancel();
    _pushMessageSubscription = null;
    _pushOpenedSubscription = null;
    _pushInitialized = false;
    await store.clear();
    api.token = null;
    session = null;
    profile = {};
    documents = [];
    online = false;
    request = null;
    activeRide = null;
    notifyListeners();
  }
  @override
  void dispose() {
    _requestPoller?.cancel();
    _presenceTimer?.cancel();
    _pushMessageSubscription?.cancel();
    _pushOpenedSubscription?.cancel();
    super.dispose();
  }

}
