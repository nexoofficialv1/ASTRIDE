import 'package:flutter/material.dart';
import '../../design/astride_theme.dart';

class AstrideMapCanvas extends StatelessWidget {
  const AstrideMapCanvas({super.key, this.showRoute = false, this.showDrivers = true});
  final bool showRoute;
  final bool showDrivers;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFEAF0F4),
      child: CustomPaint(
        painter: _RoadPainter(showRoute: showRoute, showDrivers: showDrivers),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  const _RoadPainter({required this.showRoute, required this.showDrivers});
  final bool showRoute;
  final bool showDrivers;

  @override
  void paint(Canvas canvas, Size size) {
    final minor = Paint()..color = const Color(0xFFD7E0E6)..strokeWidth = 3;
    final major = Paint()..color = Colors.white..strokeWidth = 16..strokeCap = StrokeCap.round;
    for (double y = 70; y < size.height; y += 120) {
      canvas.drawLine(Offset(-20, y), Offset(size.width + 20, y + 40), major);
      canvas.drawLine(Offset(-20, y), Offset(size.width + 20, y + 40), minor);
    }
    for (double x = 40; x < size.width; x += 130) {
      canvas.drawLine(Offset(x, -20), Offset(x - 60, size.height + 20), major);
      canvas.drawLine(Offset(x, -20), Offset(x - 60, size.height + 20), minor);
    }
    if (showRoute) {
      final route = Paint()
        ..color = AstrideColors.green
        ..strokeWidth = 7
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final p = Path()
        ..moveTo(size.width * .20, size.height * .72)
        ..cubicTo(size.width * .35, size.height * .50, size.width * .58, size.height * .62, size.width * .75, size.height * .28);
      canvas.drawPath(p, route);
    }
    if (showDrivers) {
      final driver = Paint()..color = AstrideColors.navy;
      for (final point in [const Offset(.25, .34), const Offset(.72, .48), const Offset(.50, .22)]) {
        canvas.drawCircle(Offset(size.width * point.dx, size.height * point.dy), 12, driver);
      }
    }
    canvas.drawCircle(Offset(size.width * .20, size.height * .72), 10, Paint()..color = AstrideColors.green);
    canvas.drawCircle(Offset(size.width * .75, size.height * .28), 10, Paint()..color = AstrideColors.orange);
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) => oldDelegate.showRoute != showRoute || oldDelegate.showDrivers != showDrivers;
}
