import 'package:flutter/material.dart';
import '../design/astride_theme.dart';
import '../state/driver_controller.dart';
import '../widgets/brand/astride_wordmark.dart';
import 'driver_shell.dart';
import 'onboarding/driver_registration_screen.dart';
import 'onboarding/document_verification_screen.dart';
import 'onboarding/approval_status_screen.dart';

class DriverRoot extends StatefulWidget {
  const DriverRoot({super.key, required this.controller});
  final DriverController controller;
  @override State<DriverRoot> createState() => _DriverRootState();
}

class _DriverRootState extends State<DriverRoot> {
  final mobile = TextEditingController();
  final otp = TextEditingController();
  bool sent = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (c.loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (c.locale == null) return _LanguageScreen(controller: c);
    if (c.session == null) return _LoginScreen(controller: c, mobile: mobile, otp: otp, sent: sent, onSent: () => setState(() => sent = true));
    if (c.onboardingStep == 'PROFILE') return DriverRegistrationScreen(controller: c);
    if (c.onboardingStep == 'DOCUMENTS') return DocumentVerificationScreen(controller: c);
    if (c.approval != 'APPROVED') return ApprovalStatusScreen(controller: c);
    return DriverShell(controller: c);
  }
}

class _LanguageScreen extends StatelessWidget {
  const _LanguageScreen({required this.controller});
  final DriverController controller;
  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const AstrideWordmark(),
      const SizedBox(height: 36),
      const Icon(Icons.language_rounded, size: 56, color: AstrideColors.green),
      const SizedBox(height: 18),
      const Text('Choose your language', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: AstrideColors.navy)),
      const SizedBox(height: 22),
      for (final e in const {'en':'English','bn':'বাংলা','hi':'हिंदी'}.entries)
        Padding(padding: const EdgeInsets.only(bottom: 12), child: SizedBox(width: double.infinity, child: FilledButton.tonal(onPressed: () => controller.language(e.key), child: Text(e.value)))),
    ]))),
  );
}

class _LoginScreen extends StatelessWidget {
  const _LoginScreen({required this.controller, required this.mobile, required this.otp, required this.sent, required this.onSent});
  final DriverController controller;
  final TextEditingController mobile, otp;
  final bool sent;
  final VoidCallback onSent;
  @override Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
      const SizedBox(height: 28), const AstrideWordmark(), const SizedBox(height: 48),
      Text(controller.t('driverLogin'), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AstrideColors.navy)),
      const SizedBox(height: 8), Text(controller.t('driverLoginSubtitle'), style: const TextStyle(color: AstrideColors.muted)),
      const SizedBox(height: 28),
      TextField(controller: mobile, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: controller.t('mobileNumber'), prefixIcon: const Icon(Icons.phone_android_rounded))),
      if (sent) ...[const SizedBox(height: 14), TextField(controller: otp, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: controller.t('otp'), prefixIcon: const Icon(Icons.lock_outline_rounded)))],
      const SizedBox(height: 20), FilledButton(
        onPressed: controller.busy ? null : () async { if (!sent) { await controller.requestOtp(mobile.text); onSent(); } else { await controller.login(mobile.text, otp.text); } },
        child: controller.busy ? const CircularProgressIndicator() : Text(sent ? controller.t('verifyOtp') : controller.t('sendOtp')),
      ),
      const SizedBox(height: 18), Text(controller.t('termsConsent'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AstrideColors.muted)),
    ])),
  );
}
