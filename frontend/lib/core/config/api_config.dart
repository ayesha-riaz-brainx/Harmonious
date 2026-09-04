import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiConfig {
  const ApiConfig._();

  /// Public backend base URL for store / device builds.
  /// Set in `frontend/.env`, e.g. `API_BASE_URL=https://api.yourdomain.com`
  /// (no trailing slash).
  static String? _envBaseUrl() {
    try {
      final raw = dotenv.env['API_BASE_URL']?.trim();
      if (raw == null || raw.isEmpty || raw.contains('PASTE_YOUR_')) {
        return null;
      }
      return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
    } catch (_) {
      return null;
    }
  }

  /// Emulator / local-dev fallbacks only. Store builds must set API_BASE_URL.
  static String get _localDevBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  static String get baseUrl {
    final configured = _envBaseUrl();
    if (configured != null) return configured;

    assert(() {
      debugPrint(
        'ApiConfig: API_BASE_URL missing in .env — using local backend '
        '($_localDevBaseUrl). Store / physical-device builds will fail '
        'to load the dashboard until you set a public HTTPS API URL.',
      );
      return true;
    }());

    return _localDevBaseUrl;
  }

  static bool get hasProductionBaseUrl => _envBaseUrl() != null;

  /// Landing page after Supabase email confirmation (hosted on the API).
  static String get emailConfirmedPageUrl =>
      '$baseUrl/auth/email-confirmed';

  /// Web page where users set a new password from Supabase reset email.
  static String get passwordResetPageUrl =>
      '$baseUrl/auth/reset-password';

  static String get privacyPolicyUrl => '$baseUrl/privacy-policy.html';

  static Uri get signUp => Uri.parse('$baseUrl/api/auth/signup');
  static Uri get forgotPassword => Uri.parse('$baseUrl/api/auth/forgot-password');
  static Uri get deleteAccount => Uri.parse('$baseUrl/api/auth/account');
  static Uri get homeToday => Uri.parse('$baseUrl/api/home/today');

  static Uri feature(String path, {Map<String, String>? query}) {
    final normalized = path.startsWith('/') ? path.substring(1) : path;
    final pathOnly = normalized.split('?').first;
    final uri = Uri.parse('$baseUrl/api/features/$pathOnly');
    if (query == null || query.isEmpty) return uri;
    return uri.replace(queryParameters: query);
  }

  static Map<String, String> authHeaders() {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    final now = DateTime.now();
    final clientDate =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Client-Date': clientDate,
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
