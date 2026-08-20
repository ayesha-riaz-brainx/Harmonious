import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:slot_1_tasks/core/config/api_config.dart';

class FeatureService {
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await http
        .get(
          ApiConfig.feature(path, query: query),
          headers: ApiConfig.authHeaders(),
        )
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
    final body = _parseBody(response);
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? _statusMessage(response.statusCode));
    }
    return body;
  }

  Map<String, dynamic> _parseBody(http.Response response) {
    if (response.body.isEmpty) return {};

    final trimmed = response.body.trimLeft();
    final contentType = response.headers['content-type']?.toLowerCase() ?? '';
    final looksJson =
        trimmed.startsWith('{') || trimmed.startsWith('[');
    final isJson = contentType.contains('json') || looksJson;

    if (!isJson) {
      throw Exception(_nonJsonMessage(response));
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw const FormatException('Expected JSON object');
    } on FormatException {
      throw Exception(
        'Server returned an unexpected response. Try again or enter calories manually.',
      );
    }
  }

  String _nonJsonMessage(http.Response response) {
    if (response.statusCode == 404) {
      return 'This feature is not available on the server. '
          'Restart the backend or enter calories manually.';
    }
    if (response.statusCode >= 500) {
      return 'Server error (${response.statusCode}). Try again in a moment.';
    }
    return 'Could not reach the server. Check your connection and try again.';
  }

  String _statusMessage(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Session expired. Please log in again.';
      case 503:
        return 'Service temporarily unavailable.';
      default:
        return 'Request failed ($statusCode).';
    }
  }
}
