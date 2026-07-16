import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class PinnedTransport {
  PinnedTransport._();

  static SecurityContext? _context;
  static bool _initialized = false;
  static String? initializationError;

  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      final data = await rootBundle.load(
        'assets/security/astride_api_chain.pem',
      );
      final bytes = Uint8List.sublistView(data);
      final text = String.fromCharCodes(bytes);
      if (!text.contains('-----BEGIN CERTIFICATE-----')) {
        throw const FormatException('api_certificate_bundle_missing');
      }
      final context = SecurityContext(withTrustedRoots: false);
      context.setTrustedCertificatesBytes(bytes);
      _context = context;
    } catch (error) {
      initializationError = '$error';
      if (kReleaseMode ||
          const bool.fromEnvironment(
            'ASTRIDE_CERT_PINNING_REQUIRED',
            defaultValue: false,
          )) {
        rethrow;
      }
    }
  }

  static HttpClient newHttpClient() {
    final context = _context;
    final client = context == null
        ? HttpClient()
        : HttpClient(context: context);
    client.connectionTimeout = const Duration(seconds: 20);
    client.idleTimeout = const Duration(seconds: 15);
    return client;
  }

  static http.Client newClient() => IOClient(newHttpClient());

  static bool get pinningActive => _context != null;
}
