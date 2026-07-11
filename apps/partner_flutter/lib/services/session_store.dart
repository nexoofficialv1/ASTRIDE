import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionStore {
  const SessionStore();
  static const _s = FlutterSecureStorage();
  Future<String?> read() => _s.read(key: 'partner_token');
  Future<void> write(String t) => _s.write(key: 'partner_token', value: t);
  Future<void> clear() => _s.delete(key: 'partner_token');
  Future<String> readLanguage() async => await _s.read(key: 'partner_language') ?? 'en';
  Future<void> writeLanguage(String code) => _s.write(key: 'partner_language', value: code);
}
