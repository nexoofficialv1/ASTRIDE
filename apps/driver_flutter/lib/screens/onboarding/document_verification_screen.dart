import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../design/astride_theme.dart';
import '../../state/driver_controller.dart';

class DocumentVerificationScreen extends StatefulWidget {
  const DocumentVerificationScreen({
    super.key,
    required this.controller,
  });

  final DriverController controller;

  @override
  State<DocumentVerificationScreen> createState() =>
      _DocumentVerificationScreenState();
}

class _DocumentVerificationScreenState
    extends State<DocumentVerificationScreen> {
  final Map<String, bool> uploaded = {};
  String? uploadingType;

  DriverController get c => widget.controller;

  static const documents = <_DocumentSpec>[
    _DocumentSpec(
      'IDENTITY_DOCUMENT',
      'Identity document',
      Icons.badge_outlined,
    ),
    _DocumentSpec(
      'VEHICLE_REGISTRATION',
      'Vehicle registration',
      Icons.description_outlined,
    ),
    _DocumentSpec(
      'VEHICLE_PHOTO',
      'Vehicle photo',
      Icons.electric_rickshaw_outlined,
    ),
    _DocumentSpec(
      'PROFILE_PHOTO',
      'Driver profile photo',
      Icons.account_circle_outlined,
    ),
    _DocumentSpec(
      'BANK_DETAILS',
      'Bank passbook / cancelled cheque',
      Icons.account_balance_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (final item in c.documents) {
      final type = '${item['type'] ?? ''}';
      if (type.isNotEmpty) uploaded[type] = true;
    }
  }

  String mimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<ImageSource?> chooseSource() =>
      showModalBottomSheet<ImageSource>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take photo'),
                onTap: () =>
                    Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () =>
                    Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );

  Future<void> upload(_DocumentSpec spec) async {
    final source = await chooseSource();
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 78,
      maxWidth: 1400,
    );
    if (picked == null) return;

    setState(() => uploadingType = spec.type);

    try {
      final bytes = await picked.readAsBytes();
      await c.uploadDocument(
        type: spec.type,
        fileName: picked.name,
        mimeType: mimeType(picked.path),
        base64: base64Encode(bytes),
      );

      if (!mounted) return;
      setState(() => uploaded[spec.type] = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${spec.label} uploaded')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => uploadingType = null);
      }
    }
  }

  Future<void> finish() async {
    try {
      await c.completeDocuments();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ready = documents.every(
      (document) => uploaded[document.type] == true,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Document verification')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Upload driver documents',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AstrideColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Only the selected images are uploaded securely for Admin verification.',
            style: TextStyle(color: AstrideColors.muted),
          ),
          const SizedBox(height: 18),
          for (final spec in documents)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Icon(
                    spec.icon,
                    color: AstrideColors.green,
                  ),
                  title: Text(
                    spec.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  trailing: uploaded[spec.type] == true
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: AstrideColors.green,
                        )
                      : uploadingType == spec.type
                          ? const SizedBox.square(
                              dimension: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : OutlinedButton(
                              onPressed: uploadingType == null
                                  ? () => upload(spec)
                                  : null,
                              child: const Text('Upload'),
                            ),
                ),
              ),
            ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed:
                ready && uploadingType == null ? finish : null,
            icon: const Icon(Icons.verified_user_outlined),
            label: const Text('Submit for verification'),
          ),
        ],
      ),
    );
  }
}

class _DocumentSpec {
  const _DocumentSpec(this.type, this.label, this.icon);

  final String type;
  final String label;
  final IconData icon;
}
