import 'package:flutter/material.dart';
import '../state/partner_controller.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});
  final PartnerController controller;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final mobile = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final s = c.strings;
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
                  Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                    DropdownButton<String>(
                      value: c.languageCode,
                      underline: const SizedBox.shrink(),
                      items: const [DropdownMenuItem(value: 'en', child: Text('English')), DropdownMenuItem(value: 'bn', child: Text('বাংলা')), DropdownMenuItem(value: 'hi', child: Text('हिंदी'))],
                      onChanged: (v) { if (v != null) c.setLanguage(v); },
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Container(width: 86, height: 86, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(28)), child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 46)),
                  const SizedBox(height: 18),
                  Text(s.t('app'), style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(s.t('partnerSubtitle')),
                  const SizedBox(height: 30),
                  TextField(controller: mobile, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: s.t('mobile'), prefixIcon: const Icon(Icons.phone_android_rounded))),
                  const SizedBox(height: 14),
                  TextField(controller: password, obscureText: obscure, decoration: InputDecoration(labelText: s.t('password'), prefixIcon: const Icon(Icons.lock_outline_rounded), suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
                  const SizedBox(height: 20),
                  FilledButton(onPressed: c.busy ? null : () => c.login(mobile.text.trim(), password.text), child: Padding(padding: const EdgeInsets.symmetric(vertical: 13), child: Text(c.busy ? s.t('signingIn') : s.t('signIn')))),
                  if (c.error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(c.error!, style: const TextStyle(color: Colors.red))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
