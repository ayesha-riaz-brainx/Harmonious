import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

/// Meaningful capture types — not every water sip / meal.
const _momentTypes = {
  'workout',
  'journal',
  'health_report',
  'weight',
  'mood',
  'sleep',
  'ai_report',
  'diet_plan',
  'workout_plan',
};

class HealthJourneyPage extends StatefulWidget {
  const HealthJourneyPage({super.key});

  @override
  State<HealthJourneyPage> createState() => _HealthJourneyPageState();
}

class _HealthJourneyPageState extends State<HealthJourneyPage> {
  final _api = FeatureService();

  bool _loading = true;
  bool _analyzing = false;
  bool _showAllMoments = false;

  List<Map<String, dynamic>> _timeline = [];
  List<Map<String, dynamic>> _trends = [];
  List<Map<String, dynamic>> _story = [];
  List<Map<String, dynamic>> _beforeVsNow = [];
  Map<String, dynamic>? _nextMilestone;
  Map<String, dynamic>? _analysis;

  @override
  void initState() {
    super.initState();
    // Rules-only on open — AI reflection is explicit via the app bar action.
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _api.get('journey');
      if (!mounted) return;
      setState(() {
        _timeline = _asMaps(data['timeline']);
        _trends = _asMaps(data['trends']);
        _story = _asMaps(data['story'])
            .where((e) => e['unlocked'] == true)
            .toList();
        _beforeVsNow = _asMaps(data['before_vs_now']);
        _nextMilestone = data['next_milestone'] is Map
            ? Map<String, dynamic>.from(data['next_milestone'] as Map)
            : null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      _toast(error);
    }
  }

  Future<void> _analyze({bool silent = false}) async {
    if (_analyzing) return;
    setState(() => _analyzing = true);
    try {
      final data = await _api.post('ai/tool', {
        'tool': 'health_journey',
        'input': {},
      });
      if (!mounted) return;
      setState(() {
        _analysis = Map<String, dynamic>.from(data['result'] as Map? ?? {});
        _analyzing = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _analyzing = false);
      if (!silent) _toast(error);
    }
  }

  List<Map<String, dynamic>> _asMaps(Object? raw) {
    return ((raw as List?) ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  void _toast(Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString().replaceFirst('Exception: ', '')),
      ),
    );
  }

  Map<String, dynamic> get _journey =>
      Map<String, dynamic>.from(_analysis?['journey'] as Map? ?? {});

  List<String> get _discoveries {
    final fromAi = ((_journey['discoveries'] as List?) ?? [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .take(3)
        .toList();
    if (fromAi.isNotEmpty) return fromAi;
    return ((_journey['habits'] as List?) ?? [])
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .take(3)
        .toList();
  }

  String get _reflection {
    final text = _journey['reflection']?.toString().trim();
    if (text != null && text.isNotEmpty) return text;
    return _analysis?['summary']?.toString().trim() ?? '';
  }

  Map<String, dynamic>? get _next {
    final raw = _journey['next_milestone'];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return _nextMilestone;
  }

  List<Map<String, dynamic>> get _chartDays {
    if (_trends.isEmpty) return const [];
    if (_trends.length <= 14) return _trends;
    return _trends.sublist(_trends.length - 14);
  }

  List<double?> _series(String key) {
    return [
      for (final row in _chartDays) (row[key] as num?)?.toDouble(),
    ];
  }

  /// Curated moments: skip noisy water/meal spam; one entry per day+type.
  List<Map<String, dynamic>> get _moments {
    final seen = <String>{};
    final out = <Map<String, dynamic>>[];

    for (final entry in _timeline) {
      final type = entry['type']?.toString() ?? '';
      if (!_momentTypes.contains(type)) continue;

      final at = DateTime.tryParse(entry['captured_at']?.toString() ?? '');
      final day = at == null
          ? 'x'
          : DateFormat('yyyy-MM-dd').format(at.toLocal());
      final key = '$day|$type';
      if (!seen.add(key)) continue;

      out.add(entry);
      if (out.length >= 24) break;
    }
    return out;
  }

  List<Map<String, dynamic>> get _visibleMoments {
    final all = _moments;
    if (_showAllMoments || all.length <= 6) return all;
    return all.take(6).toList();
  }

  Future<void> _openMoment(Map<String, dynamic> entry) async {
    final payload = Map<String, dynamic>.from(entry['payload'] as Map? ?? {});
    final at = DateTime.tryParse(entry['captured_at']?.toString() ?? '');
    final when = at == null
        ? ''
        : DateFormat('EEEE, MMM d · h:mm a').format(at.toLocal());
    final color = _colorFor(entry['type']?.toString());
    final icon = _iconFor(entry['type']?.toString());

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBorder,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry['title']?.toString() ?? 'Moment',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (when.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    when,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Text(
                  entry['detail']?.toString() ?? '',
                  style: const TextStyle(
                    height: 1.5,
                    fontSize: 15,
                    color: AppColors.textSecondary,
                  ),
                ),
                if (payload.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  for (final item in payload.entries.take(5))
                    if (item.value != null &&
                        item.value.toString().trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          '${_label(item.key)}  ·  ${item.value}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _label(String key) => key.replaceAll('_', ' ');

  static IconData _iconFor(String? type) {
    return switch (type) {
      'workout' || 'workout_plan' => Icons.fitness_center_rounded,
      'journal' => Icons.edit_note_rounded,
      'health_report' => Icons.description_outlined,
      'weight' => Icons.monitor_weight_outlined,
      'mood' => Icons.favorite_border_rounded,
      'sleep' => Icons.bedtime_outlined,
      'ai_report' => Icons.auto_awesome_outlined,
      'diet_plan' || 'meal' => Icons.restaurant_outlined,
      'water' => Icons.water_drop_outlined,
      _ => Icons.circle_outlined,
    };
  }

  static Color _colorFor(String? type) {
    return switch (type) {
      'workout' || 'workout_plan' => AppColors.coral,
      'journal' => AppColors.amber,
      'health_report' => AppColors.lavenderBright,
      'weight' => AppColors.aqua,
      'mood' => AppColors.mint,
      'sleep' => AppColors.lavender,
      'ai_report' => AppColors.lavenderBright,
      'diet_plan' || 'meal' => AppColors.amber,
      'water' => AppColors.sky,
      _ => AppColors.lavenderMuted,
    };
  }

  static IconData _storyIcon(String? id) {
    return switch (id) {
      'started' => Icons.flag_outlined,
      'first_water_goal' => Icons.water_drop_outlined,
      'first_workout' => Icons.fitness_center_rounded,
      'mood_week' => Icons.favorite_border_rounded,
      'lost_2kg' => Icons.trending_down_rounded,
      'streak_30' => Icons.local_fire_department_outlined,
      _ => Icons.check_circle_outline_rounded,
    };
  }

  static Color _storyColor(String? id) {
    return switch (id) {
      'started' => AppColors.lavenderBright,
      'first_water_goal' => AppColors.sky,
      'first_workout' => AppColors.coral,
      'mood_week' => AppColors.mint,
      'lost_2kg' => AppColors.aqua,
      'streak_30' => AppColors.amber,
      _ => AppColors.lavenderMuted,
    };
  }

  static Color _compareColor(String? id) {
    return switch (id) {
      'weight' => AppColors.aqua,
      'sleep' => AppColors.lavender,
      'mood' => AppColors.mint,
      'water' => AppColors.sky,
      _ => AppColors.lavenderMuted,
    };
  }

  @override
  Widget build(BuildContext context) {
    final reflection = _reflection;
    final discoveries = _discoveries;
    final next = _next;
    final moments = _visibleMoments;
    final allMoments = _moments;
    final weightSeries = _series('weight');
    final hasWeight = weightSeries.any((v) => v != null);
    final lineSeries = hasWeight ? weightSeries : _series('sleep_hours');
    final lineTitle = hasWeight ? 'Weight' : 'Sleep';
    final lineUnit = hasWeight ? 'kg' : 'h';
    final lineColor = hasWeight ? AppColors.aqua : AppColors.lavender;
    final waterSeries = _series('water_liters');
    final moveSeries = _series('exercise_minutes');

    return HarmoniousBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Health Journey'),
          actions: [
            IconButton(
              tooltip: 'Refresh reflection',
              onPressed: _analyzing ? null : () => _analyze(),
              icon: _analyzing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_outlined, size: 22),
            ),
          ],
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
                  children: [
                    const HarmoniousSectionHeader(
                      title: 'How far you’ve come',
                      subtitle:
                          'A quiet look at your progress — not another dashboard.',
                    ),

                    // —— Before → Now
                    if (_beforeVsNow.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      for (var i = 0; i < _beforeVsNow.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        _CompareRow(
                          item: _beforeVsNow[i],
                          color: _compareColor(
                            _beforeVsNow[i]['id']?.toString(),
                          ),
                        ),
                      ],
                    ],

                    // —— Graphs
                    if (_chartDays.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      const _Heading('Trends', color: AppColors.lavenderBright),
                      const SizedBox(height: 14),
                      _LineChartCard(
                        title: lineTitle,
                        unit: lineUnit,
                        color: lineColor,
                        values: lineSeries,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _BarChartCard(
                              title: 'Water',
                              unit: 'L',
                              color: AppColors.sky,
                              values: waterSeries,
                              maxHint: 3,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _BarChartCard(
                              title: 'Move',
                              unit: 'min',
                              color: AppColors.coral,
                              values: moveSeries,
                              maxHint: 45,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // —— Reflection
                    const SizedBox(height: 32),
                    const _Heading('Reflection', color: AppColors.lavender),
                    const SizedBox(height: 12),
                    if (_analyzing && reflection.isEmpty)
                      const _Hint('Writing your reflection…')
                    else if (reflection.isEmpty)
                      const _Hint(
                        'Tap the sparkle icon above when you want an AI coach '
                        'reflection. Trends and chapters below are free.',
                      )
                    else
                      _ReflectionPanel(
                        reflection: reflection,
                        discoveries: discoveries,
                      ),

                    // —— Chapters
                    if (_story.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      const _Heading('Chapters', color: AppColors.mint),
                      const SizedBox(height: 16),
                      for (var i = 0; i < _story.length; i++)
                        _ChapterRow(
                          item: _story[i],
                          icon: _storyIcon(_story[i]['id']?.toString()),
                          color: _storyColor(_story[i]['id']?.toString()),
                          isLast: i == _story.length - 1,
                        ),
                    ],

                    // —— Moments
                    const SizedBox(height: 32),
                    const _Heading('Moments', color: AppColors.amber),
                    const SizedBox(height: 4),
                    const Text(
                      'Workouts, journals, weight, mood, and reports.',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (allMoments.isEmpty)
                      const _Hint(
                        'Meaningful logs will show up here as you go.',
                      )
                    else ...[
                      for (final entry in moments)
                        _MomentRow(
                          entry: entry,
                          icon: _iconFor(entry['type']?.toString()),
                          color: _colorFor(entry['type']?.toString()),
                          onTap: () => _openMoment(entry),
                        ),
                      if (allMoments.length > 6)
                        TextButton(
                          onPressed: () {
                            setState(
                              () => _showAllMoments = !_showAllMoments,
                            );
                          },
                          child: Text(
                            _showAllMoments
                                ? 'Show less'
                                : 'Show ${allMoments.length - 6} more',
                          ),
                        ),
                    ],

                    // —— Next
                    if (next != null) ...[
                      const SizedBox(height: 28),
                      _NextBlock(next: next),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text, {this.color = AppColors.textMuted});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.textSecondary,
        height: 1.45,
        fontSize: 14,
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({required this.item, required this.color});
  final Map<String, dynamic> item;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final improved = item['improved'] == true;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            color.withValues(alpha: 0.16),
            color.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (item['label']?.toString() ?? '').toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Started',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['started']?.toString() ?? '—',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 6, right: 6),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: improved ? AppColors.mint : AppColors.textMuted,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Now',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['now']?.toString() ?? '—',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartCard extends StatelessWidget {
  const _LineChartCard({
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
    final present = values.whereType<double>().toList();
    final latest = present.isEmpty ? null : present.last;
    final first = present.isEmpty ? null : present.first;
    final delta = latest != null && first != null ? latest - first : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.18),
            AppColors.surface,
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
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
          if (delta != null) ...[
            const SizedBox(height: 4),
            Text(
              delta == 0
                  ? 'Steady over this period'
                  : '${delta > 0 ? '+' : ''}${delta.toStringAsFixed(1)} $unit vs start',
              style: TextStyle(
                fontSize: 12,
                color: delta <= 0 && title == 'Weight'
                    ? AppColors.mint
                    : delta >= 0 && title != 'Weight'
                        ? AppColors.mint
                        : AppColors.textMuted,
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            height: 110,
            width: double.infinity,
            child: present.isEmpty
                ? const Center(
                    child: Text(
                      'Not enough data yet',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  )
                : CustomPaint(
                    painter: _AreaLinePainter(values: values, color: color),
                  ),
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Text(
                '14 days',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              Spacer(),
              Text(
                'Latest',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarChartCard extends StatelessWidget {
  const _BarChartCard({
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
    final present = values.whereType<double>().toList();
    final latest = present.isEmpty ? null : present.last;
    final avg = present.isEmpty
        ? null
        : present.reduce((a, b) => a + b) / present.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.surface,
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            latest == null
                ? '—'
                : unit == 'L'
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
            height: 72,
            width: double.infinity,
            child: CustomPaint(
              painter: _BarsPainter(
                values: values,
                color: color,
                maxHint: maxHint,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            avg == null
                ? 'No data'
                : 'Avg ${unit == 'L' ? avg.toStringAsFixed(1) : avg.round().toString()} $unit',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReflectionPanel extends StatelessWidget {
  const _ReflectionPanel({
    required this.reflection,
    required this.discoveries,
  });

  final String reflection;
  final List<String> discoveries;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lavender.withValues(alpha: 0.14),
            AppColors.surface,
          ],
        ),
        border: Border.all(
          color: AppColors.lavender.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reflection,
            style: const TextStyle(
              fontSize: 15,
              height: 1.55,
              color: AppColors.textPrimary,
            ),
          ),
          if (discoveries.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final d in discoveries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppColors.lavenderBright,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        d,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          height: 1.4,
                          fontSize: 13.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({
    required this.item,
    required this.icon,
    required this.color,
    required this.isLast,
  });

  final Map<String, dynamic> item;
  final IconData icon;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final at = DateTime.tryParse(item['at']?.toString() ?? '');
    final when =
        at == null ? null : DateFormat('MMM d, y').format(at.toLocal());

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.16),
                    border: Border.all(color: color.withValues(alpha: 0.55)),
                  ),
                  child: Icon(icon, size: 15, color: color),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withValues(alpha: 0.5),
                            AppColors.surfaceBorder,
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),
                  Text(
                    item['title']?.toString() ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  if (when != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      when,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.85),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentRow extends StatelessWidget {
  const _MomentRow({
    required this.entry,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final Map<String, dynamic> entry;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final at = DateTime.tryParse(entry['captured_at']?.toString() ?? '');
    final day = at == null ? '' : _dayLabel(at.toLocal());

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 68,
              child: Text(
                day,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry['title']?.toString() ?? 'Moment',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry['detail']?.toString() ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _dayLabel(DateTime local) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    if (day == today) return 'Today';
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return DateFormat('MMM d').format(local);
  }
}

class _NextBlock extends StatelessWidget {
  const _NextBlock({required this.next});
  final Map<String, dynamic> next;

  @override
  Widget build(BuildContext context) {
    final progress =
        ((next['progress'] as num?)?.toDouble() ?? 0).clamp(0, 100);
    final days = (next['expected_days'] as num?)?.toInt();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.aqua.withValues(alpha: 0.16),
            AppColors.mint.withValues(alpha: 0.08),
            AppColors.surface,
          ],
        ),
        border: Border.all(color: AppColors.aqua.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Heading('Next', color: AppColors.aqua),
          const SizedBox(height: 12),
          Text(
            next['title']?.toString() ?? 'Keep going',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            [
              if (days != null) 'About $days days',
              '${progress.round()}% there',
            ].join('  ·  '),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 7,
              backgroundColor: AppColors.surfaceBorder,
              color: AppColors.aqua,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            next['encouragement']?.toString() ?? 'Keep going.',
            style: const TextStyle(
              color: AppColors.mint,
              fontWeight: FontWeight.w700,
              fontSize: 14,
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
    final present = values.whereType<double>().toList();
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
      if (v == null) continue;
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

    final dot = Paint()..color = color;
    canvas.drawCircle(points.last, 4.2, dot);
    canvas.drawCircle(points.last, 4.2, Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
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
    final present = values.whereType<double>().toList();
    final dataMax = present.isEmpty
        ? maxHint
        : present.reduce(math.max).clamp(maxHint * 0.4, double.infinity);
    final n = values.length;
    final gap = size.width / (n * 2.6);
    final barW = ((size.width - gap * (n + 1)) / n).clamp(3.0, 10.0);

    for (var i = 0; i < n; i++) {
      final v = values[i] ?? 0;
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
