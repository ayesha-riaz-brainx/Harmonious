import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:slot_1_tasks/core/services/entertainment_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/entertainment_recommendations_page.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

class MoodEntertainmentCard extends StatefulWidget {
  const MoodEntertainmentCard({
    super.key,
    required this.mood,
    this.compact = false,
  });

  final String mood;
  final bool compact;

  static String dismissKeyForToday([DateTime? date]) {
    final now = date ?? DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return 'entertainment_card_dismissed_$y-$m-$d';
  }

  static Future<bool> wasDismissedToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(dismissKeyForToday()) ?? false;
  }

  static Future<void> dismissForToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(dismissKeyForToday(), true);
  }

  @override
  State<MoodEntertainmentCard> createState() => _MoodEntertainmentCardState();
}

class _MoodEntertainmentCardState extends State<MoodEntertainmentCard> {
  bool _visible = true;

  Future<void> _dismiss() async {
    await MoodEntertainmentCard.dismissForToday();
    if (!mounted) return;
    setState(() => _visible = false);
  }

  void _openRecommendations() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => EntertainmentRecommendationsPage(
          initialMood: normalizeEntertainmentMood(widget.mood),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Dismissible(
      key: ValueKey('mood_entertainment_${widget.mood}'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => _dismiss(),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(HarmoniousSpacing.cardRadius),
        ),
        child: Icon(
          Icons.close_rounded,
          color: AppColors.textMuted.withValues(alpha: 0.8),
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(HarmoniousSpacing.cardRadius),
        ),
        child: Icon(
          Icons.close_rounded,
          color: AppColors.textMuted.withValues(alpha: 0.8),
        ),
      ),
      child: HarmoniousCard(
        accentColor: AppColors.cyanAccent,
        padding: EdgeInsets.fromLTRB(
          widget.compact ? 14 : 16,
          widget.compact ? 14 : 16,
          12,
          widget.compact ? 14 : 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.cyanAccent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.movie_filter_outlined,
                    color: AppColors.cyanAccent.withValues(alpha: 0.95),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Want something to watch?',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Gentle picks matched to how you feel — optional and easy to skip.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.35,
                              fontSize: 12.5,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _dismiss,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  color: AppColors.textMuted,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Dismiss for today',
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: HarmoniousPrimaryChipButton(
                    label: 'Browse picks',
                    onTap: _openRecommendations,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: HarmoniousSecondaryChipButton(
                    label: 'Not now',
                    onTap: _dismiss,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows the entertainment card when mood is negative and not dismissed today.
class MoodEntertainmentPrompt extends StatefulWidget {
  const MoodEntertainmentPrompt({
    super.key,
    required this.mood,
  });

  final String? mood;

  @override
  State<MoodEntertainmentPrompt> createState() => _MoodEntertainmentPromptState();
}

class _MoodEntertainmentPromptState extends State<MoodEntertainmentPrompt> {
  bool _dismissed = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDismissState();
  }

  @override
  void didUpdateWidget(covariant MoodEntertainmentPrompt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mood != widget.mood) {
      _loadDismissState();
    }
  }

  Future<void> _loadDismissState() async {
    final dismissed = await MoodEntertainmentCard.wasDismissedToday();
    if (!mounted) return;
    setState(() {
      _dismissed = dismissed;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_dismissed) return const SizedBox.shrink();
    if (!isNegativeMoodForEntertainment(widget.mood)) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: MoodEntertainmentCard(mood: widget.mood!),
    );
  }
}
