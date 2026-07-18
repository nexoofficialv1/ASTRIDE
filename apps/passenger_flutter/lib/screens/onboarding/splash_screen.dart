import 'package:flutter/material.dart';
import '../../design/astride_theme.dart';
import '../../widgets/brand/astride_wordmark.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(
        backgroundColor: AstrideColors.navy,
        body: SafeArea(
          child: Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              AstrideWordmark(),
              SizedBox(height: 18),
              Text('RIDE SMARTER. REACH FASTER.', style: TextStyle(color: Colors.white70, letterSpacing: 1.4)),
              SizedBox(height: 48),
              CircularProgressIndicator(color: AstrideColors.green),
            ]),
          ),
        ),
      );
}
