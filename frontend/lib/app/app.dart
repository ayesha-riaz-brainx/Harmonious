import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/constants/app_routes.dart';
import 'package:slot_1_tasks/core/constants/app_strings.dart';
import 'package:slot_1_tasks/core/theme/app_theme.dart';
import 'package:slot_1_tasks/features/auth/presentation/forgot_password_page.dart';
import 'package:slot_1_tasks/features/auth/presentation/login_page.dart';
import 'package:slot_1_tasks/features/auth/presentation/sign_up_page.dart';
import 'package:slot_1_tasks/features/auth/presentation/welcome_page.dart';
import 'package:slot_1_tasks/features/home/presentation/main_shell.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/onboarding_page.dart';
import 'package:slot_1_tasks/features/profile/presentation/profile_setup_page.dart';
import 'package:slot_1_tasks/features/splash/presentation/splash_page.dart';

class Slot1TasksApp extends StatelessWidget {
  const Slot1TasksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.harmonious,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashPage(),
        AppRoutes.welcome: (_) => const WelcomePage(),
        AppRoutes.signUp: (_) => const SignUpPage(),
        AppRoutes.login: (_) => const LoginPage(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordPage(),
        AppRoutes.profileSetup: (_) => const ProfileSetupPage(),
        AppRoutes.onboarding: (_) => const OnboardingPage(),
        AppRoutes.home: (_) => const MainShell(),
      },
    );
  }
}
