import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/app_config.dart';
class ApiException implements Exception {ApiException(this.message,{this.statusCode});final String message;final int? statusCode;@override String toString()=>message;}
class ApiClient {
  ApiClient({http.Client? client}):_client=client??http.Client(); final http.Client _client; String? token;
  Future<Map<String,dynamic>> getJson(String path) async=>_decode(await _client.get(Uri.parse('${AppConfig.apiBaseUrl}$path'),headers:_headers()).timeout(AppConfig.requestTimeout));
  Future<Map<String,dynamic>> postJson(String path,Map<String,dynamic> body) async=>_decode(await _client.post(Uri.parse('${AppConfig.apiBaseUrl}$path'),headers:_headers(),body:jsonEncode(body)).timeout(AppConfig.requestTimeout));
  Map<String,String> _headers()=>{'content-type':'application/json','accept':'application/json',if(token!=null)'authorization':'Bearer $token'};
  Map<String,dynamic> _decode(http.Response r){final dynamic data=r.body.isEmpty?{}:jsonDecode(r.body);if(r.statusCode<200||r.statusCode>=300)throw ApiException((data is Map?data['message']:null)?.toString()??'Request failed',statusCode:r.statusCode);return (data as Map).cast<String,dynamic>();}
  void close()=>_client.close();
}
