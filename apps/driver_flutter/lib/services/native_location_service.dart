import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart';

class LocationPermissionResult {
  const LocationPermissionResult({required this.granted, required this.permanentlyDenied});
  final bool granted;
  final bool permanentlyDenied;
}

class NativeLocationService {
  static const _service = MethodChannel('in.astride.driver/location_service');

  Future<void> startForegroundTracking() async {
    await _service.invokeMethod<bool>('start');
  }

  Future<void> stopForegroundTracking() async {
    await _service.invokeMethod<bool>('stop');
  }
  Future<LocationPermissionResult> ensurePermission({bool background = false}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const LocationPermissionResult(granted: false, permanentlyDenied: false);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
    return LocationPermissionResult(
      granted: permission == LocationPermission.whileInUse || permission == LocationPermission.always,
      permanentlyDenied: permission == LocationPermission.deniedForever,
    );
  }

  Future<Position> current() => Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
  );

  Stream<Position> stream({required int intervalSeconds, required int distanceFilter}) =>
      Geolocator.getPositionStream(locationSettings: LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: distanceFilter,
        timeLimit: Duration(seconds: intervalSeconds * 3),
      ));
}
