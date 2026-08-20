import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_draft.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_options.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/widgets/onboarding_widgets.dart';

/// Pick daily habits to track — multi-select with sensible defaults.
class HabitsStep extends StatefulWidget {
  const HabitsStep({
    super.key,
    required this.draft,
    required this.onContinue,
  });

  final OnboardingDraft draft;
  final VoidCallback onContinue;

  @override
  State<HabitsStep> createState() => _HabitsStepState();
}

class _HabitsStepState extends State<HabitsStep> {
  void _toggle(String id) {
    setState(() {
      final selected = widget.draft.selectedHabits.toSet();
      if (selected.contains(id)) {
        selected.remove(id);
      } else {
        selected.add(id);
      }
      widget.draft.selectedHabits = selected.toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.draft.selectedHabits.toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepHeader(
          eyebrow: 'Daily habits',
          title: 'What do you want to track?',
          subtitle:
              'Pick a few habits for your routine. You can add or change these anytime on Today.',
        ),
        const SizedBox(height: 8),
        for (final (id, label) in OnboardingOptions.habitPresets) ...[
          _HabitCheckboxTile(
            label: label,
            selected: selected.contains(id),
            onChanged: () => _toggle(id),
          ),
          const SizedBox(height: 8),
        ],
        if (selected.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              'Select at least one habit to continue.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.amber,
                    fontSize: 13,
                  ),
            ),
          ),
        OnboardingFooterButton(
          label: 'Continue',
          onPressed: selected.isEmpty ? null : widget.onContinue,
          onSkip: widget.onContinue,
        ),
      ],
    );
  }
}

class _HabitCheckboxTile extends StatelessWidget {
  const _HabitCheckboxTile({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final bool selected;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onChanged,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? AppColors.lavender.withValues(alpha: 0.12)
              : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.lavender : AppColors.surfaceBorder,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: selected
                    ? AppColors.lavender.withValues(alpha: 0.2)
                    : Colors.transparent,
                border: Border.all(
                  color: selected ? AppColors.lavender : AppColors.surfaceBorder,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 16, color: AppColors.lavenderBright)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
