import 'package:flutter/material.dart';

import 'package:slot_1_tasks/features/onboarding/data/onboarding_draft.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_options.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/widgets/onboarding_widgets.dart';

/// Core required step — pick at least one goal.
class GoalsStep extends StatefulWidget {
  const GoalsStep({
    super.key,
    required this.draft,
    required this.onContinue,
  });

  final OnboardingDraft draft;
  final VoidCallback onContinue;

  @override
  State<GoalsStep> createState() => _GoalsStepState();
}

class _GoalsStepState extends State<GoalsStep> {
  // Keep the list short for a faster experience.
  static const _featured = [
    'Lose Weight',
    'Gain Muscle',
    'Improve Sleep',
    'Eat Healthier',
    'Drink More Water',
    'Exercise Regularly',
    'Reduce Stress',
    'Improve Mental Health',
    'Build Better Habits',
    'General Wellness',
  ];

  void _toggle(String goal) {
    setState(() {
      final list = [...widget.draft.goals];
      if (list.contains(goal)) {
        list.remove(goal);
      } else {
        list.add(goal);
      }
      widget.draft.goals = list;
    });
  }

  void _submit() {
    if (widget.draft.goals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one goal to continue.')),
      );
      return;
    }
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final options = _featured
        .where((g) => OnboardingOptions.goals.contains(g))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepHeader(
          eyebrow: 'Your focus',
          title: 'What should we work on?',
          subtitle:
              'Pick 1–3 for now. You can change these anytime — this is the only required step.',
        ),
        const SizedBox(height: 12),
        OnboardingChipWrap(
          options: options,
          selected: widget.draft.goals.toSet(),
          onToggle: _toggle,
        ),
        OnboardingFooterButton(label: 'Continue', onPressed: _submit),
      ],
    );
  }
}
