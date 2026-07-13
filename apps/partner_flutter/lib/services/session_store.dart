import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/partner_models.dart';

class SessionStore {
  static const _secure = FlutterSecureStorage();

  Future<void> writeSession(PartnerSession session) async {
    await _secure.write(
      key: 'partnerSession',
      value: jsonEncode({
        'token': session.token,
        'name': session.name,
        'role': session.role,
        'id': session.id,
        'mobile': session.mobile,
        'mustChangePassword': session.mustChangePassword,
      }),
    );
  }

  Future<PartnerSession?> readSession() async {
    final raw = await _secure.read(key: 'partnerSession');
    if (raw == null) return null;
    final j = (jsonDecode(raw) as Map).cast<String, dynamic>();
    return PartnerSession(
      token: j['token'].toString(),
      name: (j['name'] ?? 'Partner').toString(),
      role: (j['role'] ?? 'PROMOTER').toString(),
      id: (j['id'] ?? '').toString(),
      mobile: (j['mobile'] ?? '').toString(),
      mustChangePassword: j['mustChangePassword'] == true,
    );
  }

  Future<void> clear() => _secure.deleteAll();

  Future<String> readLanguage() async =>
      (await SharedPreferences.getInstance()).getString('partnerLanguage') ??
      'en';

  Future<void> writeLanguage(String code) async =>
      (await SharedPreferences.getInstance())
          .setString('partnerLanguage', code);
}
