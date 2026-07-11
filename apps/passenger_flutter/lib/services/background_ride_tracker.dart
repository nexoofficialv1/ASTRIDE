import 'dart:async';
import '../services/api_client.dart';
import '../services/location_queue.dart';
import '../services/native_location_service.dart';

class BackgroundRideTracker {
  BackgroundRideTracker(this.api, this.location, this.queue);
  final ApiClient api;
  final NativeLocationService location;
  final LocationQueue queue;
  StreamSubscription? _subscription;

  Future<void> start({required String actorId, required String role, String? bookingId, int intervalSeconds = 10}) async {
    await stop();
    final permission = await location.ensurePermission(background: role == 'DRIVER');
    if (!permission.granted) throw StateError('Location permission is required');
    _subscription = location.stream(intervalSeconds: intervalSeconds, distanceFilter: 10).listen((position) async {
      final point = {
        'actorId': actorId,
        'role': role,
        if (bookingId != null) 'bookingId': bookingId,
        'lat': position.latitude,
        'lng': position.longitude,
        'accuracy': position.accuracy,
        'speed': position.speed,
        'heading': position.heading,
        'recordedAt': DateTime.now().toUtc().toIso8601String(),
      };
      try {
        await api.postJson('/v1/tracking/points', {'points': [point]});
      } catch (_) {
        await queue.add(point);
      }
    });
  }

  Future<void> flush() async {
    final pending = await queue.read();
    if (pending.isEmpty) return;
    await api.postJson('/v1/tracking/points', {'points': pending});
    await queue.clear();
  }

  Future<void> stop() async { await _subscription?.cancel(); _subscription = null; }
}
