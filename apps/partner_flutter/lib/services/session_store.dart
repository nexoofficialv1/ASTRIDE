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
        'staffId': session.staffId,
        'mobile': session.mobile,
        'mustChangePassword': session.mustChangePassword,
      }),
    );
  }

  Future<PartnerSession?> readSession() async {
    final raw = await _secure.read(key: 'partnerSession');
    if (raw == null) return null;

    final json =
        (jsonDecode(raw) as Map).cast<String, dynamic>();

    return PartnerSession(
      token: '${json['token'] ?? ''}',
      name: '${json['name'] ?? 'Partner'}',
      role: '${json['role'] ?? 'PROMOTER'}',
      id: '${json['id'] ?? ''}',
      staffId: '${json['staffId'] ?? ''}',
      mobile: '${json['mobile'] ?? ''}',
      mustChangePassword: json['mustChangePassword'] == true,
    );
  }

  Future<void> clear() => _secure.deleteAll();

  Future<String> readLanguage() async =>
      (await SharedPreferences.getInstance())
          .getString('partnerLanguage') ??
      'en';

  Future<void> writeLanguage(String code) async =>
      (await SharedPreferences.getInstance()).setString(
        'partnerLanguage',
        code,
      );
}
