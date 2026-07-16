import 'dart:async';

import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../services/secure_chat_service.dart';

class SecureChatScreen extends StatefulWidget {
  const SecureChatScreen({
    super.key,
    required this.api,
    required this.bookingId,
    required this.actorType,
    required this.actorId,
    required this.peerLabel,
  });

  final ApiClient api;
  final String bookingId;
  final String actorType;
  final String actorId;
  final String peerLabel;

  @override
  State<SecureChatScreen> createState() => _SecureChatScreenState();
}

class _SecureChatScreenState extends State<SecureChatScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();
  late final SecureChatService chat;
  Timer? poller;
  List<SecureChatMessage> messages = const [];
  bool loading = true;
  bool sending = false;
  String? error;

  @override
  void initState() {
    super.initState();
    chat = SecureChatService(
      api: widget.api,
      bookingId: widget.bookingId,
      actorType: widget.actorType,
      actorId: widget.actorId,
    );
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    try {
      await chat.initialize();
      await _refresh();
      poller = Timer.periodic(
        const Duration(seconds: 3),
        (_) => unawaited(_refresh(silent: true)),
      );
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _refresh({bool silent = false}) async {
    try {
      final next = await chat.list();
      if (!mounted) return;
      setState(() {
        messages = next;
        if (!silent) error = null;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) {
          scroll.animateTo(
            scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      if (!silent && mounted) setState(() => error = '$e');
    }
  }

  Future<void> _send() async {
    if (sending || input.text.trim().isEmpty) return;
    setState(() => sending = true);
    try {
      await chat.send(input.text);
      input.clear();
      await _refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  void dispose() {
    poller?.cancel();
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.peerLabel),
              const Text(
                'End-to-end encrypted',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 14),
              child: Icon(Icons.lock_outline_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              color: Theme.of(context).colorScheme.primaryContainer,
              child: const Text(
                'Message content is encrypted on this device. The ASTRIDE server stores ciphertext only.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12),
              ),
            ),
            if (chat.peerKeyChanged)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: Theme.of(context).colorScheme.errorContainer,
                child: Text(
                  'Security warning: ${widget.peerLabel} encryption identity changed. Messaging is blocked for this ride. Contact ASTRIDE support.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              )
            else if (chat.safetyCode != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Text(
                  'Security code: ${chat.safetyCode}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(error!, textAlign: TextAlign.center),
                          ),
                        )
                      : messages.isEmpty
                          ? Center(
                              child: Text(
                                chat.peerReady
                                    ? 'No secure messages yet.'
                                    : 'Waiting for ${widget.peerLabel} to open secure chat.',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              controller: scroll,
                              padding: const EdgeInsets.all(14),
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final item = messages[index];
                                final mine = item.senderType == widget.actorType &&
                                    item.senderId == widget.actorId;
                                return Align(
                                  alignment: mine
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    constraints: const BoxConstraints(maxWidth: 310),
                                    margin: const EdgeInsets.only(bottom: 9),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: mine
                                          ? Theme.of(context).colorScheme.primaryContainer
                                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(item.text),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              item.decrypted
                                                  ? Icons.lock_rounded
                                                  : Icons.warning_amber_rounded,
                                              size: 12,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              TimeOfDay.fromDateTime(item.createdAt.toLocal())
                                                  .format(context),
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: input,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 4000,
                        decoration: const InputDecoration(
                          hintText: 'Secure message',
                          counterText: '',
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: sending ? null : _send,
                      icon: sending
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
