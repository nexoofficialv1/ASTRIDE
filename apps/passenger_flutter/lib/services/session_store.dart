import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/session.dart';

class SessionStore {
  static const _secure = FlutterSecureStorage();

  Future<void> save(Session s) async {
    await _secure.write(key: 'token', value: s.token);
    await _secure.write(key: 'userId', value: s.userId);
    await _secure.write(key: 'mobile', value: s.mobile);
  }

  Future<Session?> read() async {
    final token = await _secure.read(key: 'token');
    final userId = await _secure.read(key: 'userId');
    final mobile = await _secure.read(key: 'mobile');
    return token == null || userId == null || mobile == null
        ? null
        : Session(userId: userId, token: token, mobile: mobile);
  }

  Future<void> clear() => _secure.deleteAll();

  Future<String?> language() async =>
      (await SharedPreferences.getInstance()).getString('language');

  Future<void> saveLanguage(String value) async =>
      (await SharedPreferences.getInstance()).setString('language', value);

  Future<String?> profileName() async =>
      (await SharedPreferences.getInstance()).getString('profileName');

  Future<void> saveProfileName(String value) async =>
      (await SharedPreferences.getInstance()).setString(
        'profileName',
        value.trim(),
      );

}
