import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocationQueue {
  static const _key = 'astride_pending_location_points_v2';
  static const _storage = FlutterSecureStorage();

  Future<void> add(Map<String, dynamic> point) async {
    final items = await read();
    items.add(Map<String, dynamic>.from(point));
    if (items.length > 500) {
      items.removeRange(0, items.length - 500);
    }
    await _storage.write(key: _key, value: jsonEncode(items));
  }

  Future<List<Map<String, dynamic>>> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.trim().isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];
      return decoded
          .whereType<Map>()
          .map((item) => item.cast<String, dynamic>())
          .toList();
    } catch (_) {
      await clear();
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> clear() => _storage.delete(key: _key);
}
