import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_config.dart';
import '../design/astride_theme.dart';
import '../state/passenger_controller.dart';
import 'offers_screen.dart';
import 'referral_screen.dart';
import 'report_issue_screen.dart';
import 'wallet_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.controller,
  });

  final PassengerController controller;

  String mediaUrl(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return '';
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base${raw.startsWith('/') ? raw : '/$raw'}';
  }

  String mimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> editName(BuildContext context) async {
    final field = TextEditingController(
      text: controller.profileName,
    );

    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit profile'),
        content: TextField(
          controller: field,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Name',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, field.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    field.dispose();

    if (value == null || value.trim().isEmpty) return;

    try {
      await controller.updateProfileName(value);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile name saved')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> pickPhoto(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 4),
            const Text(
              'Change profile photo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AstrideColors.navy,
              ),
            ),
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
            const SizedBox(height: 8),
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

    try {
      final bytes = await picked.readAsBytes();
      await controller.uploadProfilePhoto(
        fileName: picked.name,
        mimeType: mimeType(picked.path),
        base64: base64Encode(bytes),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo saved')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  Future<void> language(BuildContext context) async {
    final code = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            const Text(
              'Choose language',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AstrideColors.navy,
              ),
            ),
            for (final entry in const {
              'bn': 'বাংলা',
              'en': 'English',
              'hi': 'हिंदी',
            }.entries)
              ListTile(
                title: Text(entry.value),
                trailing: controller.locale?.code == entry.key
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: AstrideColors.green,
                      )
                    : null,
                onTap: () => Navigator.pop(context, entry.key),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );

    if (code != null) {
      await controller.changeLanguage(code);
    }
  }

  Future<void> logout(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(
          Icons.logout_rounded,
          color: AstrideColors.orange,
        ),
        title: const Text('Log out?'),
        content: const Text(
          'You will need a new OTP the next time you sign in.',
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

    if (yes == true) {
      await controller.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = controller.profileName.trim().isEmpty
        ? 'Passenger'
        : controller.profileName.trim();
    final photo = mediaUrl(controller.profilePhotoUrl);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: controller.refreshProfile,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AstrideColors.navy,
                    AstrideColors.navySoft,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            photo.isEmpty ? null : NetworkImage(photo, headers: controller.session?.authHeaders),
                        child: photo.isEmpty
                            ? const Icon(
                                Icons.person_rounded,
                                size: 48,
                                color: AstrideColors.navy,
                              )
                            : null,
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: Material(
                          color: AstrideColors.green,
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: () => pickPhoto(context),
                            icon: const Icon(
                              Icons.camera_alt_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+${controller.session?.mobile ?? ''}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => editName(context),
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
            Row(
              children: [
                Expanded(
                  child: _QuickCard(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Wallet',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            WalletScreen(controller: controller),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickCard(
                    icon: Icons.local_offer_rounded,
                    title: 'Offers',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            OffersScreen(controller: controller),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickCard(
                    icon: Icons.card_giftcard_rounded,
                    title: 'Refer & Earn',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ReferralScreen(controller: controller),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language_rounded),
                    title: const Text('Language'),
                    subtitle: Text(
                      controller.locale?.code == 'bn'
                          ? 'বাংলা'
                          : controller.locale?.code == 'hi'
                              ? 'हिंदी'
                              : 'English',
                    ),
                    trailing:
                        const Icon(Icons.chevron_right_rounded),
                    onTap: () => language(context),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.support_agent_rounded),
                    title: Text('Help & Support'),
                    subtitle: Text('Get help with rides and payments'),
                    trailing: Icon(Icons.chevron_right_rounded),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.report_problem_outlined,
                      color: AstrideColors.orange,
                    ),
                    title: const Text('Report an issue'),
                    subtitle: const Text(
                      'Send a report to ASTRIDE support',
                    ),
                    trailing:
                        const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReportIssueScreen(
                          controller: controller,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => logout(context),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log out'),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AstrideColors.border),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Icon(icon, color: AstrideColors.greenDark),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AstrideColors.navy,
                ),
              ),
            ],
          ),
        ),
      );
}
