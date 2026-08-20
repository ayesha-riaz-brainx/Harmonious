import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';

/// Interactive 5-4-3-2-1 grounding — senses only, no breathing takeover.
Future<void> showGroundingExerciseModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const _GroundingSheet(),
  );
}

class _GroundingSheet extends StatefulWidget {
  const _GroundingSheet();

  @override
  State<_GroundingSheet> createState() => _GroundingSheetState();
}

class _GroundingSheetState extends State<_GroundingSheet> {
  static const _steps = <(int, String, String, IconData)>[
    (
      5,
      'See',
      'Look around and name 5 things you can see — colors, shapes, objects.',
      Icons.visibility_rounded,
    ),
    (
      4,
      'Feel',
      'Notice 4 things you can feel — fabric, temperature, your feet on the floor.',
      Icons.touch_app_rounded,
    ),
    (
      3,
      'Hear',
      'Listen for 3 sounds — near or far, soft or clear.',
      Icons.hearing_rounded,
    ),
    (
      2,
      'Smell',
      'Notice 2 scents — or imagine two familiar smells if the room is neutral.',
      Icons.air_rounded,
    ),
    (
      1,
      'Taste',
      'Notice 1 taste — or simply notice your mouth and tongue at rest.',
      Icons.restaurant_rounded,
    ),
  ];

  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final step = _steps[_index];
    final progress = (_index + 1) / _steps.length;
    final height = MediaQuery.sizeOf(context).height * 0.72;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Grounding 5-4-3-2-1',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Step ${_index + 1} of ${_steps.length} · senses only',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: AppColors.background,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${step.$1}',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Icon(step.$4, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    step.$2,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                step.$3,
                style: const TextStyle(
                  height: 1.45,
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  if (_index > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _index -= 1),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_index > 0) const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        if (_index >= _steps.length - 1) {
                          Navigator.pop(context);
                        } else {
                          setState(() => _index += 1);
                        }
                      },
                      child: Text(
                        _index >= _steps.length - 1 ? 'I feel more present' : 'Next sense',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
