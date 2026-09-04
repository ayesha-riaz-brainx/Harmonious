import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/config/turnstile_config.dart';
import 'package:slot_1_tasks/core/constants/app_routes.dart';
import 'package:slot_1_tasks/core/constants/app_strings.dart';
import 'package:slot_1_tasks/core/services/auth_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/shared/widgets/auth_notice.dart';
import 'package:slot_1_tasks/shared/widgets/auth_screen_scaffold.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_gradient_button.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_text_field.dart';
import 'package:slot_1_tasks/shared/widgets/turnstile_captcha.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key, this.authService});

  final AuthService? authService;

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  late final AuthService _authService;
  final _captchaKey = GlobalKey<TurnstileCaptchaState>();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _captchaToken;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _resetCaptcha() {
    _captchaToken = null;
    _captchaKey.currentState?.reset();
  }

  bool get _captchaReady =>
      !TurnstileConfig.isConfigured ||
      (_captchaToken != null && _captchaToken!.isNotEmpty);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_captchaReady) {
      AuthNotice.show(
        context,
        message: 'Complete the security check below.',
        tone: AuthNoticeTone.warning,
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authService.signUp(
      fullName: _fullNameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      captchaToken: _captchaToken,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.success) {
      _resetCaptcha();
      AuthNotice.show(
        context,
        message: result.message,
        tone: AuthNoticeTone.error,
      );
      return;
    }

    if (result.needsEmailConfirmation || !result.signedIn) {
      AuthNotice.show(
        context,
        message: AppStrings.emailSentNotice,
        tone: AuthNoticeTone.warning,
        duration: const Duration(seconds: 5),
      );
      Navigator.of(context).pushReplacementNamed(
        AppRoutes.checkEmail,
        arguments: _emailController.text.trim().toLowerCase(),
      );
      return;
    }

    AuthNotice.show(
      context,
      message: result.message,
      tone: AuthNoticeTone.success,
    );
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.profileSetup,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenScaffold(
      showBack: true,
      onBack: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeader(
            title: AppStrings.signUpTitle,
            subtitle: AppStrings.signUpSubtitle,
          ),
          const SizedBox(height: 22),
          AuthCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  HarmoniousTextField(
                    label: AppStrings.fullNameLabel,
                    controller: _fullNameController,
                    hintText: AppStrings.fullNameHint,
                    isRequired: true,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.fieldRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  HarmoniousTextField(
                    label: AppStrings.emailLabel,
                    controller: _emailController,
                    hintText: AppStrings.emailHint,
                    isRequired: true,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return AppStrings.fieldRequired;
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                          .hasMatch(value.trim())) {
                        return AppStrings.invalidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  HarmoniousTextField(
                    label: AppStrings.passwordLabel,
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    isRequired: true,
                    textInputAction: TextInputAction.next,
                    suffix: IconButton(
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppStrings.fieldRequired;
                      }
                      if (value.length < 8) {
                        return AppStrings.passwordTooShort;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  HarmoniousTextField(
                    label: AppStrings.confirmPasswordLabel,
                    controller: _confirmController,
                    obscureText: _obscureConfirm,
                    isRequired: true,
                    textInputAction: TextInputAction.done,
                    suffix: IconButton(
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return AppStrings.passwordsDoNotMatch;
                      }
                      return null;
                    },
                  ),
                  if (TurnstileConfig.isConfigured) ...[
                    const SizedBox(height: 16),
                    TurnstileCaptcha(
                      key: _captchaKey,
                      onToken: (token) => setState(() => _captchaToken = token),
                      onExpired: _resetCaptcha,
                      onError: _resetCaptcha,
                    ),
                  ],
                  const SizedBox(height: 26),
                  HarmoniousGradientButton(
                    label: AppStrings.createAccount,
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 18),
                  Text.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                          ),
                      children: [
                        const TextSpan(text: AppStrings.alreadyHaveAccount),
                        TextSpan(
                          text: AppStrings.signIn,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.of(context)
                                  .pushReplacementNamed(AppRoutes.login);
                            },
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
