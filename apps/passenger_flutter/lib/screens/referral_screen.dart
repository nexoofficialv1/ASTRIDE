import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../design/astride_theme.dart';
import '../state/passenger_controller.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key, required this.controller});
  final PassengerController controller;

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  late Future<Map<String, dynamic>> future;
  final applyCode = TextEditingController();

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final profile = await widget.controller.referral();
    final rewards = await widget.controller.referralRewards();
    final history = await widget.controller.referralHistory();
    return {
      'profile': profile['referral'] ?? profile,
      'rewards': rewards,
      'history': history['items'] ?? const [],
    };
  }

  Future<void> _refresh() async {
    setState(() => future = _load());
    await future;
  }

  String money(dynamic paise) =>
      '₹${((num.tryParse('$paise') ?? 0) / 100).toStringAsFixed(2)}';

  @override
  void dispose() {
    applyCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Refer & Earn')),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<Map<String, dynamic>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return ListView(
                  children: const [
                    SizedBox(height: 260),
                    Center(child: CircularProgressIndicator()),
                  ],
                );
              }
              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 160),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('Try again'),
                    ),
                  ],
                );
              }

              final data = snapshot.data ?? const {};
              final profile =
                  ((data['profile'] ?? const {}) as Map).cast<String, dynamic>();
              final rewards =
                  ((data['rewards'] ?? const {}) as Map).cast<String, dynamic>();
              final history = (data['history'] ?? const []) as List;
              final code = '${profile['code'] ?? ''}';
              final link = '${profile['shareLink'] ?? ''}';

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
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
                        const Icon(
                          Icons.card_giftcard_rounded,
                          size: 54,
                          color: AstrideColors.green,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Invite friends. Earn rewards.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  code,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w900,
                                    color: AstrideColors.navy,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: code),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Referral code copied'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy_rounded),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: code.isEmpty
                              ? null
                              : () async {
                                  // ignore: deprecated_member_use
                                  await Share.share(
                                    'Join ASTRIDE with my referral code $code\n$link',
                                  );
                                },
                          icon: const Icon(Icons.share_rounded),
                          label: const Text('Share invite'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          label: 'Invited',
                          value: '${profile['totalInvited'] ?? 0}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Stat(
                          label: 'Completed',
                          value: '${profile['completed'] ?? 0}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          label: 'Earned',
                          value: money(rewards['earnedRewardPaise']),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _Stat(
                          label: 'Pending',
                          value: money(rewards['pendingRewardPaise']),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Have a referral code?',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AstrideColors.navy,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: applyCode,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'Enter referral code',
                              prefixIcon: Icon(Icons.confirmation_number_outlined),
                            ),
                          ),
                          const SizedBox(height: 10),
                          FilledButton(
                            onPressed: () async {
                              try {
                                await widget.controller.applyReferral(
                                  applyCode.text,
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Referral code applied'),
                                  ),
                                );
                                await _refresh();
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },
                            child: const Text('Apply code'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Referral activity',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AstrideColors.navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (history.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('No referrals yet')),
                      ),
                    )
                  else
                    for (final raw in history.whereType<Map>())
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: AstrideColors.successTint,
                            child: Icon(
                              Icons.person_add_alt_1_rounded,
                              color: AstrideColors.greenDark,
                            ),
                          ),
                          title: Text(
                            '${raw['referredMobile'] ?? raw['referredPassengerId'] ?? 'Passenger'}',
                          ),
                          subtitle: Text('${raw['status'] ?? ''}'),
                          trailing: Text(
                            money(raw['referrerRewardPaise']),
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AstrideColors.navy,
                ),
              ),
              const SizedBox(height: 5),
              Text(label, style: const TextStyle(color: AstrideColors.muted)),
            ],
          ),
        ),
      );
}
