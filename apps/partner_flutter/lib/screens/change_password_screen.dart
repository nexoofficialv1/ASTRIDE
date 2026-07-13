import 'package:flutter/material.dart';

import '../design/astride_theme.dart';
import '../state/partner_controller.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.controller});
  final PartnerController controller;

  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
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
              Icons.admin_panel_settings_outlined,
              size: 70,
              color: PartnerColors.green,
            ),
            const SizedBox(height: 18),
            const Text(
              'Change the temporary password before opening the Partner dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(color: PartnerColors.muted),
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
                  const InputDecoration(labelText: 'Confirm password'),
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
                      } catch (_) {}
                    },
              child: const Text('Change password and continue'),
            ),
          ],
        ),
      );
}
