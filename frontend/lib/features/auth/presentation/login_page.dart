import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/constants/app_routes.dart';
import 'package:slot_1_tasks/core/constants/app_strings.dart';
import 'package:slot_1_tasks/core/services/auth_service.dart';
import 'package:slot_1_tasks/core/services/profile_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/shared/widgets/auth_screen_scaffold.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_gradient_button.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.authService});

  final AuthService? authService;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AuthService _authService;
  final _profiles = ProfileService();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final result = await _authService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;

    if (!result.success) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message)),
      );
      return;
    }

    final profile = await _profiles.fetchCurrentProfile();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (profile == null || !profile.profileSetupCompleted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.profileSetup,
        (route) => false,
      );
      return;
    }

    if (!profile.onboardingCompleted) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        AppRoutes.onboarding,
        (route) => false,
      );
      return;
    }

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.home,
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
            title: AppStrings.loginTitle,
            subtitle: AppStrings.loginSubtitle,
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
                    textInputAction: TextInputAction.done,
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
                      return null;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamed(AppRoutes.forgotPassword);
                      },
                      child: const Text(
                        AppStrings.forgotPassword,
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  HarmoniousGradientButton(
                    label: AppStrings.login,
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
                        const TextSpan(text: AppStrings.noAccount),
                        TextSpan(
                          text: AppStrings.signUp,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.of(context)
                                  .pushReplacementNamed(AppRoutes.signUp);
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
