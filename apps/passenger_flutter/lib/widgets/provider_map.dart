import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:google_maps_flutter/google_maps_flutter.dart' as gm;
import 'package:latlong2/latlong.dart' as ll;

class ProviderMap extends StatelessWidget {
  const ProviderMap({
    super.key,
    required this.provider,
    required this.center,
    this.markers = const <gm.Marker>{},
  });

  final String provider;
  final gm.LatLng center;
  final Set<gm.Marker> markers;

  @override
  Widget build(BuildContext context) {
    final normalized = provider.toUpperCase();
    if (normalized == 'GOOGLE') {
      return gm.GoogleMap(
        initialCameraPosition: gm.CameraPosition(target: center, zoom: 16),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        compassEnabled: true,
        zoomControlsEnabled: false,
        markers: markers,
      );
    }

    final osmMarkers = markers
        .map(
          (marker) => fm.Marker(
            point: ll.LatLng(
              marker.position.latitude,
              marker.position.longitude,
            ),
            width: 46,
            height: 46,
            child: Tooltip(
              message: marker.infoWindow.title ?? '',
              child: const Icon(
                Icons.location_pin,
                size: 42,
                color: Color(0xFFE53935),
              ),
            ),
          ),
        )
        .toList(growable: false);

    return Stack(
      children: [
        fm.FlutterMap(
          options: fm.MapOptions(
            initialCenter: ll.LatLng(center.latitude, center.longitude),
            initialZoom: 16,
          ),
          children: [
            fm.TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: normalized == 'MAPPLS'
                  ? 'com.nexo.astride'
                  : 'com.nexo.astride',
              maxZoom: 19,
            ),
            if (osmMarkers.isNotEmpty) fm.MarkerLayer(markers: osmMarkers),
          ],
        ),
        Positioned(
          right: 6,
          bottom: 4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              child: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 9, color: Colors.black87),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
