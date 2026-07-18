import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/astride_theme.dart';
import '../state/passenger_controller.dart';
import '../widgets/brand/astride_wordmark.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});

  final PassengerController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final mobile = TextEditingController();
  final otp = TextEditingController();
  bool sent = false;
  bool busy = false;
  String? error;
  String? notice;

  @override
  void dispose() {
    mobile.dispose();
    otp.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    setState(() { error = null; notice = null; });
    if (mobile.text.length != 10) {
      setState(() => error = widget.controller.t('auth.invalidMobile'));
      return;
    }
    try {
      if (!sent) {
        setState(() => busy = true);
        await widget.controller.requestOtp(mobile.text);
        if (mounted) {
          setState(() {
            sent = true;
            notice = widget.controller.t('auth.otpRequested');
          });
        }
        return;
      }
      if (otp.text.length < 4) {
        setState(() => error = widget.controller.t('auth.invalidOtp'));
        return;
      }
      setState(() => busy = true);
      await widget.controller.login(mobile.text, otp.text);
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceFirst('Exception: ', '');
        setState(() => error = message.isEmpty
            ? widget.controller.t('error.generic')
            : message);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 34),
            const Center(child: AstrideWordmark()),
            const SizedBox(height: 48),
            Text(
              widget.controller.t('auth.welcome'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AstrideColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.controller.t('auth.subtitle'),
              style: const TextStyle(color: AstrideColors.muted, height: 1.5),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: mobile,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: InputDecoration(
                labelText: widget.controller.t('auth.mobile'),
                prefixText: '+91 ',
                prefixIcon: const Icon(Icons.phone_android_rounded),
              ),
            ),
            if (sent) ...[
              const SizedBox(height: 16),
              TextField(
                controller: otp,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: InputDecoration(
                  labelText: widget.controller.t('auth.otp'),
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: busy
                        ? null
                        : () async {
                            setState(() {
                              busy = true;
                              error = null;
                              notice = null;
                            });
                            try {
                              await widget.controller.requestOtp(mobile.text);
                              if (mounted) {
                                setState(() => notice =
                                    widget.controller.t('auth.otpResent'));
                              }
                            } catch (e) {
                              if (mounted) setState(() => error = e.toString());
                            } finally {
                              if (mounted) setState(() => busy = false);
                            }
                          },
                    child: Text(widget.controller.t('auth.resendOtp')),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      sent = false;
                      otp.clear();
                      notice = null;
                    }),
                    child: Text(widget.controller.t('auth.changeNumber')),
                  ),
                ],
              ),
            ],
            if (notice != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  notice!,
                  style: const TextStyle(
                    color: AstrideColors.greenDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: busy ? null : submit,
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Text(
                  sent
                      ? widget.controller.t('auth.verifyOtp')
                      : widget.controller.t('auth.sendOtp'),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              widget.controller.t('auth.terms'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AstrideColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
