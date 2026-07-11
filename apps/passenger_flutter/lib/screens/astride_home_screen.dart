import 'package:flutter/material.dart';
import '../design/astride_theme.dart';
import '../widgets/brand/astride_wordmark.dart';
import '../widgets/common/astride_map_canvas.dart';

class AstrideHomeScreen extends StatelessWidget {
  const AstrideHomeScreen({super.key, required this.t, required this.onBook});
  final String Function(String) t;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AstrideMapCanvas()),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const AstrideWordmark(compact: true),
                      const Spacer(),
                      _roundButton(Icons.notifications_none_rounded),
                      const SizedBox(width: 8),
                      _roundButton(Icons.person_outline_rounded),
                    ],
                  ),
                  const Spacer(),
                  Align(alignment: Alignment.centerRight, child: _roundButton(Icons.my_location_rounded)),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t('booking.whereTo'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AstrideColors.navy)),
                          const SizedBox(height: 14),
                          _locationField(Icons.radio_button_checked_rounded, AstrideColors.green, t('booking.currentLocation')),
                          const SizedBox(height: 10),
                          InkWell(onTap: onBook, borderRadius: BorderRadius.circular(16), child: _locationField(Icons.location_on_rounded, AstrideColors.orange, t('booking.enterDestination'))),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(child: _quick(Icons.home_rounded, t('booking.home'))),
                              const SizedBox(width: 10),
                              Expanded(child: _quick(Icons.work_rounded, t('booking.work'))),
                              const SizedBox(width: 10),
                              Expanded(child: _quick(Icons.add_location_alt_outlined, t('booking.saved'))),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: onBook, icon: const Icon(Icons.route_rounded), label: Text(t('booking.bookRide')))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _roundButton(IconData icon) => Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 1,
        child: IconButton(onPressed: () {}, icon: Icon(icon, color: AstrideColors.navy)),
      );

  Widget _locationField(IconData icon, Color color, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        decoration: BoxDecoration(color: AstrideColors.background, borderRadius: BorderRadius.circular(16), border: Border.all(color: AstrideColors.border)),
        child: Row(children: [Icon(icon, color: color), const SizedBox(width: 12), Expanded(child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, color: AstrideColors.text)))]),
      );

  Widget _quick(IconData icon, String label) => Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(color: AstrideColors.background, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [Icon(icon, color: AstrideColors.navy), const SizedBox(height: 4), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))]),
      );
}
