import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../design/astride_theme.dart';
import '../services/api_client.dart';
import '../state/passenger_controller.dart';
import '../widgets/common/astride_map_canvas.dart';
import 'ride_status_screen.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.controller});
  final PassengerController controller;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final MapController map = MapController();
  final pickupText = TextEditingController(text: 'Current location');
  final destinationText = TextEditingController();

  LatLng? pickup;
  LatLng? destination;
  List<LatLng> route = [];
  List<Map<String, dynamic>> suggestions = [];
  Timer? debounce;
  String rideType = 'FULL_TOTO';
  String paymentPreference = 'BOTH';
  bool safeRide = false;
  bool busy = false;
  Map<String, dynamic>? quote;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    debounce?.cancel();
    pickupText.dispose();
    destinationText.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) return;

      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      pickup = LatLng(p.latitude, p.longitude);
      if (mounted) setState(() {});
      map.move(pickup!, 16);
    } catch (_) {}
  }

  void _search(String query) {
    debounce?.cancel();
    if (query.trim().length < 3) {
      setState(() => suggestions = []);
      return;
    }
    debounce = Timer(const Duration(milliseconds: 420), () async {
      try {
        final data = await widget.controller.api.getJson(
          '/v1/maps/geocode?q=${Uri.encodeQueryComponent(query.trim())}',
        );
        final result = data['result'] is Map
            ? (data['result'] as Map).cast<String, dynamic>()
            : data;
        final raw = result['results'];
        if (!mounted) return;
        setState(() {
          suggestions = raw is List
              ? raw.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
              : [];
          error = null;
        });
      } catch (e) {
        if (mounted) setState(() => error = e.toString());
      }
    });
  }

  LatLng? _pointFrom(Map<String, dynamic> item) {
    final lat = double.tryParse('${item['lat'] ?? item['latitude']}');
    final lng = double.tryParse('${item['lng'] ?? item['lon'] ?? item['longitude']}');
    return lat == null || lng == null ? null : LatLng(lat, lng);
  }

  Future<void> _selectSuggestion(Map<String, dynamic> item) async {
    final point = _pointFrom(item);
    if (point == null) return;
    destination = point;
    destinationText.text =
        '${item['name'] ?? item['displayName'] ?? item['address'] ?? 'Destination'}';
    suggestions = [];
    map.move(point, 15);
    setState(() {});
    await _loadRouteAndQuote();
  }

  Future<void> _loadRouteAndQuote() async {
    if (pickup == null || destination == null) return;
    setState(() {
      busy = true;
      error = null;
    });

    try {
      final routeResponse = await widget.controller.api.postJson(
        '/v1/maps/route',
        {
          'origin': {'lat': pickup!.latitude, 'lng': pickup!.longitude},
          'destination': {
            'lat': destination!.latitude,
            'lng': destination!.longitude,
          },
        },
      );
      route = _parseRoute(routeResponse);
      final km = _extractDistanceKm(routeResponse);

      quote = await widget.controller.api.postJson(
        '/v1/fares/quote-v3',
        {
          'rideType': rideType,
          'distanceKm': km,
          'paymentPreference': paymentPreference,
          'isNight': false,
          'saferideEnabled': safeRide,
        },
      );

      if (route.length >= 2) {
        final bounds = LatLngBounds.fromPoints(route);
        map.fitCamera(
          CameraFit.bounds(
            bounds: bounds,
            padding: const EdgeInsets.fromLTRB(42, 110, 42, 430),
          ),
        );
      }
    } catch (e) {
      error = e.toString();
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  double _extractDistanceKm(Map<String, dynamic> data) {
    final result = data['result'] is Map
        ? (data['result'] as Map).cast<String, dynamic>()
        : data;
    final meters = double.tryParse(
      '${result['distanceM'] ?? result['distance'] ?? result['distanceMeters'] ?? 0}',
    ) ?? 0;
    if (meters > 100) return meters / 1000;
    if (meters > 0) return meters;
    return const Distance().as(LengthUnit.Kilometer, pickup!, destination!);
  }

  List<LatLng> _parseRoute(Map<String, dynamic> data) {
    final result = data['result'] is Map
        ? (data['result'] as Map).cast<String, dynamic>()
        : data;
    final candidates = [
      result['coordinates'],
      result['geometry'],
      result['route'],
      result['polyline'],
    ];

    for (final raw in candidates) {
      if (raw is List) {
        final points = <LatLng>[];
        for (final item in raw) {
          if (item is List && item.length >= 2) {
            final a = double.tryParse('${item[0]}');
            final b = double.tryParse('${item[1]}');
            if (a != null && b != null) {
              points.add(a.abs() <= 90 ? LatLng(a, b) : LatLng(b, a));
            }
          } else if (item is Map) {
            final p = _pointFrom(item.cast<String, dynamic>());
            if (p != null) points.add(p);
          }
        }
        if (points.length >= 2) return points;
      }
    }
    return [pickup!, destination!];
  }

  String _fareText() {
    final q = quote?['quote'] is Map ? quote!['quote'] as Map : quote;
    final value = q?['total'] ?? q?['amount'] ?? q?['fare'];
    return value == null ? '—' : '₹$value';
  }

  Future<void> _confirm() async {
    if (pickup == null || destination == null) {
      setState(() => error = 'Please choose pickup and destination.');
      return;
    }
    setState(() => busy = true);
    try {
      await widget.controller.book(
        {'lat': pickup!.latitude, 'lng': pickup!.longitude},
        {'lat': destination!.latitude, 'lng': destination!.longitude},
        paymentPreference,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RideStatusScreen(controller: widget.controller),
        ),
      );
    } on ApiException catch (e) {
      setState(() => error = e.message);
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.controller.t;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AstrideMapCanvas(
              controller: map,
              center: pickup ?? const LatLng(23.2196, 88.3628),
              currentLocation: pickup,
              pickup: pickup,
              destination: destination,
              routePoints: route,
              onTap: (point) {
                destination = point;
                destinationText.text = 'Pinned destination';
                suggestions = [];
                setState(() {});
                _loadRouteAndQuote();
              },
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      _circle(
                        Icons.arrow_back_rounded,
                        () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Material(
                        color: Colors.white,
                        elevation: 2,
                        borderRadius: BorderRadius.circular(22),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shield_outlined,
                                color: AstrideColors.green,
                              ),
                              const SizedBox(width: 6),
                              Text(t('safety.safeRide')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .62,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x240B1D45),
                        blurRadius: 28,
                        offset: Offset(0, -8),
                      ),
                    ],
                  ),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AstrideColors.border,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        t('booking.planRide'),
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                          color: AstrideColors.navy,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: pickupText,
                        readOnly: true,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.radio_button_checked_rounded,
                            color: AstrideColors.green,
                          ),
                          labelText: t('pickup'),
                          suffixIcon: IconButton(
                            onPressed: _loadCurrentLocation,
                            icon: const Icon(Icons.my_location_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: destinationText,
                        onChanged: _search,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.location_on_rounded,
                            color: AstrideColors.orange,
                          ),
                          labelText: t('destination'),
                          hintText: 'Search Kalna, station, hospital…',
                        ),
                      ),
                      if (suggestions.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: AstrideColors.border),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x160B1D45),
                                blurRadius: 14,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              for (final item in suggestions.take(5))
                                ListTile(
                                  leading: const Icon(
                                    Icons.place_outlined,
                                    color: AstrideColors.greenDark,
                                  ),
                                  title: Text(
                                    '${item['name'] ?? item['displayName'] ?? item['address'] ?? 'Place'}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => _selectSuggestion(item),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'Choose your ride',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AstrideColors.navy,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _ride(
                              'FULL_TOTO',
                              Icons.electric_rickshaw_rounded,
                              'Full Toto',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ride(
                              'SHARE_TOTO',
                              Icons.groups_rounded,
                              'Share Toto',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _ride(
                              'MOTORCYCLE',
                              Icons.two_wheeler_rounded,
                              'Bike',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'CASH', label: Text('Cash')),
                          ButtonSegment(value: 'UPI', label: Text('UPI')),
                          ButtonSegment(value: 'BOTH', label: Text('Both')),
                        ],
                        selected: {paymentPreference},
                        onSelectionChanged: (v) {
                          setState(() => paymentPreference = v.first);
                          if (destination != null) _loadRouteAndQuote();
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: safeRide,
                        onChanged: (v) {
                          setState(() => safeRide = v);
                          if (destination != null) _loadRouteAndQuote();
                        },
                        title: const Text(
                          'SafeRide',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: const Text(
                          'Trusted-driver priority and safety prompts',
                        ),
                        secondary: const Icon(
                          Icons.verified_user_outlined,
                          color: AstrideColors.greenDark,
                        ),
                      ),
                      if (quote != null)
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: AstrideColors.successTint,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.payments_outlined,
                                color: AstrideColors.greenDark,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Estimated fare',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text(
                                _fareText(),
                                style: const TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                  color: AstrideColors.navy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          error!,
                          style: const TextStyle(color: AstrideColors.danger),
                        ),
                      ],
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: busy ? null : _confirm,
                        icon: busy
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(
                          quote == null
                              ? 'Select destination'
                              : 'Confirm ride • ${_fareText()}',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(IconData icon, VoidCallback onTap) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        child: IconButton(onPressed: onTap, icon: Icon(icon)),
      );

  Widget _ride(String value, IconData icon, String label) {
    final selected = rideType == value;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        setState(() => rideType = value);
        if (destination != null) _loadRouteAndQuote();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? AstrideColors.successTint : Colors.white,
          border: Border.all(
            color: selected ? AstrideColors.green : AstrideColors.border,
            width: selected ? 1.8 : 1,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? AstrideColors.greenDark : AstrideColors.navy,
            ),
            const SizedBox(height: 7),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
