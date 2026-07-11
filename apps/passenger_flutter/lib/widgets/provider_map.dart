import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ProviderMap extends StatelessWidget {
  const ProviderMap({super.key, required this.provider, required this.center, this.markers = const {}});
  final String provider;
  final LatLng center;
  final Set<Marker> markers;

  @override
  Widget build(BuildContext context) {
    final normalized = provider.toUpperCase();
    if (normalized == 'GOOGLE') {
      return GoogleMap(
        initialCameraPosition: CameraPosition(target: center, zoom: 16),
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        compassEnabled: true,
        zoomControlsEnabled: false,
        markers: markers,
      );
    }
    return ColoredBox(
      color: const Color(0xffe7efed),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.map_outlined, size: 72),
          const SizedBox(height: 12),
          Text('$provider native adapter', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text('Map credentials and provider adapter are supplied by the backend configuration.'),
        ]),
      ),
    );
  }
}
