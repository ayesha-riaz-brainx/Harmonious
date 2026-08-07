import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_draft.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_options.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/widgets/onboarding_widgets.dart';

/// One light screen: mood + activity + sleep/wake clocks — all optional.
class PulseStep extends StatefulWidget {
  const PulseStep({
    super.key,
    required this.draft,
    required this.onContinue,
  });

  final OnboardingDraft draft;
  final VoidCallback onContinue;

  @override
  State<PulseStep> createState() => _PulseStepState();
}

class _PulseStepState extends State<PulseStep> {
  void _toggleMood(String label) {
    setState(() {
      widget.draft.moods = [label];
    });
  }

  Future<void> _pickTime({
    required String? current,
    required void Function(String) save,
  }) async {
    final parts = (current ?? '07:00').split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 7,
        minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
      ),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.lavender,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() => save(formatted));
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.draft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingStepHeader(
          eyebrow: 'Quick pulse',
          title: 'How are things lately?',
          subtitle:
              'Optional — skip anything. Sleep & wake use the clock you liked.',
        ),
        OnboardingFieldLabel('Feeling'),
        MoodChipWrap(
          options: OnboardingOptions.moods,
          selected: d.moods.toSet(),
          onToggle: _toggleMood,
        ),
        OnboardingFieldLabel('Activity'),
        OnboardingChipWrap(
          options: OnboardingOptions.activityLevels,
          selected: {
            if (d.activityLevel != null) d.activityLevel!,
          },
          multi: false,
          onToggle: (v) => setState(() => d.activityLevel = v),
        ),
        OnboardingFieldLabel('Bedtime'),
        _ClockCard(
          label: 'Sleep time',
          value: d.preferredBedtime ?? d.routineBedtime,
          icon: Icons.nightlight_round,
          onTap: () => _pickTime(
            current: d.preferredBedtime ?? d.routineBedtime ?? '22:30',
            save: (v) {
              d.preferredBedtime = v;
              d.routineBedtime = v;
            },
          ),
        ),
        const SizedBox(height: 12),
        OnboardingFieldLabel('Wake time'),
        _ClockCard(
          label: 'Awake time',
          value: d.wakeTime ?? d.routineWakeUp,
          icon: Icons.wb_sunny_rounded,
          onTap: () => _pickTime(
            current: d.wakeTime ?? d.routineWakeUp ?? '07:00',
            save: (v) {
              d.wakeTime = v;
              d.routineWakeUp = v;
            },
          ),
        ),
        OnboardingFooterButton(
          label: 'Continue',
          onPressed: widget.onContinue,
          onSkip: widget.onContinue,
        ),
      ],
    );
  }
}

class _ClockCard extends StatelessWidget {
  const _ClockCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String? value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: AppColors.surface,
          border: Border.all(
            color: value == null ? AppColors.surfaceBorder : AppColors.lavender,
          ),
          boxShadow: value == null
              ? null
              : [
                  BoxShadow(
                    color: AppColors.lavender.withValues(alpha: 0.14),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.lavender.withValues(alpha: 0.16),
              ),
              child: Icon(icon, color: AppColors.lavenderBright),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value ?? 'Tap to open clock',
                    style: TextStyle(
                      color: value == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.schedule_rounded, color: AppColors.lavender),
          ],
        ),
      ),
    );
  }
}
