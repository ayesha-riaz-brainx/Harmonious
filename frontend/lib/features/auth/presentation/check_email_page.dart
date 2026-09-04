import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:slot_1_tasks/core/config/turnstile_config.dart';
import 'package:slot_1_tasks/core/constants/app_routes.dart';
import 'package:slot_1_tasks/core/constants/app_strings.dart';
import 'package:slot_1_tasks/core/services/auth_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/shared/widgets/auth_notice.dart';
import 'package:slot_1_tasks/shared/widgets/auth_screen_scaffold.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_gradient_button.dart';
import 'package:slot_1_tasks/shared/widgets/turnstile_captcha.dart';

class CheckEmailPage extends StatefulWidget {
  const CheckEmailPage({
    super.key,
    required this.email,
    this.authService,
  });

  final String email;
  final AuthService? authService;

  @override
  State<CheckEmailPage> createState() => _CheckEmailPageState();
}

class _CheckEmailPageState extends State<CheckEmailPage> {
  late final AuthService _auth;
  final _captchaKey = GlobalKey<TurnstileCaptchaState>();
  bool _resending = false;
  String? _captchaToken;

  @override
  void initState() {
    super.initState();
    _auth = widget.authService ?? AuthService();
  }

  Future<void> _openMailApp() async {
    final uri = Uri(scheme: 'mailto', path: widget.email);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      AuthNotice.show(
        context,
        message: 'Open your inbox and look for an email from Harmonious.',
        tone: AuthNoticeTone.info,
      );
    }
  }

  Future<void> _copyEmail() async {
    await Clipboard.setData(ClipboardData(text: widget.email));
    if (!mounted) return;
    AuthNotice.show(
      context,
      message: 'Email address copied.',
      tone: AuthNoticeTone.success,
      duration: const Duration(seconds: 2),
    );
  }

  void _resetCaptcha() {
    _captchaToken = null;
    _captchaKey.currentState?.reset();
  }

  bool get _captchaReady =>
      !TurnstileConfig.isConfigured ||
      (_captchaToken != null && _captchaToken!.isNotEmpty);

  Future<void> _resend() async {
    if (!_captchaReady) {
      AuthNotice.show(
        context,
        message: 'Complete the security check below.',
        tone: AuthNoticeTone.warning,
      );
      return;
    }

    setState(() => _resending = true);
    final result = await _auth.resendSignupConfirmation(
      email: widget.email,
      captchaToken: _captchaToken,
    );
    if (!mounted) return;
    setState(() => _resending = false);
    if (!result.success) {
      _resetCaptcha();
    }
    AuthNotice.show(
      context,
      message: result.message,
      tone: result.success ? AuthNoticeTone.success : AuthNoticeTone.error,
      duration: const Duration(seconds: 5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenScaffold(
      showBack: true,
      onBack: () {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.welcome,
          (route) => false,
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: AppStrings.checkEmailTitle,
            subtitle: AppStrings.checkEmailSubtitle,
          ),
          const SizedBox(height: 22),
          AuthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    color: AppColors.primary,
                    size: 34,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'We sent a verification link to',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _copyEmail,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      widget.email,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                _Step(
                  number: '1',
                  text: 'Open the email and tap “Verify email address”.',
                ),
                _Step(
                  number: '2',
                  text: 'You’ll land on a Harmonious confirmation page.',
                ),
                _Step(
                  number: '3',
                  text:
                      'Return here only after the confirmation page says your email is verified, then sign in.',
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.checkEmailMustVerify,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 24),
                if (TurnstileConfig.isConfigured) ...[
                  TurnstileCaptcha(
                    key: _captchaKey,
                    onToken: (token) => setState(() => _captchaToken = token),
                    onExpired: _resetCaptcha,
                    onError: _resetCaptcha,
                  ),
                  const SizedBox(height: 16),
                ],
                HarmoniousGradientButton(
                  label: AppStrings.openMailApp,
                  onPressed: _openMailApp,
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _resending ? null : _resend,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.surfaceBorder),
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: _resending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(AppStrings.resendVerification),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.login,
                      (route) => false,
                      arguments: widget.email,
                    );
                  },
                  child: const Text(AppStrings.verifiedGoToLogin),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.45,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
