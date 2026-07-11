import 'package:flutter/material.dart';
import '../../design/astride_theme.dart';
import '../../state/driver_controller.dart';

class DocumentVerificationScreen extends StatefulWidget {
  const DocumentVerificationScreen({super.key, required this.controller});
  final DriverController controller;

  @override
  State<DocumentVerificationScreen> createState() => _DocumentVerificationScreenState();
}

class _DocumentVerificationScreenState extends State<DocumentVerificationScreen> {
  final Map<String, bool> uploaded = {};

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final docs = <(String, IconData)>[
      ('identityDocument', Icons.badge_outlined),
      ('vehicleRegistration', Icons.description_outlined),
      ('vehiclePhoto', Icons.electric_rickshaw_outlined),
      ('profilePhoto', Icons.account_circle_outlined),
      ('bankDetails', Icons.account_balance_outlined),
    ];
    final ready = docs.every((d) => uploaded[d.$1] == true);

    return Scaffold(
      appBar: AppBar(title: Text(c.t('documentVerification'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            c.t('uploadDocuments'),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AstrideColors.navy),
          ),
          const SizedBox(height: 6),
          Text(c.t('documentSecurityNote'), style: const TextStyle(color: AstrideColors.muted)),
          const SizedBox(height: 18),
          for (final d in docs)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Icon(d.$2, color: AstrideColors.green),
                  title: Text(c.t(d.$1), style: const TextStyle(fontWeight: FontWeight.w700)),
                  trailing: uploaded[d.$1] == true
                      ? const Icon(Icons.check_circle, color: AstrideColors.green)
                      : OutlinedButton(
                          onPressed: () => setState(() => uploaded[d.$1] = true),
                          child: Text(c.t('upload')),
                        ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: ready ? () => c.submitDocuments({'documents': uploaded.keys.toList()}) : null,
            child: Text(c.t('submitForVerification')),
          ),
        ],
      ),
    );
  }
}
