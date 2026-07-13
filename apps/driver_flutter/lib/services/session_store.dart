import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session.dart';

class SessionStore {
  static const _secure = FlutterSecureStorage();

  Future<void> save(Session s) async {
    await _secure.write(key: 'token', value: s.token);
    await _secure.write(key: 'userId', value: s.userId);
    await _secure.write(key: 'staffId', value: s.staffId);
    await _secure.write(key: 'mobile', value: s.mobile);
    await _secure.write(key: 'role', value: s.role);
    await _secure.write(
      key: 'mustChangePassword',
      value: s.mustChangePassword ? '1' : '0',
    );
  }

  Future<Session?> read() async {
    final token = await _secure.read(key: 'token');
    final userId = await _secure.read(key: 'userId');
    final mobile = await _secure.read(key: 'mobile');

    if (token == null || userId == null || mobile == null) {
      return null;
    }

    return Session(
      token: token,
      userId: userId,
      staffId: await _secure.read(key: 'staffId') ?? '',
      mobile: mobile,
      role: await _secure.read(key: 'role') ?? 'DRIVER',
      mustChangePassword:
          await _secure.read(key: 'mustChangePassword') == '1',
    );
  }

  Future<void> clear() => _secure.deleteAll();

  Future<String?> language() async =>
      (await SharedPreferences.getInstance()).getString('language');

  Future<void> saveLanguage(String value) async =>
      (await SharedPreferences.getInstance()).setString(
        'language',
        value,
      );
}
