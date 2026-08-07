import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:slot_1_tasks/app/app.dart';
import 'package:slot_1_tasks/core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');

  if (SupabaseConfig.isConfigured) {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      publishableKey: SupabaseConfig.anonKey,
    );
  } else {
    debugPrint(
      '⚠️  Supabase keys missing. Paste SUPABASE_URL and '
      'SUPABASE_ANON_KEY into frontend/.env',
    );
  }

  runApp(const Slot1TasksApp());
}
