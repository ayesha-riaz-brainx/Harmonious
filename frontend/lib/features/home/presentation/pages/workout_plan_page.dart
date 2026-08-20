import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_gradient_button.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

class WorkoutPlanPage extends StatefulWidget {
  const WorkoutPlanPage({super.key});

  @override
  State<WorkoutPlanPage> createState() => _WorkoutPlanPageState();
}

class _WorkoutPlanPageState extends State<WorkoutPlanPage> {
  final _api = FeatureService();
  final _notes = TextEditingController(
    text: '3–4 days/week, beginner-friendly, bodyweight + light cardio',
  );

  bool _busy = false;
  Map<String, dynamic>? _result;
  List<Map<String, dynamic>> _days = [];

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() {
      _busy = true;
      _result = null;
      _days = [];
    });
    try {
      final data = await _api.post('ai/tool', {
        'tool': 'workout_plan',
        'input': {'text': _notes.text.trim()},
      });
      if (!mounted) return;
      final result = Map<String, dynamic>.from(data['result'] as Map? ?? {});
      final plan = Map<String, dynamic>.from(result['plan'] as Map? ?? {});
      final days = ((plan['days'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        _result = result;
        _days = days;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return HarmoniousBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Workout plan'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(
            HarmoniousSpacing.screenHorizontal,
            8,
            HarmoniousSpacing.screenHorizontal,
            32,
          ),
          children: [
            const HarmoniousSectionHeader(
              title: 'Your weekly training plan',
              subtitle:
                  'Tell Harmonious your schedule and ability. We’ll build a clear day-by-day plan.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notes,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Preferences',
                hintText: 'Days available, equipment, injuries, goals…',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 14),
            HarmoniousGradientButton(
              label: _busy ? 'Building plan…' : 'Create workout plan',
              isLoading: _busy,
              onPressed: _busy ? null : _generate,
            ),
            if (_result == null && !_busy) ...[
              const SizedBox(height: 24),
              const HarmoniousEmptyState(
                icon: Icons.fitness_center_outlined,
                title: 'No plan yet',
                message: 'Add your preferences above, then tap Create workout plan.',
                compact: true,
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 22),
              Text(
                _result!['title']?.toString() ?? 'Your plan',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _result!['summary']?.toString() ?? '',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              if (_days.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Text(_result!['summary']?.toString() ?? 'Plan ready.'),
                )
              else
                for (final day in _days) _DayCard(day: day),
              if (((_result!['actions'] as List?) ?? []).isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text(
                  'Tips',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (final tip in ((_result!['actions'] as List?) ?? []))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text('• $tip'),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});
  final Map<String, dynamic> day;

  @override
  Widget build(BuildContext context) {
    final exercises = ((day['exercises'] as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  day['day']?.toString() ?? 'Day',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              if ((day['focus']?.toString() ?? '').isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    day['focus'].toString(),
                    style: const TextStyle(
                      color: AppColors.coral,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if ((day['notes']?.toString() ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              day['notes'].toString(),
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          for (final ex in exercises)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 18,
                    color: AppColors.lavenderBright,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ex['name']?.toString() ?? 'Exercise',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if ((ex['sets']?.toString() ?? '').isNotEmpty)
                              ex['sets'],
                            if ((ex['notes']?.toString() ?? '').isNotEmpty)
                              ex['notes'],
                          ].join(' · '),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
