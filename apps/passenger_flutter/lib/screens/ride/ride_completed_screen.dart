import 'package:flutter/material.dart';

import '../../design/astride_theme.dart';

class RideCompletedScreen extends StatefulWidget {
  const RideCompletedScreen({
    super.key,
    required this.t,
    required this.fare,
    required this.paymentMethod,
    required this.onDone,
  });

  final String Function(String) t;
  final num fare;
  final String paymentMethod;
  final VoidCallback onDone;

  @override
  State<RideCompletedScreen> createState() => _RideCompletedScreenState();
}

class _RideCompletedScreenState extends State<RideCompletedScreen> {
  int rating = 5;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: Color(0x1422C55E),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 62,
                    color: AstrideColors.green,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  widget.t('ride.completed'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AstrideColors.navy,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  '₹${widget.fare.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: AstrideColors.navy,
                  ),
                ),
                Text(
                  'Payment: ${widget.paymentMethod.toUpperCase()}',
                  style: const TextStyle(color: AstrideColors.muted),
                ),
                const SizedBox(height: 34),
                Text(
                  widget.t('ride.rateDriver'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                    (index) => IconButton(
                      onPressed: () => setState(() => rating = index + 1),
                      icon: Icon(
                        index < rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: AstrideColors.orange,
                        size: 34,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: widget.onDone,
                    child: Text(widget.t('common.done')),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
