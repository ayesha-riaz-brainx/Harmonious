import 'package:flutter/material.dart';

import 'package:slot_1_tasks/features/onboarding/data/onboarding_draft.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_options.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/widgets/onboarding_widgets.dart';

/// Optional health — skip is first-class.
class HealthStep extends StatefulWidget {
  const HealthStep({
    super.key,
    required this.draft,
    required this.onContinue,
  });

  final OnboardingDraft draft;
  final VoidCallback onContinue;

  @override
  State<HealthStep> createState() => _HealthStepState();
}

class _HealthStepState extends State<HealthStep> {
  void _toggle(String option) {
    setState(() {
      final list = [...widget.draft.healthConditions];
      if (option == 'None') {
        widget.draft.healthConditions = ['None'];
        return;
      }
      list.remove('None');
      if (list.contains(option)) {
        list.remove(option);
      } else {
        list.add(option);
      }
      widget.draft.healthConditions = list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepHeader(
          eyebrow: 'Health',
          title: 'Any conditions to keep in mind?',
          subtitle: 'Totally optional. Helps keep suggestions safer.',
        ),
        const SizedBox(height: 8),
        OnboardingChipWrap(
          options: OnboardingOptions.healthConditions,
          selected: widget.draft.healthConditions.toSet(),
          onToggle: _toggle,
        ),
        OnboardingFooterButton(
          label: 'Continue',
          onPressed: widget.onContinue,
          onSkip: () {
            widget.draft.healthConditions = [];
            widget.onContinue();
          },
        ),
      ],
    );
  }
}
