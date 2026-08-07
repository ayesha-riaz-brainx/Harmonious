import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/constants/app_routes.dart';
import 'package:slot_1_tasks/core/constants/app_strings.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_logo.dart';
import 'package:slot_1_tasks/core/services/auth_service.dart';
import 'package:slot_1_tasks/core/services/profile_service.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  final _auth = AuthService();
  final _profiles = ProfileService();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([
      Future<void>.delayed(const Duration(milliseconds: 1600)),
      _auth.ensureInitialized(),
    ]);

    if (!mounted) return;

    if (!_auth.isLoggedIn) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
      return;
    }

    try {
      final profile = await _profiles.fetchCurrentProfile();
      if (!mounted) return;

      if (profile == null || !profile.profileSetupCompleted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.profileSetup);
        return;
      }

      if (!profile.onboardingCompleted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
        return;
      }

      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.welcome);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final logoSize = size.height < 720 ? 84.0 : 104.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: HarmoniousBackground(
        child: SafeArea(
          child: FadeTransition(
            opacity: _fade,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HarmoniousLogo(size: logoSize),
                    const SizedBox(height: 24),
                    Text(
                      AppStrings.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: size.height < 720 ? 30 : 34,
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
