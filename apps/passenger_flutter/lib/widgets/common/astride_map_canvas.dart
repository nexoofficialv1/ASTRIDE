import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../design/astride_theme.dart';

class AstrideMapCanvas extends StatelessWidget {
  const AstrideMapCanvas({
    super.key,
    this.controller,
    this.center = const LatLng(23.2196, 88.3628),
    this.zoom = 14.2,
    this.currentLocation,
    this.pickup,
    this.destination,
    this.routePoints = const [],
    this.onTap,
    this.interactive = true,
    this.showRoute = true,
    this.showDrivers = false,
  });

  final MapController? controller;
  final LatLng center;
  final double zoom;
  final LatLng? currentLocation;
  final LatLng? pickup;
  final LatLng? destination;
  final List<LatLng> routePoints;
  final void Function(LatLng point)? onTap;
  final bool interactive;
  /// Backwards-compatible flags used by existing ride-status screens.
  final bool showRoute;
  final bool showDrivers;

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>[
      if (currentLocation != null)
        Marker(
          point: currentLocation!,
          width: 54,
          height: 54,
          child: const _MapPin(
            icon: Icons.navigation_rounded,
            color: AstrideColors.navy,
            pulse: true,
          ),
        ),
      if (pickup != null)
        Marker(
          point: pickup!,
          width: 48,
          height: 48,
          child: const _MapPin(
            icon: Icons.radio_button_checked_rounded,
            color: AstrideColors.green,
          ),
        ),
      if (destination != null)
        Marker(
          point: destination!,
          width: 48,
          height: 48,
          child: const _MapPin(
            icon: Icons.location_on_rounded,
            color: AstrideColors.orange,
          ),
        ),
    ];

    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: center,
        initialZoom: zoom,
        minZoom: 4,
        maxZoom: 19,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
        onTap: onTap == null ? null : (_, point) => onTap!(point),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'in.astride.passenger',
          maxNativeZoom: 19,
        ),
        if (showRoute && routePoints.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: routePoints,
                color: AstrideColors.green,
                strokeWidth: 6,
                borderColor: Colors.white,
                borderStrokeWidth: 2,
              ),
            ],
          ),
        MarkerLayer(markers: markers),
        const RichAttributionWidget(
          attributions: [
            TextSourceAttribution('OpenStreetMap contributors'),
          ],
        ),
      ],
    );
  }
}

class _MapPin extends StatelessWidget {
  const _MapPin({
    required this.icon,
    required this.color,
    this.pulse = false,
  });

  final IconData icon;
  final Color color;
  final bool pulse;

  @override
  Widget build(BuildContext context) => Stack(
        alignment: Alignment.center,
        children: [
          if (pulse)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(.18),
                shape: BoxShape.circle,
              ),
            ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x330B1D45),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Icon(icon, size: 19, color: Colors.white),
          ),
        ],
      );
}
