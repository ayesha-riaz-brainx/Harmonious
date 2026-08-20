import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';

/// Interactive breathe-in / hold / breathe-out circle session.
Future<void> showBreathingExerciseModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const _BreathingSheet(),
  );
}

class _BreathingSheet extends StatefulWidget {
  const _BreathingSheet();

  @override
  State<_BreathingSheet> createState() => _BreathingSheetState();
}

enum _Phase { inhale, hold, exhale }

class _BreathingSheetState extends State<_BreathingSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  _Phase _phase = _Phase.inhale;
  int _round = 1;
  static const _totalRounds = 4;

  // 4s inhale → 4s hold → 6s exhale
  static const _inhale = 4.0;
  static const _hold = 4.0;
  static const _exhale = 6.0;
  static const _cycle = _inhale + _hold + _exhale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_cycle * 1000).round()),
    )..addListener(_onTick);
    _controller.repeat();
  }

  void _onTick() {
    final t = _controller.value * _cycle;
    final next = t < _inhale
        ? _Phase.inhale
        : t < _inhale + _hold
            ? _Phase.hold
            : _Phase.exhale;
    if (next != _phase) {
      setState(() {
        if (next == _Phase.inhale && _phase == _Phase.exhale) {
          _round = (_round % _totalRounds) + 1;
        }
        _phase = next;
      });
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onTick)
      ..dispose();
    super.dispose();
  }

  String get _label => switch (_phase) {
        _Phase.inhale => 'Breathe in',
        _Phase.hold => 'Hold',
        _Phase.exhale => 'Breathe out',
      };

  String get _hint => switch (_phase) {
        _Phase.inhale => 'Inhale slowly for 4 seconds',
        _Phase.hold => 'Gently hold for 4 seconds',
        _Phase.exhale => 'Exhale slowly for 6 seconds',
      };

  double _scaleFor(double t) {
    final seconds = t * _cycle;
    if (seconds <= _inhale) {
      return 0.55 + 0.45 * (seconds / _inhale);
    }
    if (seconds <= _inhale + _hold) {
      return 1.0;
    }
    final exhaleT = (seconds - _inhale - _hold) / _exhale;
    return 1.0 - 0.45 * exhaleT;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Breathing exercise',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Round $_round of $_totalRounds · 4–4–6 pattern',
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final scale = _scaleFor(_controller.value);
                  return Column(
                    children: [
                      SizedBox(
                        width: 220,
                        height: 220,
                        child: Center(
                          child: Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    AppColors.primary.withValues(alpha: 0.95),
                                    AppColors.primaryBright.withValues(alpha: 0.55),
                                    AppColors.primary.withValues(alpha: 0.15),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.35),
                                    blurRadius: 28,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _hint,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('I’m feeling calmer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
