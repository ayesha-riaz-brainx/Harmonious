import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/emotional_support_page.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/water_tracking_page.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/water_glass_card.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

class ToolsTab extends StatefulWidget {
  const ToolsTab({
    super.key,
    this.onDataChanged,
  });

  final Future<void> Function({bool includeToday})? onDataChanged;

  @override
  ToolsTabState createState() => ToolsTabState();
}

class ToolsTabState extends State<ToolsTab> {
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
      'Grounding, breathing, and check-ins',
      Icons.favorite_rounded,
      AppColors.coral,
    ),
  ];

  Future<void> reload() async {}

  Future<void> _openTool(String tool) async {
    if (tool == 'water_intake') {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(builder: (_) => const WaterTrackingPage()),
      );
      if (changed == true) {
        await widget.onDataChanged?.call(includeToday: true);
      }
      return;
    }
    if (tool == 'emotional_support') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const EmotionalSupportPage()),
      );
    }
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
              icon: Icons.spa_outlined,
              title: 'Wellness tools',
              subtitle: 'Quick helpers for hydration and emotional care.',
            ),
            const SizedBox(height: HarmoniousSpacing.sectionGap),
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
                  onTap: () => _openTool(tool.$1),
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
        ),
      ),
    );
  }
}
