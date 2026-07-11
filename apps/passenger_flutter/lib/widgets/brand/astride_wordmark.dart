import 'package:flutter/material.dart';
import '../../design/astride_theme.dart';

class AstrideWordmark extends StatelessWidget {
  const AstrideWordmark({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: compact ? 34 : 44,
        height: compact ? 34 : 44,
        decoration: BoxDecoration(
          color: AstrideColors.navy,
          borderRadius: BorderRadius.circular(compact ? 10 : 13),
        ),
        alignment: Alignment.center,
        child: Text('A', style: TextStyle(color: AstrideColors.white, fontSize: compact ? 22 : 29, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic)),
      ),
      const SizedBox(width: 10),
      RichText(text: TextSpan(style: TextStyle(fontSize: compact ? 21 : 27, fontWeight: FontWeight.w800, fontStyle: FontStyle.italic, letterSpacing: 0.4), children: const [
        TextSpan(text: 'AST', style: TextStyle(color: AstrideColors.navy)),
        TextSpan(text: 'RIDE', style: TextStyle(color: AstrideColors.green)),
      ])),
    ]);
  }
}
