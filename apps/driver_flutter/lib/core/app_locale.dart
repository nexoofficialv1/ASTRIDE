import 'dart:convert';
import 'package:flutter/services.dart';
class AppLocale {
  AppLocale(this.code, this._values);
  final String code; final Map<String,String> _values;
  static Future<AppLocale> load(String code) async {
    final raw=await rootBundle.loadString('assets/locales/$code.json');
    final decoded=(jsonDecode(raw) as Map<String,dynamic>).map((k,v)=>MapEntry(k,v.toString()));
    return AppLocale(code,decoded);
  }
  String t(String key)=>_values[key]??'[$key]';
}
