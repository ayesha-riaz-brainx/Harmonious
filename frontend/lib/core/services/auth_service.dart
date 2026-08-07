import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:slot_1_tasks/core/config/api_config.dart';
import 'package:slot_1_tasks/core/config/supabase_config.dart';

class AuthResult {
  const AuthResult._({
    required this.success,
    required this.message,
    this.signedIn = false,
    this.user,
  });

  factory AuthResult.success({
    required String message,
    bool signedIn = true,
    Map<String, dynamic>? user,
  }) {
    return AuthResult._(
      success: true,
      message: message,
      signedIn: signedIn,
      user: user,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(success: false, message: message);
  }

  final bool success;
  final bool signedIn;
  final String message;
  final Map<String, dynamic>? user;
}

class AuthService {
  AuthService({this._client});

  final SupabaseClient? _client;

  SupabaseClient get _supabase {
    try {
      return _client ?? Supabase.instance.client;
    } catch (_) {
      throw StateError(
        'Supabase is still starting. Wait a moment and try again.',
      );
    }
  }

  User? get currentUser {
    if (!SupabaseConfig.isConfigured) return null;
    try {
      return _supabase.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Session? get currentSession {
    if (!SupabaseConfig.isConfigured) return null;
    try {
      return _supabase.auth.currentSession;
    } catch (_) {
      return null;
    }
  }

  bool get isLoggedIn => currentSession != null;

  Stream<AuthState> get authStateChanges {
    if (!SupabaseConfig.isConfigured) {
      return const Stream.empty();
    }
    return _supabase.auth.onAuthStateChange;
  }

  Future<void> ensureInitialized() async {
    // supabase_flutter restores session from secure storage automatically
    // after Supabase.initialize. Give it a brief moment if needed.
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  String _mapError(Object error) {
    final text = error.toString();
    final lower = text.toLowerCase();

    if (error is SocketException ||
        lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('failed host lookup') ||
        lower.contains('clientexception')) {
      return 'No internet connection. Please try again.';
    }

    if (lower.contains('rate limit') ||
        lower.contains('over_email_send_rate_limit') ||
        lower.contains('email rate limit')) {
      return 'Too many signup emails sent. In Supabase → Authentication → Providers → Email, turn off “Confirm email”, wait a minute, then try again.';
    }

    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('rate limit')) {
        return 'Too many signup emails sent. Turn off “Confirm email” in Supabase Auth settings, then try again.';
      }
      if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
        return 'Invalid email or password.';
      }
      if (msg.contains('already') || msg.contains('registered')) {
        return 'An account with this email already exists.';
      }
      if (msg.contains('password')) {
        return error.message;
      }
      if (msg.contains('email')) {
        return error.message;
      }
      return error.message;
    }

    // Postgrest / schema issues
    if (lower.contains('display_name') || lower.contains('column')) {
      return 'Database profile columns are missing. Run supabase/profiles_extend.sql in Supabase SQL Editor.';
    }
    if (lower.contains('row-level security') || lower.contains('rls')) {
      return 'Profile permission error. Check Supabase RLS policies on profiles.';
    }

    // Surface a useful message instead of a generic one
    if (text.isNotEmpty && text.length < 180) {
      return text.replaceFirst('Exception: ', '').replaceFirst('PostgrestException(', '').split('\n').first;
    }

    return 'Something went wrong. Please try again.';
  }

  Future<AuthResult> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      return AuthResult.failure(
        'Supabase is not configured. Add keys to frontend/.env',
      );
    }

    final trimmedName = fullName.trim();
    final trimmedEmail = email.trim().toLowerCase();

    try {
      // Prefer backend admin createUser (email_confirm, no confirmation email).
      // Avoids Supabase "email rate limit exceeded" during local testing.
      final createdViaBackend = await _signUpViaBackend(
        fullName: trimmedName,
        email: trimmedEmail,
        password: password,
      );

      if (createdViaBackend != null) {
        if (!createdViaBackend.success) {
          return createdViaBackend;
        }

        // Establish a client session so the app can navigate authenticated.
        final loginResponse = await _supabase.auth.signInWithPassword(
          email: trimmedEmail,
          password: password,
        );

        if (loginResponse.session == null || loginResponse.user == null) {
          return AuthResult.success(
            message: 'Account created. Please log in.',
            signedIn: false,
            user: createdViaBackend.user,
          );
        }

        return AuthResult.success(
          message: 'Account created successfully.',
          signedIn: true,
          user: {
            'id': loginResponse.user!.id,
            'email': loginResponse.user!.email,
            'fullName': trimmedName,
          },
        );
      }

      // Fallback: direct Supabase signup (sends confirmation email if enabled).
      return _signUpViaSupabase(
        fullName: trimmedName,
        email: trimmedEmail,
        password: password,
      );
    } catch (error) {
      return AuthResult.failure(_mapError(error));
    }
  }

  /// Returns null when the backend is unreachable so we can fall back.
  Future<AuthResult?> _signUpViaBackend({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            ApiConfig.signUp,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'fullName': fullName,
              'email': email,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 12));

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      final message = (body['message'] as String?) ?? 'Unable to create account.';

      if (response.statusCode == 201 || response.statusCode == 200) {
        final user = body['user'] as Map<String, dynamic>?;
        return AuthResult.success(
          message: message,
          signedIn: false,
          user: user,
        );
      }

      if (response.statusCode == 409) {
        return AuthResult.failure('An account with this email already exists.');
      }

      return AuthResult.failure(message);
    } on SocketException {
      return null;
    } on http.ClientException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<AuthResult> _signUpViaSupabase({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
    );

    final user = response.user;
    if (user == null) {
      return AuthResult.failure('Unable to create account. Please try again.');
    }

    if (response.session != null) {
      try {
        await _supabase.from('profiles').upsert({
          'id': user.id,
          'full_name': fullName,
          'email': email,
          'display_name': fullName,
        });
      } catch (_) {
        try {
          await _supabase.from('profiles').upsert({
            'id': user.id,
            'full_name': fullName,
            'email': email,
          });
        } catch (_) {}
      }
    }

    final signedIn = response.session != null;
    return AuthResult.success(
      message: signedIn
          ? 'Account created successfully.'
          : 'Account created. Check your email to confirm, then log in.',
      signedIn: signedIn,
      user: {
        'id': user.id,
        'email': user.email,
        'fullName': fullName,
      },
    );
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      return AuthResult.failure(
        'Supabase is not configured. Add keys to frontend/.env',
      );
    }

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = response.user;
      if (user == null || response.session == null) {
        return AuthResult.failure('Invalid email or password.');
      }

      return AuthResult.success(
        message: 'Logged in successfully.',
        user: {
          'id': user.id,
          'email': user.email,
          'fullName': user.userMetadata?['full_name'],
        },
      );
    } catch (error) {
      return AuthResult.failure(_mapError(error));
    }
  }

  Future<AuthResult> forgotPassword({required String email}) async {
    try {
      final response = await http
          .post(
            ApiConfig.forgotPassword,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim().toLowerCase()}),
          )
          .timeout(const Duration(seconds: 30));
      final body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 400) {
        return AuthResult.failure(
          body['message']?.toString() ?? 'Could not send reset code.',
        );
      }
      return AuthResult.success(
        message: body['message']?.toString() ??
            'If an account exists, a reset code was sent.',
        signedIn: false,
      );
    } catch (error) {
      return AuthResult.failure(_mapError(error));
    }
  }

  Future<AuthResult> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            ApiConfig.resetPassword,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim().toLowerCase(),
              'code': code.trim(),
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 30));
      final body = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode >= 400) {
        return AuthResult.failure(
          body['message']?.toString() ?? 'Could not reset password.',
        );
      }
      return AuthResult.success(
        message: body['message']?.toString() ?? 'Password updated.',
        signedIn: false,
      );
    } catch (error) {
      return AuthResult.failure(_mapError(error));
    }
  }

  Future<AuthResult> logout() async {
    try {
      await _supabase.auth.signOut();
      return AuthResult.success(message: 'Logged out.', signedIn: false);
    } catch (error) {
      return AuthResult.failure(_mapError(error));
    }
  }

  Future<AuthResult> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) {
        return AuthResult.failure('Session expired. Please log in again.');
      }

      // Soft-mark profile then sign out. Hard delete via backend if available.
      await _supabase.from('profiles').delete().eq('id', user.id);
      await _supabase.auth.signOut();

      return AuthResult.success(
        message:
            'Signed out and profile removed. Ask an admin to fully delete the auth user if needed, or use the backend delete endpoint.',
        signedIn: false,
      );
    } catch (error) {
      return AuthResult.failure(_mapError(error));
    }
  }
}

/// Backward-compatible alias used by older screens/tests.
typedef SignUpResult = AuthResult;
