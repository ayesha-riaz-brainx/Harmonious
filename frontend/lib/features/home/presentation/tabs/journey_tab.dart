import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';

class JourneyTab extends StatefulWidget {
  const JourneyTab({super.key});

  @override
  JourneyTabState createState() => JourneyTabState();
}

class JourneyTabState extends State<JourneyTab> {
  final _api = FeatureService();
  List<Map<String, dynamic>> _timeline = [];
  List<Map<String, dynamic>> _trends = [];
  bool _loading = true;
  bool _reporting = false;

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
        _timeline = ((data['timeline'] as List?) ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
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

  Future<void> _review(String period) async {
    setState(() => _reporting = true);
    try {
      final data = await _api.post('journey/review', {'period': period});
      if (!mounted) return;
      setState(() => _reporting = false);
      final report = Map<String, dynamic>.from(data['report'] as Map? ?? {});
      await _showReport(report);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _reporting = false);
      _toast(error);
    }
  }

  Future<void> _showReport(Map<String, dynamic> report) {
    final highlights =
        ((report['highlights'] as List?) ?? []).map((e) => e.toString());
    final next =
        ((report['next_steps'] as List?) ?? []).map((e) => e.toString());
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .72,
        maxChildSize: .92,
        builder: (context, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(22),
          children: [
            Text(
              report['title']?.toString() ?? 'Progress Review',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Text(
              report['summary']?.toString() ?? '',
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 18),
            const Text(
              'Highlights',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final item in highlights)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• $item'),
              ),
            const SizedBox(height: 14),
            const Text(
              'Next steps',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final item in next)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• $item'),
              ),
          ],
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

  Map<String, List<Map<String, dynamic>>> _groupedTimeline() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final groups = <String, List<Map<String, dynamic>>>{};

    for (final entry in _timeline) {
      final time = DateTime.tryParse(entry['captured_at']?.toString() ?? '');
      final local = time?.toLocal();
      final day = local == null
          ? null
          : DateTime(local.year, local.month, local.day);
      final label = day == null
          ? 'Earlier'
          : day == today
              ? 'Today'
              : day == yesterday
                  ? 'Yesterday'
                  : DateFormat('EEEE, MMM d').format(day);
      groups.putIfAbsent(label, () => []).add(entry);
    }
    return groups;
  }

  List<Map<String, dynamic>> get _latestTrends {
    if (_trends.length <= 14) return _trends;
    return _trends.sublist(_trends.length - 14);
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupedTimeline();

    return HarmoniousBackground(
      child: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: AppColors.lavender,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.insights_rounded,
                          color: AppColors.lavenderBright,
                          size: 27,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Journey',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Your history, patterns, and progress reports.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Progress',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    _progressGrid(),
                    const SizedBox(height: 20),
                    _reports(),
                    const SizedBox(height: 20),
                    const Text(
                      'Timeline',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    if (_timeline.isEmpty)
                      _empty()
                    else
                      for (final group in groups.entries) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 10),
                          child: Text(
                            group.key,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.lavenderBright,
                            ),
                          ),
                        ),
                        for (final entry in group.value) _timelineItem(entry),
                      ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _progressGrid() {
    final data = _latestTrends;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _miniChart(
                title: 'Weight',
                color: AppColors.aqua,
                data: data,
                read: (row) => (row['weight'] as num?)?.toDouble(),
                normalize: (v, max) => max <= 0 ? 0 : (v / max).clamp(0, 1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _miniChart(
                title: 'Water',
                color: AppColors.sky,
                data: data,
                read: (row) => (row['water_liters'] as num?)?.toDouble() ?? 0,
                normalize: (v, _) => (v / 3).clamp(0, 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _miniChart(
                title: 'Workouts',
                color: AppColors.coral,
                data: data,
                read: (row) =>
                    (row['exercise_minutes'] as num?)?.toDouble() ?? 0,
                normalize: (v, _) => (v / 45).clamp(0, 1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _miniChart(
                title: 'Sleep',
                color: AppColors.lavender,
                data: data,
                read: (row) => (row['sleep_hours'] as num?)?.toDouble() ?? 0,
                normalize: (v, _) => (v / 10).clamp(0, 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _moodTrend(data),
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
            style: TextStyle(
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

  Widget _moodTrend(List<Map<String, dynamic>> data) {
    final moods = <String>[
      for (final row in data)
        if ((row['mood']?.toString() ?? '').isNotEmpty) row['mood'].toString(),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mood trends',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 10),
          if (moods.isEmpty)
            const Text(
              'Log mood from Add to see trends here.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mood in moods.take(14))
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.mint.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: AppColors.mint.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      mood,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _reports() {
    final reports = [
      ('Weekly AI Review', 'Weekly'),
      ('Monthly AI Review', 'Monthly'),
      ('Yearly Life Report', 'Yearly'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reports',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        for (final report in reports)
          Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: InkWell(
              onTap: _reporting ? null : () => _review(report.$2),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.lavender.withValues(alpha: 0.12),
                      AppColors.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.lavenderBright,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        report.$1,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    _reporting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textMuted,
                          ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _timelineItem(Map<String, dynamic> entry) {
    final type = entry['type']?.toString() ?? 'update';
    final payload = Map<String, dynamic>.from(entry['payload'] as Map? ?? {});
    final time = DateTime.tryParse(entry['captured_at']?.toString() ?? '');
    final config = _typeConfig(type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: config.$2.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(config.$1, color: config.$2, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _describe(type, payload),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (time != null) ...[
                    const SizedBox(height: 5),
                    Text(
                      DateFormat('h:mm a').format(time.toLocal()),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
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

  (IconData, Color) _typeConfig(String type) => switch (type) {
        'water' => (Icons.water_drop_rounded, AppColors.sky),
        'meal' => (Icons.restaurant_rounded, AppColors.amber),
        'weight' => (Icons.monitor_weight_outlined, AppColors.aqua),
        'workout' => (Icons.fitness_center_rounded, AppColors.coral),
        'mood' => (Icons.mood_rounded, AppColors.mint),
        'sleep' => (Icons.bedtime_rounded, AppColors.lavender),
        'journal' => (Icons.edit_note_rounded, AppColors.sky),
        'health_report' => (Icons.description_rounded, AppColors.coral),
        'ai_report' => (Icons.auto_awesome_rounded, AppColors.lavender),
        'ai_tool' => (Icons.auto_fix_high_rounded, AppColors.aqua),
        _ => (Icons.check_circle_outline_rounded, AppColors.textSecondary),
      };

  String _describe(String type, Map<String, dynamic> payload) {
    return switch (type) {
      'water' => () {
        final glasses = payload['glasses'];
        if (glasses != null) return '$glasses glass${glasses == 1 ? '' : 'es'} logged';
        final liters = (payload['liters'] as num?)?.toDouble() ?? 0.25;
        final count = (liters / 0.25).round();
        return '$count glass${count == 1 ? '' : 'es'} logged';
      }(),
      'meal' =>
        '${payload['name'] ?? 'Meal'} · ${payload['calories'] ?? 0} kcal',
      'weight' => 'Weight updated to ${payload['weight']} kg',
      'workout' =>
        '${payload['activity'] ?? 'Workout'} · ${payload['minutes'] ?? 0} min',
      'mood' => 'Mood: ${payload['mood'] ?? 'Updated'}',
      'sleep' => '${payload['hours'] ?? 0} hours sleep logged',
      'journal' => payload['text']?.toString() ?? 'Journal entry',
      'health_report' =>
        'Health report added: ${payload['name'] ?? 'Document'}',
      'ai_report' => '${payload['period'] ?? 'Progress'} AI report created',
      'ai_tool' => 'AI tool: ${payload['tool'] ?? 'analysis'}',
      _ => type.replaceAll('_', ' '),
    };
  }

  Widget _empty() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: const Text(
          'Use Add to log your first activity. It will appear here instantly.',
          style: TextStyle(color: AppColors.textSecondary, height: 1.4),
        ),
      );
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
