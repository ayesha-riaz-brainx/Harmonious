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

  factory AuthResult.failure(
    String message, {
    bool needsEmailConfirmation = false,
  }) {
    return AuthResult._(
      success: false,
      message: message,
      needsEmailConfirmation: needsEmailConfirmation,
    );
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
        'Harmonious is still starting. Wait a moment and try again.',
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

  /// User-facing copy only — never leak provider / SDK / SQL details.
  String _mapError(Object error) {
    final raw = error is AuthException ? error.message : error.toString();
    final lower = raw.toLowerCase();

    if (error is SocketException ||
        lower.contains('socket') ||
        lower.contains('network') ||
        lower.contains('failed host lookup') ||
        lower.contains('clientexception') ||
        lower.contains('failed to fetch') ||
        lower.contains('connection')) {
      return 'No internet connection. Please try again.';
    }

    if (lower.contains('rate limit') ||
        lower.contains('over_email_send_rate_limit') ||
        lower.contains('email rate limit') ||
        lower.contains('too many requests')) {
      return 'Too many emails sent. Wait about a minute, then try again.';
    }

    if (lower.contains('captcha') ||
        lower.contains('turnstile') ||
        lower.contains('security check')) {
      return 'Complete the security check and try again.';
    }

    if (lower.contains('error sending confirmation email') ||
        lower.contains('error sending') ||
        lower.contains('smtp')) {
      return 'Could not send the verification email. Please try again shortly.';
    }

    if (lower.contains('email not confirmed') ||
        lower.contains('not confirmed') ||
        lower.contains('email_not_confirmed')) {
      return 'Please verify your email first. Open the link we sent, then sign in.';
    }

    if (lower.contains('invalid login') ||
        lower.contains('invalid credentials') ||
        lower.contains('invalid_credentials')) {
      return 'Invalid email or password.';
    }

    if (lower.contains('already') ||
        lower.contains('registered') ||
        lower.contains('user_already_exists')) {
      return 'An account with this email already exists. Try signing in.';
    }

    if (lower.contains('password should be') ||
        lower.contains('password is too') ||
        lower.contains('weak_password')) {
      return 'Password is too weak. Use at least 8 characters.';
    }

    if (lower.contains('valid email') || lower.contains('invalid email')) {
      return 'Please enter a valid email address.';
    }

    if (lower.contains('user not found') || lower.contains('user_not_found')) {
      return 'No account found for that email.';
    }

    if (lower.contains('session') && lower.contains('expired')) {
      return 'Your session expired. Please sign in again.';
    }

    if (lower.contains('display_name') ||
        lower.contains('column') ||
        lower.contains('row-level security') ||
        lower.contains('rls') ||
        lower.contains('postgrest') ||
        lower.contains('pgrst')) {
      return 'Something went wrong saving your profile. Please try again.';
    }

    // Never show AuthException / AuthApiException / Supabase / GoTrue text.
    if (lower.contains('supabase') ||
        lower.contains('gotrue') ||
        lower.contains('authexception') ||
        lower.contains('authapiexception') ||
        lower.contains('authretryable') ||
        lower.contains('authsessionmissing') ||
        lower.contains('statuscode') ||
        lower.contains('sign in with') ||
        lower.contains('signinwith')) {
      return 'Unable to sign in right now. Please try again.';
    }

    return 'Something went wrong. Please try again.';
  }

  Future<AuthResult> signUp({
    required String fullName,
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      return AuthResult.failure(
        'Unable to create an account right now. Please try again later.',
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
        captchaToken: captchaToken,
      );
    } catch (error) {
      return AuthResult.failure(_mapError(error));
    }
  }

  Future<AuthResult> _signUpViaSupabase({
    required String fullName,
    required String email,
    required String password,
    String? captchaToken,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      emailRedirectTo: ApiConfig.emailConfirmedPageUrl,
      data: {'full_name': fullName},
      captchaToken: captchaToken,
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
        'An account with this email already exists. Try signing in, or use '
        'Forgot password if you need to reset access.',
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

  Future<AuthResult> resendSignupConfirmation({
    required String email,
    String? captchaToken,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      return AuthResult.failure(
        'Unable to resend the email right now. Please try again later.',
      );
    }

    try {
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email.trim().toLowerCase(),
        emailRedirectTo: ApiConfig.emailConfirmedPageUrl,
        captchaToken: captchaToken,
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
    String? captchaToken,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      return AuthResult.failure(
        'Unable to sign in right now. Please try again later.',
      );
    }

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim().toLowerCase(),
        password: password,
        captchaToken: captchaToken,
      );

      final user = response.user;
      if (user == null || response.session == null) {
        return AuthResult.failure('Invalid email or password.');
      }

      // Always enforce email verification in the app, even if the auth
      // provider would otherwise issue a session.
      final confirmed = (user.emailConfirmedAt ?? '').trim().isNotEmpty;
      if (!confirmed) {
        try {
          await _supabase.auth.signOut();
        } catch (_) {}
        return AuthResult.failure(
          'Please verify your email first. Open the link we sent, then sign in.',
          needsEmailConfirmation: true,
        );
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
      final mapped = _mapError(error);
      final needsVerify = mapped.toLowerCase().contains('verify');
      return AuthResult.failure(
        mapped,
        needsEmailConfirmation: needsVerify,
      );
    }
  }

  Future<AuthResult> forgotPassword({
    required String email,
    String? captchaToken,
  }) async {
    try {
      final payload = <String, dynamic>{
        'email': email.trim().toLowerCase(),
      };
      if (captchaToken != null && captchaToken.isNotEmpty) {
        payload['captchaToken'] = captchaToken;
      }

      final response = await http
          .post(
            ApiConfig.forgotPassword,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 45));

      final body = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : <String, dynamic>{};
      final message = (body['message'] as String?) ??
          'If an account exists for that email, we sent a reset link. '
              'Open it, choose a new password, then sign in in the app.';

      if (response.statusCode == 429) {
        return AuthResult.failure(message);
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return AuthResult.success(message: message, signedIn: false);
      }

      return AuthResult.failure(_mapError(Exception(message)));
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
