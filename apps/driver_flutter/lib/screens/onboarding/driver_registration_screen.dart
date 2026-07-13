import 'package:flutter/material.dart';

import '../../design/astride_theme.dart';
import '../../state/driver_controller.dart';
import '../../widgets/brand/astride_wordmark.dart';

class DriverRegistrationScreen extends StatefulWidget {
  const DriverRegistrationScreen({
    super.key,
    required this.controller,
  });

  final DriverController controller;

  @override
  State<DriverRegistrationScreen> createState() =>
      _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState
    extends State<DriverRegistrationScreen> {
  late final TextEditingController name;
  late final TextEditingController address;
  late final TextEditingController vehicle;
  late final TextEditingController upi;
  late final TextEditingController emergency;
  String vehicleType = 'FULL_TOTO';

  DriverController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    final profile = c.profile;
    final vehicleData =
        (profile['vehicle'] as Map?)?.cast<String, dynamic>() ?? {};

    name = TextEditingController(
      text: '${profile['fullName'] ?? ''}',
    );
    address = TextEditingController(
      text: '${profile['address'] ?? ''}',
    );
    vehicle = TextEditingController(
      text: '${vehicleData['number'] ?? ''}',
    );
    upi = TextEditingController(
      text: '${profile['upiId'] ?? ''}',
    );
    emergency = TextEditingController(
      text: '${profile['emergencyContact'] ?? ''}',
    );
    vehicleType = '${vehicleData['type'] ?? 'FULL_TOTO'}';
  }

  @override
  void dispose() {
    name.dispose();
    address.dispose();
    vehicle.dispose();
    upi.dispose();
    emergency.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty ||
        address.text.trim().isEmpty ||
        vehicle.text.trim().isEmpty ||
        emergency.text.replaceAll(RegExp(r'\D'), '').length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Name, address, vehicle number and a valid emergency number are required.',
          ),
        ),
      );
      return;
    }

    try {
      await c.saveProfile({
        'fullName': name.text.trim(),
        'address': address.text.trim(),
        'vehicle': {
          'number': vehicle.text.trim().toUpperCase(),
          'type': vehicleType,
        },
        'upiId': upi.text.trim(),
        'emergencyContact':
            emergency.text.replaceAll(RegExp(r'\D'), ''),
        'preferredLanguage': c.locale?.code ?? 'en',
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const AstrideWordmark(compact: true),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              c.t('completeProfile'),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AstrideColors.navy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Complete the driver information created by ASTRIDE Admin.',
              style: TextStyle(color: AstrideColors.muted),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: address,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Address',
                prefixIcon: Icon(Icons.home_outlined),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: vehicleType,
              decoration: const InputDecoration(
                labelText: 'Vehicle type',
                prefixIcon: Icon(Icons.electric_rickshaw_outlined),
              ),
              items: const [
                DropdownMenuItem(
                  value: 'FULL_TOTO',
                  child: Text('Full Toto'),
                ),
                DropdownMenuItem(
                  value: 'SHARE_TOTO',
                  child: Text('Share Toto'),
                ),
                DropdownMenuItem(
                  value: 'MOTORCYCLE',
                  child: Text('Motorcycle'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => vehicleType = value);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: vehicle,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Vehicle number',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: upi,
              decoration: const InputDecoration(
                labelText: 'UPI ID (optional)',
                prefixIcon:
                    Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emergency,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Emergency contact',
                prefixIcon: Icon(Icons.emergency_outlined),
              ),
            ),
            if (c.error != null) ...[
              const SizedBox(height: 12),
              Text(
                c.error!,
                style: const TextStyle(
                  color: AstrideColors.danger,
                ),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: c.busy ? null : save,
              icon: c.busy
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: const Text('Save and continue'),
            ),
          ],
        ),
      );
}
