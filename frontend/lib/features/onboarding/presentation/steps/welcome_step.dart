import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/widgets/onboarding_widgets.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_logo.dart';

class WelcomeStep extends StatefulWidget {
  const WelcomeStep({super.key, required this.onBegin});

  final VoidCallback onBegin;

  @override
  State<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<WelcomeStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _scale = Tween<double>(begin: 0.92, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const HarmoniousLogo(size: 96),
              const SizedBox(height: 28),
              Text(
                'Meet Your AI Life Companion',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 30,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 14),
              Text(
                'A few quick taps — under 2 minutes.\nOnly what helps me personalize your plan.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 15.5,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: const Column(
                  children: [
                    Text(
                      '✦',
                      style: TextStyle(
                        fontSize: 36,
                        color: AppColors.lavenderBright,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'You can skip anything optional.\nGoals are the only must-pick.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              OnboardingFooterButton(
                label: "Let's Begin",
                onPressed: widget.onBegin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
