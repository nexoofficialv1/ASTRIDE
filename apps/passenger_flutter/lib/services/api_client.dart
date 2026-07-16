import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/app_config.dart';
import 'pinned_transport.dart';
import 'app_attestation_service.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;
  final String? code;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? PinnedTransport.newClient();

  final http.Client _client;
  String? token;
  String? refreshToken;
  String? refreshPath;
  Future<void> Function(String accessToken, String refreshToken)?
      onTokensChanged;
  Future<bool>? _refreshInFlight;

  Future<Map<String, dynamic>> getJson(String path) => _send('GET', path);

  Future<Map<String, dynamic>> postJson(
    String path,
    Map<String, dynamic> body,
  ) =>
      _send('POST', path, body: body);

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body,
  ) =>
      _send('PUT', path, body: body);

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  ) =>
      _send('PATCH', path, body: body);

  void configureSession({
    required String accessToken,
    required String rotatingRefreshToken,
    required String endpoint,
    Future<void> Function(String accessToken, String refreshToken)? onChanged,
  }) {
    token = accessToken;
    refreshToken = rotatingRefreshToken;
    refreshPath = endpoint;
    onTokensChanged = onChanged;
  }

  void clearSession() {
    token = null;
    refreshToken = null;
    refreshPath = null;
    onTokensChanged = null;
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool allowRefresh = true,
  }) async {
    try {
      final response = await _perform(method, path, body: body);
      final canRefresh = allowRefresh &&
          response.statusCode == 401 &&
          refreshToken?.isNotEmpty == true &&
          refreshPath?.isNotEmpty == true &&
          path != refreshPath &&
          !path.endsWith('/login');
      if (canRefresh && await _refreshSession()) {
        return _send(method, path, body: body, allowRefresh: false);
      }
      return _decode(response);
    } on SocketException {
      throw ApiException('Unable to connect to the ASTRIDE server.');
    } on HttpException {
      throw ApiException('The server connection was interrupted.');
    } on TimeoutException {
      throw ApiException('The server request timed out.');
    } on FormatException {
      throw ApiException('The server returned an invalid response.');
    }
  }

  Future<http.Response> _perform(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, _uri(path));
    request.headers.addAll(await _headers());
    if (body != null) request.body = jsonEncode(body);
    final streamed = await _client.send(request).timeout(AppConfig.requestTimeout);
    return http.Response.fromStream(streamed);
  }

  Future<bool> _refreshSession() {
    final current = _refreshInFlight;
    if (current != null) return current;
    final future = _doRefresh();
    _refreshInFlight = future;
    return future.whenComplete(() => _refreshInFlight = null);
  }

  Future<bool> _doRefresh() async {
    final endpoint = refreshPath;
    final currentRefresh = refreshToken;
    if (endpoint == null || currentRefresh == null || currentRefresh.isEmpty) {
      return false;
    }
    try {
      final response = await _client
          .post(
            _uri(endpoint),
            headers: await _headers(includeAuthorization: false),
            body: jsonEncode({'refreshToken': currentRefresh}),
          )
          .timeout(AppConfig.requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) return false;
      final data = _decode(response);
      final nextAccess = (data['accessToken'] ?? data['token'] ?? '').toString();
      final nextRefresh = (data['refreshToken'] ?? '').toString();
      if (nextAccess.isEmpty || nextRefresh.isEmpty) return false;
      token = nextAccess;
      refreshToken = nextRefresh;
      await onTokensChanged?.call(nextAccess, nextRefresh);
      return true;
    } catch (_) {
      return false;
    }
  }

  Uri _uri(String path) {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalizedPath');
  }

  Future<Map<String, String>> _headers({
    bool includeAuthorization = true,
  }) async {
    final attestation = await AppAttestationService.instance.token();
    return {
      'content-type': 'application/json',
      'accept': 'application/json',
      if (includeAuthorization && token != null && token!.isNotEmpty)
        'authorization': 'Bearer $token',
      if (attestation != null && attestation.isNotEmpty)
        'X-Firebase-AppCheck': attestation,
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> data = <String, dynamic>{};
    final body = response.body.trim();
    if (body.isNotEmpty) {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        data = decoded.cast<String, dynamic>();
      } else {
        throw ApiException(
          'The server returned an unexpected response.',
          statusCode: response.statusCode,
        );
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = (data['message'] ??
              data['error_description'] ??
              data['detail'] ??
              data['error'] ??
              'Request failed (${response.statusCode})')
          .toString();
      throw ApiException(
        message,
        statusCode: response.statusCode,
        code: data['error']?.toString(),
      );
    }
    return data;
  }

  void close() => _client.close();
}
