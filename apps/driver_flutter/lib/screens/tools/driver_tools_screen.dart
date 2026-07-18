import 'package:flutter/material.dart';

import '../../design/astride_theme.dart';
import '../../state/driver_controller.dart';
import '../onboarding/document_verification_screen.dart';

class DriverSupportScreen extends StatefulWidget {
  const DriverSupportScreen({
    super.key,
    required this.controller,
  });

  final DriverController controller;

  @override
  State<DriverSupportScreen> createState() =>
      _DriverSupportScreenState();
}

class _DriverSupportScreenState
    extends State<DriverSupportScreen> {
  final description = TextEditingController();
  String category = 'APP_SUPPORT';
  bool sending = false;

  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Driver Support')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Icon(
              Icons.support_agent_rounded,
              size: 60,
              color: AstrideColors.green,
            ),
            const SizedBox(height: 12),
            const Text(
              'Tell ASTRIDE Support what you need help with.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AstrideColors.muted),
            ),
            const SizedBox(height: 22),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration:
                  const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(
                  value: 'APP_SUPPORT',
                  child: Text('App or login problem'),
                ),
                DropdownMenuItem(
                  value: 'RIDE_SUPPORT',
                  child: Text('Ride or Passenger problem'),
                ),
                DropdownMenuItem(
                  value: 'PAYMENT',
                  child: Text('Wallet or settlement'),
                ),
                DropdownMenuItem(
                  value: 'DOCUMENTS',
                  child: Text('Document verification'),
                ),
                DropdownMenuItem(
                  value: 'SAFETY',
                  child: Text('Safety issue'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => category = value);
                }
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: description,
              minLines: 4,
              maxLines: 7,
              decoration: const InputDecoration(
                labelText: 'Describe the problem',
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: sending ? null : _submit,
              icon: const Icon(Icons.send_rounded),
              label: Text(
                sending ? 'Sending…' : 'Send to Support',
              ),
            ),
          ],
        ),
      );

  Future<void> _submit() async {
    final text = description.text.trim();
    if (text.length < 5) {
      _toast('Write a little more detail.');
      return;
    }
    setState(() => sending = true);
    try {
      final result =
          await widget.controller.submitSupportIssue(
        category: category,
        description: text,
        rideId:
            widget.controller.activeRide?['id']?.toString(),
      );
      description.clear();
      _toast(
        'Support request sent. ID: ${result['id'] ?? '-'}',
      );
    } catch (error) {
      _toast('$error');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class DriverDocumentsScreen extends StatelessWidget {
  const DriverDocumentsScreen({
    super.key,
    required this.controller,
  });

  final DriverController controller;

  @override
  Widget build(BuildContext context) {
    final documents = controller.documents;
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Documents')),
      body: RefreshIndicator(
        onRefresh: controller.refreshDriver,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(
                  Icons.verified_user_rounded,
                  color: AstrideColors.green,
                ),
                title: const Text('Verification status'),
                subtitle: Text(controller.approval),
              ),
            ),
            const SizedBox(height: 12),
            if (documents.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(22),
                  child: Text(
                    'No documents uploaded yet.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              for (final document in documents)
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.description_outlined,
                    ),
                    title: Text(
                      _label('${document['type'] ?? ''}'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      '${document['remarks'] ?? 'No remarks'}',
                    ),
                    trailing: _Status(
                      '${document['status'] ?? 'PENDING'}',
                    ),
                  ),
                ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DocumentVerificationScreen(
                    controller: controller,
                  ),
                ),
              ),
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Upload / Replace Documents'),
            ),
          ],
        ),
      ),
    );
  }

  static String _label(String type) {
    switch (type) {
      case 'IDENTITY_DOCUMENT':
        return 'Identity document';
      case 'VEHICLE_REGISTRATION':
        return 'Vehicle registration';
      case 'VEHICLE_PHOTO':
        return 'Vehicle photo';
      case 'PROFILE_PHOTO':
        return 'Driver profile photo';
      case 'BANK_DETAILS':
        return 'Bank details';
      default:
        return type.replaceAll('_', ' ');
    }
  }
}

class DriverSafetyScreen extends StatelessWidget {
  const DriverSafetyScreen({
    super.key,
    required this.controller,
  });

  final DriverController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Safety & SOS')),
        body: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0x14EF4444),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.sos_rounded,
                    size: 64,
                    color: AstrideColors.danger,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Emergency SOS',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AstrideColors.navy,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Your live location and current ride details '
                    'will be sent to the ASTRIDE Safety Team.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AstrideColors.danger,
              ),
              onPressed: () => _sendSos(context),
              icon: const Icon(Icons.warning_amber_rounded),
              label: const Text('Send SOS Now'),
            ),
            const SizedBox(height: 14),
            Card(
              child: ListTile(
                leading: const Icon(Icons.contact_phone_outlined),
                title: const Text('Emergency contact'),
                subtitle: Text(
                  '${controller.profile['emergencyContact'] ?? 'Not added'}',
                ),
              ),
            ),
          ],
        ),
      );

  Future<void> _sendSos(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm emergency SOS'),
        content: const Text(
          'Use SOS only for an actual safety emergency.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final incident = await controller.triggerSos();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'SOS sent. Incident ID: ${incident['id'] ?? '-'}',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SOS could not be sent. Call 112 if immediate help is required.')),
      );
    }
  }
}

class _Status extends StatelessWidget {
  const _Status(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final approved = value == 'APPROVED';
    final rejected = value == 'REJECTED';
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: approved
            ? AstrideColors.successTint
            : rejected
                ? const Color(0x14EF4444)
                : const Color(0x14F59E0B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        value,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: approved
              ? AstrideColors.greenDark
              : rejected
                  ? AstrideColors.danger
                  : AstrideColors.orange,
        ),
      ),
    );
  }
}
