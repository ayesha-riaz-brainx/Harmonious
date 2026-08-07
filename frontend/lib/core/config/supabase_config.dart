import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Keys live in `frontend/.env` (copy from `.env.example`).
///
/// REQUIRED KEYS (Supabase → Project Settings → API):
/// - SUPABASE_URL
/// - SUPABASE_ANON_KEY
class SupabaseConfig {
  const SupabaseConfig._();

  static String? _read(String key) {
    try {
      return dotenv.env[key]?.trim();
    } catch (_) {
      return null;
    }
  }

  static String get url {
    final value = _read('SUPABASE_URL') ?? '';
    if (value.isEmpty || value.contains('PASTE_YOUR_')) {
      throw StateError(
        'Missing SUPABASE_URL. Paste it in frontend/.env '
        '(from Supabase → Project Settings → API).',
      );
    }
    return value;
  }

  static String get anonKey {
    final value = _read('SUPABASE_ANON_KEY') ?? '';
    if (value.isEmpty || value.contains('PASTE_YOUR_')) {
      throw StateError(
        'Missing SUPABASE_ANON_KEY. Paste it in frontend/.env '
        '(from Supabase → Project Settings → API → anon public).',
      );
    }
    return value;
  }

  static bool get isConfigured {
    final url = _read('SUPABASE_URL') ?? '';
    final key = _read('SUPABASE_ANON_KEY') ?? '';
    return url.isNotEmpty &&
        key.isNotEmpty &&
        !url.contains('PASTE_YOUR_') &&
        !key.contains('PASTE_YOUR_');
  }
}
