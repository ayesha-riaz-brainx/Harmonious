import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:slot_1_tasks/app/app.dart';
import 'package:slot_1_tasks/core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  if (SupabaseConfig.isConfigured) {
    // Implicit flow: email confirm opens the web landing page, then the user
    // signs in in the app. PKCE is for deep-link OAuth, not this flow.
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.implicit,
      ),
    );
  } else {
    debugPrint(
      '⚠️  Supabase keys missing. Paste SUPABASE_URL and '
      'SUPABASE_ANON_KEY into frontend/.env',
    );
  }

  runApp(const Slot1TasksApp());
}
