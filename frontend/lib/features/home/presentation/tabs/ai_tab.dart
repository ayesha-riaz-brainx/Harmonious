import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/ai_chat_page.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/emotional_support_page.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/health_journey_page.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/water_tracking_page.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/workout_plan_page.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/water_glass_card.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';

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
      AppColors.aqua,
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
      AppColors.lavenderBright,
    ),
    (
      'progress_review',
      'Review progress',
      'AI wins and next steps',
      Icons.insights_rounded,
      AppColors.mint,
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
    final autoTools = {'progress_review'};

    if (!autoTools.contains(tool)) {
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
    }

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
      if (tool == 'progress_review') {
        await widget.onDataChanged?.call();
      }
    } catch (error) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      _toast(error);
    }
  }

  Future<void> _showToolResult(Map<String, dynamic> result) {
    final actions =
        ((result['actions'] as List?) ?? []).map((e) => e.toString()).toList();
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            const Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.lavenderBright,
                  size: 26,
                ),
                SizedBox(width: 10),
                Text(
                  'Your AI',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Personal chat and tools built around your day.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 18),
            _chatLaunchCard(),
            const SizedBox(height: 22),
            _toolsGrid(),
          ],
        ),
      ),
    );
  }

  Widget _chatLaunchCard() {
    return InkWell(
      onTap: _openChat,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              AppColors.lavender.withValues(alpha: 0.22),
              AppColors.surface,
            ],
          ),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: const Row(
          children: [
            Icon(Icons.chat_bubble_rounded, color: AppColors.lavenderBright),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Talk with your companion',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Pick a coach inside chat. Private session — not saved.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _toolsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'AI Tools',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _tools.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.92,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemBuilder: (context, index) {
            final tool = _tools[index];
            final color = tool.$5;
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openTool(tool.$1, tool.$2),
                borderRadius: BorderRadius.circular(20),
                child: Ink(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.18),
                        AppColors.surface,
                      ],
                    ),
                    border: Border.all(color: color.withValues(alpha: 0.35)),
                  ),
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
                          child: Icon(tool.$4, color: color, size: 24),
                        ),
                      const Spacer(),
                      Text(
                        tool.$2,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tool.$3,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
