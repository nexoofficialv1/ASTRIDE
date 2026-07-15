import 'package:flutter/material.dart';

import '../design/astride_theme.dart';
import '../services/api_client.dart';
import '../state/partner_controller.dart';

class PartnerDriversScreen extends StatelessWidget {
  const PartnerDriversScreen({super.key, required this.controller});
  final PartnerController controller;

  Future<void> _openDriver(BuildContext context, Map<String, dynamic> row) async {
    final id = (row['driverId'] ?? '').toString();
    if (id.isEmpty) return;
    try {
      final details = await controller.driverDetails(id);
      if (!context.mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DriverDetailsScreen(controller: controller, driverId: id, details: details),
      ));
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: controller.refreshAll,
        child: controller.drivers.isEmpty
            ? ListView(children: const [SizedBox(height: 180), Center(child: Text('No drivers in your scope'))])
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: controller.drivers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = controller.drivers[index];
                  final online = item['online'] == true;
                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: CircleAvatar(
                        backgroundColor: online ? AstrideColors.successTint : AstrideColors.navyTint,
                        child: Icon(Icons.person, color: online ? AstrideColors.greenDark : AstrideColors.navy),
                      ),
                      title: Text((item['name'] ?? 'Driver').toString(), style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text('${item['mobile'] ?? ''}\nCompleted ${item['completed'] ?? 0} • Acceptance ${item['acceptanceRate'] ?? 0}%'),
                      ),
                      isThreeLine: true,
                      trailing: Icon(online ? Icons.circle : Icons.circle_outlined, color: online ? AstrideColors.green : AstrideColors.muted, size: 16),
                      onTap: () => _openDriver(context, item),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: controller.isPromoter
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddDriverScreen(controller: controller))),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Add Driver'),
            )
          : null,
    );
  }
}

class DriverDetailsScreen extends StatefulWidget {
  const DriverDetailsScreen({super.key, required this.controller, required this.driverId, required this.details});
  final PartnerController controller;
  final String driverId;
  final Map<String, dynamic> details;

  @override
  State<DriverDetailsScreen> createState() => _DriverDetailsScreenState();
}

class _DriverDetailsScreenState extends State<DriverDetailsScreen> {
  late Map<String, dynamic> details = widget.details;

  Map<String, dynamic> get profile => details['profile'] is Map ? (details['profile'] as Map).cast<String, dynamic>() : {};
  Map<String, dynamic> get approval => details['approval'] is Map ? (details['approval'] as Map).cast<String, dynamic>() : {};
  Map<String, dynamic> get actions => details['partnerActions'] is Map ? (details['partnerActions'] as Map).cast<String, dynamic>() : {};

  Future<void> review(String status) async {
    final remarks = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == 'APPROVED' ? 'Approve driver?' : 'Reject driver?'),
        content: TextField(controller: remarks, maxLines: 3, decoration: const InputDecoration(labelText: 'Remarks')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await widget.controller.reviewDriver(widget.driverId, status, remarks: remarks.text);
      details = await widget.controller.driverDetails(widget.driverId);
      if (mounted) setState(() {});
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> coaching() async {
    final message = TextEditingController();
    String type = 'COACHING';
    final submit = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setInner) => AlertDialog(
        title: const Text('Send driver note'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          DropdownButtonFormField<String>(
            value: type,
            items: const [
              DropdownMenuItem(value: 'COACHING', child: Text('Coaching')),
              DropdownMenuItem(value: 'WARNING', child: Text('Warning')),
              DropdownMenuItem(value: 'ENCOURAGEMENT', child: Text('Encouragement')),
            ],
            onChanged: (v) => setInner(() => type = v ?? type),
          ),
          const SizedBox(height: 12),
          TextField(controller: message, maxLines: 4, decoration: const InputDecoration(labelText: 'Message')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send')),
        ],
      )),
    );
    if (submit != true || message.text.trim().isEmpty) return;
    try {
      await widget.controller.sendCoaching(widget.driverId, type, message.text);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note sent')));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final canApprove = actions['canApprove'] == true;
    return Scaffold(
      appBar: AppBar(title: Text((profile['fullName'] ?? profile['name'] ?? 'Driver').toString())),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _row('Mobile', profile['mobile'] ?? ''),
          _row('Status', profile['status'] ?? ''),
          _row('Approval stage', approval['stage'] ?? ''),
          _row('Vehicle', profile['vehicle'] is Map ? ((profile['vehicle'] as Map)['number'] ?? '') : ''),
        ]))),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: coaching, icon: const Icon(Icons.message_outlined), label: const Text('Coach / Warn / Encourage')),
        if (canApprove) ...[
          const SizedBox(height: 10),
          FilledButton.icon(onPressed: () => review('APPROVED'), icon: const Icon(Icons.verified_outlined), label: const Text('Approve')), 
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => review('REJECTED'), icon: const Icon(Icons.block), label: const Text('Reject')),
        ],
      ]),
    );
  }

  static Widget _row(String label, Object value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 125, child: Text(label, style: const TextStyle(color: AstrideColors.muted))),
          Expanded(child: Text('$value', style: const TextStyle(fontWeight: FontWeight.w700))),
        ]),
      );
}

class AddDriverScreen extends StatefulWidget {
  const AddDriverScreen({super.key, required this.controller});
  final PartnerController controller;
  @override
  State<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends State<AddDriverScreen> {
  final name = TextEditingController();
  final mobile = TextEditingController();
  final password = TextEditingController();
  final vehicle = TextEditingController();

  @override
  void dispose() {
    name.dispose(); mobile.dispose(); password.dispose(); vehicle.dispose(); super.dispose();
  }

  Future<void> save() async {
    try {
      await widget.controller.createDriver(
        mobile: mobile.text,
        fullName: name.text,
        temporaryPassword: password.text,
        vehicleNumber: vehicle.text,
      );
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Add Driver')),
        body: ListView(padding: const EdgeInsets.all(18), children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
          const SizedBox(height: 12),
          TextField(controller: mobile, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Mobile')),
          const SizedBox(height: 12),
          TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Temporary password')),
          const SizedBox(height: 12),
          TextField(controller: vehicle, textCapitalization: TextCapitalization.characters, decoration: const InputDecoration(labelText: 'Vehicle number (optional)')),
          const SizedBox(height: 20),
          FilledButton(onPressed: widget.controller.busy ? null : save, child: const Text('Create Driver')),
        ]),
      );
}
