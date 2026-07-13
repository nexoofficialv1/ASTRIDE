import 'package:flutter/material.dart';

import '../design/astride_theme.dart';
import '../state/partner_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});
  final PartnerController controller;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: DropdownButton<String>(
                      value: c.languageCode,
                      underline: const SizedBox.shrink(),
                      items: const [
                        DropdownMenuItem(
                          value: 'en',
                          child: Text('English'),
                        ),
                        DropdownMenuItem(
                          value: 'bn',
                          child: Text('বাংলা'),
                        ),
                        DropdownMenuItem(
                          value: 'hi',
                          child: Text('हिंदी'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) c.setLanguage(v);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      color: PartnerColors.navy,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const Icon(
                      Icons.handshake_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'ASTRIDE Partner',
                    style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w900,
                      color: PartnerColors.navy,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Promoter & Area Promoter secure login',
                    style: TextStyle(color: PartnerColors.muted),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: identity,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Partner ID / Mobile number',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: password,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon:
                          const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => obscure = !obscure),
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () async {
                        if (identity.text.trim().isEmpty) return;
                        try {
                          await c.requestPasswordReset(identity.text);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Password reset OTP requested.'),
                              ),
                            );
                          }
                        } catch (_) {}
                      },
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  FilledButton(
                    onPressed: c.busy
                        ? null
                        : () async {
                            try {
                              await c.login(
                                identity.text,
                                password.text,
                              );
                            } catch (_) {}
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Text(c.busy ? 'Signing in…' : 'Login'),
                    ),
                  ),
                  if (c.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        c.error!,
                        style:
                            const TextStyle(color: PartnerColors.danger),
                      ),
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    'Partner accounts are created only by ASTRIDE Admin. Self-registration is disabled.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: PartnerColors.muted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
