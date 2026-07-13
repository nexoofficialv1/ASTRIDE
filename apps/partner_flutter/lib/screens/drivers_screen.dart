import 'package:flutter/material.dart';

import '../models/partner_models.dart';
import '../state/partner_controller.dart';
import 'driver_detail_screen.dart';

class DriversScreen extends StatelessWidget {
  const DriversScreen({super.key, required this.c});

  final PartnerController c;

  String _label(String en, String bn, String hi) => switch (c.languageCode) {
        'bn' => bn,
        'hi' => hi,
        _ => en,
      };

  @override
  Widget build(BuildContext context) {
    final s = c.strings;
    final items = c.visibleDrivers;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: c.setDriverQuery,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded),
                    hintText: s.t('searchDriver'),
                  ),
                ),
              ),
              if (c.isPromoter) ...[
                const SizedBox(width: 10),
                FilledButton.icon(
                  onPressed: c.busy ? null : () => _addDriver(context),
                  icon: const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(_label('Add', 'যোগ করুন', 'जोड़ें')),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            children: [
              _chip(c, 'ALL', s.t('all')),
              _chip(c, 'ONLINE', s.t('online')),
              _chip(c, 'ATTENTION', s.t('needsAttention')),
              _chip(c, 'TOP', s.t('topPerformers')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(c.range.label, style: const TextStyle(fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${items.length} ${s.t('drivers')}'),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_search_rounded, size: 56),
                      const SizedBox(height: 10),
                      Text(s.t('noDrivers')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: c.refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _DriverCard(c: c, driver: items[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _chip(PartnerController c, String value, String label) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(
          label: Text(label),
          selected: c.driverFilter == value,
          onSelected: (_) => c.setDriverFilter(value),
        ),
      );

  Future<void> _addDriver(BuildContext context) async {
    final name = TextEditingController();
    final mobile = TextEditingController();
    final password = TextEditingController();
    final vehicle = TextEditingController();
    String vehicleType = 'TOTO';

    final submit = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(_label('Add Driver', 'ড্রাইভার যোগ করুন', 'ड्राइवर जोड़ें')),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: InputDecoration(labelText: _label('Full name', 'সম্পূর্ণ নাম', 'पूरा नाम'))),
                const SizedBox(height: 10),
                TextField(controller: mobile, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: _label('Mobile number', 'মোবাইল নম্বর', 'मोबाइल नंबर'))),
                const SizedBox(height: 10),
                TextField(controller: password, obscureText: true, decoration: InputDecoration(labelText: _label('Temporary password', 'অস্থায়ী পাসওয়ার্ড', 'अस्थायी पासवर्ड'))),
                const SizedBox(height: 10),
                TextField(controller: vehicle, textCapitalization: TextCapitalization.characters, decoration: InputDecoration(labelText: _label('Vehicle number', 'গাড়ির নম্বর', 'वाहन नंबर'))),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: vehicleType,
                  decoration: InputDecoration(labelText: _label('Vehicle type', 'গাড়ির ধরন', 'वाहन प्रकार')),
                  items: const [
                    DropdownMenuItem(value: 'TOTO', child: Text('Toto / E-rickshaw')),
                    DropdownMenuItem(value: 'BIKE', child: Text('Bike')),
                  ],
                  onChanged: (value) => setState(() => vehicleType = value ?? 'TOTO'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(_label('Cancel', 'বাতিল', 'रद्द करें'))),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(_label('Create', 'তৈরি করুন', 'बनाएँ'))),
          ],
        ),
      ),
    );

    if (submit != true || !context.mounted) return;
    if (name.text.trim().isEmpty || mobile.text.trim().length < 10 || password.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_label('Enter name, valid mobile and an 8+ character password.', 'নাম, সঠিক মোবাইল এবং অন্তত ৮ অক্ষরের পাসওয়ার্ড দিন।', 'नाम, सही मोबाइल और कम से कम 8 अक्षर का पासवर्ड दें।'))));
      return;
    }

    try {
      final result = await c.createDriver(
        fullName: name.text,
        mobile: mobile.text,
        temporaryPassword: password.text,
        vehicleNumber: vehicle.text,
        vehicleType: vehicleType,
      );
      if (!context.mounted) return;
      final staff = ((result['staff'] as Map?) ?? const {}).cast<String, dynamic>();
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(_label('Driver created', 'ড্রাইভার তৈরি হয়েছে', 'ड्राइवर बनाया गया')),
          content: SelectableText('${_label('Login ID', 'লগইন আইডি', 'लॉगिन आईडी')}: ${staff['loginId'] ?? '-'}\n${_label('Temporary password', 'অস্থায়ী পাসওয়ার্ড', 'अस्थायी पासवर्ड')}: ${password.text}\n\n${_label('The Driver must change this password and upload all documents.', 'ড্রাইভারকে পাসওয়ার্ড পরিবর্তন করে সব নথি আপলোড করতে হবে।', 'ड्राइवर को पासवर्ड बदलकर सभी दस्तावेज़ अपलोड करने होंगे।')}'),
          actions: [FilledButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      name.dispose();
      mobile.dispose();
      password.dispose();
      vehicle.dispose();
    }
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.c, required this.driver});

  final PartnerController c;
  final DriverPerformance driver;

  @override
  Widget build(BuildContext context) {
    final s = c.strings;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => DriverDetailScreen(c: c, driver: driver)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(radius: 25, child: Text(driver.name.isEmpty ? 'D' : driver.name[0].toUpperCase())),
                      Positioned(right: 0, bottom: 0, child: Container(width: 13, height: 13, decoration: BoxDecoration(color: driver.online ? const Color(0xFF22C55E) : Colors.grey, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(driver.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                        Text('${driver.vehicle} • ${driver.online ? s.t('online') : s.t('offline')}'),
                        const SizedBox(height: 4),
                        Text('P: ${driver.promoterStatus}  •  Area: ${driver.areaStatus}  •  Admin: ${driver.adminStatus}', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                  if (driver.canApprove) const Icon(Icons.verified_user_rounded, color: Colors.orange),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _stat('${driver.uploadedDocuments}/${driver.requiredDocuments}', 'Documents')),
                  Expanded(child: _stat('${driver.completed}', s.t('completed'))),
                  Expanded(child: _stat('${driver.acceptance.toStringAsFixed(0)}%', s.t('acceptance'))),
                  Expanded(child: _stat(driver.status, 'Status')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis),
        ],
      );
}
