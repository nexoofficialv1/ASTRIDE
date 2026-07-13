import 'package:flutter/material.dart';

import '../core/app_config.dart';
import '../models/partner_models.dart';
import '../state/partner_controller.dart';

class DriverDetailScreen extends StatefulWidget {
  const DriverDetailScreen({super.key, required this.c, required this.driver});

  final PartnerController c;
  final DriverPerformance driver;

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  Map<String, dynamic>? detail;
  String? error;
  bool loading = true;

  PartnerController get c => widget.c;
  DriverPerformance get driver => widget.driver;

  String _label(String en, String bn, String hi) => switch (c.languageCode) {
        'bn' => bn,
        'hi' => hi,
        _ => en,
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final value = await c.loadDriverReview(driver.id);
      if (!mounted) return;
      setState(() => detail = value);
    } catch (e) {
      if (!mounted) return;
      setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _absoluteUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/${path.replaceFirst(RegExp(r'^/+'), '')}';
  }

  @override
  Widget build(BuildContext context) {
    final s = c.strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('driverDetails'))),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [Text(error!, textAlign: TextAlign.center), const SizedBox(height: 12), FilledButton(onPressed: _load, child: Text(s.t('refresh')))])))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _profileCard(context),
                      const SizedBox(height: 14),
                      _approvalChain(context),
                      const SizedBox(height: 14),
                      _documents(context),
                      const SizedBox(height: 14),
                      _performance(context),
                      const SizedBox(height: 16),
                      FilledButton.icon(onPressed: () => _coach(context, 'ENCOURAGE'), icon: const Icon(Icons.thumb_up_alt_rounded), label: Text(s.t('encourage'))),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(onPressed: () => _coach(context, 'WARNING'), icon: const Icon(Icons.warning_amber_rounded), label: Text(s.t('warning'))),
                    ],
                  ),
                ),
    );
  }

  Widget _profileCard(BuildContext context) {
    final profile = ((detail?['profile'] as Map?) ?? const {}).cast<String, dynamic>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            CircleAvatar(radius: 38, child: Text(driver.name.isEmpty ? 'D' : driver.name[0].toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900))),
            const SizedBox(height: 10),
            Text('${profile['fullName'] ?? driver.name}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            Text('${profile['mobile'] ?? driver.mobile}'),
            Text('${c.strings.t('vehicle')}: ${((profile['vehicle'] as Map?) ?? const {})['number'] ?? driver.vehicle}'),
            const SizedBox(height: 8),
            Chip(label: Text('${profile['status'] ?? driver.status}')),
          ],
        ),
      ),
    );
  }

  Widget _approvalChain(BuildContext context) {
    final approval = ((detail?['approval'] as Map?) ?? const {}).cast<String, dynamic>();
    final actions = ((detail?['partnerActions'] as Map?) ?? const {}).cast<String, dynamic>();
    final promoter = ((approval['promoter'] as Map?) ?? const {}).cast<String, dynamic>();
    final area = ((approval['areaPromoter'] as Map?) ?? const {}).cast<String, dynamic>();
    final admin = ((approval['admin'] as Map?) ?? const {}).cast<String, dynamic>();
    final canApprove = actions['canApprove'] == true;
    final stage = '${actions['stage'] ?? ''}';
    final approveText = stage == 'AREA_PROMOTER'
        ? _label('Area Approve & send to Admin', 'এরিয়া অনুমোদন দিয়ে অ্যাডমিনে পাঠান', 'एरिया अनुमोदन कर एडमिन को भेजें')
        : _label('Partial Approve & send to Area Promoter', 'পার্টলি অনুমোদন দিয়ে এরিয়া প্রোমোটারে পাঠান', 'आंशिक अनुमोदन कर एरिया प्रमोटर को भेजें');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_label('Approval chain', 'অনুমোদনের ধাপ', 'अनुमोदन क्रम'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            _stage('1', _label('Promoter partial approval', 'প্রোমোটারের পার্টলি অনুমোদন', 'प्रमोटर आंशिक अनुमोदन'), promoter),
            _stage('2', _label('Area Promoter approval', 'এরিয়া প্রোমোটারের অনুমোদন', 'एरिया प्रमोटर अनुमोदन'), area),
            _stage('3', _label('Admin final approval', 'অ্যাডমিনের ফাইনাল অনুমোদন', 'एडमिन अंतिम अनुमोदन'), admin),
            const SizedBox(height: 12),
            if (canApprove)
              FilledButton.icon(onPressed: () => _review('APPROVED'), icon: const Icon(Icons.verified_rounded), label: Text(approveText)),
            if (canApprove) const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: () => _review('REJECTED'), icon: const Icon(Icons.cancel_outlined), label: Text(_label('Reject with reason', 'কারণ লিখে বাতিল করুন', 'कारण देकर अस्वीकार करें'))),
            if (!canApprove)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(_label('Approval will activate after all mandatory documents and the previous stage are complete.', 'সব বাধ্যতামূলক নথি এবং আগের ধাপ সম্পূর্ণ হলে অনুমোদন সক্রিয় হবে।', 'सभी अनिवार्य दस्तावेज़ और पिछला चरण पूरा होने पर अनुमोदन सक्रिय होगा।'), style: Theme.of(context).textTheme.bodySmall),
              ),
          ],
        ),
      ),
    );
  }

  Widget _stage(String number, String title, Map<String, dynamic> value) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(child: Text(number)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text('${value['remarks'] ?? ''}'),
        trailing: Chip(label: Text('${value['status'] ?? 'PENDING'}')),
      );

  Widget _documents(BuildContext context) {
    final documents = ((detail?['documents'] as List?) ?? const []).whereType<Map>().map((item) => item.cast<String, dynamic>()).toList();
    final verification = ((detail?['verification'] as Map?) ?? const {}).cast<String, dynamic>();
    final labels = <String, String>{
      'IDENTITY_DOCUMENT': _label('Identity document', 'পরিচয়পত্র', 'पहचान दस्तावेज़'),
      'VEHICLE_REGISTRATION': _label('Vehicle registration', 'গাড়ির রেজিস্ট্রেশন', 'वाहन पंजीकरण'),
      'VEHICLE_PHOTO': _label('Vehicle photo', 'গাড়ির ছবি', 'वाहन फोटो'),
      'PROFILE_PHOTO': _label('Driver profile photo', 'ড্রাইভারের ছবি', 'ड्राइवर फोटो'),
      'BANK_DETAILS': _label('Bank details', 'ব্যাংকের নথি', 'बैंक दस्तावेज़'),
    };
    final latest = <String, Map<String, dynamic>>{};
    for (final doc in documents) latest['${doc['type']}'] = doc;
    final required = ((verification['required'] as List?) ?? const []).whereType<Map>().map((item) => item.cast<String, dynamic>()).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_label('Driver documents', 'ড্রাইভারের নথি', 'ड्राइवर दस्तावेज़'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            for (final item in required) _documentTile(context, labels['${item['type']}'] ?? '${item['type']}', latest['${item['type']}']),
          ],
        ),
      ),
    );
  }

  Widget _documentTile(BuildContext context, String title, Map<String, dynamic>? document) {
    if (document == null) return ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.upload_file_rounded), title: Text(title), trailing: const Chip(label: Text('MISSING')));
    final url = _absoluteUrl('${document['fileUrl'] ?? ''}');
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: const Icon(Icons.description_rounded),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text('${document['status'] ?? 'PENDING'}'),
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.network(url, height: 220, width: double.infinity, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox(height: 100, child: Center(child: Icon(Icons.broken_image_outlined)))),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _performance(BuildContext context) => GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.7,
        children: [
          _metric(c.strings.t('rideRequests'), '${driver.requests}'),
          _metric(c.strings.t('completedRides'), '${driver.completed}'),
          _metric(c.strings.t('acceptanceRate'), '${driver.acceptance.toStringAsFixed(1)}%'),
          _metric(c.strings.t('cancellationRate'), '${driver.cancellationRate.toStringAsFixed(1)}%'),
        ],
      );

  Widget _metric(String label, String value) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)])));

  Future<void> _review(String status) async {
    final remarks = TextEditingController();
    final approve = status == 'APPROVED';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? _label('Confirm approval', 'অনুমোদন নিশ্চিত করুন', 'अनुमोदन की पुष्टि करें') : _label('Reject Driver', 'ড্রাইভার বাতিল করুন', 'ड्राइवर अस्वीकार करें')),
        content: TextField(controller: remarks, maxLines: 4, decoration: InputDecoration(labelText: _label('Remarks / reason', 'মন্তব্য / কারণ', 'टिप्पणी / कारण'))),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(_label('Cancel', 'বাতিল', 'रद्द करें'))), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(approve ? _label('Approve', 'অনুমোদন', 'अनुमोदन') : _label('Reject', 'বাতিল', 'अस्वीकार')))],
      ),
    );
    if (ok != true) {
      remarks.dispose();
      return;
    }
    if (!approve && remarks.text.trim().isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_label('A rejection reason is required.', 'বাতিলের কারণ লিখতে হবে।', 'अस्वीकार का कारण आवश्यक है।'))));
      remarks.dispose();
      return;
    }
    try {
      await c.reviewDriver(driver.id, status: status, remarks: remarks.text);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_label('Approval stage updated.', 'অনুমোদনের ধাপ আপডেট হয়েছে।', 'अनुमोदन चरण अपडेट हुआ।'))));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      remarks.dispose();
    }
  }

  Future<void> _coach(BuildContext context, String type) async {
    final s = c.strings;
    final ctl = TextEditingController(text: type == 'ENCOURAGE' ? 'Keep up the good work.' : 'Please improve ride acceptance and reduce cancellations.');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('coachDriver')),
        content: TextField(controller: ctl, maxLines: 4, decoration: InputDecoration(labelText: s.t('message'))),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.t('cancel'))), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s.t('send')))],
      ),
    );
    if (ok == true) {
      await c.coach(driver.id, type, ctl.text.trim());
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('message'))));
    }
    ctl.dispose();
  }
}
