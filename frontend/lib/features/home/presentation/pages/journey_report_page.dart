import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

class JourneyReportPage extends StatefulWidget {
  const JourneyReportPage({
    super.key,
    required this.period,
    required this.title,
    this.trends,
  });

  final String period;
  final String title;
  final List<Map<String, dynamic>>? trends;

  @override
  State<JourneyReportPage> createState() => _JourneyReportPageState();
}

class _JourneyReportPageState extends State<JourneyReportPage> {
  final _api = FeatureService();

  bool _loading = true;
  List<Map<String, dynamic>> _trends = const [];

  int get _days => switch (widget.period) {
        'Yearly' => 365,
        'Monthly' => 31,
        _ => 7,
      };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.trends != null && widget.trends!.isNotEmpty) {
      setState(() {
        _trends = _filterTrends(widget.trends!);
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);
    try {
      final data = await _api.get('journey');
      if (!mounted) return;
      final raw = ((data['trends'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      setState(() {
        _trends = _filterTrends(raw);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  List<Map<String, dynamic>> _filterTrends(List<Map<String, dynamic>> trends) {
    if (trends.isEmpty) return const [];
    final cutoff = DateTime.now().subtract(Duration(days: _days - 1));
    final cutoffKey =
        '${cutoff.year.toString().padLeft(4, '0')}-${cutoff.month.toString().padLeft(2, '0')}-${cutoff.day.toString().padLeft(2, '0')}';
    return trends.where((row) {
      final raw = row['log_date']?.toString() ?? '';
      final key = raw.length >= 10 ? raw.substring(0, 10) : raw;
      return key.compareTo(cutoffKey) >= 0;
    }).toList();
  }

  List<double?> _series(String key) {
    final rows = _downsample(_trends);
    return [for (final row in rows) (row[key] as num?)?.toDouble()];
  }

  List<Map<String, dynamic>> _downsample(List<Map<String, dynamic>> rows) {
    const maxPoints = 42;
    if (rows.length <= maxPoints) return rows;
    final bucket = (rows.length / maxPoints).ceil();
    final out = <Map<String, dynamic>>[];
    for (var i = 0; i < rows.length; i += bucket) {
      final slice = rows.sublist(i, math.min(i + bucket, rows.length));
      out.add(_averageRow(slice));
    }
    return out;
  }

  Map<String, dynamic> _averageRow(List<Map<String, dynamic>> slice) {
    double? avg(String key) {
      final values = slice
          .map((row) => (row[key] as num?)?.toDouble())
          .whereType<double>()
          .where((v) => v > 0)
          .toList();
      if (values.isEmpty) return null;
      return values.reduce((a, b) => a + b) / values.length;
    }

    return {
      'log_date': slice.last['log_date'],
      'weight': avg('weight'),
      'water_liters': avg('water_liters'),
      'calories': avg('calories'),
      'exercise_minutes': avg('exercise_minutes'),
      'sleep_hours': avg('sleep_hours'),
    };
  }

  bool _hasAnyData() {
    for (final row in _trends) {
      if (((row['water_liters'] as num?)?.toDouble() ?? 0) > 0) return true;
      if (((row['calories'] as num?)?.toInt() ?? 0) > 0) return true;
      if (((row['exercise_minutes'] as num?)?.toInt() ?? 0) > 0) return true;
      if (((row['sleep_hours'] as num?)?.toDouble() ?? 0) > 0) return true;
      final weight = (row['weight'] as num?)?.toDouble();
      if (weight != null && weight > 0) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final weightSeries = _series('weight');
    final hasWeight = weightSeries.any((v) => v != null && v > 0);
    final lineSeries = hasWeight ? weightSeries : _series('sleep_hours');
    final lineTitle = hasWeight ? 'Weight' : 'Sleep';
    final lineUnit = hasWeight ? 'kg' : 'h';
    final lineColor = hasWeight ? AppColors.aqua : AppColors.lavender;

    return HarmoniousBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(widget.title),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    HarmoniousSpacing.screenHorizontal,
                    4,
                    HarmoniousSpacing.screenHorizontal,
                    48,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  children: [
                    if (!_hasAnyData())
                      const HarmoniousCard(
                        child: HarmoniousEmptyState(
                          icon: Icons.show_chart_outlined,
                          title: 'No data for this period',
                          message:
                              'Log meals, water, workouts, or sleep to see charts here.',
                          compact: true,
                        ),
                      )
                    else ...[
                      _LineChart(
                        title: lineTitle,
                        unit: lineUnit,
                        color: lineColor,
                        values: lineSeries,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _BarChart(
                              title: 'Water',
                              unit: 'L',
                              color: AppColors.sky,
                              values: _series('water_liters'),
                              maxHint: 3,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _BarChart(
                              title: 'Move',
                              unit: 'min',
                              color: AppColors.coral,
                              values: _series('exercise_minutes'),
                              maxHint: 45,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _BarChart(
                              title: 'Sleep',
                              unit: 'h',
                              color: AppColors.secondary,
                              values: _series('sleep_hours'),
                              maxHint: 10,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _BarChart(
                              title: 'Calories',
                              unit: 'kcal',
                              color: AppColors.amber,
                              values: _series('calories'),
                              maxHint: 2200,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({
    required this.title,
    required this.unit,
    required this.color,
    required this.values,
  });

  final String title;
  final String unit;
  final Color color;
  final List<double?> values;

  @override
  Widget build(BuildContext context) {
    final present = values.whereType<double>().where((v) => v > 0).toList();
    final latest = present.isEmpty ? null : present.last;

    return HarmoniousCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const Spacer(),
              if (latest != null)
                Text(
                  '${latest.toStringAsFixed(1)} $unit',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: present.isEmpty
                ? const Center(
                    child: Icon(
                      Icons.show_chart_outlined,
                      color: AppColors.textMuted,
                      size: 28,
                    ),
                  )
                : CustomPaint(
                    painter: _AreaLinePainter(values: values, color: color),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.title,
    required this.unit,
    required this.color,
    required this.values,
    required this.maxHint,
  });

  final String title;
  final String unit;
  final Color color;
  final List<double?> values;
  final double maxHint;

  @override
  Widget build(BuildContext context) {
    final present = values.whereType<double>().where((v) => v > 0).toList();
    final latest = present.isEmpty ? null : present.last;

    return HarmoniousCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            latest == null
                ? '—'
                : unit == 'L'
                    ? '${latest.toStringAsFixed(1)} $unit'
                    : unit == 'h'
                        ? '${latest.toStringAsFixed(1)} $unit'
                        : '${latest.round()} $unit',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            width: double.infinity,
            child: present.isEmpty
                ? const Center(
                    child: Icon(
                      Icons.bar_chart_rounded,
                      color: AppColors.textMuted,
                      size: 24,
                    ),
                  )
                : CustomPaint(
                    painter: _BarsPainter(
                      values: values,
                      color: color,
                      maxHint: maxHint,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AreaLinePainter extends CustomPainter {
  const _AreaLinePainter({required this.values, required this.color});

  final List<double?> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final points = <Offset>[];
    final present = values.whereType<double>().where((v) => v > 0).toList();
    if (present.isEmpty) return;

    var minV = present.reduce(math.min);
    var maxV = present.reduce(math.max);
    if ((maxV - minV).abs() < 0.01) {
      minV -= 1;
      maxV += 1;
    }
    final pad = (maxV - minV) * 0.12;
    minV -= pad;
    maxV += pad;

    final span = values.length <= 1 ? 1 : values.length - 1;
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v == null || v <= 0) continue;
      final x = values.length == 1 ? size.width / 2 : size.width * i / span;
      final t = ((v - minV) / (maxV - minV)).clamp(0.0, 1.0);
      final y = size.height - t * (size.height - 8) - 4;
      points.add(Offset(x, y));
    }
    if (points.isEmpty) return;

    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final mid = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      line.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    line.lineTo(points.last.dx, points.last.dy);

    final fill = Path.from(line)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            color.withValues(alpha: 0.35),
            color.withValues(alpha: 0.02),
          ],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    canvas.drawCircle(points.last, 4.2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _AreaLinePainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class _BarsPainter extends CustomPainter {
  const _BarsPainter({
    required this.values,
    required this.color,
    required this.maxHint,
  });

  final List<double?> values;
  final Color color;
  final double maxHint;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final present = values.whereType<double>().where((v) => v > 0).toList();
    final dataMax = present.isEmpty
        ? maxHint
        : present.reduce(math.max).clamp(maxHint * 0.4, double.infinity);
    final n = values.length;
    final gap = size.width / (n * 2.6);
    final barW = ((size.width - gap * (n + 1)) / n).clamp(2.0, 10.0);

    for (var i = 0; i < n; i++) {
      final v = values[i] ?? 0;
      if (v <= 0) continue;
      final h = (v / dataMax).clamp(0.0, 1.0) * (size.height - 2);
      final x = gap + i * (barW + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - h, barW, math.max(h, 2)),
        const Radius.circular(3),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              color.withValues(alpha: 0.35),
              color,
            ],
          ).createShader(rect.outerRect),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.color != color ||
      oldDelegate.maxHint != maxHint;
}
