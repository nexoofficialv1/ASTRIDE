import 'package:flutter/foundation.dart';

import '../core/partner_strings.dart';
import '../models/partner_models.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';

class PartnerController extends ChangeNotifier {
  PartnerController(this.api, this.store);

  final ApiClient api;
  final SessionStore store;

  PartnerSession? session;
  Map<String, dynamic> profile = {};
  Map<String, dynamic>? dashboard;
  List<DriverPerformance> drivers = [];
  Map<String, dynamic>? earnings;

  bool busy = false;
  String? error;
  String languageCode = 'en';
  String driverFilter = 'ALL';
  String driverQuery = '';
  DateTimeRangeValue range = DateTimeRangeValue.month();

  bool get mustChangePassword =>
      session?.mustChangePassword == true;
  PartnerStrings get strings => PartnerStrings(languageCode);
  bool get isPromoter => session?.role == 'PROMOTER';
  bool get isAreaPromoter => session?.role == 'AREA_PROMOTER';

  Future<void> bootstrap() async {
    languageCode = await store.readLanguage();
    session = await store.readSession();

    if (session != null) {
      api.token = session!.token;

      try {
        await _migrateLinkedIdentity();

        if (!mustChangePassword) {
          await refreshProfile();
          await refresh();
        }
      } catch (e) {
        error = e.toString();
      }
    }

    notifyListeners();
  }

  Future<void> _migrateLinkedIdentity() async {
    final response = await api.get('/v1/staff-auth/me');
    final staff =
        ((response['staff'] ?? const {}) as Map).cast<String, dynamic>();
    final linked = '${staff['linkedEntityId'] ?? ''}';

    if (linked.isEmpty) {
      throw ApiException('Partner profile is not linked to this account.');
    }

    session = session!.copyWith(
      id: linked,
      staffId: '${staff['id'] ?? session!.staffId}',
      name: '${staff['name'] ?? session!.name}',
      mobile: '${staff['mobile'] ?? session!.mobile}',
      role: '${staff['role'] ?? session!.role}',
      mustChangePassword: staff['mustChangePassword'] == true,
    );
    await store.writeSession(session!);
  }

  Future<void> setLanguage(String code) async {
    languageCode = code;
    await store.writeLanguage(code);
    notifyListeners();

    if (session != null && !mustChangePassword) {
      try {
        await updateProfile({'preferredLanguage': code});
      } catch (_) {}
    }
  }

  Future<void> login(String identity, String password) async {
    await _run(() async {
      final response = await api.post('/v1/staff-auth/login', {
        'identity': identity.trim(),
        'password': password,
        'expectedRole': 'PARTNER',
      });

      session = PartnerSession.fromJson(response);

      if (session!.token.isEmpty) {
        throw ApiException('Login token was not returned.');
      }
      if (session!.id.isEmpty) {
        throw ApiException('Partner profile is not linked.');
      }

      api.token = session!.token;
      await store.writeSession(session!);

      if (!mustChangePassword) {
        await refreshProfile();
        await refresh();
      }
    });
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    await _run(() async {
      await api.post('/v1/staff-auth/change-password', {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      session = session!.copyWith(mustChangePassword: false);
      await store.writeSession(session!);
      await refreshProfile();
      await refresh();
    });
  }

  Future<void> requestPasswordReset(String identity) =>
      _run(
        () => api.post(
          '/v1/staff-auth/forgot-password/request',
          {
            'identity': identity.trim(),
            'expectedRole': 'PARTNER',
          },
        ),
      );

  Future<void> refreshProfile() async {
    final response = await api.get('/v1/partner/me');
    profile =
        ((response['partner'] ?? response) as Map)
            .cast<String, dynamic>();

    session = session!.copyWith(
      id: '${profile['id'] ?? session!.id}',
      name: '${profile['name'] ?? session!.name}',
      mobile: '${profile['mobile'] ?? session!.mobile}',
      role: '${profile['role'] ?? session!.role}',
    );
    await store.writeSession(session!);
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    await _run(() async {
      final response = await api.patchJson(
        '/v1/partner/me',
        data,
      );
      profile =
          ((response['partner'] ?? response) as Map)
              .cast<String, dynamic>();
      session = session!.copyWith(
        name: '${profile['name'] ?? session!.name}',
        mobile: '${profile['mobile'] ?? session!.mobile}',
      );
      await store.writeSession(session!);
    });
  }

  Future<String> uploadFile({
    required String fileName,
    required String mimeType,
    required String base64,
    required String category,
  }) async {
    final response = await api.post('/v1/uploads', {
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

  Future<void> refresh({
    String? from,
    String? to,
  }) async {
    if (mustChangePassword) return;

    final start = from ?? range.fromIso;
    final end = to ?? range.toIso;
    final suffix = '?from=$start&to=$end';

    final output = await Future.wait([
      api.get('/v1/partner/dashboard$suffix'),
      api.get('/v1/partner/drivers$suffix'),
      api.get('/v1/partner/earnings'),
    ]);

    dashboard = output[0];
    drivers = ((output[1]['items'] ?? const []) as List)
        .whereType<Map>()
        .map(
          (item) => DriverPerformance.fromJson(
            item.cast<String, dynamic>(),
          ),
        )
        .toList();
    earnings = output[2];
    notifyListeners();
  }

  Future<void> setRange(
    DateTime from,
    DateTime to,
  ) async {
    range = DateTimeRangeValue(from, to);
    await refresh();
  }

  void setDriverFilter(String value) {
    driverFilter = value;
    notifyListeners();
  }

  void setDriverQuery(String value) {
    driverQuery = value.trim().toLowerCase();
    notifyListeners();
  }

  List<DriverPerformance> get visibleDrivers =>
      drivers.where((driver) {
        final queryOk = driverQuery.isEmpty ||
            driver.name.toLowerCase().contains(driverQuery) ||
            driver.vehicle.toLowerCase().contains(driverQuery) ||
            driver.mobile.contains(driverQuery);

        final filterOk = switch (driverFilter) {
          'ONLINE' => driver.online,
          'ATTENTION' => driver.needsAttention,
          'TOP' => driver.topPerformer,
          _ => true,
        };

        return queryOk && filterOk;
      }).toList();

  Future<Map<String, dynamic>> createDriver({
    required String fullName,
    required String mobile,
    required String temporaryPassword,
    required String vehicleNumber,
    String vehicleType = 'TOTO',
  }) async {
    if (!isPromoter) {
      throw ApiException('Only a Promoter can add a Driver.');
    }
    Map<String, dynamic> result = {};
    await _run(() async {
      result = await api.post('/v1/partner/drivers/create', {
        'fullName': fullName.trim(),
        'mobile': mobile.replaceAll(RegExp(r'\D'), ''),
        'temporaryPassword': temporaryPassword,
        'preferredLanguage': languageCode,
        'vehicle': {
          'number': vehicleNumber.trim(),
          'type': vehicleType,
        },
      });
    });
    await refresh();
    return result;
  }

  Future<Map<String, dynamic>> loadDriverReview(String driverId) =>
      api.get('/v1/partner/drivers/$driverId');

  Future<Map<String, dynamic>> reviewDriver(
    String driverId, {
    required String status,
    String? remarks,
  }) async {
    Map<String, dynamic> result = {};
    await _run(() async {
      result = await api.post(
        '/v1/partner/drivers/$driverId/review',
        {
          'status': status,
          'remarks': remarks?.trim(),
        },
      );
    });
    await refresh();
    return result;
  }

  Future<void> coach(
    String driverId,
    String type,
    String message,
  ) =>
      _run(
        () => api.post('/v1/partner/coaching', {
          'driverId': driverId,
          'type': type,
          'message': message,
        }),
      );

  Future<void> withdraw(double amount) async {
    await _run(
      () => api.post(
        '/v1/partner/withdrawals',
        {'amount': amount},
      ),
    );
    await refresh();
  }

  Future<void> logout() async {
    try {
      await api.post('/v1/staff-auth/logout', const {});
    } catch (_) {}

    api.token = null;
    session = null;
    profile = {};
    dashboard = null;
    drivers = [];
    await store.clear();
    notifyListeners();
  }

  Future<void> _run(
    Future<dynamic> Function() action,
  ) async {
    busy = true;
    error = null;
    notifyListeners();

    try {
      await action();
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}

class DateTimeRangeValue {
  DateTimeRangeValue(this.from, this.to);

  final DateTime from;
  final DateTime to;

  factory DateTimeRangeValue.month() {
    final now = DateTime.now();
    return DateTimeRangeValue(
      DateTime(now.year, now.month, 1),
      now,
    );
  }

  String get fromIso => _iso(from);
  String get toIso => _iso(to);
  String get label => '${_short(from)} – ${_short(to)}';

  static String _iso(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String _short(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
