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

class ExerciseTrackingPage extends StatefulWidget {
  const ExerciseTrackingPage({super.key});

  @override
  State<ExerciseTrackingPage> createState() => _ExerciseTrackingPageState();
}

class _ExerciseEntry {
  const _ExerciseEntry({
    required this.id,
    required this.at,
    required this.minutes,
    required this.label,
  });

  final String id;
  final DateTime at;
  final int minutes;
  final String label;
}

class _ExerciseTrackingPageState extends State<ExerciseTrackingPage> {
  final _api = FeatureService();
  final _home = HomeService();

  List<_ExerciseEntry> _entries = const [];
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
      ]);
      final capturesResult = results[0] as Map<String, dynamic>;
      final dashboard = results[1] as HomeDashboard;
      final raw = (capturesResult['captures'] as List?) ?? const [];
      final entries = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .where((e) => e['type']?.toString() == 'workout')
          .map(_fromCapture)
          .whereType<_ExerciseEntry>()
          .toList()
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

  _ExerciseEntry? _fromCapture(Map<String, dynamic> json) {
    final payload = json['payload'] is Map
        ? Map<String, dynamic>.from(json['payload'] as Map)
        : <String, dynamic>{};
    final minutes = (payload['minutes'] as num?)?.round() ?? 0;
    if (minutes <= 0) return null;
    final name =
        (payload['activity'] ?? payload['name'] ?? payload['label'] ?? '')
            .toString()
            .trim();
    final raw = json['captured_at']?.toString();
    return _ExerciseEntry(
      id: json['id']?.toString() ?? '',
      at: raw != null ? DateTime.tryParse(raw) ?? DateTime.now() : DateTime.now(),
      minutes: minutes,
      label: name.isEmpty ? 'Workout' : name,
    );
  }

  Future<void> _logExercise() async {
    final result = await showQuickCapture(
      context,
      action: QuickAddAction.workout,
    );
    if (!mounted || result?.saved != true) return;
    setState(() => _changed = true);
    await _load();
  }

  int get _todayMinutes => _today?.exerciseMinutes ?? 0;
  int get _goalMinutes => _today?.exerciseGoal ?? 30;

  @override
  Widget build(BuildContext context) {
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
            title: const Text('Exercise'),
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
                            accentColor: AppColors.coral,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.coral,
                                        letterSpacing: 1,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$_todayMinutes / $_goalMinutes min',
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
                            label: 'Log exercise',
                            onPressed: _logExercise,
                          ),
                          const SizedBox(height: 22),
                          CollapsibleHistoryCard(
                            itemCount: _entries.length,
                            emptyMessage:
                                'No workouts logged yet. Tap Log exercise to add your first.',
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
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.label,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            DateFormat('EEE, MMM d · h:mm a')
                                                .format(entry.at.toLocal()),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: AppColors.textMuted,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${entry.minutes} min',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.coral,
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
