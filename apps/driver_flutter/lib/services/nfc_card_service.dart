import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nfc_manager/nfc_manager.dart';

class NfcCardService {
  const NfcCardService();

  Future<bool> isAvailable() async {
    final availability = await NfcManager.instance.checkAvailability();
    return availability == NfcAvailability.enabled;
  }

  Future<String> readAstrideCredential({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (!await isAvailable()) {
      throw StateError('NFC is unavailable or switched off on this phone.');
    }
    final result = Completer<String>();
    Timer? timer;
    try {
      timer = Timer(timeout, () {
        if (!result.isCompleted) {
          result.completeError(TimeoutException('No ASTRIDE card was detected.'));
          unawaited(NfcManager.instance.stopSession(errorMessageIos: 'Card scan timed out.'));
        }
      });
      await NfcManager.instance.startSession(
        pollingOptions: const {NfcPollingOption.iso14443},
        invalidateAfterFirstReadIos: true,
        onDiscovered: (tag) async {
          try {
            final credential = _findCredential(tag.data);
            if (credential == null) {
              throw const FormatException('This is not a provisioned ASTRIDE card.');
            }
            await NfcManager.instance.stopSession(
              alertMessageIos: 'ASTRIDE card read successfully.',
            );
            if (!result.isCompleted) result.complete(credential);
          } catch (error) {
            await NfcManager.instance.stopSession(
              errorMessageIos: 'ASTRIDE card could not be verified.',
            );
            if (!result.isCompleted) result.completeError(error);
          }
        },
        onSessionErrorIos: (error) {
          if (!result.isCompleted) result.completeError(StateError('$error'));
        },
      );
      return await result.future;
    } finally {
      timer?.cancel();
    }
  }

  String? _findCredential(Object? value) {
    const marker = 'ASTRIDE_CARD_V1:';
    String? inspectText(String text) {
      final index = text.indexOf(marker);
      if (index < 0) return null;
      final tail = text.substring(index + marker.length);
      final match = RegExp(r'^[A-Za-z0-9_-]{32,256}').firstMatch(tail);
      return match?.group(0);
    }

    String? walk(Object? node, int depth) {
      if (node == null || depth > 12) return null;
      if (node is String) return inspectText(node);
      if (node is Uint8List) {
        try {
          return inspectText(utf8.decode(node, allowMalformed: true));
        } catch (_) {
          return null;
        }
      }
      if (node is List<int>) {
        try {
          return inspectText(utf8.decode(node, allowMalformed: true));
        } catch (_) {
          return null;
        }
      }
      if (node is Map) {
        for (final entry in node.entries) {
          final found = walk(entry.value, depth + 1);
          if (found != null) return found;
        }
      } else if (node is Iterable) {
        for (final item in node) {
          final found = walk(item, depth + 1);
          if (found != null) return found;
        }
      }
      return null;
    }

    return walk(value, 0);
  }
}
