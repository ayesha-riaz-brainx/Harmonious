import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_draft.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_options.dart';
import 'package:slot_1_tasks/features/onboarding/presentation/widgets/onboarding_widgets.dart';

class RoutineStep extends StatefulWidget {
  const RoutineStep({
    super.key,
    required this.draft,
    required this.onContinue,
  });

  final OnboardingDraft draft;
  final VoidCallback onContinue;

  @override
  State<RoutineStep> createState() => _RoutineStepState();
}

class _RoutineStepState extends State<RoutineStep> {
  static const _slots = [
    ('Wake up', Icons.wb_sunny_outlined, 'routineWakeUp'),
    ('Work starts', Icons.laptop_mac_outlined, 'workStarts'),
    ('Lunch', Icons.restaurant_outlined, 'lunchTime'),
    ('Work ends', Icons.logout_outlined, 'workEnds'),
    ('Exercise', Icons.fitness_center_outlined, 'exerciseTime'),
    ('Bedtime', Icons.nightlight_outlined, 'routineBedtime'),
  ];

  String? _get(String key) {
    final d = widget.draft;
    return switch (key) {
      'routineWakeUp' => d.routineWakeUp,
      'workStarts' => d.workStarts,
      'lunchTime' => d.lunchTime,
      'workEnds' => d.workEnds,
      'exerciseTime' => d.exerciseTime,
      'routineBedtime' => d.routineBedtime,
      _ => null,
    };
  }

  void _set(String key, String value) {
    final d = widget.draft;
    setState(() {
      switch (key) {
        case 'routineWakeUp':
          d.routineWakeUp = value;
        case 'workStarts':
          d.workStarts = value;
        case 'lunchTime':
          d.lunchTime = value;
        case 'workEnds':
          d.workEnds = value;
        case 'exerciseTime':
          d.exerciseTime = value;
        case 'routineBedtime':
          d.routineBedtime = value;
      }
    });
  }

  Future<void> _pick(String key) async {
    final current = _get(key) ?? '09:00';
    final parts = current.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 9,
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
    _set(
      key,
      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}',
    );
  }

  void _applyPreset(String name) {
    setState(() {
      final d = widget.draft;
      if (name == 'Early bird') {
        d.routineWakeUp = '06:00';
        d.workStarts = '08:00';
        d.lunchTime = '12:30';
        d.workEnds = '17:00';
        d.exerciseTime = '18:00';
        d.routineBedtime = '22:00';
      } else if (name == 'Standard') {
        d.routineWakeUp = '07:30';
        d.workStarts = '09:00';
        d.lunchTime = '13:00';
        d.workEnds = '18:00';
        d.exerciseTime = '19:00';
        d.routineBedtime = '23:00';
      } else {
        d.routineWakeUp = '09:00';
        d.workStarts = '11:00';
        d.lunchTime = '14:00';
        d.workEnds = '19:00';
        d.exerciseTime = '20:00';
        d.routineBedtime = '00:30';
      }
    });
  }

  void _submit() {
    final d = widget.draft;
    if (d.routineWakeUp == null ||
        d.workStarts == null ||
        d.workEnds == null ||
        d.lunchTime == null ||
        d.exerciseTime == null ||
        d.routineBedtime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick a day preset or tap each moment on the timeline'),
        ),
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
          eyebrow: 'Your day',
          title: 'Build a day that fits you',
          subtitle:
              'Start with a preset, then tweak any moment. No endless fields.',
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final preset in ['Early bird', 'Standard', 'Night owl']) ...[
              Expanded(
                child: _PresetChip(
                  label: preset,
                  onTap: () => _applyPreset(preset),
                ),
              ),
              if (preset != 'Night owl') const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 22),
        ...[
          for (var i = 0; i < _slots.length; i++) ...[
            _TimelineTile(
              title: _slots[i].$1,
              icon: _slots[i].$2,
              value: _get(_slots[i].$3),
              isLast: i == _slots.length - 1,
              onTap: () => _pick(_slots[i].$3),
            ),
          ],
        ],
        OnboardingFieldLabel('Days off'),
        OnboardingChipWrap(
          options: OnboardingOptions.daysOff,
          selected: d.daysOff.toSet(),
          onToggle: (day) {
            setState(() {
              final list = [...d.daysOff];
              if (list.contains(day)) {
                list.remove(day);
              } else {
                list.add(day);
              }
              d.daysOff = list;
            });
          },
        ),
        OnboardingFooterButton(label: 'Continue', onPressed: _submit),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface,
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.lavenderBright,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.title,
    required this.icon,
    required this.value,
    required this.onTap,
    required this.isLast,
  });

  final String title;
  final IconData icon;
  final String? value;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lavender.withValues(alpha: 0.18),
                  border: Border.all(color: AppColors.lavender),
                ),
                child: Icon(icon, size: 18, color: AppColors.lavenderBright),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 28,
                  color: AppColors.surfaceBorder,
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 12, top: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    value ?? 'Set time',
                    style: TextStyle(
                      color: value == null
                          ? AppColors.textMuted
                          : AppColors.lavenderBright,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
