import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_client.dart';

class SecureChatMessage {
  const SecureChatMessage({
    required this.id,
    required this.senderType,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.decrypted,
  });

  final String id;
  final String senderType;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool decrypted;
}

class SecureChatService {
  SecureChatService({
    required this.api,
    required this.bookingId,
    required this.actorType,
    required this.actorId,
  });

  final ApiClient api;
  final String bookingId;
  final String actorType;
  final String actorId;

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static final _x25519 = X25519();
  static final _aes = AesGcm.with256bits();
  static final _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static final _sha256 = Sha256();

  SimpleKeyPairData? _localKeyPair;
  String? _localKeyId;
  List<Map<String, dynamic>> _keys = const [];
  Map<String, dynamic>? _trustedPeer;
  bool _peerKeyChanged = false;
  String? _safetyCode;

  String get _storageKey => 'astride.secure-chat.identity.$actorType.$actorId';
  String get _peerTrustStorageKey =>
      'astride.secure-chat.peer.$bookingId.$actorType.$actorId';

  bool get peerReady => _trustedPeer != null && !_peerKeyChanged;
  bool get peerKeyChanged => _peerKeyChanged;
  String? get safetyCode => _safetyCode;

  Future<void> initialize() async {
    await _loadOrCreateIdentity();
    await api.postJson('/v1/communications/bookings/$bookingId/keys', {
      'keyId': _localKeyId,
      'publicKey': _encode(_localKeyPair!.publicKey.bytes),
      'algorithm': 'X25519',
    });
    await refreshKeys();
  }

  Future<void> refreshKeys() async {
    final response = await api.getJson(
      '/v1/communications/bookings/$bookingId/keys',
    );
    _keys = ((response['items'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
    await _verifyPeerContinuity();
  }

  Future<SecureChatMessage> send(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) throw ApiException('Message cannot be empty.');
    if (clean.length > 4000) throw ApiException('Message is too long.');
    await refreshKeys();
    if (_peerKeyChanged) {
      throw ApiException(
        'The peer encryption identity changed. Stop the ride communication and contact ASTRIDE support.',
      );
    }
    final peer = _trustedPeer;
    if (peer == null) {
      throw ApiException(
        'Secure chat is waiting for the other device to establish encryption.',
      );
    }
    final clientMessageId =
        'local_${DateTime.now().microsecondsSinceEpoch}_${_randomId(8)}';
    final senderKeyId = _localKeyId!;
    final recipientKeyId = '${peer['keyId']}';
    final aad = _aad(
      actorType,
      actorId,
      clientMessageId,
      senderKeyId,
      recipientKeyId,
    );
    final key = await _sharedKey(peer);
    final nonce = _randomBytes(12);
    final box = await _aes.encrypt(
      utf8.encode(clean),
      secretKey: key,
      nonce: nonce,
      aad: aad,
    );
    final response = await api.postJson(
      '/v1/communications/bookings/$bookingId/messages',
      {
        'clientMessageId': clientMessageId,
        'envelope': {
          'algorithm': 'X25519-HKDF-SHA256-AES-256-GCM',
          'ciphertext': _encode(box.cipherText),
          'nonce': _encode(box.nonce),
          'mac': _encode(box.mac.bytes),
          'senderKeyId': senderKeyId,
          'recipientKeyId': recipientKeyId,
          'aadVersion': 2,
        },
      },
    );
    final item = (response['item'] as Map).cast<String, dynamic>();
    return SecureChatMessage(
      id: '${item['id']}',
      senderType: actorType,
      senderId: actorId,
      text: clean,
      createdAt: DateTime.tryParse('${item['createdAt']}') ?? DateTime.now(),
      decrypted: true,
    );
  }

  Future<List<SecureChatMessage>> list({DateTime? after}) async {
    await refreshKeys();
    final suffix = after == null
        ? ''
        : '?after=${Uri.encodeQueryComponent(after.toUtc().toIso8601String())}';
    final response = await api.getJson(
      '/v1/communications/bookings/$bookingId/messages$suffix',
    );
    final items = ((response['items'] as List?) ?? const [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>());
    final output = <SecureChatMessage>[];
    for (final item in items) {
      try {
        output.add(await _decrypt(item));
      } catch (_) {
        output.add(SecureChatMessage(
          id: '${item['id']}',
          senderType: '${item['senderType']}',
          senderId: '${item['senderId']}',
          text: 'Unable to decrypt this secure message.',
          createdAt: DateTime.tryParse('${item['createdAt']}') ?? DateTime.now(),
          decrypted: false,
        ));
      }
    }
    return output;
  }

  Future<Map<String, dynamic>> requestSecureCall() => api.postJson(
        '/v1/communications/bookings/$bookingId/call-sessions',
        {'mode': 'IN_APP_RELAY'},
      );

  Future<SecureChatMessage> _decrypt(Map<String, dynamic> item) async {
    if (_peerKeyChanged) throw StateError('peer_key_changed');
    final senderType = '${item['senderType']}';
    final senderId = '${item['senderId']}';
    final clientMessageId = '${item['clientMessageId']}';
    final envelope = (item['envelope'] as Map).cast<String, dynamic>();
    final senderKeyId = '${envelope['senderKeyId']}';
    final recipientKeyId = '${envelope['recipientKeyId']}';
    final isMine = senderType == actorType && senderId == actorId;
    if (!isMine && recipientKeyId != _localKeyId) {
      throw StateError('message_recipient_key_mismatch');
    }
    Map<String, dynamic>? remote;
    if (isMine) {
      remote = _trustedPeer;
    } else {
      remote = _keys.cast<Map<String, dynamic>?>().firstWhere(
            (entry) => entry?['keyId'] == senderKeyId,
            orElse: () => null,
          );
    }
    if (remote == null) throw StateError('peer_key_missing');
    final key = await _sharedKey(remote);
    final box = SecretBox(
      _decode('${envelope['ciphertext']}'),
      nonce: _decode('${envelope['nonce']}'),
      mac: Mac(_decode('${envelope['mac']}')),
    );
    final clear = await _aes.decrypt(
      box,
      secretKey: key,
      aad: _aad(
        senderType,
        senderId,
        clientMessageId,
        senderKeyId,
        recipientKeyId,
      ),
    );
    return SecureChatMessage(
      id: '${item['id']}',
      senderType: senderType,
      senderId: senderId,
      text: utf8.decode(clear),
      createdAt: DateTime.tryParse('${item['createdAt']}') ?? DateTime.now(),
      decrypted: true,
    );
  }

  Future<SecretKey> _sharedKey(Map<String, dynamic> remote) async {
    final remotePublic = SimplePublicKey(
      _decode('${remote['publicKey']}'),
      type: KeyPairType.x25519,
    );
    final shared = await _x25519.sharedSecretKey(
      keyPair: _localKeyPair!,
      remotePublicKey: remotePublic,
    );
    return _hkdf.deriveKey(
      secretKey: shared,
      nonce: utf8.encode('ASTRIDE:$bookingId'),
      info: utf8.encode('secure-chat-v2'),
    );
  }

  Map<String, dynamic>? _latestPeerKey() {
    for (final item in _keys.reversed) {
      if ('${item['actorType']}' != actorType || '${item['actorId']}' != actorId) {
        return item;
      }
    }
    return null;
  }

  Future<void> _verifyPeerContinuity() async {
    final current = _latestPeerKey();
    if (current == null) {
      _trustedPeer = null;
      _safetyCode = null;
      return;
    }
    final stored = await _storage.read(key: _peerTrustStorageKey);
    if (stored == null || stored.isEmpty) {
      await _storage.write(
        key: _peerTrustStorageKey,
        value: jsonEncode({
          'keyId': '${current['keyId']}',
          'publicKey': '${current['publicKey']}',
          'trustedAt': DateTime.now().toUtc().toIso8601String(),
        }),
      );
      _trustedPeer = current;
      _peerKeyChanged = false;
    } else {
      final pinned = (jsonDecode(stored) as Map).cast<String, dynamic>();
      _peerKeyChanged = '${pinned['publicKey']}' != '${current['publicKey']}';
      _trustedPeer = _peerKeyChanged ? null : current;
    }
    _safetyCode = _peerKeyChanged || _trustedPeer == null
        ? null
        : await _calculateSafetyCode(_trustedPeer!);
  }

  Future<String> _calculateSafetyCode(Map<String, dynamic> peer) async {
    final local = _localKeyPair!.publicKey.bytes;
    final remote = _decode('${peer['publicKey']}');
    final first = _lexicographicCompare(local, remote) <= 0 ? local : remote;
    final second = identical(first, local) ? remote : local;
    final digest = await _sha256.hash([
      ...utf8.encode('ASTRIDE-SAFETY-CODE|$bookingId|'),
      ...first,
      ...second,
    ]);
    final hex = digest.bytes.take(8).map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    final number = BigInt.parse(hex, radix: 16) % BigInt.from(1000000000000);
    final digits = number.toString().padLeft(12, '0');
    return '${digits.substring(0, 4)} ${digits.substring(4, 8)} ${digits.substring(8, 12)}';
  }

  static int _lexicographicCompare(List<int> left, List<int> right) {
    final length = min(left.length, right.length);
    for (var index = 0; index < length; index += 1) {
      final comparison = left[index].compareTo(right[index]);
      if (comparison != 0) return comparison;
    }
    return left.length.compareTo(right.length);
  }

  List<int> _aad(
    String senderType,
    String senderId,
    String clientMessageId,
    String senderKeyId,
    String recipientKeyId,
  ) =>
      utf8.encode(
        '$bookingId|$senderType|$senderId|$clientMessageId|$senderKeyId|$recipientKeyId|2',
      );

  Future<void> _loadOrCreateIdentity() async {
    final stored = await _storage.read(key: _storageKey);
    if (stored != null && stored.isNotEmpty) {
      final data = (jsonDecode(stored) as Map).cast<String, dynamic>();
      final publicKey = SimplePublicKey(
        _decode('${data['publicKey']}'),
        type: KeyPairType.x25519,
      );
      _localKeyPair = SimpleKeyPairData(
        _decode('${data['privateKey']}'),
        publicKey: publicKey,
        type: KeyPairType.x25519,
      );
      _localKeyId = '${data['keyId']}';
      return;
    }
    final generated = await _x25519.newKeyPair();
    final privateBytes = await generated.extractPrivateKeyBytes();
    final publicKey = await generated.extractPublicKey();
    final keyId = 'x25519_${_randomId(18)}';
    _localKeyPair = SimpleKeyPairData(
      privateBytes,
      publicKey: publicKey,
      type: KeyPairType.x25519,
    );
    _localKeyId = keyId;
    await _storage.write(
      key: _storageKey,
      value: jsonEncode({
        'keyId': keyId,
        'privateKey': _encode(privateBytes),
        'publicKey': _encode(publicKey.bytes),
      }),
    );
  }

  static Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }

  static String _randomId(int bytes) => _encode(_randomBytes(bytes));
  static String _encode(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');
  static Uint8List _decode(String input) {
    final normalized = input.padRight((input.length + 3) ~/ 4 * 4, '=');
    return Uint8List.fromList(base64Url.decode(normalized));
  }
}
