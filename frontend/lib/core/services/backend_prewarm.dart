import 'package:http/http.dart' as http;

import 'package:slot_1_tasks/core/config/api_config.dart';

/// Best-effort ping so Render is less likely to be cold on the first API call.
/// Never throws — failures are ignored.
Future<void> prewarmBackend() async {
  try {
    await http
        .get(Uri.parse('${ApiConfig.baseUrl}/api/health'))
        .timeout(const Duration(seconds: 45));
  } catch (_) {}
}
