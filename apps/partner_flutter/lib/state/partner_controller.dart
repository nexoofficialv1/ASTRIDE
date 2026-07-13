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
  Map<String, dynamic>? dashboard;
  List<DriverPerformance> drivers = [];
  Map<String, dynamic>? earnings;
  bool busy = false;
  String? error;
  String languageCode = 'en';
  String driverFilter = 'ALL';
  String driverQuery = '';
  DateTimeRangeValue range = DateTimeRangeValue.month();

  bool get mustChangePassword => session?.mustChangePassword == true;
  PartnerStrings get strings => PartnerStrings(languageCode);

  Future<void> bootstrap() async {
    languageCode = await store.readLanguage();
    session = await store.readSession();
    if (session != null) {
      api.token = session!.token;
      if (!mustChangePassword) {
        try {
          final me = await api.get('/v1/partner/me');
          final partner =
              (me['partner'] as Map).cast<String, dynamic>();
          session = PartnerSession(
            token: session!.token,
            id: (partner['id'] ?? session!.id).toString(),
            mobile: (partner['mobile'] ?? session!.mobile).toString(),
            name: (partner['name'] ?? session!.name).toString(),
            role: (partner['role'] ?? session!.role).toString(),
            mustChangePassword:
                partner['mustChangePassword'] == true,
          );
          await store.writeSession(session!);
          await refresh();
        } catch (_) {
          // Do not delete a valid encrypted session on temporary network failure.
        }
      }
    }
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    languageCode = code;
    await store.writeLanguage(code);
    notifyListeners();
  }

  Future<void> login(String identity, String password) async {
    await _run(() async {
      final x = await api.post('/v1/staff-auth/login', {
        'identity': identity.trim(),
        'password': password,
        'expectedRole': 'PARTNER',
      });
      session = PartnerSession.fromJson(x);
      api.token = session!.token;
      await store.writeSession(session!);
      if (!mustChangePassword) await refresh();
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
      await refresh();
    });
  }

  Future<void> requestPasswordReset(String identity) =>
      _run(() => api.post('/v1/staff-auth/forgot-password/request', {
            'identity': identity.trim(),
            'expectedRole': 'PARTNER',
          }));

  Future<void> refresh({String? from, String? to}) async {
    if (mustChangePassword) return;
    final f = from ?? range.fromIso;
    final t = to ?? range.toIso;
    final suffix = '?from=$f&to=$t';
    final out = await Future.wait([
      api.get('/v1/partner/dashboard$suffix'),
      api.get('/v1/partner/drivers$suffix'),
      api.get('/v1/partner/earnings'),
    ]);
    dashboard = out[0];
    drivers = ((out[1]['items'] ?? []) as List)
        .map((e) => DriverPerformance.fromJson(
              (e as Map).cast<String, dynamic>(),
            ))
        .toList();
    earnings = out[2];
    notifyListeners();
  }

  Future<void> setRange(DateTime from, DateTime to) async {
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

  List<DriverPerformance> get visibleDrivers => drivers.where((d) {
        final queryOk = driverQuery.isEmpty ||
            d.name.toLowerCase().contains(driverQuery) ||
            d.vehicle.toLowerCase().contains(driverQuery) ||
            d.mobile.contains(driverQuery);
        final filterOk = switch (driverFilter) {
          'ONLINE' => d.online,
          'ATTENTION' => d.needsAttention,
          'TOP' => d.topPerformer,
          _ => true,
        };
        return queryOk && filterOk;
      }).toList();

  Future<void> coach(String driverId, String type, String message) =>
      _run(() => api.post('/v1/partner/coaching', {
            'driverId': driverId,
            'type': type,
            'message': message,
          }));

  Future<void> withdraw(double amount) async {
    await _run(
      () => api.post('/v1/partner/withdrawals', {'amount': amount}),
    );
    await refresh();
  }

  Future<void> logout() async {
    try {
      await api.post('/v1/partner/auth/logout', {});
    } catch (_) {}
    api.token = null;
    session = null;
    dashboard = null;
    drivers = [];
    await store.clear();
    notifyListeners();
  }

  Future<void> _run(Future<dynamic> Function() fn) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await fn();
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
  final DateTime from, to;

  factory DateTimeRangeValue.month() {
    final now = DateTime.now();
    return DateTimeRangeValue(DateTime(now.year, now.month, 1), now);
  }

  String get fromIso => _iso(from);
  String get toIso => _iso(to);
  String get label => '${_short(from)} – ${_short(to)}';

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String _short(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}
