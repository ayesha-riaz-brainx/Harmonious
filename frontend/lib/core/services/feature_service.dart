import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:slot_1_tasks/core/config/api_config.dart';

class FeatureService {
  Future<Map<String, dynamic>> get(String path) async {
    final response = await http
        .get(ApiConfig.feature(path), headers: ApiConfig.authHeaders())
        .timeout(const Duration(seconds: 40));
    return _decode(response);
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          ApiConfig.feature(path),
          headers: ApiConfig.authHeaders(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));
    return _decode(response);
  }

  Future<Map<String, dynamic>> patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .patch(
          ApiConfig.feature(path),
          headers: ApiConfig.authHeaders(),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 40));
    return _decode(response);
  }

  Future<Map<String, dynamic>> delete(String path) async {
    final response = await http
        .delete(ApiConfig.feature(path), headers: ApiConfig.authHeaders())
        .timeout(const Duration(seconds: 30));
    return _decode(response);
  }

  Map<String, dynamic> _decode(http.Response response) {
    final body = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Request failed.');
    }
    return body;
  }
}
