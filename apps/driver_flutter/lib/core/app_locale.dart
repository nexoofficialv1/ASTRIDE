import 'dart:convert';
import 'package:flutter/services.dart';

class AppLocale {
  AppLocale(this.code, this._values);
  final String code;
  final Map<String, String> _values;

  static Future<AppLocale> load(String code) async {
    final safe = const {'en', 'bn', 'hi'}.contains(code) ? code : 'en';
    final raw = await rootBundle.loadString('assets/locales/$safe.json');
    final decoded = (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v.toString()));
    return AppLocale(safe, decoded);
  }

  String t(String key) {
    final value = _values[key];
    if (value != null && value.trim().isNotEmpty) return value;
    final tail = key.split('.').last;
    return tail
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'),
            (m) => '${m.group(1)} ${m.group(2)}')
        .replaceAll('_', ' ')
        .trim();
  }
}
