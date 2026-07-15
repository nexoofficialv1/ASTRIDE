import 'package:flutter/material.dart';

import '../design/astride_theme.dart';
import '../services/api_client.dart';
import '../state/partner_controller.dart';
import '../widgets/brand/astride_wordmark.dart';

class PartnerLoginScreen extends StatefulWidget {
  const PartnerLoginScreen({super.key, required this.controller});
  final PartnerController controller;

  @override
  State<PartnerLoginScreen> createState() => _PartnerLoginScreenState();
}

class _PartnerLoginScreenState extends State<PartnerLoginScreen> {
  final mobile = TextEditingController();
  final password = TextEditingController();
  bool obscure = true;

  @override
  void dispose() {
    mobile.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    try {
      await widget.controller.login(mobile.text, password.text);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(alignment: Alignment.centerLeft, child: AstrideWordmark()),
                      const SizedBox(height: 14),
                      const Text(
                        'Partner Control',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AstrideColors.navy),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Promoter ও Area Promoter login',
                        style: TextStyle(color: AstrideColors.muted, fontSize: 16),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: mobile,
                        keyboardType: TextInputType.phone,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        decoration: const InputDecoration(labelText: 'Mobile number', prefixIcon: Icon(Icons.phone_android)),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: password,
                        obscureText: obscure,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => obscure = !obscure),
                            icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          ),
                        ),
                        onSubmitted: (_) => submit(),
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: widget.controller.busy ? null : submit,
                        icon: widget.controller.busy
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.login),
                        label: const Text('Sign in'),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Self-registration বন্ধ। Partner account Admin তৈরি করবে।',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AstrideColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
