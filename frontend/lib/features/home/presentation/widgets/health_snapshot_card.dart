import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/services/health_snapshot_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/health_snapshot_page.dart';

class HealthSnapshotCard extends StatelessWidget {
  const HealthSnapshotCard({
    super.key,
    required this.snapshot,
    this.activeFocus,
    this.onFocusStarted,
  });

  final HealthSnapshot snapshot;
  final ActiveFocus? activeFocus;
  final VoidCallback? onFocusStarted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (activeFocus != null && activeFocus!.isActive)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: FocusBanner(focus: activeFocus!),
          ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (_) => HealthSnapshotPage(
                    initialSnapshot: snapshot,
                    initialFocus: activeFocus,
                  ),
                ),
              );
              onFocusStarted?.call();
            },
            borderRadius: BorderRadius.circular(16),
            splashColor: AppColors.cyanAccent.withValues(alpha: 0.12),
            child: Ink(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.cyanAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🌱', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'My Health Snapshot',
                            style:
                                Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ),
                        Text(
                          '${snapshot.overallScore}/100',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.cyanAccent,
                                  ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textMuted.withValues(alpha: 0.8),
                          size: 22,
                        ),
                      ],
                    ),
                    if (snapshot.streak.currentStreak > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '🔥 ${snapshot.streak.currentStreak}-day streak',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.amber,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Text(
                      'This week',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < snapshot.categories.length; i++) ...[
                      if (i > 0) const SizedBox(height: 6),
                      _CategoryPreviewRow(
                        category: snapshot.categories[i],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Focus: ${snapshot.focusText}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FocusBanner extends StatelessWidget {
  const FocusBanner({super.key, required this.focus});

  final ActiveFocus focus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cyanAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.cyanAccent.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(
            focus.category.icon,
            size: 18,
            color: AppColors.cyanAccent,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Focus: ${focus.category.displayName} (Day ${focus.currentDay}/7)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
            ),
          ),
          Icon(
            Icons.flag_outlined,
            size: 16,
            color: AppColors.cyanAccent.withValues(alpha: 0.8),
          ),
        ],
      ),
    );
  }
}

class _CategoryPreviewRow extends StatelessWidget {
  const _CategoryPreviewRow({required this.category});

  final CategoryStatus category;

  @override
  Widget build(BuildContext context) {
    final color = SnapshotStatusColors.forStatus(category.status);
    return Row(
      children: [
        Icon(
          category.category.icon,
          size: 15,
          color: AppColors.textMuted.withValues(alpha: 0.9),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            category.category.displayName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
          ),
        ),
        _StatusLabel(label: category.status, color: color),
      ],
    );
  }
}

class SnapshotStatusColors {
  const SnapshotStatusColors._();

  static Color forStatus(String status) {
    switch (status) {
      case 'Excellent':
        return AppColors.cyanAccent;
      case 'Good':
      case 'Improving':
        return AppColors.mint;
      case 'Fair':
      case 'Stable':
        return AppColors.textSecondary;
      case 'Needs attention':
      case 'Low':
        return AppColors.amber;
      default:
        return AppColors.textMuted;
    }
  }
}

class SnapshotStatusLabel extends StatelessWidget {
  const SnapshotStatusLabel({
    super.key,
    required this.label,
    this.compact = false,
  });

  final String label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return _StatusLabel(
      label: label,
      color: SnapshotStatusColors.forStatus(label),
      compact: compact,
    );
  }
}

class _StatusLabel extends StatelessWidget {
  const _StatusLabel({
    required this.label,
    required this.color,
    this.compact = false,
  });

  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color.withValues(alpha: 0.95),
              fontSize: compact ? 9.5 : 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
      ),
    );
  }
}
