import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:slot_1_tasks/core/config/supabase_config.dart';
import 'package:slot_1_tasks/core/services/auth_service.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    this.fullName,
    this.displayName,
    this.email,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.country,
    this.weightUnit = 'kg',
    this.heightUnit = 'cm',
    this.profileSetupCompleted = false,
    this.onboardingCompleted = false,
    this.aiProfile,
    this.zodiacSign,
    this.birthday,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? ai;
    final rawAi = json['ai_profile'];
    if (rawAi is Map) {
      ai = Map<String, dynamic>.from(rawAi);
    }

    return UserProfile(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      displayName: json['display_name'] as String?,
      email: json['email'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      country: json['country'] as String?,
      weightUnit: (json['weight_unit'] as String?) ?? 'kg',
      heightUnit: (json['height_unit'] as String?) ?? 'cm',
      profileSetupCompleted: json['profile_setup_completed'] == true,
      onboardingCompleted: json['onboarding_completed'] == true,
      aiProfile: ai,
      zodiacSign: json['zodiac_sign'] as String?,
      birthday: json['birthday'] != null
          ? DateTime.tryParse(json['birthday'].toString())
          : null,
    );
  }

  final String id;
  final String? fullName;
  final String? displayName;
  final String? email;
  final int? age;
  final String? gender;
  final double? height;
  final double? weight;
  final String? country;
  final String weightUnit;
  final String heightUnit;
  final bool profileSetupCompleted;
  final bool onboardingCompleted;
  final Map<String, dynamic>? aiProfile;
  final String? zodiacSign;
  final DateTime? birthday;
}

class ProfileService {
  ProfileService({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  String _mapSaveError(Object error) {
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
    return 'Unable to save profile. Please try again.';
  }

  Future<UserProfile?> fetchCurrentProfile() async {
    if (!SupabaseConfig.isConfigured) return null;
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(Map<String, dynamic>.from(response));
  }

  Future<AuthResult> saveProfileSetup({
    required String displayName,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? country,
    required String weightUnit,
    required String heightUnit,
    bool markCompleted = true,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return AuthResult.failure('Session expired. Please log in again.');
      }

      final payload = <String, dynamic>{
        'id': user.id,
        'email': user.email,
        'display_name': displayName.trim(),
        'full_name': displayName.trim(),
        'weight_unit': weightUnit,
        'height_unit': heightUnit,
        'profile_setup_completed': markCompleted,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (age != null) payload['age'] = age;
      if (gender != null && gender.isNotEmpty) payload['gender'] = gender;
      if (height != null) payload['height'] = height;
      if (weight != null) payload['weight'] = weight;
      if (country != null && country.isNotEmpty) payload['country'] = country;

      await _supabase.from('profiles').upsert(payload);

      return AuthResult.success(message: 'Profile saved.');
    } catch (error) {
      return AuthResult.failure(_mapSaveError(error));
    }
  }
}
