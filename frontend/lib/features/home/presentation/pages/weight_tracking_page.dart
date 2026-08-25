import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/services/home_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/bmi_assessment_page.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/collapsible_history_card.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_gradient_button.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

class WeightTrackingPage extends StatefulWidget {
  const WeightTrackingPage({super.key});

  @override
  State<WeightTrackingPage> createState() => _WeightTrackingPageState();
}

class _WeightEntry {
  const _WeightEntry({required this.date, required this.kg});

  final DateTime date;
  final double kg;
}

class _WeightTrackingPageState extends State<WeightTrackingPage> {
  final _home = HomeService();
  final _api = FeatureService();
  final _input = TextEditingController();

  HomeDashboard? _data;
  List<_WeightEntry> _history = const [];
  bool _loading = true;
  bool _busy = false;
  bool _changed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _home.fetchToday(),
        _api.get('journey'),
      ]);
      final data = results[0] as HomeDashboard;
      final journey = results[1] as Map<String, dynamic>;
      final trends = ((journey['trends'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      final history = <_WeightEntry>[];
      for (final row in trends) {
        final weight = (row['weight'] as num?)?.toDouble();
        if (weight == null || weight <= 0) continue;
        final date = DateTime.tryParse(row['log_date']?.toString() ?? '');
        if (date == null) continue;
        history.add(_WeightEntry(date: date, kg: weight));
      }
      history.sort((a, b) => b.date.compareTo(a.date));

      if (!mounted) return;
      setState(() {
        _data = data;
        _history = history;
        _loading = false;
        if (data.today.weight != null) {
          _input.text = _formatKg(data.today.weight!);
        } else if (history.isNotEmpty) {
          _input.text = _formatKg(history.first.kg);
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _formatKg(double kg) {
    return kg == kg.roundToDouble()
        ? kg.toStringAsFixed(0)
        : kg.toStringAsFixed(1);
  }

  double? get _currentKg {
    final today = _data?.today.weight;
    if (today != null && today > 0) return today;
    if (_history.isNotEmpty) return _history.first.kg;
    return null;
  }

  double? get _targetKg {
    for (final goal in _data?.activeGoals ?? const <ActiveGoal>[]) {
      if (goal.kind != 'weight') continue;
      final target = goal.target;
      if (target is num) return target.toDouble();
      return double.tryParse('$target');
    }
    return null;
  }

  double? get _previousKg {
    if (_history.length < 2) return null;
    // History is newest-first; skip today's entry if present.
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    for (final entry in _history) {
      final key = DateFormat('yyyy-MM-dd').format(entry.date);
      if (key == todayKey) continue;
      return entry.kg;
    }
    return _history.length >= 2 ? _history[1].kg : null;
  }

  Future<void> _logWeight() async {
    final kg = double.tryParse(_input.text.trim());
    if (kg == null || kg < 20 || kg > 400) {
      _toast('Enter a valid weight in kg (20–400).');
      return;
    }

    setState(() => _busy = true);
    try {
      final result = await _api.post('captures', {
        'type': 'weight',
        'payload': {'weight': kg},
      });

      HomeDashboard data;
      if (result['home'] is Map) {
        data = HomeDashboard.fromJson(
          Map<String, dynamic>.from(result['home'] as Map),
        );
      } else {
        data = await _home.fetchToday();
      }

      final today = DateTime.now();
      final todayKey = DateFormat('yyyy-MM-dd').format(today);
      final nextHistory = [
        _WeightEntry(date: today, kg: kg),
        ..._history.where(
          (e) => DateFormat('yyyy-MM-dd').format(e.date) != todayKey,
        ),
      ];

      if (!mounted) return;
      setState(() {
        _data = data;
        _history = nextHistory;
        _busy = false;
        _changed = true;
        _input.text = _formatKg(kg);
      });
      _toast('Weight logged');
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      _toast(e);
    }
  }

  void _toast(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentKg;
    final previous = _previousKg;
    final target = _targetKg;
    final delta = (current != null && previous != null)
        ? current - previous
        : null;
    final chartPoints = _history.reversed.map((e) => e.kg).toList();

    return HarmoniousBackground(
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          Navigator.of(context).pop(_changed);
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const Text('Weight tracker'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(_changed),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const BmiAssessmentPage(),
                    ),
                  );
                },
                child: const Text('BMI'),
              ),
            ],
          ),
          body: SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? HarmoniousErrorState(
                        message: _error!,
                        onRetry: _load,
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          HarmoniousSpacing.screenHorizontal,
                          8,
                          HarmoniousSpacing.screenHorizontal,
                          32,
                        ),
                        children: [
                          HarmoniousCard(
                            padding: const EdgeInsets.all(18),
                            accentColor: AppColors.amber,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Current',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.amber,
                                        letterSpacing: 1.0,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      current != null
                                          ? _formatKg(current)
                                          : '—',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(
                                            fontSize: 40,
                                            fontWeight: FontWeight.w700,
                                            height: 1,
                                          ),
                                    ),
                                    const SizedBox(width: 6),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        'kg',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                      ),
                                    ),
                                    const Spacer(),
                                    if (delta != null)
                                      _DeltaChip(delta: delta),
                                  ],
                                ),
                                if (target != null) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    'Goal ${_formatKg(target)} kg'
                                    '${current != null ? ' · ${_formatKg((current - target).abs())} kg to go' : ''}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          HarmoniousCard(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Log weight',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _input,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Weight (kg)',
                                    hintText: 'e.g. 68.5',
                                  ),
                                ),
                                const SizedBox(height: 14),
                                HarmoniousGradientButton(
                                  label: 'Save today’s weight',
                                  isLoading: _busy,
                                  onPressed: _busy ? null : _logWeight,
                                ),
                              ],
                            ),
                          ),
                          if (chartPoints.length >= 2) ...[
                            const SizedBox(height: 16),
                            HarmoniousCard(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Trend',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Last ${chartPoints.length} logged days',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    height: 120,
                                    width: double.infinity,
                                    child: CustomPaint(
                                      painter: _WeightSparklinePainter(
                                        values: chartPoints,
                                        color: AppColors.amber,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          CollapsibleHistoryCard(
                            itemCount: _history.length,
                            emptyMessage:
                                'No weight logs yet. Save today’s weight to start your history.',
                            title: 'History',
                            itemBuilder: (context, i) {
                              return _HistoryRow(
                                entry: _history[i],
                                previous: i + 1 < _history.length
                                    ? _history[i + 1]
                                    : null,
                              );
                            },
                          ),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.delta});

  final double delta;

  @override
  Widget build(BuildContext context) {
    final down = delta < 0;
    final flat = delta.abs() < 0.05;
    final color = flat
        ? AppColors.textMuted
        : down
            ? AppColors.mint
            : AppColors.coral;
    final label = flat
        ? 'No change'
        : '${down ? '' : '+'}${delta.toStringAsFixed(1)} kg';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.entry,
    this.previous,
  });

  final _WeightEntry entry;
  final _WeightEntry? previous;

  @override
  Widget build(BuildContext context) {
    final delta =
        previous != null ? entry.kg - previous!.kg : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE, MMM d').format(entry.date),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('yyyy').format(entry.date),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.kg == entry.kg.roundToDouble() ? entry.kg.toStringAsFixed(0) : entry.kg.toStringAsFixed(1)} kg',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          if (delta != null) ...[
            const SizedBox(width: 10),
            SizedBox(
              width: 64,
              child: Text(
                delta.abs() < 0.05
                    ? '—'
                    : '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: delta.abs() < 0.05
                      ? AppColors.textMuted
                      : delta < 0
                          ? AppColors.mint
                          : AppColors.coral,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WeightSparklinePainter extends CustomPainter {
  _WeightSparklinePainter({
    required this.values,
    required this.color,
  });

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final span = (maxV - minV).abs() < 0.01 ? 1.0 : (maxV - minV);
    final padY = 8.0;
    final usableH = size.height - padY * 2;

    final path = Path();
    final fill = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : size.width * (i / (values.length - 1));
      final y = padY + usableH * (1 - ((values[i] - minV) / span));
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.28),
            color.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    final lastX = size.width;
    final lastY =
        padY + usableH * (1 - ((values.last - minV) / span));
    canvas.drawCircle(
      Offset(lastX, lastY),
      4,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _WeightSparklinePainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
