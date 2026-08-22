import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/constants/app_routes.dart';
import 'package:slot_1_tasks/core/constants/app_strings.dart';
import 'package:slot_1_tasks/core/services/auth_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/shared/widgets/auth_notice.dart';
import 'package:slot_1_tasks/shared/widgets/auth_screen_scaffold.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_gradient_button.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_text_field.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _auth = AuthService();

  bool _isLoading = false;
  bool _linkSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await _auth.forgotPassword(email: _emailController.text);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) _linkSent = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AuthNotice.show(
        context,
        message: result.message,
        tone: result.success ? AuthNoticeTone.success : AuthNoticeTone.error,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthScreenScaffold(
      showBack: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthHeader(
            title: _linkSent ? 'Check your email' : AppStrings.forgotTitle,
            subtitle: _linkSent
                ? 'Open the reset link we sent, choose a new password on that page, then return here to sign in.'
                : AppStrings.forgotSubtitle,
          ),
          const SizedBox(height: 22),
          AuthCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  if (!_linkSent)
                    HarmoniousTextField(
                      label: AppStrings.emailLabel,
                      controller: _emailController,
                      hintText: AppStrings.emailHint,
                      keyboardType: TextInputType.emailAddress,
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
                    )
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        _emailController.text.trim(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 26),
                  if (!_linkSent)
                    HarmoniousGradientButton(
                      label: AppStrings.sendResetLink,
                      isLoading: _isLoading,
                      onPressed: _sendLink,
                    ),
                  if (_linkSent) ...[
                    HarmoniousGradientButton(
                      label: AppStrings.backToLogin,
                      isLoading: false,
                      onPressed: () {
                        Navigator.of(context)
                            .pushReplacementNamed(AppRoutes.login);
                      },
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() => _linkSent = false),
                      child: const Text(
                        'Use a different email',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                  if (!_linkSent) ...[
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushReplacementNamed(AppRoutes.login);
                      },
                      child: const Text(
                        AppStrings.backToLogin,
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
