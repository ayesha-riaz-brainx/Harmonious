import 'package:flutter/material.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/journey_report_page.dart';
import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

class JourneyTab extends StatefulWidget {
  const JourneyTab({super.key});

  @override
  JourneyTabState createState() => JourneyTabState();
}

class JourneyTabState extends State<JourneyTab> {
  final _api = FeatureService();
  List<Map<String, dynamic>> _trends = [];
  Map<String, dynamic>? _todayReview;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await _api.get('journey');
      if (!mounted) return;
      setState(() {
        _todayReview = data['today_review'] is Map
            ? Map<String, dynamic>.from(data['today_review'] as Map)
            : null;
        _trends = ((data['trends'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast(error);
    }
  }

  Future<void> refresh() => _load();

  void _openReport(String title, String period) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => JourneyReportPage(
          title: title,
          period: period,
          trends: _trends,
        ),
      ),
    );
  }

  void _toast(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString().replaceFirst('Exception: ', '')),
      ),
    );
  }

  Map<String, dynamic>? get _reviewFromTrends {
    if (_todayReview != null) return _todayReview;
    if (_trends.isEmpty) return null;

    final now = DateTime.now();
    final todayKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    Map<String, dynamic>? row;
    for (final entry in _trends.reversed) {
      final raw = entry['log_date']?.toString() ?? '';
      final key = raw.length >= 10 ? raw.substring(0, 10) : raw;
      if (key == todayKey) {
        row = entry;
        break;
      }
    }
    if (row == null) {
      return const {
        'has_data': false,
        'meals': {'label': 'No meals logged'},
        'water': {'label': 'No water logged'},
        'activity': {'label': 'No activity logged'},
        'mood': {'label': 'Not set'},
        'sleep': {'label': 'Not logged'},
      };
    }

    final calories = (row['calories'] as num?)?.toInt() ?? 0;
    final water = (row['water_liters'] as num?)?.toDouble() ?? 0;
    final glasses = (water / 0.25).round();
    final exercise = (row['exercise_minutes'] as num?)?.toInt() ?? 0;
    final mood = row['mood']?.toString();
    final sleep = (row['sleep_hours'] as num?)?.toDouble();
    final weight = (row['weight'] as num?)?.toDouble();

    return {
      'has_data': calories > 0 ||
          water > 0 ||
          exercise > 0 ||
          (mood != null && mood.isNotEmpty) ||
          (sleep != null && sleep > 0) ||
          (weight != null && weight > 0),
      'meals': {'label': calories > 0 ? '$calories kcal logged' : 'No meals logged'},
      'water': {
        'label': water > 0
            ? '$glasses glass${glasses == 1 ? '' : 'es'} · ${water.toStringAsFixed(1)} L'
            : 'No water logged',
      },
      'activity': {
        'label': exercise > 0 ? '$exercise min exercise' : 'No activity logged',
      },
      'mood': {'label': mood ?? 'Not set'},
      'sleep': {
        'label': sleep != null && sleep > 0
            ? '${sleep % 1 == 0 ? sleep.toStringAsFixed(0) : sleep.toStringAsFixed(1)} h sleep'
            : 'Not logged',
      },
    };
  }

  List<Map<String, dynamic>> get _latestTrends {
    if (_trends.length <= 14) return _trends;
    return _trends.sublist(_trends.length - 14);
  }

  @override
  Widget build(BuildContext context) {
    final review = _reviewFromTrends;

    return HarmoniousBackground(
      child: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: AppColors.primary,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    HarmoniousSpacing.screenHorizontal,
                    16,
                    HarmoniousSpacing.screenHorizontal,
                    32,
                  ),
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  children: [
                    const HarmoniousPageHeader(
                      icon: Icons.show_chart_rounded,
                      title: 'Journey',
                    ),
                    const SizedBox(height: HarmoniousSpacing.sectionGap),
                    _todaysReview(review),
                    const HarmoniousSectionDivider(),
                    const SizedBox(height: 12),
                    const HarmoniousSectionHeader(
                      title: 'Trends',
                    ),
                    const SizedBox(height: 12),
                    _progressGrid(),
                    const HarmoniousSectionDivider(),
                    const SizedBox(height: 12),
                    _reports(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _todaysReview(Map<String, dynamic>? review) {
    final hasData = review?['has_data'] == true;
    final meals = Map<String, dynamic>.from(review?['meals'] as Map? ?? {});
    final water = Map<String, dynamic>.from(review?['water'] as Map? ?? {});
    final activity =
        Map<String, dynamic>.from(review?['activity'] as Map? ?? {});
    final mood = Map<String, dynamic>.from(review?['mood'] as Map? ?? {});
    final sleep = Map<String, dynamic>.from(review?['sleep'] as Map? ?? {});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HarmoniousSectionHeader(
          title: "Today's Review",
        ),
        const SizedBox(height: 12),
        HarmoniousCard(
          child: hasData
              ? Column(
                  children: [
                    _reviewRow(
                      Icons.restaurant_outlined,
                      'Meals',
                      meals['label']?.toString() ?? '—',
                      AppColors.amber,
                    ),
                    _reviewRow(
                      Icons.water_drop_outlined,
                      'Water',
                      water['label']?.toString() ?? '—',
                      AppColors.sky,
                    ),
                    _reviewRow(
                      Icons.directions_run_outlined,
                      'Activity',
                      activity['label']?.toString() ?? '—',
                      AppColors.coral,
                    ),
                    _reviewRow(
                      Icons.sentiment_satisfied_alt_outlined,
                      'Mood',
                      mood['label']?.toString() ?? 'Not set',
                      AppColors.mint,
                    ),
                    _reviewRow(
                      Icons.bedtime_outlined,
                      'Sleep',
                      sleep['label']?.toString() ?? 'Not logged',
                      AppColors.secondary,
                      isLast: true,
                    ),
                  ],
                )
              : const HarmoniousEmptyState(
                  icon: Icons.add_circle_outline,
                  title: 'Nothing logged yet',
                  message:
                      'Tap Add on the bottom bar to log meals, water, mood, or activity.',
                  compact: true,
                ),
        ),
      ],
    );
  }

  Widget _reviewRow(
    IconData icon,
    String label,
    String value,
    Color color, {
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  bool _rowHasMeaningfulData(Map<String, dynamic> row) {
    final water = (row['water_liters'] as num?)?.toDouble() ?? 0;
    final calories = (row['calories'] as num?)?.toInt() ?? 0;
    final exercise = (row['exercise_minutes'] as num?)?.toInt() ?? 0;
    final sleep = (row['sleep_hours'] as num?)?.toDouble() ?? 0;
    final weight = (row['weight'] as num?)?.toDouble();
    final mood = row['mood']?.toString() ?? '';
    return water > 0 ||
        calories > 0 ||
        exercise > 0 ||
        sleep > 0 ||
        (weight != null && weight > 0) ||
        mood.isNotEmpty;
  }

  Widget _progressGrid() {
    final data = _latestTrends;
    if (data.isEmpty || !data.any(_rowHasMeaningfulData)) {
      return const HarmoniousCard(
        child: HarmoniousEmptyState(
          icon: Icons.show_chart_outlined,
          title: 'No trend data yet',
          message: 'Log water, workouts, or sleep for a few days to see charts.',
          compact: true,
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _miniChart(
                title: 'Weight',
                color: AppColors.aqua,
                data: data,
                read: (row) {
                  final value = (row['weight'] as num?)?.toDouble();
                  return value != null && value > 0 ? value : null;
                },
                normalize: (v, max) => max <= 0 ? 0 : (v / max).clamp(0, 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _miniChart(
                title: 'Water',
                color: AppColors.sky,
                data: data,
                read: (row) {
                  final value = (row['water_liters'] as num?)?.toDouble();
                  return value != null && value > 0 ? value : null;
                },
                normalize: (v, _) => (v / 3).clamp(0, 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _miniChart(
                title: 'Workouts',
                color: AppColors.coral,
                data: data,
                read: (row) {
                  final value =
                      (row['exercise_minutes'] as num?)?.toDouble();
                  return value != null && value > 0 ? value : null;
                },
                normalize: (v, _) => (v / 45).clamp(0, 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _miniChart(
                title: 'Sleep',
                color: AppColors.secondary,
                data: data,
                read: (row) {
                  final value = (row['sleep_hours'] as num?)?.toDouble();
                  return value != null && value > 0 ? value : null;
                },
                normalize: (v, _) => (v / 10).clamp(0, 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _miniChart({
    required String title,
    required Color color,
    required List<Map<String, dynamic>> data,
    required double? Function(Map<String, dynamic>) read,
    required double Function(double value, double max) normalize,
  }) {
    final values = data.map(read).whereType<double>().toList();
    final max = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);
    final latest = values.isEmpty ? null : values.last;

    return HarmoniousCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            latest == null
                ? '—'
                : title == 'Weight'
                    ? '${latest.toStringAsFixed(1)} kg'
                    : title == 'Water'
                        ? '${latest.toStringAsFixed(1)} L'
                        : title == 'Sleep'
                            ? '${latest.toStringAsFixed(1)} h'
                            : '${latest.round()} min',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            width: double.infinity,
            child: CustomPaint(
              painter: _SparklinePainter(
                points: [
                  for (final row in data)
                    normalize(read(row) ?? 0, max.toDouble()),
                ],
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reports() {
    final reports = [
      ('Weekly review', 'Weekly', 'Last 7 days'),
      ('Monthly review', 'Monthly', 'Last 31 days'),
      ('Yearly review', 'Yearly', 'Last 365 days'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HarmoniousSectionHeader(
          title: 'Reports',
        ),
        const SizedBox(height: 12),
        for (final report in reports)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: HarmoniousCard(
              padding: const EdgeInsets.all(15),
              onTap: () => _openReport(report.$1, report.$2),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.show_chart_outlined,
                      color: AppColors.primaryBright,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.$1,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          report.$3,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.points, required this.color});

  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final span = points.length == 1 ? 1 : points.length - 1;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = points.length == 1 ? size.width / 2 : size.width * i / span;
      final y = size.height - points[i].clamp(0, 1) * (size.height - 4) - 2;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
