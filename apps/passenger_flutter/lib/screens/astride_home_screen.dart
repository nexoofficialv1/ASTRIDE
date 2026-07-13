import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../design/astride_theme.dart';
import '../widgets/brand/astride_wordmark.dart';
import '../widgets/common/astride_map_canvas.dart';

class AstrideHomeScreen extends StatefulWidget {
  const AstrideHomeScreen({
    super.key,
    required this.t,
    required this.onBook,
  });

  final String Function(String) t;
  final VoidCallback onBook;

  @override
  State<AstrideHomeScreen> createState() => _AstrideHomeScreenState();
}

class _AstrideHomeScreenState extends State<AstrideHomeScreen> {
  final MapController _map = MapController();
  LatLng? _location;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    _findMe(silent: true);
  }

  Future<void> _findMe({bool silent = false}) async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please turn on location services.')),
          );
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!silent && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission is required.')),
          );
        }
        return;
      }

      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final next = LatLng(p.latitude, p.longitude);
      if (!mounted) return;
      setState(() => _location = next);
      _map.move(next, 16);
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AstrideMapCanvas(
              controller: _map,
              center: _location ?? const LatLng(23.2196, 88.3628),
              currentLocation: _location,
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.white.withValues(alpha: .95),
                      Colors.white.withValues(alpha: .02),
                    ],
                    stops: const [0, .25],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Row(
                    children: [
                      const AstrideWordmark(compact: true),
                      const Spacer(),
                      _RoundButton(
                        icon: Icons.notifications_none_rounded,
                        onTap: () {},
                      ),
                      const SizedBox(width: 9),
                      _RoundButton(
                        icon: Icons.person_outline_rounded,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      children: [
                        _MapAction(
                          icon: _locating
                              ? Icons.hourglass_top_rounded
                              : Icons.my_location_rounded,
                          label: 'My Location',
                          onTap: () => _findMe(),
                        ),
                        const SizedBox(height: 10),
                        _MapAction(
                          icon: Icons.sos_rounded,
                          label: 'SOS',
                          danger: true,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AstrideColors.border,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: widget.onBook,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 17,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: AstrideColors.border),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.search_rounded,
                                color: AstrideColors.navy,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  t('booking.whereTo'),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    color: AstrideColors.muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: AstrideColors.navyTint,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.radio_button_checked_rounded,
                              color: AstrideColors.green,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _location == null
                                    ? t('booking.currentLocation')
                                    : 'Current location ready',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AstrideColors.text,
                                ),
                              ),
                            ),
                            const Text(
                              'Kalna',
                              style: TextStyle(
                                color: AstrideColors.greenDark,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _QuickPlace(
                              icon: Icons.home_rounded,
                              title: t('booking.home'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickPlace(
                              icon: Icons.work_rounded,
                              title: t('booking.work'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _QuickPlace(
                              icon: Icons.star_rounded,
                              title: t('booking.saved'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: widget.onBook,
                          icon: const Icon(Icons.route_rounded),
                          label: Text(t('booking.bookRide')),
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
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 2,
        shadowColor: const Color(0x220B1D45),
        child: IconButton(
          onPressed: onTap,
          icon: Icon(icon, color: AstrideColors.navy),
        ),
      );
}

class _MapAction extends StatelessWidget {
  const _MapAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        elevation: 4,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: danger ? AstrideColors.orange : AstrideColors.navy,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: danger ? AstrideColors.orange : AstrideColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _QuickPlace extends StatelessWidget {
  const _QuickPlace({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
        decoration: BoxDecoration(
          color: AstrideColors.background,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: AstrideColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AstrideColors.navy),
            const SizedBox(height: 7),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AstrideColors.navy,
              ),
            ),
          ],
        ),
      );
}
