import 'dart:async';

import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/theme/app_colors.dart';

/// Quiet 2-minute pause — no breathing circle forced.
Future<void> showPauseExerciseModal(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const _PauseSheet(),
  );
}

class _PauseSheet extends StatefulWidget {
  const _PauseSheet();

  @override
  State<_PauseSheet> createState() => _PauseSheetState();
}

class _PauseSheetState extends State<_PauseSheet> {
  static const _totalSeconds = 120;
  int _remaining = _totalSeconds;
  Timer? _timer;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remaining <= 1) {
        timer.cancel();
        if (!mounted) return;
        setState(() {
          _remaining = 0;
          _running = false;
        });
        return;
      }
      setState(() => _remaining -= 1);
    });
  }

  String get _clock {
    final m = (_remaining ~/ 60).toString().padLeft(1, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = 1 - (_remaining / _totalSeconds);
    final height = MediaQuery.sizeOf(context).height * 0.62;

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
                '2-minute pause',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'Sit comfortably. Soften your shoulders. Nothing to fix.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
              const Spacer(),
              Text(
                _clock,
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.background,
                  color: AppColors.lavenderBright,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Let thoughts pass like clouds. Stay with this quiet minute.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _remaining == 0
                      ? () => Navigator.pop(context)
                      : _toggle,
                  child: Text(
                    _remaining == 0
                        ? 'Done'
                        : _running
                            ? 'Pause timer'
                            : 'Start pause',
                  ),
                ),
              ),
              if (_remaining > 0) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
