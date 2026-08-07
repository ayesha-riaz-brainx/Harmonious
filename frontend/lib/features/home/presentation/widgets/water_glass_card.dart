import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';

/// Standard full glass size used for goal display.
const double kGlassLiters = 0.25;

int glassesFromLiters(double liters) =>
    (liters / kGlassLiters).floor().clamp(0, 99);

double glassProgress(double liters, double goalLiters) {
  if (goalLiters <= 0) return 0;
  return (liters / goalLiters).clamp(0.0, 1.0);
}

int goalGlassesFromLiters(double goalLiters) {
  if (goalLiters <= 0) return 8;
  return (goalLiters / kGlassLiters).round().clamp(4, 16);
}

/// Filled water bottle progress graphic (reference-style).
class WaterBottleProgress extends StatelessWidget {
  const WaterBottleProgress({
    super.key,
    required this.progress,
    this.width = 120,
    this.height = 220,
    this.showMarks = true,
  });

  final double progress;
  final double width;
  final double height;
  final bool showMarks;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: WaterBottlePainter(
          progress: progress,
          showMarks: showMarks,
        ),
      ),
    );
  }
}

class WaterBottlePainter extends CustomPainter {
  const WaterBottlePainter({
    required this.progress,
    this.showMarks = true,
  });

  final double progress;
  final bool showMarks;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyLeft = size.width * 0.22;
    final bodyWidth = size.width * 0.56;
    final bodyTop = size.height * 0.14;
    final bodyHeight = size.height * 0.78;

    final bottle = RRect.fromRectAndRadius(
      Rect.fromLTWH(bodyLeft, bodyTop, bodyWidth, bodyHeight),
      Radius.circular(bodyWidth * 0.28),
    );
    final neck = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.36,
        size.height * 0.02,
        size.width * 0.28,
        size.height * 0.14,
      ),
      const Radius.circular(10),
    );
    final cap = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.38,
        0,
        size.width * 0.24,
        size.height * 0.05,
      ),
      const Radius.circular(6),
    );

    // Soft bottle body
    canvas.drawRRect(
      bottle,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );
    canvas.drawRRect(
      neck,
      Paint()..color = Colors.white.withValues(alpha: 0.08),
    );

    // Water fill
    final p = progress.clamp(0.0, 1.0);
    final fillHeight = bodyHeight * p;
    final fillTop = bodyTop + bodyHeight - fillHeight;

    canvas.save();
    canvas.clipRRect(bottle);
    final fillRect = Rect.fromLTRB(
      bodyLeft,
      fillTop,
      bodyLeft + bodyWidth,
      bodyTop + bodyHeight,
    );
    canvas.drawRect(
      fillRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF9ADFFF),
            Color(0xFF4BB8F0),
            Color(0xFF2A9FD8),
          ],
        ).createShader(fillRect),
    );

    // Soft wave highlight near surface
    if (p > 0.02) {
      final wave = Path()
        ..moveTo(bodyLeft, fillTop + 4)
        ..quadraticBezierTo(
          bodyLeft + bodyWidth * 0.25,
          fillTop - 3,
          bodyLeft + bodyWidth * 0.5,
          fillTop + 3,
        )
        ..quadraticBezierTo(
          bodyLeft + bodyWidth * 0.75,
          fillTop + 8,
          bodyLeft + bodyWidth,
          fillTop + 2,
        )
        ..lineTo(bodyLeft + bodyWidth, fillTop + 14)
        ..lineTo(bodyLeft, fillTop + 14)
        ..close();
      canvas.drawPath(
        wave,
        Paint()..color = Colors.white.withValues(alpha: 0.22),
      );
    }
    canvas.restore();

    // Tick marks on left (like the reference)
    if (showMarks) {
      final markPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      for (final t in [0.25, 0.5, 0.75, 1.0]) {
        final y = bodyTop + bodyHeight * (1 - t);
        canvas.drawLine(
          Offset(bodyLeft - size.width * 0.12, y),
          Offset(bodyLeft - size.width * 0.03, y),
          markPaint,
        );
      }
      // Current level marker
      if (p > 0.04) {
        canvas.drawLine(
          Offset(bodyLeft - size.width * 0.14, fillTop),
          Offset(bodyLeft - size.width * 0.02, fillTop),
          Paint()
            ..color = const Color(0xFF9ADFFF)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    // Outline
    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawRRect(bottle, outline);
    canvas.drawRRect(neck, outline);
    canvas.drawRRect(
      cap,
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant WaterBottlePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.showMarks != showMarks;
}

/// Sip-friendly water logger with a large bottle hero.
class WaterGlassCard extends StatelessWidget {
  const WaterGlassCard({
    super.key,
    required this.liters,
    required this.goalLiters,
    required this.onAddMl,
    this.busy = false,
    this.compact = false,
  });

  final double liters;
  final double goalLiters;
  final void Function(int ml) onAddMl;
  final bool busy;
  final bool compact;

  static const _sips = <(int, String)>[
    (50, 'Sip\n50 ml'),
    (100, 'Small\n100 ml'),
    (150, 'Cup\n150 ml'),
    (200, 'Almost\n200 ml'),
    (250, 'Glass\n250 ml'),
  ];

  @override
  Widget build(BuildContext context) {
    final progress = glassProgress(liters, goalLiters);
    final glassesApprox = liters / kGlassLiters;
    final goalGlasses = goalGlassesFromLiters(goalLiters);
    final remainingMl =
        ((goalLiters - liters).clamp(0.0, goalLiters) * 1000).round();
    final currentMl = (liters * 1000).round();
    final goalMl = (goalLiters * 1000).round();

    if (compact) {
      return _compact(progress, glassesApprox, goalGlasses, remainingMl);
    }

    final encouragement = progress >= 1
        ? 'Goal crushed — nice work!'
        : progress >= 0.6
            ? 'Nice work! Keep it up!'
            : progress >= 0.3
                ? 'You’re building the habit.'
                : 'Every sip counts.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1B4F72),
            Color(0xFF163A56),
            AppColors.surface,
          ],
        ),
        border: Border.all(color: AppColors.sky.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Text(
            '${liters.toStringAsFixed(2)} L  ·  ${goalLiters.toStringAsFixed(1)} L goal',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 78,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currentMl ml',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF9ADFFF),
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const Text(
                      'WATER',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      '$goalMl ml',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const Text(
                      'GOAL',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Center(
                  child: WaterBottleProgress(
                    progress: progress,
                    width: 118,
                    height: 210,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 72,
                child: Text(
                  progress >= 1
                      ? 'Done'
                      : '$remainingMl\nml\nto go',
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            encouragement,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '≈ ${glassesApprox.toStringAsFixed(1)} / $goalGlasses glasses',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  label: 'TO GO',
                  value: progress >= 1 ? '0 ml' : '$remainingMl ml',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(
                  label: 'GOAL',
                  value: '${goalLiters.toStringAsFixed(1)} L',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Add what you drank',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < _sips.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _SipButton(
                    label: _sips[i].$2,
                    enabled: !busy && progress < 1,
                    onTap: () => onAddMl(_sips[i].$1),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _compact(
    double progress,
    double glassesApprox,
    int goalGlasses,
    int remainingMl,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: AppColors.surface,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          WaterBottleProgress(
            progress: progress,
            width: 52,
            height: 86,
            showMarks: false,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hydration today',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${liters.toStringAsFixed(2)} L of ${goalLiters.toStringAsFixed(1)} L',
                  style: const TextStyle(
                    color: AppColors.sky,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  progress >= 1
                      ? 'Daily goal complete'
                      : '≈ ${glassesApprox.toStringAsFixed(1)} / $goalGlasses glasses · $remainingMl ml to go',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
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

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF9ADFFF),
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SipButton extends StatelessWidget {
  const _SipButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: enabled
                ? Colors.white.withValues(alpha: 0.28)
                : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            height: 1.2,
            color: enabled ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
