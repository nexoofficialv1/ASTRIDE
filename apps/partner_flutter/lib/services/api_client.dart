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

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final response = await _client
          .get(_uri(path), headers: _headers())
          .timeout(AppConfig.requestTimeout);
      return _decode(response);
    } on SocketException {
      throw ApiException('Unable to connect to the ASTRIDE server.');
    } on HttpException {
      throw ApiException('The server connection was interrupted.');
    } on FormatException {
      throw ApiException('The server returned an invalid response.');
    }
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client
          .post(
            _uri(path),
            headers: _headers(),
            body: jsonEncode(body),
          )
          .timeout(AppConfig.requestTimeout);
      return _decode(response);
    } on SocketException {
      throw ApiException('Unable to connect to the ASTRIDE server.');
    } on HttpException {
      throw ApiException('The server connection was interrupted.');
    } on FormatException {
      throw ApiException('The server returned an invalid response.');
    }
  }

  Future<Map<String, dynamic>> putJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client
          .put(_uri(path), headers: _headers(), body: jsonEncode(body))
          .timeout(AppConfig.requestTimeout);
      return _decode(response);
    } on SocketException {
      throw ApiException('Unable to connect to the ASTRIDE server.');
    }
  }

  Future<Map<String, dynamic>> patchJson(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _client
          .patch(_uri(path), headers: _headers(), body: jsonEncode(body))
          .timeout(AppConfig.requestTimeout);
      return _decode(response);
    } on SocketException {
      throw ApiException('Unable to connect to the ASTRIDE server.');
    }
  }

  Uri _uri(String path) {
    final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalizedPath');
  }

  Map<String, String> _headers() => {
        'content-type': 'application/json',
        'accept': 'application/json',
        if (token != null && token!.isNotEmpty)
          'authorization': 'Bearer $token',
      };

  Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> data = <String, dynamic>{};

    if (response.body.isNotEmpty) {
      final decoded = jsonDecode(response.body);
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
              'Request failed')
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
