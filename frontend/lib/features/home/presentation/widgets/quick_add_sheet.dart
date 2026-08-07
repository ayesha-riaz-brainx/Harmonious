import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/water_tracking_page.dart';

enum QuickAddAction {
  meal,
  water,
  weight,
  workout,
  mood,
  sleep,
  journal,
  healthReport,
}

Future<QuickAddAction?> showQuickAddSheet(BuildContext context) {
  return showModalBottomSheet<QuickAddAction>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      final actions = <(QuickAddAction, IconData, String, String, Color)>[
        (
          QuickAddAction.meal,
          Icons.restaurant_rounded,
          'Log Meal',
          'Calories & food',
          AppColors.amber,
        ),
        (
          QuickAddAction.water,
          Icons.water_drop_rounded,
          'Log Water',
          'Fill your bottle',
          AppColors.sky,
        ),
        (
          QuickAddAction.weight,
          Icons.monitor_weight_outlined,
          'Log Weight',
          'Update today\'s kg',
          AppColors.aqua,
        ),
        (
          QuickAddAction.workout,
          Icons.fitness_center_rounded,
          'Log Workout',
          'Minutes moved',
          AppColors.coral,
        ),
        (
          QuickAddAction.mood,
          Icons.mood_rounded,
          'Log Mood',
          'How you feel',
          AppColors.mint,
        ),
        (
          QuickAddAction.sleep,
          Icons.bedtime_rounded,
          'Log Sleep',
          'Hours rested',
          AppColors.lavender,
        ),
        (
          QuickAddAction.journal,
          Icons.edit_note_rounded,
          'Journal',
          'Quick reflection',
          AppColors.sky,
        ),
        (
          QuickAddAction.healthReport,
          Icons.upload_file_rounded,
          'Health Report',
          'Photo or note',
          AppColors.coral,
        ),
      ];

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Quick Capture',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pick one — then finish the short log step',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: actions.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.55,
                ),
                itemBuilder: (context, index) {
                  final action = actions[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(sheetContext, action.$1),
                      borderRadius: BorderRadius.circular(18),
                      child: Ink(
                        padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              action.$5.withValues(alpha: 0.16),
                              AppColors.background,
                            ],
                          ),
                          border: Border.all(
                            color: action.$5.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(action.$2, size: 24, color: action.$5),
                            const Spacer(),
                            Text(
                              action.$3,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              action.$4,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 11,
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
          ),
        ),
      );
    },
  );
}

class CaptureResult {
  const CaptureResult({
    required this.saved,
    this.message,
    this.home,
  });

  final bool saved;
  final String? message;
  final Map<String, dynamic>? home;
}

/// Runs capture flows from Add / Today. Always uses the root navigator.
class QuickCaptureFlow {
  QuickCaptureFlow(this.context, {FeatureService? api})
      : _api = api ?? FeatureService();

  final BuildContext context;
  final FeatureService _api;

  Future<CaptureResult> run(QuickAddAction action) async {
    // Let the picker sheet finish disposing before opening the next overlay.
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!context.mounted) return const CaptureResult(saved: false);

    try {
      switch (action) {
        case QuickAddAction.meal:
          final result = await _numberPrompt(
            title: 'Log meal',
            label: 'Estimated calories',
            suffix: 'kcal',
            initial: '400',
          );
          if (result == null) return const CaptureResult(saved: false);
          return _capture('meal', {
            'name': 'Meal',
            'calories': result.round(),
          });
        case QuickAddAction.water:
          // Full bottle experience instead of a tiny choice sheet.
          final changed = await Navigator.of(context, rootNavigator: true).push<bool>(
            MaterialPageRoute<bool>(
              builder: (_) => const WaterTrackingPage(),
            ),
          );
          return CaptureResult(
            saved: changed == true,
            message: changed == true ? 'Water updated.' : null,
          );
        case QuickAddAction.weight:
          final value = await _numberPrompt(
            title: 'Log weight',
            label: 'Weight',
            suffix: 'kg',
            initial: '',
          );
          if (value == null) return const CaptureResult(saved: false);
          return _capture('weight', {'weight': value});
        case QuickAddAction.workout:
          final minutes = await _optionSheet<int>(
            title: 'Log workout',
            subtitle: 'How long did you move?',
            options: const [
              ('10 minutes', 10),
              ('20 minutes', 20),
              ('30 minutes', 30),
              ('45 minutes', 45),
              ('60 minutes', 60),
            ],
          );
          if (minutes == null) return const CaptureResult(saved: false);
          return _capture('workout', {
            'activity': 'Workout',
            'minutes': minutes,
          });
        case QuickAddAction.mood:
          final mood = await _optionSheet<String>(
            title: 'Log mood',
            subtitle: 'How are you feeling right now?',
            options: const [
              ('Happy', 'Happy'),
              ('Neutral', 'Neutral'),
              ('Stressed', 'Stressed'),
              ('Tired', 'Tired'),
              ('Anxious', 'Anxious'),
            ],
          );
          if (mood == null) return const CaptureResult(saved: false);
          return _capture('mood', {'mood': mood});
        case QuickAddAction.sleep:
          final hours = await _numberPrompt(
            title: 'Log sleep',
            label: 'Hours slept',
            suffix: 'hours',
            initial: '8',
          );
          if (hours == null) return const CaptureResult(saved: false);
          return _capture('sleep', {'hours': hours});
        case QuickAddAction.journal:
          final text = await _textPrompt(
            title: 'Quick journal',
            hint: 'What’s on your mind?',
            lines: 5,
          );
          if (text == null || text.isEmpty) {
            return const CaptureResult(saved: false);
          }
          return _capture('journal', {'text': text});
        case QuickAddAction.healthReport:
          return _healthReport();
      }
    } catch (error) {
      return CaptureResult(
        saved: false,
        message: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<CaptureResult> _healthReport() async {
    final choice = await _optionSheet<String>(
      title: 'Health report',
      subtitle: 'How do you want to add it?',
      options: const [
        ('Take photo', 'camera'),
        ('Choose from gallery', 'gallery'),
        ('Enter report name', 'name'),
      ],
    );

    if (choice == 'camera' || choice == 'gallery') {
      final image = await ImagePicker().pickImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 1600,
      );
      if (image == null) return const CaptureResult(saved: false);
      return _capture('health_report', {
        'name': image.name,
        'extension': image.name.split('.').last,
        'source': choice,
      });
    }

    if (choice == 'name') {
      final text = await _textPrompt(
        title: 'Health report',
        hint: 'e.g. Blood test Aug 2026',
      );
      if (text == null || text.isEmpty) {
        return const CaptureResult(saved: false);
      }
      return _capture('health_report', {
        'name': text,
        'extension': 'note',
        'source': 'manual',
      });
    }

    return const CaptureResult(saved: false);
  }

  Future<CaptureResult> _capture(
    String type,
    Map<String, dynamic> payload,
  ) async {
    final result = await _api.post('captures', {
      'type': type,
      'payload': payload,
    });
    final home = result['home'] is Map
        ? Map<String, dynamic>.from(result['home'] as Map)
        : null;
    return CaptureResult(
      saved: true,
      message: result['message']?.toString() ?? 'Saved.',
      home: home,
    );
  }

  Future<double?> _numberPrompt({
    required String title,
    required String label,
    required String suffix,
    required String initial,
  }) async {
    final controller = TextEditingController(text: initial);
    final value = await showDialog<double>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: label, suffixText: suffix),
          onSubmitted: (_) {
            Navigator.of(dialogContext).pop(
              double.tryParse(controller.text.trim()),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              double.tryParse(controller.text.trim()),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  Future<String?> _textPrompt({
    required String title,
    required String hint,
    int lines = 1,
  }) async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: lines,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(
              controller.text.trim(),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    return value;
  }

  Future<T?> _optionSheet<T>({
    required String title,
    required String subtitle,
    required List<(String, T)> options,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              for (final option in options)
                ListTile(
                  title: Text(
                    option.$1,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                  onTap: () => Navigator.of(sheetContext).pop(option.$2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
