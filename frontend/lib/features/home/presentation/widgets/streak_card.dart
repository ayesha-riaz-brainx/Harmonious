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
    final dayLabel = count == 1 ? 'Day' : 'Days';
    final subtitle = count > 0
        ? "Keep going! You're building a healthy routine."
        : 'Log water, meals, mood, or habits to start your streak.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.amber.withValues(alpha: 0.35),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.amber.withValues(alpha: 0.08),
            AppColors.cardSurface,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  count > 0 ? '$count $dayLabel Streak' : 'Start Your Streak',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
          ),
          if (streak.bestStreak > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Best Streak: ${streak.bestStreak} ${streak.bestStreak == 1 ? 'day' : 'days'}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyanAccent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌱', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Today's Wellness Score",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                '${breakdown.total} / 100',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cyanAccent,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.cardBorder.withValues(alpha: 0.8),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.cyanAccent,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            breakdown.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.mint,
                  fontSize: 14,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            breakdown.message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                  fontSize: 13,
                ),
          ),
        ],
      ),
    );
  }
}
