import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/partner_session.dart';

class SessionStore {
  static const _storage = FlutterSecureStorage();
  static const _key = 'astride_partner_session_v1';

  Future<void> save(PartnerSession session) =>
      _storage.write(key: _key, value: jsonEncode(session.toJson()));

  Future<PartnerSession?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final session = PartnerSession.fromJson(decoded.cast<String, dynamic>());
      if (session.token.isEmpty || session.partnerId.isEmpty) return null;
      return session;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() => _storage.delete(key: _key);
}
