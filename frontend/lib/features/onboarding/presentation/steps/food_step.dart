import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_draft.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_options.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/widgets/onboarding_widgets.dart';

/// One-tap diet preference — optional.
class FoodStep extends StatefulWidget {
  const FoodStep({
    super.key,
    required this.draft,
    required this.onContinue,
  });

  final OnboardingDraft draft;
  final VoidCallback onContinue;

  @override
  FoodStepState createState() => FoodStepState();
}

class FoodStepState extends State<FoodStep> {
  bool tryGoBack() => false;

  @override
  void initState() {
    super.initState();
    widget.draft.dietType ??= widget.draft.dietPreference;
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepHeader(
          eyebrow: 'Food',
          title: 'How do you like to eat?',
          subtitle: 'One tap is enough. Skip if you prefer later.',
        ),
        const SizedBox(height: 14),
        for (final diet in OnboardingOptions.dietTypes) ...[
          _DietCard(
            title: diet,
            emoji: switch (diet) {
              'Vegetarian' => '🥗',
              'Vegan' => '🌱',
              'Non-Vegetarian' => '🍗',
              _ => '✨',
            },
            selected: d.dietType == diet,
            onTap: () => setState(() {
              d.dietType = diet;
              d.dietPreference = diet;
            }),
          ),
          const SizedBox(height: 10),
        ],
        OnboardingFooterButton(
          label: 'Continue',
          onPressed: widget.onContinue,
          onSkip: widget.onContinue,
        ),
      ],
    );
  }
}

class _DietCard extends StatelessWidget {
  const _DietCard({
    required this.title,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: selected
              ? LinearGradient(
                  colors: [
                    AppColors.lavender.withValues(alpha: 0.22),
                    AppColors.tealDeep.withValues(alpha: 0.35),
                  ],
                )
              : null,
          color: selected ? null : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.lavender : AppColors.surfaceBorder,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                color: selected ? AppColors.lavenderBright : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
