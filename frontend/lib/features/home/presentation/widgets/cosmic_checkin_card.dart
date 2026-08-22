import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/astrology/cosmic_checkin.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

class CosmicCheckInCard extends StatelessWidget {
  const CosmicCheckInCard({
    super.key,
    required this.checkIn,
  });

  final CosmicCheckIn checkIn;

  @override
  Widget build(BuildContext context) {
    return HarmoniousCard(
      padding: const EdgeInsets.all(18),
      accentColor: AppColors.secondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                checkIn.sign.symbol,
                style: const TextStyle(fontSize: 28),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Cosmic Check-in',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.secondaryBright,
                            letterSpacing: 1.1,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      checkIn.headline,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ThemeChip(theme: checkIn.theme),
          const SizedBox(height: 16),
          _InsightRow(
            icon: Icons.favorite_rounded,
            color: AppColors.coral,
            label: 'Relationships',
            text: checkIn.relationships,
          ),
          const SizedBox(height: 12),
          _InsightRow(
            icon: Icons.work_outline_rounded,
            color: AppColors.amber,
            label: 'Productivity',
            text: checkIn.productivity,
          ),
          const SizedBox(height: 12),
          _InsightRow(
            icon: Icons.spa_outlined,
            color: AppColors.mint,
            label: 'Wellness',
            text: checkIn.wellness,
          ),
        ],
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({required this.theme});

  final String theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColors.secondary.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        'Your theme: $theme',
        style: const TextStyle(
          color: AppColors.secondaryBright,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.45,
                      fontSize: 13,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
