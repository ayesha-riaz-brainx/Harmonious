import 'package:flutter/material.dart';

import 'package:slot_1_tasks/features/onboarding/data/onboarding_draft.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_options.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/widgets/onboarding_widgets.dart';

class MentalStep extends StatefulWidget {
  const MentalStep({
    super.key,
    required this.draft,
    required this.onContinue,
  });

  final OnboardingDraft draft;
  final VoidCallback onContinue;

  @override
  State<MentalStep> createState() => _MentalStepState();
}

class _MentalStepState extends State<MentalStep> {
  void _toggleMood(String label) {
    setState(() {
      final list = [...widget.draft.moods];
      if (list.contains(label)) {
        list.remove(label);
      } else {
        list.add(label);
      }
      widget.draft.moods = list;
    });
  }

  void _toggleTrigger(String label) {
    setState(() {
      final list = [...widget.draft.moodTriggers];
      if (list.contains(label)) {
        list.remove(label);
      } else {
        list.add(label);
      }
      widget.draft.moodTriggers = list;
    });
  }

  void _submit() {
    if (widget.draft.moods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select how you’ve been feeling.')),
      );
      return;
    }
    if (widget.draft.moodTriggers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('What affects you the most?')),
      );
      return;
    }
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepHeader(
          eyebrow: 'Mental wellbeing',
          title: 'How have you been feeling lately?',
          subtitle: 'You can pick more than one — honesty helps me support you better.',
        ),
        const SizedBox(height: 8),
        MoodChipWrap(
          options: OnboardingOptions.moods,
          selected: widget.draft.moods.toSet(),
          onToggle: _toggleMood,
        ),
        OnboardingFieldLabel('What affects you the most?', required: true),
        OnboardingChipWrap(
          options: OnboardingOptions.moodTriggers,
          selected: widget.draft.moodTriggers.toSet(),
          onToggle: _toggleTrigger,
        ),
        OnboardingFooterButton(label: 'Continue', onPressed: _submit),
      ],
    );
  }
}
