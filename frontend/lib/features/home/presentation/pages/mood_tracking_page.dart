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

class MoodTrackingPage extends StatefulWidget {
  const MoodTrackingPage({super.key});

  @override
  State<MoodTrackingPage> createState() => _MoodTrackingPageState();
}

class _MoodEntry {
  const _MoodEntry({
    required this.id,
    required this.at,
    required this.mood,
  });

  final String id;
  final DateTime at;
  final String mood;
}

class _MoodTrackingPageState extends State<MoodTrackingPage> {
  final _api = FeatureService();
  final _home = HomeService();

  List<_MoodEntry> _entries = const [];
  String? _todayMood;
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
          .where((e) => e['type']?.toString() == 'mood')
          .map(_fromCapture)
          .whereType<_MoodEntry>()
          .toList()
        ..sort((a, b) => b.at.compareTo(a.at));

      if (!mounted) return;
      setState(() {
        _entries = entries;
        _todayMood = dashboard.today.mood;
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

  _MoodEntry? _fromCapture(Map<String, dynamic> json) {
    final payload = json['payload'] is Map
        ? Map<String, dynamic>.from(json['payload'] as Map)
        : <String, dynamic>{};
    final mood = (payload['mood'] ?? '').toString().trim();
    if (mood.isEmpty) return null;
    final raw = json['captured_at']?.toString();
    return _MoodEntry(
      id: json['id']?.toString() ?? '',
      at: raw != null ? DateTime.tryParse(raw) ?? DateTime.now() : DateTime.now(),
      mood: mood,
    );
  }

  Future<void> _logMood() async {
    final result = await showQuickCapture(
      context,
      action: QuickAddAction.mood,
    );
    if (!mounted || result?.saved != true) return;
    setState(() => _changed = true);
    await _load();
  }

  Color _moodColor(String mood) {
    final value = mood.toLowerCase();
    if (value.contains('happy') || value.contains('great')) {
      return AppColors.mint;
    }
    if (value.contains('stress') || value.contains('anxious')) {
      return AppColors.coral;
    }
    if (value.contains('tired')) return AppColors.amber;
    return AppColors.sky;
  }

  @override
  Widget build(BuildContext context) {
    final current = _todayMood?.trim();

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
            title: const Text('Mood'),
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
                            accentColor: AppColors.mint,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: AppColors.mint,
                                        letterSpacing: 1,
                                      ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  (current == null || current.isEmpty)
                                      ? 'Not logged yet'
                                      : current,
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
                            label: 'Log mood',
                            onPressed: _logMood,
                          ),
                          const SizedBox(height: 22),
                          CollapsibleHistoryCard(
                            itemCount: _entries.length,
                            emptyMessage:
                                'No moods logged yet. Tap Log mood to add your first.',
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
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _moodColor(entry.mood),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.mood,
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
