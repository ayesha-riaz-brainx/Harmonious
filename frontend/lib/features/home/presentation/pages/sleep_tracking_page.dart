import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/services/home_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/collapsible_history_card.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/quick_add_sheet.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_gradient_button.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

class SleepTrackingPage extends StatefulWidget {
  const SleepTrackingPage({super.key});

  @override
  State<SleepTrackingPage> createState() => _SleepTrackingPageState();
}

class _SleepEntry {
  const _SleepEntry({
    required this.id,
    required this.at,
    required this.hours,
  });

  final String id;
  final DateTime at;
  final double hours;
}

class _SleepTrackingPageState extends State<SleepTrackingPage> {
  final _api = FeatureService();
  final _home = HomeService();

  List<_SleepEntry> _entries = const [];
  TodayState? _today;
  bool _loading = true;
  bool _changed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.get('captures?limit=100'),
        _home.fetchToday(),
        _api.get('journey'),
      ]);
      final capturesResult = results[0] as Map<String, dynamic>;
      final dashboard = results[1] as HomeDashboard;
      final journey = results[2] as Map<String, dynamic>;

      final byDay = <String, _SleepEntry>{};

      final raw = (capturesResult['captures'] as List?) ?? const [];
      for (final item in raw.whereType<Map>()) {
        final json = Map<String, dynamic>.from(item);
        if (json['type']?.toString() != 'sleep') continue;
        final entry = _fromCapture(json);
        if (entry == null) continue;
        final key = DateFormat('yyyy-MM-dd').format(entry.at.toLocal());
        byDay[key] = entry;
      }

      final trends = ((journey['trends'] as List?) ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map));
      for (final row in trends) {
        final hours = (row['sleep_hours'] as num?)?.toDouble();
        if (hours == null || hours <= 0) continue;
        final rawDate = row['log_date']?.toString() ?? '';
        final date = DateTime.tryParse(rawDate);
        if (date == null) continue;
        final key = DateFormat('yyyy-MM-dd').format(date);
        byDay.putIfAbsent(
          key,
          () => _SleepEntry(
            id: 'log_$key',
            at: date,
            hours: hours,
          ),
        );
      }

      final entries = byDay.values.toList()
        ..sort((a, b) => b.at.compareTo(a.at));

      if (!mounted) return;
      setState(() {
        _entries = entries;
        _today = dashboard.today;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  _SleepEntry? _fromCapture(Map<String, dynamic> json) {
    final payload = json['payload'] is Map
        ? Map<String, dynamic>.from(json['payload'] as Map)
        : <String, dynamic>{};
    final hours = (payload['hours'] as num?)?.toDouble();
    if (hours == null || hours <= 0) return null;
    final raw = json['captured_at']?.toString();
    return _SleepEntry(
      id: json['id']?.toString() ?? '',
      at: raw != null ? DateTime.tryParse(raw) ?? DateTime.now() : DateTime.now(),
      hours: hours,
    );
  }

  Future<void> _logSleep() async {
    final result = await showQuickCapture(
      context,
      action: QuickAddAction.sleep,
    );
    if (!mounted || result?.saved != true) return;
    setState(() => _changed = true);
    await _load();
  }

  String _formatHours(double hours) {
    return hours == hours.roundToDouble()
        ? '${hours.toStringAsFixed(0)} h'
        : '${hours.toStringAsFixed(1)} h';
  }

  @override
  Widget build(BuildContext context) {
    final todayHours = _today?.sleepHours;

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
            title: const Text('Sleep'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.of(context).pop(_changed),
            ),
          ),
          body: SafeArea(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? HarmoniousErrorState(message: _error!, onRetry: _load)
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
                            accentColor: AppColors.lavender,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Last night',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.lavender,
                                        letterSpacing: 1,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  todayHours != null && todayHours > 0
                                      ? _formatHours(todayHours)
                                      : 'Not logged',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          HarmoniousGradientButton(
                            label: 'Log sleep',
                            onPressed: _logSleep,
                          ),
                          const SizedBox(height: 22),
                          CollapsibleHistoryCard(
                            itemCount: _entries.length,
                            emptyMessage:
                                'No sleep logged yet. Tap Log sleep to add your first.',
                            title: 'History',
                            itemBuilder: (context, i) {
                              final entry = _entries[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        DateFormat('EEE, MMM d')
                                            .format(entry.at.toLocal()),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatHours(entry.hours),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.lavender,
                                      ),
                                    ),
                                  ],
                                ),
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
