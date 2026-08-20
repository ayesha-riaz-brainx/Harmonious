import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:slot_1_tasks/core/constants/app_routes.dart';
import 'package:slot_1_tasks/core/constants/app_strings.dart';
import 'package:slot_1_tasks/core/services/auth_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
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
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _auth = AuthService();

  bool _isLoading = false;
  bool _codeSent = false;
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await _auth.forgotPassword(email: _emailController.text);
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.success) _codeSent = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
    });
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await _auth.resetPassword(
      email: _emailController.text,
      code: _codeController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      if (result.success) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
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
            title: _codeSent ? 'Enter reset code' : AppStrings.forgotTitle,
            subtitle: _codeSent
                ? 'Enter the 6-digit code from your email, then choose a new password.'
                : AppStrings.forgotSubtitle,
          ),
          const SizedBox(height: 22),
          AuthCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  HarmoniousTextField(
                    label: AppStrings.emailLabel,
                    controller: _emailController,
                    hintText: AppStrings.emailHint,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_codeSent,
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
                  if (_codeSent) ...[
                    const SizedBox(height: 14),
                    HarmoniousTextField(
                      label: 'RESET CODE',
                      controller: _codeController,
                      hintText: '6-digit code',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().length != 6) {
                          return 'Enter the 6-digit code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    HarmoniousTextField(
                      label: 'NEW PASSWORD',
                      controller: _passwordController,
                      obscureText: _obscure,
                      hintText: 'At least 8 characters',
                      suffix: IconButton(
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 8) {
                          return 'Password must be at least 8 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    HarmoniousTextField(
                      label: AppStrings.confirmPasswordLabel,
                      controller: _confirmController,
                      obscureText: _obscure,
                      hintText: 'Repeat new password',
                      validator: (value) {
                        if (value != _passwordController.text) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 26),
                  HarmoniousGradientButton(
                    label: _codeSent
                        ? 'Update password'
                        : AppStrings.sendResetLink,
                    isLoading: _isLoading,
                    onPressed: _codeSent ? _resetPassword : _sendCode,
                  ),
                  if (_codeSent) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              setState(() {
                                _codeSent = false;
                                _codeController.clear();
                                _passwordController.clear();
                                _confirmController.clear();
                              });
                            },
                      child: const Text(
                        'Use a different email',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
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
              ),
            ),
          ),
        ],
      ),
    );
  }
}
