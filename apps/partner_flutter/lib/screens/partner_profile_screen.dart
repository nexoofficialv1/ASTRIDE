import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../services/api_client.dart';
import '../state/partner_controller.dart';

class PartnerProfileScreen extends StatelessWidget {
  const PartnerProfileScreen({super.key, required this.controller});
  final PartnerController controller;

  Future<void> edit(BuildContext context) async {
    final name = TextEditingController(text: (controller.partner['name'] ?? '').toString());
    final address = TextEditingController(text: (controller.partner['address'] ?? '').toString());
    final upi = TextEditingController(text: (controller.partner['upiId'] ?? '').toString());
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit profile'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Name')),
          const SizedBox(height: 12),
          TextField(controller: address, maxLines: 3, decoration: const InputDecoration(labelText: 'Address')),
          const SizedBox(height: 12),
          TextField(controller: upi, decoration: const InputDecoration(labelText: 'UPI ID')),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await controller.updateProfile({'name': name.text.trim(), 'address': address.text.trim(), 'upiId': upi.text.trim()});
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = controller.partner;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text((p['name'] ?? 'Partner').toString(), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text((p['role'] ?? '').toString().replaceAll('_', ' ')),
        const Divider(height: 28),
        _row('Mobile', p['mobile'] ?? ''),
        _row('Area', p['areaId'] ?? ''),
        _row('Address', p['address'] ?? ''),
        _row('UPI', p['upiId'] ?? ''),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: () => edit(context), icon: const Icon(Icons.edit_outlined), label: const Text('Edit profile')),
      ]))),
      const SizedBox(height: 14),
      Card(child: ListTile(title: const Text('App version'), trailing: Text(AppConfig.appVersion))),
      const SizedBox(height: 14),
      FilledButton.tonalIcon(onPressed: controller.logout, icon: const Icon(Icons.logout), label: const Text('Sign out')),
    ]);
  }

  static Widget _row(String label, Object value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 90, child: Text(label)), Expanded(child: Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)))]),
      );
}
