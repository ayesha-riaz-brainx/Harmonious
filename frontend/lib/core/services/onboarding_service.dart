import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:slot_1_tasks/core/services/auth_service.dart';
import 'package:slot_1_tasks/features/onboarding/data/ai_profile_builder.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_draft.dart';

class OnboardingService {
  OnboardingService({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  String _mapError(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('jwt') ||
        text.contains('session') ||
        text.contains('not authenticated')) {
      return 'Session expired. Please sign in again.';
    }
    if (text.contains('network') ||
        text.contains('socket') ||
        text.contains('failed host lookup')) {
      return 'No internet connection. Please try again.';
    }
    return 'Unable to save onboarding. Please try again.';
  }

  Future<AuthResult> saveOnboarding({
    required OnboardingDraft draft,
    required AiProfile profile,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return AuthResult.failure('Session expired. Please log in again.');
      }

      final payload = <String, dynamic>{
        'id': user.id,
        'email': user.email,
        'onboarding_data': draft.toJson(),
        'ai_profile': profile.toJson(),
        'onboarding_completed': true,
        'profile_setup_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (draft.age != null) payload['age'] = draft.age;
      if (draft.gender != null) payload['gender'] = draft.gender;
      if (draft.height != null) payload['height'] = draft.height;
      if (draft.weight != null) payload['weight'] = draft.weight;
      if (draft.activityLevel != null) {
        payload['activity_level'] = draft.activityLevel;
      }
      if (draft.birthday != null) {
        payload['birthday'] =
            draft.birthday!.toIso8601String().split('T').first;
      }
      if (draft.zodiacSign != null && draft.zodiacSign!.isNotEmpty) {
        payload['zodiac_sign'] = draft.zodiacSign;
      }
      payload['height_unit'] = draft.heightUnit;
      payload['weight_unit'] = draft.weightUnit;

      await _supabase.from('profiles').upsert(payload);
      return AuthResult.success(message: 'Your wellness profile is ready.');
    } catch (error) {
      return AuthResult.failure(_mapError(error));
    }
  }
}
