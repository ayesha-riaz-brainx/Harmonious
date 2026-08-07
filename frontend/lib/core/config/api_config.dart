import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApiConfig {
  const ApiConfig._();

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000';
    }

    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000';
    }

    return 'http://localhost:3000';
  }

  static Uri get signUp => Uri.parse('$baseUrl/api/auth/signup');
  static Uri get forgotPassword =>
      Uri.parse('$baseUrl/api/auth/forgot-password');
  static Uri get resetPassword =>
      Uri.parse('$baseUrl/api/auth/reset-password');
  static Uri get homeToday => Uri.parse('$baseUrl/api/home/today');
  static Uri get homeRefreshAi =>
      Uri.parse('$baseUrl/api/home/today/refresh-ai');
  static Uri get onboardingAiSummary =>
      Uri.parse('$baseUrl/api/onboarding/ai-summary');
  static Uri feature(String path) =>
      Uri.parse('$baseUrl/api/features/$path');

  static Map<String, String> authHeaders() {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }
}
