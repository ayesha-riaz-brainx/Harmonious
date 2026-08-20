import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/constants/app_routes.dart';
import 'package:slot_1_tasks/core/constants/app_strings.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/shared/widgets/auth_screen_scaffold.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_gradient_button.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_logo.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final logoSize = height < 720 ? 78.0 : 96.0;

    return AuthScreenScaffold(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HarmoniousLogo(size: logoSize),
          SizedBox(height: height < 720 ? 22 : 28),
          Text(
            AppStrings.appName,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: height < 720 ? 30 : 34,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            AppStrings.tagline,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.welcomeSubtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.45,
                ),
          ),
          SizedBox(height: height < 720 ? 40 : 56),
          HarmoniousGradientButton(
            label: AppStrings.startJourney,
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.signUp);
            },
          ),
          const SizedBox(height: 20),
          Center(
            child: Text.rich(
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
                        Navigator.of(context).pushNamed(AppRoutes.login);
                      },
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
