import 'package:flutter/material.dart';

import '../design/astride_theme.dart';
import '../state/driver_controller.dart';
import '../widgets/brand/astride_wordmark.dart';
import 'driver_shell.dart';
import 'onboarding/approval_status_screen.dart';
import 'onboarding/document_verification_screen.dart';
import 'onboarding/driver_registration_screen.dart';

class DriverRoot extends StatefulWidget {
  const DriverRoot({super.key, required this.controller});
  final DriverController controller;

  @override
  State<DriverRoot> createState() => _DriverRootState();
}

class _DriverRootState extends State<DriverRoot> {
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    if (c.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (c.locale == null) return _LanguageScreen(controller: c);
    if (c.session == null) return _PasswordLogin(controller: c);
    if (c.mustChangePassword) return _ChangePassword(controller: c);
    if (c.onboardingStep == 'PROFILE') {
      return DriverRegistrationScreen(controller: c);
    }
    if (c.onboardingStep == 'DOCUMENTS') {
      return DocumentVerificationScreen(controller: c);
    }
    if (c.approval != 'APPROVED') {
      return ApprovalStatusScreen(controller: c);
    }
    return DriverShell(controller: c);
  }
}

class _LanguageScreen extends StatelessWidget {
  const _LanguageScreen({required this.controller});
  final DriverController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AstrideWordmark(),
                const SizedBox(height: 36),
                const Icon(
                  Icons.language_rounded,
                  size: 56,
                  color: AstrideColors.green,
                ),
                const SizedBox(height: 18),
                const Text(
                  'Choose your language',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: AstrideColors.navy,
                  ),
                ),
                const SizedBox(height: 22),
                for (final e in const {
                  'en': 'English',
                  'bn': 'বাংলা',
                  'hi': 'हिंदी',
                }.entries)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: () => controller.language(e.key),
                        child: Text(e.value),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

class _PasswordLogin extends StatefulWidget {
  const _PasswordLogin({required this.controller});
  final DriverController controller;

  @override
  State<_PasswordLogin> createState() => _PasswordLoginState();
}

class _PasswordLoginState extends State<_PasswordLogin> {
  final identity = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;

  @override
  void dispose() {
    identity.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 28),
            const AstrideWordmark(),
            const SizedBox(height: 46),
            const Text(
              'Driver Login',
              style: TextStyle(
                fontSize: 29,
                fontWeight: FontWeight.w900,
                color: AstrideColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use the Driver ID or mobile number created by ASTRIDE.',
              style: TextStyle(color: AstrideColors.muted),
            ),
            const SizedBox(height: 28),
            TextField(
              controller: identity,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Driver ID / Mobile number',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: password,
              obscureText: obscure,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscure = !obscure),
                  icon: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _forgotPassword(context),
                child: const Text('Forgot password?'),
              ),
            ),
            FilledButton(
              onPressed: c.busy
                  ? null
                  : () async {
                      try {
                        await c.loginWithPassword(
                          identity.text,
                          password.text,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      }
                    },
              child: c.busy
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Login'),
            ),
            const SizedBox(height: 18),
            const Text(
              'Driver self-registration is disabled. Contact your Promoter or ASTRIDE Admin for an account.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AstrideColors.muted),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _forgotPassword(BuildContext context) async {
    if (identity.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter Driver ID or mobile number.')),
      );
      return;
    }
    try {
      await widget.controller.requestPasswordReset(identity.text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset OTP requested.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }
}

class _ChangePassword extends StatefulWidget {
  const _ChangePassword({required this.controller});
  final DriverController controller;

  @override
  State<_ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<_ChangePassword> {
  final current = TextEditingController();
  final next = TextEditingController();
  final confirm = TextEditingController();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Create new password'),
          automaticallyImplyLeading: false,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(
              Icons.password_rounded,
              size: 68,
              color: AstrideColors.green,
            ),
            const SizedBox(height: 18),
            const Text(
              'Your temporary password must be changed before using the Driver App.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AstrideColors.muted),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: current,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Temporary password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: next,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                helperText: 'Use at least 8 characters.',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirm,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'Confirm new password'),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: widget.controller.busy
                  ? null
                  : () async {
                      if (next.text.length < 8 ||
                          next.text != confirm.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Password must be 8+ characters and match.',
                            ),
                          ),
                        );
                        return;
                      }
                      try {
                        await widget.controller.changePassword(
                          current.text,
                          next.text,
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      }
                    },
              child: const Text('Change password and continue'),
            ),
          ],
        ),
      );
}
