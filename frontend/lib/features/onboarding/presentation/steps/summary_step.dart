import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/onboarding/data/ai_profile_builder.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/widgets/onboarding_widgets.dart';

class SummaryStep extends StatelessWidget {
  const SummaryStep({
    super.key,
    required this.profile,
    required this.isLoading,
    required this.onEnter,
  });

  final AiProfile profile;
  final bool isLoading;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingStepHeader(
          eyebrow: 'Your AI profile',
          title: 'Here’s your starting plan',
          subtitle: profile.message,
        ),
        const SizedBox(height: 8),
        _card(
          context,
          children: [
            _row(context, 'Primary Goal', profile.primaryGoal),
            if (profile.secondaryGoals.isNotEmpty)
              _row(
                context,
                'Secondary Goals',
                profile.secondaryGoals.join('\n'),
              ),
            _row(
              context,
              'Daily Calorie Target',
              '${_formatNumber(profile.calorieTarget)} kcal',
            ),
            _row(context, 'Water Goal', '${profile.waterGoalLiters} L'),
            _row(context, 'Sleep Goal', profile.sleepGoalHours),
            _row(context, 'Workout Plan', profile.workoutPlan),
            _row(context, 'Focus Areas', profile.focusAreas.join('\n')),
          ],
        ),
        OnboardingFooterButton(
          label: 'Enter My Dashboard',
          isLoading: isLoading,
          onPressed: isLoading ? null : onEnter,
        ),
      ],
    );
  }

  static String _formatNumber(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final fromEnd = s.length - i;
      buf.write(s[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  Widget _card(BuildContext context, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(children: children),
    );
  }

  Widget _row(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
