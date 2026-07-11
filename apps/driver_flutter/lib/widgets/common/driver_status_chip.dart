import 'package:flutter/material.dart';
import '../../design/astride_theme.dart';

class DriverStatusChip extends StatelessWidget {
  const DriverStatusChip({super.key, required this.label, required this.active});
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0x1822C55E) : const Color(0x146B7280),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: active ? AstrideColors.green : AstrideColors.muted, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: active ? AstrideColors.green : AstrideColors.muted)),
        ]),
      );
}
