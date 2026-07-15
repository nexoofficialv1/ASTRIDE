import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../core/app_config.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.code});
  final String message;
  final int? statusCode;
  final String? code;
  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  String? token;

  Future<Map<String, dynamic>> getJson(String path) => _send('GET', path);
  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) =>
      _send('POST', path, body: body);
  Future<Map<String, dynamic>> patchJson(String path, Map<String, dynamic> body) =>
      _send('PATCH', path, body: body);

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final request = http.Request(method, _uri(path));
      request.headers.addAll(_headers());
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _client.send(request).timeout(AppConfig.requestTimeout);
      final response = await http.Response.fromStream(streamed);
      return _decode(response);
    } on SocketException {
      throw ApiException('ASTRIDE server-এর সঙ্গে সংযোগ করা যাচ্ছে না।');
    } on HttpException {
      throw ApiException('Server connection interrupted.');
    } on FormatException {
      throw ApiException('Server invalid response পাঠিয়েছে।');
    }
  }

  Uri _uri(String path) {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final normalized = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalized');
  }

  Map<String, String> _headers() => {
        'content-type': 'application/json',
        'accept': 'application/json',
        if (token != null && token!.isNotEmpty) 'authorization': 'Bearer $token',
      };

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> data = <String, dynamic>{};
    final body = response.body.trim();
    if (body.isNotEmpty) {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        data = decoded.cast<String, dynamic>();
      } else {
        throw ApiException(
          'Unexpected server response.',
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
