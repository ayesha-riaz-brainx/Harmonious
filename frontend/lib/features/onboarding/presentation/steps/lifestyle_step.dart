import 'package:flutter/material.dart';

import 'package:slot_1_tasks/features/onboarding/data/onboarding_draft.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_options.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/widgets/onboarding_widgets.dart';

class LifestyleStep extends StatefulWidget {
  const LifestyleStep({
    super.key,
    required this.draft,
    required this.onContinue,
  });

  final OnboardingDraft draft;
  final VoidCallback onContinue;

  @override
  State<LifestyleStep> createState() => _LifestyleStepState();
}

class _LifestyleStepState extends State<LifestyleStep> {
  void _submit() {
    final d = widget.draft;
    if (d.sleepHours == null ||
        d.waterIntake == null ||
        d.workStress == null ||
        d.screenTime == null ||
        d.workHours == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please answer each question.')),
      );
      return;
    }
    if (d.exercises && d.exerciseFrequency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('How often do you exercise?')),
      );
      return;
    }
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepHeader(
          eyebrow: 'Lifestyle',
          title: 'How does a typical day look?',
          subtitle: 'Sleep, water, movement, stress — the basics that shape energy.',
        ),
        OnboardingFieldLabel('How many hours do you sleep?', required: true),
        OnboardingChipWrap(
          options: OnboardingOptions.sleepHours,
          selected: {if (d.sleepHours != null) d.sleepHours!},
          multi: false,
          onToggle: (v) => setState(() => d.sleepHours = v),
        ),
        OnboardingFieldLabel('How much water do you drink daily?', required: true),
        OnboardingChipWrap(
          options: OnboardingOptions.waterIntake,
          selected: {if (d.waterIntake != null) d.waterIntake!},
          multi: false,
          onToggle: (v) => setState(() => d.waterIntake = v),
        ),
        OnboardingFieldLabel('Do you exercise?', required: true),
        OnboardingChipWrap(
          options: const ['Yes', 'Not regularly'],
          selected: {d.exercises ? 'Yes' : 'Not regularly'},
          multi: false,
          onToggle: (v) {
            setState(() {
              d.exercises = v == 'Yes';
              if (!d.exercises) d.exerciseFrequency = null;
            });
          },
        ),
        if (d.exercises) ...[
          OnboardingFieldLabel('How often?', required: true),
          OnboardingChipWrap(
            options: OnboardingOptions.exerciseFrequency,
            selected: {
              if (d.exerciseFrequency != null) d.exerciseFrequency!,
            },
            multi: false,
            onToggle: (v) => setState(() => d.exerciseFrequency = v),
          ),
        ],
        OnboardingFieldLabel('How stressful is your work?', required: true),
        OnboardingChipWrap(
          options: OnboardingOptions.stressLevels,
          selected: {if (d.workStress != null) d.workStress!},
          multi: false,
          onToggle: (v) => setState(() => d.workStress = v),
        ),
        OnboardingFieldLabel('Average screen time?', required: true),
        OnboardingChipWrap(
          options: OnboardingOptions.screenTime,
          selected: {if (d.screenTime != null) d.screenTime!},
          multi: false,
          onToggle: (v) => setState(() => d.screenTime = v),
        ),
        OnboardingFieldLabel('How many hours do you work?', required: true),
        OnboardingChipWrap(
          options: OnboardingOptions.workHours,
          selected: {if (d.workHours != null) d.workHours!},
          multi: false,
          onToggle: (v) => setState(() => d.workHours = v),
        ),
        OnboardingFooterButton(label: 'Continue', onPressed: _submit),
      ],
    );
  }
}
