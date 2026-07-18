import 'package:flutter/material.dart';

import '../design/astride_theme.dart';
import '../state/passenger_controller.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key, required this.controller});
  final PassengerController controller;

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final description = TextEditingController();
  final rideId = TextEditingController();
  String category = 'RIDE';
  bool busy = false;

  @override
  void dispose() {
    description.dispose();
    rideId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Report an issue')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AstrideColors.successTint,
                      child: Icon(
                        Icons.support_agent_rounded,
                        color: AstrideColors.greenDark,
                      ),
                    ),
                    SizedBox(width: 13),
                    Expanded(
                      child: Text(
                        'Tell us what happened. ASTRIDE support will review your report.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: category,
              decoration: const InputDecoration(
                labelText: 'Issue category',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'RIDE', child: Text('Ride issue')),
                DropdownMenuItem(
                  value: 'PAYMENT',
                  child: Text('Payment issue'),
                ),
                DropdownMenuItem(
                  value: 'DRIVER',
                  child: Text('Driver behaviour'),
                ),
                DropdownMenuItem(
                  value: 'SAFETY',
                  child: Text('Safety concern'),
                ),
                DropdownMenuItem(value: 'APP', child: Text('App problem')),
                DropdownMenuItem(value: 'OTHER', child: Text('Other')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => category = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rideId,
              decoration: const InputDecoration(
                labelText: 'Ride ID (optional)',
                prefixIcon: Icon(Icons.receipt_long_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              minLines: 5,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Describe the issue',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: busy
                  ? null
                  : () async {
                      if (description.text.trim().length < 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please describe the issue in at least 10 characters.',
                            ),
                          ),
                        );
                        return;
                      }
                      setState(() => busy = true);
                      try {
                        await widget.controller.submitIssue(
                          category: category,
                          description: description.text,
                          rideId: rideId.text,
                        );
                        if (!context.mounted) return;
                        showDialog<void>(
                          context: context,
                          builder: (_) => AlertDialog(
                            icon: const Icon(
                              Icons.check_circle_rounded,
                              color: AstrideColors.green,
                              size: 54,
                            ),
                            title: const Text('Issue submitted'),
                            content: const Text(
                              'Your report has been sent to ASTRIDE support.',
                            ),
                            actions: [
                              FilledButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                },
                                child: const Text('Done'),
                              ),
                            ],
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
              icon: const Icon(Icons.send_rounded),
              label: Text(busy ? 'Submitting…' : 'Submit report'),
            ),
          ],
        ),
      );
}
