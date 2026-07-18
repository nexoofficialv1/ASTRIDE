import 'dart:convert';

import 'package:flutter/services.dart';

class AppLocale {
  AppLocale(this.code, this._values);

  final String code;
  final Map<String, String> _values;

  static Future<AppLocale> load(String code) async {
    final safeCode = const {'en', 'bn', 'hi'}.contains(code) ? code : 'en';
    final raw = await rootBundle.loadString('assets/locales/$safeCode.json');
    final decoded = (jsonDecode(raw) as Map<String, dynamic>)
        .map((k, v) => MapEntry(k, v.toString()));
    return AppLocale(safeCode, decoded);
  }

  String t(String key) {
    final value = _values[key];
    if (value != null && value.trim().isNotEmpty) return value;

    final tail = key.split('.').last;
    final readable = tail
        .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (m) => '${m.group(1)} ${m.group(2)}',
        )
        .replaceAll('_', ' ')
        .trim();

    if (readable.isEmpty) return '';
    return readable[0].toUpperCase() + readable.substring(1);
  }
}
