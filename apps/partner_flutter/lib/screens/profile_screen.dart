import 'package:flutter/material.dart';
import '../state/partner_controller.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.c});
  final PartnerController c;

  @override
  Widget build(BuildContext context) {
    final s = c.strings;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              const CircleAvatar(radius: 38, child: Icon(Icons.handshake_rounded, size: 36)),
              const SizedBox(height: 10),
              Text(c.session?.name ?? 'Partner', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              Text(c.session?.role == 'AREA_PROMOTER' ? s.t('areaDashboard') : s.t('promoterDashboard')),
              const SizedBox(height: 8),
              Text(s.t('scopeNote'), textAlign: TextAlign.center),
            ]),
          ),
        ),
        const SizedBox(height: 14),
        Card(
          child: Column(children: [
            ListTile(leading: const Icon(Icons.badge_rounded), title: Text(s.t('role')), trailing: Text(c.session?.role ?? '-')),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.language_rounded),
              title: Text(s.t('language')),
              trailing: DropdownButton<String>(
                value: c.languageCode,
                underline: const SizedBox.shrink(),
                items: const [DropdownMenuItem(value: 'en', child: Text('English')), DropdownMenuItem(value: 'bn', child: Text('বাংলা')), DropdownMenuItem(value: 'hi', child: Text('हिंदी'))],
                onChanged: (v) { if (v != null) c.setLanguage(v); },
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(onPressed: c.logout, icon: const Icon(Icons.logout_rounded), label: Text(s.t('logout'))),
      ],
    );
  }
}
