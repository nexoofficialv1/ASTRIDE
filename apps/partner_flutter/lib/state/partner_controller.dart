import 'package:flutter/foundation.dart';

import '../models/partner_session.dart';
import '../services/api_client.dart';
import '../services/session_store.dart';

class PartnerController extends ChangeNotifier {
  PartnerController(this.api, this.store);

  final ApiClient api;
  final SessionStore store;

  bool bootstrapping = true;
  bool busy = false;
  String? error;
  PartnerSession? session;
  Map<String, dynamic> partner = {};
  Map<String, dynamic> dashboard = {};
  List<Map<String, dynamic>> drivers = [];
  Map<String, dynamic> earnings = {};
  List<Map<String, dynamic>> withdrawals = [];

  bool get isAuthenticated => session != null;
  bool get isPromoter => (partner['role'] ?? session?.role) == 'PROMOTER';

  void _bindApiSession() {
    final current = session;
    if (current == null) {
      api.clearSession();
      return;
    }
    api.configureSession(
      accessToken: current.token,
      rotatingRefreshToken: current.refreshToken,
      endpoint: '/v1/partner/auth/refresh',
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
    session = await store.read();
    if (session != null) {
      _bindApiSession();
      try {
        await refreshAll();
      } on ApiException catch (e) {
        if (e.statusCode == 401) await _clearSession();
        error = e.message;
      }
    }
    bootstrapping = false;
    notifyListeners();
  }

  Future<void> login(String mobile, String password) async {
    await _guard(() async {
      final normalized = mobile.replaceAll(RegExp(r'\D'), '');
      if (normalized.length < 10) throw ApiException('সঠিক mobile number দিন।');
      if (password.length < 6) throw ApiException('Password সঠিকভাবে দিন।');
      final data = await api.postJson('/v1/partner/auth/login', {
        'mobile': normalized,
        'password': password,
      });
      final actor = _map(data['partner']);
      final token = (data['accessToken'] ?? data['token'] ?? '').toString();
      final refreshToken = (data['refreshToken'] ?? '').toString();
      if (token.isEmpty || refreshToken.isEmpty || actor.isEmpty) {
        throw ApiException('Login response incomplete.');
      }
      session = PartnerSession(
        partnerId: (actor['id'] ?? '').toString(),
        token: token,
        refreshToken: refreshToken,
        mobile: (actor['mobile'] ?? normalized).toString(),
        role: (actor['role'] ?? 'PROMOTER').toString(),
        name: (actor['name'] ?? 'Partner').toString(),
      );
      _bindApiSession();
      partner = actor;
      await store.save(session!);
      await refreshAll(notify: false);
    });
  }

  Future<void> refreshAll({bool notify = true}) async {
    final me = await api.getJson('/v1/partner/me');
    partner = _map(me['partner']);
    final dashboardData = await api.getJson('/v1/partner/dashboard');
    dashboard = dashboardData;
    final driverData = await api.getJson('/v1/partner/drivers');
    drivers = _list(driverData['items']);
    final earningsData = await api.getJson('/v1/partner/earnings');
    earnings = earningsData;
    final withdrawalData = await api.getJson('/v1/partner/withdrawals');
    withdrawals = _list(withdrawalData['items']);
    if (notify) notifyListeners();
  }

  Future<Map<String, dynamic>> driverDetails(String driverId) async =>
      api.getJson('/v1/partner/drivers/$driverId');

  Future<void> reviewDriver(
    String driverId,
    String status, {
    String? remarks,
  }) async {
    await _guard(() async {
      await api.postJson('/v1/partner/drivers/$driverId/review', {
        'status': status,
        if (remarks != null && remarks.trim().isNotEmpty) 'remarks': remarks.trim(),
      });
      await refreshAll(notify: false);
    });
  }

  Future<void> sendCoaching(
    String driverId,
    String type,
    String message,
  ) async {
    await _guard(() async {
      await api.postJson('/v1/partner/coaching', {
        'driverId': driverId,
        'type': type,
        'message': message.trim(),
      });
    });
  }

  Future<void> createDriver({
    required String mobile,
    required String fullName,
    required String temporaryPassword,
    String? vehicleNumber,
  }) async {
    await _guard(() async {
      await api.postJson('/v1/partner/drivers/create', {
        'mobile': mobile.replaceAll(RegExp(r'\D'), ''),
        'fullName': fullName.trim(),
        'temporaryPassword': temporaryPassword,
        'vehicle': {
          if (vehicleNumber != null && vehicleNumber.trim().isNotEmpty)
            'number': vehicleNumber.trim().toUpperCase(),
        },
      });
      await refreshAll(notify: false);
    });
  }

  Future<void> requestWithdrawal(double amount) async {
    await _guard(() async {
      await api.postJson('/v1/partner/withdrawals', {'amount': amount});
      await refreshAll(notify: false);
    });
  }

  Future<void> updateProfile(Map<String, dynamic> patch) async {
    await _guard(() async {
      final response = await api.patchJson('/v1/partner/me', patch);
      partner = _map(response['partner']);
    });
  }

  Future<void> logout() async {
    try {
      await api.postJson('/v1/partner/auth/logout', {});
    } catch (_) {}
    await _clearSession();
    notifyListeners();
  }

  Future<void> _clearSession() async {
    session = null;
    partner = {};
    dashboard = {};
    drivers = [];
    earnings = {};
    withdrawals = [];
    api.clearSession();
    await store.clear();
  }

  Future<void> _guard(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } on ApiException catch (e) {
      error = e.message;
      if (e.statusCode == 401) await _clearSession();
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  static Map<String, dynamic> _map(dynamic value) =>
      value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

  static List<Map<String, dynamic>> _list(dynamic value) => value is List
      ? value.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
      : <Map<String, dynamic>>[];

  @override
  void dispose() {
    api.close();
    super.dispose();
  }
}
