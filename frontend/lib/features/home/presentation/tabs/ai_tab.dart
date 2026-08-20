import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/ai_chat_page.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/bmi_assessment_page.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/emotional_support_page.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/health_journey_page.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/water_tracking_page.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/workout_plan_page.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/water_glass_card.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

class AiTab extends StatefulWidget {
  const AiTab({
    super.key,
    this.onDataChanged,
  });

  final Future<void> Function({bool refreshAi, bool includeToday})?
      onDataChanged;

  @override
  AiTabState createState() => AiTabState();
}

class AiTabState extends State<AiTab> {
  final _api = FeatureService();

  static const _tools = [
    (
      'water_intake',
      'Water intake',
      'Track sips and glasses',
      Icons.water_drop_rounded,
      AppColors.sky,
    ),
    (
      'bmi_assessment',
      'BMI check',
      'WHO-style weight range',
      Icons.monitor_weight_outlined,
      AppColors.aqua,
    ),
    (
      'emotional_support',
      'Emotional support',
      'Grounding and check-ins',
      Icons.favorite_rounded,
      AppColors.coral,
    ),
    (
      'health_journey',
      'Health journey',
      'Your story over time',
      Icons.timeline_rounded,
      AppColors.mint,
    ),
    (
      'diet_plan',
      'Diet plan',
      'Meals that fit you',
      Icons.restaurant_menu_rounded,
      AppColors.amber,
    ),
    (
      'workout_plan',
      'Workout plan',
      'Weekly training plan',
      Icons.fitness_center_rounded,
      AppColors.primaryBright,
    ),
  ];

  @override
  void initState() {
    super.initState();
  }

  Future<void> reload() async {}

  Future<void> openChat() => _openChat();

  Future<void> _openChat() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const AiChatPage(),
      ),
    );
  }

  Future<void> _openTool(String tool, String title) async {
    if (tool == 'water_intake') {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(builder: (_) => const WaterTrackingPage()),
      );
      if (changed == true) {
        await widget.onDataChanged?.call(
          refreshAi: false,
          includeToday: true,
        );
      }
      return;
    }
    if (tool == 'bmi_assessment') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const BmiAssessmentPage()),
      );
      return;
    }
    if (tool == 'emotional_support') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const EmotionalSupportPage()),
      );
      return;
    }
    if (tool == 'health_journey') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const HealthJourneyPage()),
      );
      await widget.onDataChanged?.call();
      return;
    }
    if (tool == 'workout_plan') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const WorkoutPlanPage()),
      );
      return;
    }
    await _runTool(tool, title);
  }

  Future<void> _runTool(String tool, String title) async {
    Map<String, dynamic> input = {};
    final text = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          final controller = TextEditingController();
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(title),
            content: TextField(
              controller: controller,
              maxLines: 5,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Add details or preferences',
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, controller.text.trim()),
                child: const Text('Generate'),
              ),
            ],
          );
        },
      );
    if (text == null) return;
    input = {'text': text};

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
    try {
      final data = await _api.post('ai/tool', {'tool': tool, 'input': input});
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      final result = Map<String, dynamic>.from(data['result'] as Map? ?? {});
      await _showToolResult(result);
      await widget.onDataChanged?.call();
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _toast(error);
    }
  }

  Future<void> _showToolResult(Map<String, dynamic> result) {
    final actions =
        ((result['actions'] as List?) ?? []).map((e) => e.toString()).toList();
    final highlights = ((result['highlights'] as List?) ?? [])
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .toList();
    final nested = result['report'] is Map
        ? Map<String, dynamic>.from(result['report'] as Map)
        : null;
    if (highlights.isEmpty && nested != null) {
      highlights.addAll(
        ((nested['highlights'] as List?) ?? []).map((e) => e.toString()),
      );
    }
    final source = result['source']?.toString() ?? nested?['source']?.toString();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result['title']?.toString() ?? 'AI Result',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                result['summary']?.toString() ?? '',
                style: const TextStyle(height: 1.5),
              ),
              if (source == 'rules') ...[
                const SizedBox(height: 8),
                const Text(
                  'From your logs (no AI key required)',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
              if (highlights.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Highlights',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                for (final item in highlights)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• $item'),
                  ),
              ],
              if (actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                for (final action in actions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• $action'),
                  ),
              ],
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _toast(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString().replaceFirst('Exception: ', '')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return HarmoniousBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            HarmoniousSpacing.screenHorizontal,
            14,
            HarmoniousSpacing.screenHorizontal,
            32,
          ),
          children: [
            const HarmoniousPageHeader(
              icon: Icons.auto_awesome_rounded,
              title: 'Your AI',
              subtitle: 'Tools for your day — AI only when you ask.',
            ),
            const SizedBox(height: HarmoniousSpacing.sectionGap),
            _toolsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _toolsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HarmoniousSectionHeader(
          title: 'Tools',
          subtitle: 'Tap a tool to open it or generate a plan',
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tools.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.95,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final tool = _tools[index];
            final color = tool.$5;
            return HarmoniousCard(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              accentColor: color,
              onTap: () => _openTool(tool.$1, tool.$2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tool.$1 == 'water_intake')
                    const WaterBottleProgress(
                      progress: 0.55,
                      width: 36,
                      height: 52,
                      showMarks: false,
                    )
                  else
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(tool.$4, color: color, size: 22),
                    ),
                  const Spacer(),
                  Text(
                    tool.$2,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tool.$3,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.3,
                        ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
