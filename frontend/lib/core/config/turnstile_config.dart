import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Cloudflare Turnstile site key (public) from `frontend/.env`.
class TurnstileConfig {
  const TurnstileConfig._();

  static String? get siteKey {
    try {
      final value = dotenv.env['TURNSTILE_SITE_KEY']?.trim();
      if (value == null || value.isEmpty || value.contains('PASTE_YOUR_')) {
        return null;
      }
      return value;
    } catch (_) {
      return null;
    }
  }

  static bool get isConfigured => siteKey != null;
}
