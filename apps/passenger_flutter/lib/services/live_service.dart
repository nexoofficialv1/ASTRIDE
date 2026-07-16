import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/app_config.dart';
import 'pinned_transport.dart';

class LiveService {
  WebSocketChannel? _channel;
  Timer? _retry;
  bool _disposed = false;
  String? _bookingId;
  String? _token;

  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _events.stream;

  void connect(String bookingId, String token) {
    _bookingId = bookingId;
    _token = token;
    _open();
  }

  void _open() {
    final bookingId = _bookingId;
    final token = _token;
    if (_disposed || bookingId == null || token == null || token.isEmpty) {
      return;
    }
    _closeSocket();
    try {
      final base = AppConfig.wsBaseUrl.replaceAll(RegExp(r'/+$'), '');
      final uri = Uri.parse('$base/v1/realtime/rides/$bookingId');
      _channel = IOWebSocketChannel.connect(
        uri,
        headers: <String, dynamic>{
          'Authorization': 'Bearer $token',
        },
        pingInterval: const Duration(seconds: 20),
        connectTimeout: const Duration(seconds: 15),
        customClient: PinnedTransport.newHttpClient(),
      );
      _channel!.stream.listen(
        (message) {
          try {
            final decoded = jsonDecode('$message');
            if (decoded is Map) {
              _events.add(decoded.cast<String, dynamic>());
            }
          } catch (_) {
            // Ignore malformed realtime frames; polling remains the fallback.
          }
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed || _bookingId == null || _token == null) return;
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 3), _open);
  }

  void _closeSocket() {
    final channel = _channel;
    _channel = null;
    if (channel != null) {
      unawaited(channel.sink.close());
    }
  }

  void disconnect() {
    _bookingId = null;
    _token = null;
    _retry?.cancel();
    _retry = null;
    _closeSocket();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    disconnect();
    unawaited(_events.close());
  }
}
