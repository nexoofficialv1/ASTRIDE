import 'package:flutter/material.dart';
import '../design/astride_theme.dart';
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
  final pickup = TextEditingController(text: 'Current location');
  final destination = TextEditingController();
  String rideType = 'FULL_TOTO';
  String paymentPreference = 'BOTH';
  bool safeRide = false;
  bool busy = false;
  Map<String, dynamic>? quote;

  @override
  Widget build(BuildContext context) {
    final t = widget.controller.t;
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: AstrideMapCanvas(showRoute: true)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Material(color: Colors.white, shape: const CircleBorder(), child: IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back_rounded))),
                      const Spacer(),
                      Material(color: Colors.white, shape: const StadiumBorder(), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [const Icon(Icons.shield_outlined, color: AstrideColors.green), const SizedBox(width: 6), Text(t('safety.safeRide'))]))),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t('booking.planRide'), style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: AstrideColors.navy)),
                        const SizedBox(height: 14),
                        TextField(controller: pickup, decoration: InputDecoration(prefixIcon: const Icon(Icons.radio_button_checked_rounded, color: AstrideColors.green), labelText: t('pickup'))),
                        const SizedBox(height: 10),
                        TextField(controller: destination, onChanged: (_) => setState(() => quote = null), decoration: InputDecoration(prefixIcon: const Icon(Icons.location_on_rounded, color: AstrideColors.orange), labelText: t('destination'))),
                        const SizedBox(height: 16),
                        Text(t('booking.chooseRide'), style: const TextStyle(fontWeight: FontWeight.w700, color: AstrideColors.navy)),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: _rideChoice('FULL_TOTO', Icons.electric_rickshaw_rounded, t('ride.fullToto'))),
                          const SizedBox(width: 8),
                          Expanded(child: _rideChoice('SHARE_TOTO', Icons.groups_rounded, t('ride.shareToto'))),
                          const SizedBox(width: 8),
                          Expanded(child: _rideChoice('MOTORCYCLE', Icons.two_wheeler_rounded, t('ride.motorcycle'))),
                        ]),
                        const SizedBox(height: 16),
                        Text(t('payment.preference'), style: const TextStyle(fontWeight: FontWeight.w700, color: AstrideColors.navy)),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: [
                            ButtonSegment(value: 'CASH', label: Text(t('payment.cash')), icon: const Icon(Icons.payments_outlined)),
                            ButtonSegment(value: 'UPI', label: Text(t('payment.upi')), icon: const Icon(Icons.qr_code_rounded)),
                            ButtonSegment(value: 'BOTH', label: Text(t('payment.both')), icon: const Icon(Icons.swap_horiz_rounded)),
                          ],
                          selected: {paymentPreference},
                          onSelectionChanged: (value) => setState(() => paymentPreference = value.first),
                          showSelectedIcon: false,
                        ),
                        const SizedBox(height: 10),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          value: safeRide,
                          onChanged: (value) => setState(() => safeRide = value),
                          secondary: const Icon(Icons.shield_rounded, color: AstrideColors.green),
                          title: Text(t('safety.safeRide'), style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(t('safety.safeRideBody')),
                        ),
                        if (quote != null) ...[
                          const Divider(height: 24),
                          Row(children: [Text(t('estimatedFare'), style: const TextStyle(fontWeight: FontWeight.w700)), const Spacer(), Text('₹${quote!['amount'] ?? quote!['fare'] ?? 50}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AstrideColors.navy))]),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: busy || destination.text.trim().isEmpty ? null : _submit,
                            child: Text(quote == null ? t('checkFare') : t('bookNow')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rideChoice(String value, IconData icon, String label) {
    final selected = rideType == value;
    return InkWell(
      onTap: () => setState(() { rideType = value; quote = null; }),
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
        decoration: BoxDecoration(color: selected ? const Color(0x1422C55E) : AstrideColors.background, borderRadius: BorderRadius.circular(16), border: Border.all(color: selected ? AstrideColors.green : AstrideColors.border, width: selected ? 1.6 : 1)),
        child: Column(children: [Icon(icon, color: selected ? AstrideColors.green : AstrideColors.navy, size: 28), const SizedBox(height: 6), Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? AstrideColors.green : AstrideColors.text))]),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => busy = true);
    try {
      final p = {'lat': 23.22, 'lng': 88.36, 'address': pickup.text};
      final d = {'lat': 23.24, 'lng': 88.39, 'address': destination.text};
      if (quote == null) {
        quote = await widget.controller.estimate(p, d);
        if (mounted) setState(() {});
      } else {
        await widget.controller.book(p, d, paymentPreference);
        if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RideStatusScreen(controller: widget.controller)));
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}
