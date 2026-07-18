import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:geolocator/geolocator.dart';

import '../core/app_config.dart';
import '../core/app_locale.dart';
import '../models/runtime_config.dart';
import '../models/session.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';
import '../services/push_notification_service.dart';
import '../services/live_service.dart';
import '../services/nfc_card_service.dart';

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
  List<Map<String, dynamic>> earningTransactions = [];
  List<Map<String, dynamic>> settlements = [];
  Map<String, dynamic>? routeVehicle;
  Map<String, dynamic>? routeTrip;
  Map<String, dynamic>? routeInfo;
  List<Map<String, dynamic>> routePassengers = [];
  bool routeServiceBusy = false;
  bool nfcAvailable = false;
  bool cardTapGoReady = false;

  Timer? _requestPoller;
  Timer? _presenceTimer;
  Timer? _routeHeartbeatTimer;
  StreamSubscription<RemoteMessage>? _pushMessageSubscription;
  StreamSubscription<RemoteMessage>? _pushOpenedSubscription;
  bool _pollInFlight = false;
  bool _presenceInFlight = false;
  bool _pushInitialized = false;
  final Set<String> _rejectedRequestIds = <String>{};
  final LiveService _live = LiveService();
  final NfcCardService _nfcCardService = const NfcCardService();
  StreamSubscription<Map<String, dynamic>>? _liveSubscription;
  String? _liveBookingId;

  bool get mustChangePassword => session?.mustChangePassword == true;
  String t(String key) => locale?.t(key) ?? key;

  void _bindApiSession() {
    final current = session;
    if (current == null) {
      api.clearSession();
      return;
    }
    api.configureSession(
      accessToken: current.token,
      rotatingRefreshToken: current.refreshToken,
      endpoint: '/v1/staff-auth/refresh',
      onChanged: (accessToken, refreshToken) async {
        final active = session;
        if (active == null) return;
        session = active.copyWith(
          token: accessToken,
          refreshToken: refreshToken,
        );
        await store.save(session!);
      },
    );
  }

  Future<void> bootstrap() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final code = await store.language().timeout(
        const Duration(seconds: 5),
      );
      if (code != null) {
        locale = await AppLocale.load(code).timeout(
          const Duration(seconds: 5),
        );
      }

      session = await store.read().timeout(
        const Duration(seconds: 8),
      );
      _bindApiSession();

      // Runtime configuration and push registration must never hold the
      // startup screen. Fallback configuration keeps login usable offline.
      unawaited(_refreshRuntimeConfig());

      if (session != null) {
        await _migrateLinkedIdentity().timeout(
          const Duration(seconds: 20),
        );
        if (!mustChangePassword) {
          await refreshDriver().timeout(
            const Duration(seconds: 25),
          );
          await refreshRouteService().timeout(const Duration(seconds: 25));
          unawaited(_initializePushSafely());
        }
      }
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshRuntimeConfig() async {
    try {
      final response = await api.getJson(
        '/v1/public/mobile-config?app=driver&version=${AppConfig.appVersion}',
      );
      config = RuntimeConfig.fromJson(
        (response['config'] ?? response).cast<String, dynamic>(),
      );
      notifyListeners();
    } catch (_) {
      // Keep the built-in fallback configuration and continue startup.
    }
  }

  Future<void> _initializePushSafely() async {
    try {
      await _initializePush().timeout(const Duration(seconds: 15));
    } catch (_) {
      _pushInitialized = false;
    }
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

      final refreshToken = (response['refreshToken'] ?? '').toString();

      if (token.isEmpty || token == 'null' || refreshToken.isEmpty) {
        throw ApiException('Login token was not returned.');
      }
      if (driverId.isEmpty) {
        throw ApiException('Driver profile is not linked to this account.');
      }

      session = Session(
        userId: driverId,
        staffId: '${staff['id'] ?? ''}',
        token: token,
        refreshToken: refreshToken,
        mobile: '${staff['mobile'] ?? identity}',
        role: '${staff['role'] ?? 'DRIVER'}',
        mustChangePassword:
            response['mustChangePassword'] == true ||
            staff['mustChangePassword'] == true,
      );

      _bindApiSession();
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
      api.getJson(
        '/v1/driver-profiles/${session!.userId}/settlements',
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
    earningTransactions = transactions
        .map((item) => item.cast<String, dynamic>())
        .toList();
    settlements = ((output[3]['items'] ?? const []) as List)
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
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
      _startRequestPolling();
      if (activeRide != null) _connectActiveRide();
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
        _connectActiveRide();
        notifyListeners();
        return;
      }

      if (activeRide != null) {
        activeRide = null;
        _disconnectActiveRide();
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

  void _connectActiveRide() {
    final bookingId = '${activeRide?['id'] ?? ''}';
    final token = session?.token ?? '';
    if (bookingId.isEmpty || token.isEmpty) return;
    if (_liveBookingId == bookingId && _liveSubscription != null) return;
    _disconnectActiveRide();
    _liveBookingId = bookingId;
    _live.connect(bookingId, token);
    _liveSubscription = _live.events.listen((event) {
      final raw = event['booking'];
      if (raw is! Map) return;
      final booking = raw.cast<String, dynamic>();
      if ('${booking['id'] ?? ''}' != _liveBookingId) return;
      final nextStatus = '${booking['status'] ?? ''}';
      if (const {
        'COMPLETED',
        'CANCELLED_BY_PASSENGER',
        'CANCELLED_BY_DRIVER',
      }.contains(nextStatus)) {
        activeRide = null;
        _disconnectActiveRide();
      } else {
        activeRide = booking;
      }
      notifyListeners();
    });
  }

  void _disconnectActiveRide() {
    _liveBookingId = null;
    unawaited(_liveSubscription?.cancel());
    _liveSubscription = null;
    _live.disconnect();
  }

  Future<void> resumeRealtime() async {
    if (session == null || mustChangePassword) return;
    try {
      await refreshDriver();
      await refreshRouteService();
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
      appVersion: AppConfig.appVersion,
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


  String _routeIdempotencyKey(String action) {
    final random = Random.secure().nextInt(1 << 32);
    return 'driver:${session?.userId ?? 'unknown'}:$action:'
        '${DateTime.now().microsecondsSinceEpoch}:$random';
  }

  Future<Map<String, dynamic>> _freshRouteLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw ApiException('Turn on location services for Route Service.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw ApiException('Location permission is required for Route Service.');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    if (position.accuracy > 100) {
      throw ApiException('Location accuracy is too low. Move to an open area and retry.');
    }
    return {
      'lat': position.latitude,
      'lng': position.longitude,
      'accuracy': position.accuracy,
      'capturedAt': position.timestamp.toUtc().toIso8601String(),
    };
  }

  Future<void> refreshRouteService() async {
    if (session == null || mustChangePassword) return;
    try {
      final response = await api.getJson('/v1/driver/route-service/status');
      final vehicle = response['vehicle'];
      final trip = response['trip'];
      final route = response['route'];
      routeVehicle = vehicle is Map ? vehicle.cast<String, dynamic>() : null;
      routeTrip = trip is Map ? trip.cast<String, dynamic>() : null;
      routeInfo = route is Map ? route.cast<String, dynamic>() : null;
      routePassengers = ((response['passengers'] ?? const []) as List)
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
      final capabilities = response['capabilities'] is Map
          ? (response['capabilities'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
      cardTapGoReady = capabilities['cardTapGoReady'] == true;
      nfcAvailable = await _nfcCardService.isAvailable();
      if (routeVehicle != null) {
        final capabilityResponse = await api.postJson(
          '/v1/driver/route-service/capability',
          {
            'builtInNfc': nfcAvailable,
            'externalReader': false,
            'capabilityObservedAt': DateTime.now().toUtc().toIso8601String(),
          },
        );
        final reportedCapabilities = capabilityResponse['capabilities'];
        if (reportedCapabilities is Map) {
          cardTapGoReady = reportedCapabilities['cardTapGoReady'] == true;
        }
      }
      if (routeTrip != null) {
        _startRouteHeartbeat();
      } else {
        _stopRouteHeartbeat();
      }
      notifyListeners();
    } catch (_) {
      routeVehicle = null;
      routeTrip = null;
      routeInfo = null;
      routePassengers = [];
      cardTapGoReady = false;
      _stopRouteHeartbeat();
      notifyListeners();
    }
  }

  void _startRouteHeartbeat() {
    if (routeTrip == null) return;
    _routeHeartbeatTimer?.cancel();
    _routeHeartbeatTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => unawaited(sendRouteHeartbeat()),
    );
  }

  void _stopRouteHeartbeat() {
    _routeHeartbeatTimer?.cancel();
    _routeHeartbeatTimer = null;
  }

  Future<void> sendRouteHeartbeat() async {
    final tripId = '${routeTrip?['id'] ?? ''}';
    if (tripId.isEmpty) return;
    try {
      final location = await _freshRouteLocation();
      final response = await api.postJson(
        '/v1/driver/route-service/heartbeat',
        {'tripId': tripId, 'location': location},
      );
      final trip = response['trip'];
      if (trip is Map) routeTrip = trip.cast<String, dynamic>();
      final passengers = await api.getJson('/v1/driver/route-service/passengers');
      routePassengers = ((passengers['items'] ?? const []) as List)
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
      notifyListeners();
    } catch (_) {
      // A later heartbeat retries. Route start/end still fail closed server-side.
    }
  }

  Future<void> startRouteTrip(String direction) async {
    if (routeVehicle == null) throw ApiException('No route vehicle is assigned to this Driver.');
    if (routeTrip != null) throw ApiException('A route trip is already active.');
    routeServiceBusy = true;
    notifyListeners();
    try {
      final location = await _freshRouteLocation();
      final response = await api.postJson('/v1/driver/route-service/start-trip', {
        'direction': direction.toUpperCase(),
        'location': location,
      });
      routeTrip = (response['trip'] as Map).cast<String, dynamic>();
      final route = response['route'];
      if (route is Map) routeInfo = route.cast<String, dynamic>();
      _startRouteHeartbeat();
    } finally {
      routeServiceBusy = false;
      notifyListeners();
    }
  }

  Future<void> endRouteTrip() async {
    final tripId = '${routeTrip?['id'] ?? ''}';
    if (tripId.isEmpty) throw ApiException('No active route trip was found.');
    routeServiceBusy = true;
    notifyListeners();
    try {
      await api.postJson('/v1/driver/route-service/end-trip', {'tripId': tripId});
      routeTrip = null;
      routePassengers = [];
      _stopRouteHeartbeat();
      await refreshRouteService();
    } finally {
      routeServiceBusy = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> tapPrepaidCard() async {
    if (routeTrip == null) throw ApiException('Start the assigned route trip first.');
    if (!nfcAvailable) throw ApiException('NFC is not available on this phone.');
    if (!cardTapGoReady) {
      throw ApiException(
        'Physical Card Tap & Go is hardware-gated until the secure card reader is verified by ASTRIDE.',
      );
    }
    if (routeServiceBusy) throw ApiException('Another card transaction is processing.');
    routeServiceBusy = true;
    notifyListeners();
    try {
      final credential = await _nfcCardService.readAstrideCredential();
      final location = await _freshRouteLocation();
      final response = await api.postJson('/v1/driver/route-service/card-tap', {
        'credential': credential,
        'method': 'NFC',
        'location': location,
        'idempotencyKey': _routeIdempotencyKey('card-tap'),
      });
      await refreshRouteService();
      return response;
    } finally {
      routeServiceBusy = false;
      notifyListeners();
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
    _connectActiveRide();
    notifyListeners();
  }

  Future<void> rejectRequest({String reason = 'DRIVER_DECLINED'}) async {
    final id = '${request?['id'] ?? ''}';
    if (id.isEmpty) return;
    await api.postJson(
      '/v1/bookings/$id/reject',
      {'reason': reason},
    );
    _rejectedRequestIds.add(id);
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

      final verification = await api.postJson(
        '/v1/bookings/$bookingId/verify-ride-otp',
        {'code': otp.trim()},
      );
      final verifiedBooking = verification['booking'];
      if (verifiedBooking is Map) {
        activeRide = verifiedBooking.cast<String, dynamic>();
      }
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
      _disconnectActiveRide();
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
      _disconnectActiveRide();
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
    _stopRouteHeartbeat();
    _disconnectActiveRide();
    await _pushMessageSubscription?.cancel();
    await _pushOpenedSubscription?.cancel();
    _pushMessageSubscription = null;
    _pushOpenedSubscription = null;
    _pushInitialized = false;
    await store.clear();
    api.clearSession();
    session = null;
    profile = {};
    documents = [];
    online = false;
    request = null;
    activeRide = null;
    routeVehicle = null;
    routeTrip = null;
    routeInfo = null;
    routePassengers = [];
    routeServiceBusy = false;
    cardTapGoReady = false;
    notifyListeners();
  }
  @override
  void dispose() {
    _requestPoller?.cancel();
    _presenceTimer?.cancel();
    _routeHeartbeatTimer?.cancel();
    _disconnectActiveRide();
    _live.dispose();
    _pushMessageSubscription?.cancel();
    _pushOpenedSubscription?.cancel();
    super.dispose();
  }

}
