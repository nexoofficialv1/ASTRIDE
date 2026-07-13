import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_config.dart';
import '../design/astride_theme.dart';
import '../state/partner_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.c,
  });

  final PartnerController c;

  String mediaUrl(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base${raw.startsWith('/') ? raw : '/$raw'}';
  }

  Future<void> logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need your Partner ID/mobile and password to sign in again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await c.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = c.profile;
    final photo = mediaUrl('${profile['photoUrl'] ?? ''}');
    final role = '${profile['role'] ?? c.session?.role ?? '-'}';

    return RefreshIndicator(
      onRefresh: c.refreshProfile,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  PartnerColors.navy,
                  PartnerColors.navySoft,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      photo.isEmpty ? null : NetworkImage(photo),
                  child: photo.isEmpty
                      ? const Icon(
                          Icons.handshake_rounded,
                          size: 45,
                          color: PartnerColors.navy,
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  '${profile['name'] ?? c.session?.name ?? 'Partner'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c.session?.mobile ?? '',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 5),
                Text(
                  role == 'AREA_PROMOTER'
                      ? 'Area Promoter'
                      : 'Promoter',
                  style: const TextStyle(
                    color: PartnerColors.green,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PartnerEditProfileScreen(
                        controller: c,
                      ),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white54),
                  ),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                _Tile(
                  Icons.badge_rounded,
                  'Role',
                  role,
                ),
                _Tile(
                  Icons.location_city_outlined,
                  'Address',
                  '${profile['address'] ?? '-'}',
                ),
                _Tile(
                  Icons.account_balance_wallet_outlined,
                  'UPI ID',
                  '${profile['upiId'] ?? '-'}',
                ),
                _Tile(
                  Icons.emergency_outlined,
                  'Emergency contact',
                  '${profile['emergencyContact'] ?? '-'}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language_rounded),
                  title: const Text('Language'),
                  trailing: DropdownButton<String>(
                    value: c.languageCode,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(
                        value: 'en',
                        child: Text('English'),
                      ),
                      DropdownMenuItem(
                        value: 'bn',
                        child: Text('বাংলা'),
                      ),
                      DropdownMenuItem(
                        value: 'hi',
                        child: Text('हिंदी'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        c.setLanguage(value);
                      }
                    },
                  ),
                ),
                const Divider(height: 1),
                const ListTile(
                  leading: Icon(Icons.support_agent_rounded),
                  title: Text('Help & Support'),
                  subtitle: Text('Contact ASTRIDE Partner support'),
                  trailing: Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => logout(context),
            icon: const Icon(
              Icons.logout_rounded,
              color: PartnerColors.danger,
            ),
            label: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class PartnerEditProfileScreen extends StatefulWidget {
  const PartnerEditProfileScreen({
    super.key,
    required this.controller,
  });

  final PartnerController controller;

  @override
  State<PartnerEditProfileScreen> createState() =>
      _PartnerEditProfileScreenState();
}

class _PartnerEditProfileScreenState
    extends State<PartnerEditProfileScreen> {
  late final TextEditingController name;
  late final TextEditingController address;
  late final TextEditingController upi;
  late final TextEditingController emergency;
  late final TextEditingController accountHolder;
  late final TextEditingController accountNumber;
  late final TextEditingController ifsc;
  bool uploadingPhoto = false;

  PartnerController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    final profile = c.profile;
    final bank =
        (profile['bank'] as Map?)?.cast<String, dynamic>() ?? {};

    name = TextEditingController(
      text: '${profile['name'] ?? c.session?.name ?? ''}',
    );
    address =
        TextEditingController(text: '${profile['address'] ?? ''}');
    upi = TextEditingController(text: '${profile['upiId'] ?? ''}');
    emergency = TextEditingController(
      text: '${profile['emergencyContact'] ?? ''}',
    );
    accountHolder = TextEditingController(
      text: '${bank['accountHolder'] ?? ''}',
    );
    accountNumber = TextEditingController(
      text: '${bank['accountNumber'] ?? ''}',
    );
    ifsc = TextEditingController(text: '${bank['ifsc'] ?? ''}');
  }

  @override
  void dispose() {
    name.dispose();
    address.dispose();
    upi.dispose();
    emergency.dispose();
    accountHolder.dispose();
    accountNumber.dispose();
    ifsc.dispose();
    super.dispose();
  }

  String mimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> photo() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take photo'),
              onTap: () => Navigator.pop(
                context,
                ImageSource.camera,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(
                context,
                ImageSource.gallery,
              ),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 76,
      maxWidth: 900,
    );
    if (picked == null) return;

    setState(() => uploadingPhoto = true);

    try {
      final bytes = await picked.readAsBytes();
      await c.uploadProfilePhoto(
        fileName: picked.name,
        mimeType: mimeType(picked.path),
        base64: base64Encode(bytes),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => uploadingPhoto = false);
    }
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required.')),
      );
      return;
    }

    try {
      await c.updateProfile({
        'name': name.text.trim(),
        'address': address.text.trim(),
        'upiId': upi.text.trim(),
        'emergencyContact':
            emergency.text.replaceAll(RegExp(r'\D'), ''),
        'bank': {
          'accountHolder': accountHolder.text.trim(),
          'accountNumber': accountNumber.text.trim(),
          'ifsc': ifsc.text.trim().toUpperCase(),
        },
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partner profile saved')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Edit partner profile')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OutlinedButton.icon(
              onPressed: uploadingPhoto ? null : photo,
              icon: uploadingPhoto
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.camera_alt_outlined),
              label: const Text('Change profile photo'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: name,
              decoration: const InputDecoration(
                labelText: 'Name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: address,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Address',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: upi,
              decoration: const InputDecoration(labelText: 'UPI ID'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emergency,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Emergency contact',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Payout bank details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: PartnerColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: accountHolder,
              decoration: const InputDecoration(
                labelText: 'Account holder name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: accountNumber,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Account number',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ifsc,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'IFSC code',
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: c.busy ? null : save,
              icon: c.busy
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: const Text('Save profile'),
            ),
          ],
        ),
      );
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.title, this.value);

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) => ListTile(
        leading: Icon(icon, color: PartnerColors.green),
        title: Text(title),
        subtitle: Text(value),
      );
}
