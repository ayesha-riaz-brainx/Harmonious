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
    this.needsEmailConfirmation = false,
    this.user,
  });

  factory AuthResult.success({
    required String message,
    bool signedIn = true,
    bool needsEmailConfirmation = false,
    Map<String, dynamic>? user,
  }) {
    return AuthResult._(
      success: true,
      message: message,
      signedIn: signedIn,
      needsEmailConfirmation: needsEmailConfirmation,
      user: user,
    );
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(success: false, message: message);
  }

  final bool success;
  final bool signedIn;
  final bool needsEmailConfirmation;
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
      if (msg.contains('rate limit') ||
          msg.contains('over_email_send_rate_limit')) {
        return 'Too many emails sent. Wait about a minute, then try Resend.';
      }
      if (msg.contains('error sending confirmation email') ||
          msg.contains('error sending') ||
          msg.contains('smtp')) {
        return 'Could not send the verification email. Check Supabase SMTP '
            '(Username must be the full Gmail address, not “Harmonious”).';
      }
      if (msg.contains('email not confirmed') ||
          msg.contains('not confirmed')) {
        return 'Please verify your email first. Open the link we sent, then sign in.';
      }
      if (msg.contains('invalid login') || msg.contains('invalid credentials')) {
        return 'Invalid email or password.';
      }
      if (msg.contains('already') || msg.contains('registered')) {
        return 'An account with this email already exists. Try signing in.';
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
      // Use Supabase Auth signup so confirmation emails are sent via SMTP
      // (Brevo). Do not use admin createUser with email_confirm:true — that
      // creates the account silently with no inbox message.
      return await _signUpViaSupabase(
        fullName: trimmedName,
        email: trimmedEmail,
        password: password,
      );
    } catch (error) {
      return AuthResult.failure(_mapError(error));
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
      emailRedirectTo: ApiConfig.emailConfirmedPageUrl,
      data: {'full_name': fullName},
    );

    final user = response.user;
    if (user == null) {
      return AuthResult.failure('Unable to create account. Please try again.');
    }

    // Supabase returns a user with empty identities (and no email) when the
    // address is already registered — avoid a fake “check your email” screen.
    final identities = user.identities ?? const [];
    if (identities.isEmpty && response.session == null) {
      return AuthResult.failure(
        'An account with this email already exists. Sign in, or delete the '
        'user in Supabase → Authentication → Users and try again.',
      );
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
    final needsConfirm = !signedIn;
    return AuthResult.success(
      message: signedIn
          ? 'Account created successfully.'
          : 'Account created. We sent a verification link to $email.',
      signedIn: signedIn,
      needsEmailConfirmation: needsConfirm,
      user: {
        'id': user.id,
        'email': user.email,
        'fullName': fullName,
      },
    );
  }

  Future<AuthResult> resendSignupConfirmation({required String email}) async {
    if (!SupabaseConfig.isConfigured) {
      return AuthResult.failure(
        'Supabase is not configured. Add keys to frontend/.env',
      );
    }

    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email.trim().toLowerCase(),
        emailRedirectTo: ApiConfig.emailConfirmedPageUrl,
      );
      return AuthResult.success(
        message: 'Verification email resent. Check your inbox.',
        signedIn: false,
        needsEmailConfirmation: true,
      );
    } catch (error) {
      return AuthResult.failure(_mapError(error));
    }
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
    if (!SupabaseConfig.isConfigured) {
      return AuthResult.failure(
        'Supabase is not configured. Add keys to frontend/.env',
      );
    }

    try {
      await _supabase.auth.resetPasswordForEmail(
        email.trim().toLowerCase(),
        redirectTo: ApiConfig.passwordResetPageUrl,
      );
      return AuthResult.success(
        message:
            'If an account exists for that email, we sent a reset link. '
            'Open it, choose a new password, then sign in in the app.',
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

      final response = await http
          .delete(
            ApiConfig.deleteAccount,
            headers: ApiConfig.authHeaders(),
          )
          .timeout(const Duration(seconds: 45));

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      final message =
          (body['message'] as String?) ?? 'Unable to delete account.';

      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          await _supabase.auth.signOut();
        } catch (_) {}
        return AuthResult.success(
          message: message,
          signedIn: false,
        );
      }

      return AuthResult.failure(message);
    } catch (error) {
      return AuthResult.failure(_mapError(error));
    }
  }
}

/// Backward-compatible alias used by older screens/tests.
typedef SignUpResult = AuthResult;
