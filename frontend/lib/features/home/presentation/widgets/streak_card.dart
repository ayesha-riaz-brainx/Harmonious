import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/services/streak_service.dart';
import 'package:slot_1_tasks/core/services/wellness_score_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';

class StreakCard extends StatelessWidget {
  const StreakCard({super.key, required this.streak});

  final StreakSnapshot streak;

  @override
  Widget build(BuildContext context) {
    final count = streak.currentStreak;
    final dayLabel = count == 1 ? 'day' : 'days';
    final title = count > 0 ? '$count $dayLabel' : 'Start streak';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.amber.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),
          if (streak.bestStreak > 0) ...[
            const SizedBox(height: 4),
            Text(
              'Best ${streak.bestStreak}d',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            Text(
              'Log to begin',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class WellnessScoreCard extends StatelessWidget {
  const WellnessScoreCard({super.key, required this.breakdown});

  final WellnessScoreBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final progress = breakdown.total / 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.cyanAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              const Text('🌱', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Wellness',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                '${breakdown.total}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cyanAccent,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: AppColors.cardBorder.withValues(alpha: 0.8),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.cyanAccent,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            breakdown.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.mint,
                  fontSize: 11,
                ),
          ),
        ],
      ),
    );
  }
}
