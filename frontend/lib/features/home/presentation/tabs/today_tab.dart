import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/services/health_snapshot_service.dart';
import 'package:slot_1_tasks/core/services/home_service.dart';
import 'package:slot_1_tasks/core/services/streak_service.dart';
import 'package:slot_1_tasks/core/services/wellness_score_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/emotional_support_page.dart';
import 'package:slot_1_tasks/features/home/presentation/pages/journal_page.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/health_snapshot_card.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/mood_entertainment_card.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/quick_add_sheet.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/streak_card.dart';
import 'package:slot_1_tasks/features/onboarding/data/onboarding_options.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

class TodayTab extends StatefulWidget {
  const TodayTab({
    super.key,
    this.onDataChanged,
    this.onOpenToolsTab,
  });

  final Future<void> Function({bool includeToday})? onDataChanged;
  final VoidCallback? onOpenToolsTab;

  @override
  TodayTabState createState() => TodayTabState();
}

class TodayTabState extends State<TodayTab> with TickerProviderStateMixin {
  final _home = HomeService();
  final _features = FeatureService();
  final _streakService = StreakService();
  final _snapshotService = HealthSnapshotService();
  final _scroll = ScrollController();
  final _planKey = GlobalKey();

  HomeDashboard? _data;
  StreakSnapshot? _streak;
  WellnessScoreBreakdown? _wellness;
  HealthSnapshot? _healthSnapshot;
  ActiveFocus? _activeFocus;
  int _mealCount = 0;
  List<dynamic> _captures = const [];
  String? _error;
  bool _loading = true;
  bool _busy = false;

  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _load();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> reload({bool silent = false}) => _load(silent: silent);

  void applyHome(Map<String, dynamic> home) {
    if (!mounted) return;
    try {
      final parsed = HomeDashboard.fromJson(home);
      _reloadMetrics(parsed);
    } catch (_) {
      _load(silent: true);
    }
  }

  Future<void> _reloadMetrics(HomeDashboard data) async {
    try {
      final capturesResult = await _features.get('captures?limit=100');
      final captures = (capturesResult['captures'] as List?) ?? const [];
      await _refreshDerivedMetrics(data, captures: captures);
    } catch (_) {
      await _refreshDerivedMetrics(data);
    }
  }

  Future<void> _refreshDerivedMetrics(
    HomeDashboard data, {
    List<dynamic>? captures,
  }) async {
    final streak = await _streakService.evaluate(data.today);
    final captureList = captures ?? _captures;
    final meals = captures != null
        ? WellnessScoreService.mealCountFromCaptures(
            captures,
            DateTime.now(),
          )
        : _mealCount;
    final wellness = WellnessScoreService.calculate(
      today: data.today,
      mealCount: meals,
    );
    final snapshot = HealthSnapshotService.compute(
      dashboard: data,
      streak: streak,
      captures: captureList,
    );
    final focus = await _snapshotService.getActiveFocus();
    if (!mounted) return;
    setState(() {
      _data = data;
      _streak = streak;
      _wellness = wellness;
      _healthSnapshot = snapshot;
      _activeFocus = focus;
      if (captures != null) {
        _mealCount = meals;
        _captures = captures;
      }
      _loading = false;
      _error = null;
    });
  }

  Future<void> _refreshFocus() async {
    final focus = await _snapshotService.getActiveFocus();
    if (!mounted) return;
    setState(() => _activeFocus = focus);
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        _home.fetchToday(),
        _features.get('captures?limit=100'),
      ]);
      final data = results[0] as HomeDashboard;
      final capturesResult = results[1] as Map<String, dynamic>;
      final captures = (capturesResult['captures'] as List?) ?? const [];
      if (!mounted) return;
      await _refreshDerivedMetrics(data, captures: captures);
      if (!silent) _entrance.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (!silent) {
          _error = e.toString().replaceFirst('Exception: ', '');
        }
      });
    }
  }

  Future<void> _patch(Map<String, dynamic> body) async {
    setState(() => _busy = true);
    try {
      final data = await _home.updateToday(body);
      if (!mounted) return;
      await _reloadMetrics(data);
      await widget.onDataChanged?.call(includeToday: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> handleQuickAdd(QuickAddAction action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final outcome = await QuickCaptureFlow(context).run(action);
      if (!mounted) return;

      if (!outcome.saved) {
        if (outcome.message != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              SnackBar(content: Text(outcome.message!)),
            );
          });
        }
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        try {
          if (outcome.home != null) {
            await _reloadMetrics(HomeDashboard.fromJson(outcome.home!));
          } else {
            await _load(silent: true);
          }
        } catch (_) {
          await _load(silent: true);
        }
        if (!mounted) return;
        if (outcome.message != null) {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text(outcome.message!)),
          );
        }
        _dirtyNotify();
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _dirtyNotify() {
    widget.onDataChanged?.call(includeToday: false);
  }

  Future<void> _openJournalPage() async {
    if (_busy) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const JournalPage()),
    );
    if (!mounted || changed != true) return;
    await _load(silent: true);
    _dirtyNotify();
  }

  Future<void> _showAddHabitSheet() async {
    if (_busy || _data == null) return;
    final existingIds = _data!.today.tasks.map((t) => t.id).toSet();
    final custom = TextEditingController();
    final selected = <String>{};

    final added = await showModalBottomSheet<List<Map<String, String>>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              20 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add habits',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pick from presets or add your own.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 16),
                  for (final (id, label) in OnboardingOptions.habitPresets)
                    if (!existingIds.contains(id)) ...[
                      CheckboxListTile(
                        value: selected.contains(id),
                        onChanged: (_) => setSheetState(() {
                          selected.contains(id)
                              ? selected.remove(id)
                              : selected.add(id);
                        }),
                        title: Text(label),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: AppColors.lavender,
                      ),
                    ],
                  if (OnboardingOptions.habitPresets
                      .every((preset) => existingIds.contains(preset.$1)))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'All preset habits are already on your list.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ),
                  TextField(
                    controller: custom,
                    decoration: const InputDecoration(
                      labelText: 'Custom habit',
                      hintText: 'e.g. Stretch for 5 minutes',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      final value = custom.text.trim();
                      if (value.isEmpty) return;
                      final slug =
                          'custom_${value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}';
                      if (existingIds.contains(slug)) return;
                      setSheetState(() {
                        selected.add(slug);
                        custom.clear();
                      });
                    },
                    child: const Text('Add custom to selection'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: selected.isEmpty
                          ? null
                          : () {
                              final items = selected.map((id) {
                                String? preset;
                                for (final (habitId, label)
                                    in OnboardingOptions.habitPresets) {
                                  if (habitId == id) {
                                    preset = label;
                                    break;
                                  }
                                }
                                if (preset != null) {
                                  return {'id': id, 'label': preset};
                                }
                                final label = id.startsWith('custom_')
                                    ? id.substring(7).replaceAll('_', ' ')
                                    : id;
                                return {'id': id, 'label': label};
                              }).toList();
                              Navigator.pop(context, items);
                            },
                      child: const Text('Add to today'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!mounted || added == null || added.isEmpty) return;

    final nextTasks = [
      ..._data!.today.tasks,
      for (final item in added)
        HomeTask(
          id: item['id']!,
          label: _habitLabelForId(item['id']!, item['label']!),
          done: false,
        ),
    ];
    final templates = nextTasks.map((t) => t.id).toList();
    await _patch({
      'tasks': nextTasks.map((t) => t.toJson()).toList(),
      'habitTemplates': templates,
    });
  }

  String _habitLabelForId(String id, String fallback) {
    if (id == 'water') return 'Drink water';
    if (id == 'workout') return 'Move / exercise';
    if (id == 'breakfast') return 'Log breakfast';
    return fallback;
  }

  void _scrollToPlan() {
    final ctx = _planKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
      return;
    }
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      280,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 'Good morning';
    if (hour >= 12 && hour < 17) return 'Good afternoon';
    if (hour >= 17 && hour < 21) return 'Good evening';
    return 'Good night';
  }

  @override
  Widget build(BuildContext context) {
    return HarmoniousBackground(
      child: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? HarmoniousErrorState(
                    message: _error!,
                    onRetry: _load,
                    hint: 'Pull to refresh, or try again in a moment.',
                  )
                : RefreshIndicator(
                    color: AppColors.cyanAccent,
                    // Pull-to-refresh reloads tracked data only — no OpenAI.
                    onRefresh: () => _load(),
                    child: CustomScrollView(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 36),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _fadeSlide(
                                0,
                                _Header(
                                  greeting: _greeting(),
                                  name: _data!.greetingName,
                                ),
                              ),
                              if (_streak != null && _wellness != null) ...[
                                const SizedBox(height: 16),
                                _fadeSlide(
                                  1,
                                  IntrinsicHeight(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: StreakCard(streak: _streak!),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          flex: 2,
                                          child: WellnessScoreCard(
                                            breakdown: _wellness!,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                              if (_healthSnapshot != null) ...[
                                const SizedBox(height: 12),
                                _fadeSlide(
                                  2,
                                  HealthSnapshotCard(
                                    snapshot: _healthSnapshot!,
                                    activeFocus: _activeFocus,
                                    onFocusStarted: _refreshFocus,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              _fadeSlide(
                                3,
                                KeyedSubtree(
                                  key: _planKey,
                                  child: _ProgressSection(
                                    today: _data!.today,
                                    goals: _data!.activeGoals,
                                    busy: _busy,
                                    onLogWater: () =>
                                        handleQuickAdd(QuickAddAction.water),
                                    onAddMeal: () =>
                                        handleQuickAdd(QuickAddAction.meal),
                                    onStartWorkout: () =>
                                        handleQuickAdd(QuickAddAction.workout),
                                    onLogWeight: () =>
                                        handleQuickAdd(QuickAddAction.weight),
                                    onChangeMood: () =>
                                        handleQuickAdd(QuickAddAction.mood),
                                    onLogSleep: () =>
                                        handleQuickAdd(QuickAddAction.sleep),
                                    onOpenJournal: _openJournalPage,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _fadeSlide(
                                5,
                                _TasksSection(
                                  tasks: _data!.today.tasks,
                                  onAddHabit: _showAddHabitSheet,
                                  onRemove: (task) async {
                                    final next = _data!.today.tasks
                                        .where((t) => t.id != task.id)
                                        .toList();
                                    final templates = next.map((t) => t.id).toList();
                                    await _patch({
                                      'tasks':
                                          next.map((t) => t.toJson()).toList(),
                                      'habitTemplates': templates,
                                    });
                                  },
                                  onToggle: (task) async {
                                    final next = _data!.today.tasks
                                        .map(
                                          (t) => t.id == task.id
                                              ? HomeTask(
                                                  id: t.id,
                                                  label: t.label,
                                                  done: !t.done,
                                                )
                                              : t,
                                        )
                                        .toList();
                                    await _patch({
                                      'tasks':
                                          next.map((t) => t.toJson()).toList(),
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                              _fadeSlide(
                                6,
                                _WeekSection(
                                  history: _data!.weeklyHistory,
                                  today: _data!.today,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _fadeSlide(
                                7,
                                _GoalsSection(goals: _data!.activeGoals),
                              ),
                              const SizedBox(height: 24),
                              _fadeSlide(
                                7,
                                _WellnessFocusCard(
                                  brief: _data!.today.aiBrief,
                                  onPlan: _scrollToPlan,
                                  onOpenTools: widget.onOpenToolsTab,
                                ),
                              ),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _fadeSlide(int index, Widget child) {
    final start = (index * 0.09).clamp(0.0, 0.65);
    final end = (start + 0.38).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.09),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

/// Subtle scale-down on press — used for CTAs and habit rows.
class _Pressable extends StatefulWidget {
  const _Pressable({
    required this.child,
    this.onTap,
    this.borderRadius,
    this.scale = 0.97,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final double scale;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || widget.onTap == null) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? widget.scale : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOutCubic,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: _setPressed,
          borderRadius: widget.borderRadius,
          splashColor: AppColors.cyanAccent.withValues(alpha: 0.12),
          highlightColor: AppColors.cyanAccent.withValues(alpha: 0.05),
          child: widget.child,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.greeting,
    required this.name,
  });

  final String greeting;
  final String name;

  IconData get _timeIcon {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return Icons.wb_sunny_outlined;
    if (hour >= 12 && hour < 17) return Icons.wb_cloudy_outlined;
    if (hour >= 17 && hour < 21) return Icons.wb_twilight_outlined;
    return Icons.nightlight_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final date = intl.DateFormat('EEEE, MMMM d').format(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          date.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.textMuted,
                fontSize: 11,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Icon(
                _timeIcon,
                size: 26,
                color: AppColors.cyanAccent.withValues(alpha: 0.9),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$greeting,\n$name',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                      color: AppColors.textPrimary,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Mood-specific colors and gentle nudges for the Today dashboard.
class _MoodVisual {
  const _MoodVisual._();

  static Color? valueColor(String? mood) {
    switch (mood?.toLowerCase()) {
      case 'stressed':
      case 'anxious':
        return AppColors.coral;
      case 'tired':
        return AppColors.amber;
      case 'happy':
        return AppColors.mint;
      default:
        return null;
    }
  }

  static Color? accentColor(String? mood) {
    final color = valueColor(mood);
    return color?.withValues(alpha: 0.55);
  }

  static String? nudge(String? mood) {
    switch (mood?.toLowerCase()) {
      case 'stressed':
        return 'Consider a short pause';
      case 'anxious':
        return 'Take a breath — you\'ve got this';
      case 'tired':
        return 'Rest when you can today';
      default:
        return null;
    }
  }

  static IconData iconFor(String? mood) {
    switch (mood?.toLowerCase()) {
      case 'stressed':
        return Icons.sentiment_dissatisfied_outlined;
      case 'anxious':
        return Icons.psychology_outlined;
      case 'tired':
        return Icons.bedtime_outlined;
      case 'happy':
        return Icons.sentiment_very_satisfied_outlined;
      default:
        return Icons.sentiment_satisfied_alt_outlined;
    }
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.accentColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: accent == null
            ? AppColors.cardSurface
            : Color.alphaBlend(
                accent.withValues(alpha: 0.07),
                AppColors.cardSurface,
              ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accent == null
              ? AppColors.cardBorder.withValues(alpha: 0.85)
              : accent.withValues(alpha: 0.42),
        ),
      ),
      child: child,
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color.withValues(alpha: 0.95),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.25,
            ),
      ),
    );
  }
}

class _MetricActionLink extends StatelessWidget {
  const _MetricActionLink({
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: enabled ? AppColors.cyanAccent : AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.15,
              ),
        ),
      ),
    );
  }
}

class _MetricLogButton extends StatelessWidget {
  const _MetricLogButton({
    required this.label,
    this.onTap,
    this.fullWidth = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final child = OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: enabled ? AppColors.cyanAccent : AppColors.textMuted,
        backgroundColor: enabled
            ? AppColors.cyanAccent.withValues(alpha: 0.1)
            : AppColors.cardBorder.withValues(alpha: 0.2),
        side: BorderSide(
          color: enabled
              ? AppColors.cyanAccent.withValues(alpha: 0.65)
              : AppColors.cardBorder,
          width: 1.2,
        ),
        minimumSize: Size(fullWidth ? double.infinity : 44, 44),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 0.1,
            ),
      ),
      child: Text(label),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: child);
    }
    return child;
  }
}

class _CircularDayGauge extends StatelessWidget {
  const _CircularDayGauge({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    return SizedBox(
      width: 58,
      height: 58,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return CustomPaint(
            painter: _CircularGaugePainter(progress: value),
            child: Center(
              child: Text(
                '$percent%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cyanAccent,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CircularGaugePainter extends CustomPainter {
  const _CircularGaugePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;
    const startAngle = -3.14159 / 2;
    const sweepFull = 3.14159 * 2;

    final trackPaint = Paint()
      ..color = AppColors.cardBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    final arcPaint = Paint()
      ..shader = const SweepGradient(
        colors: [AppColors.cyanGradientStart, AppColors.cyanGradientEnd],
        startAngle: 0,
        endAngle: 3.14159 * 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      sweepFull,
      false,
      trackPaint,
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepFull * progress,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularGaugePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _WellnessFocusCard extends StatelessWidget {
  const _WellnessFocusCard({
    required this.brief,
    required this.onPlan,
    this.onOpenTools,
  });

  final Map<String, dynamic> brief;
  final VoidCallback onPlan;
  final VoidCallback? onOpenTools;

  @override
  Widget build(BuildContext context) {
    final title = (brief['title'] as String?) ?? 'Wellness focus';
    final items = ((brief['focus_items'] as List?) ?? [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .take(3)
        .toList();
    final encouragement = (brief['encouragement'] as String?) ??
        'Log meals, water, or movement to personalize your focus.';

    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: AppColors.cyanAccent.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: AppColors.textPrimary,
                      ),
                ),
              ),
            ],
          ),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 16),
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.background.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.cardBorder.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 16,
                        color: AppColors.cyanAccent.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        items[i],
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              height: 1.45,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: AppColors.cyanAccent.withValues(alpha: 0.55),
                  width: 3,
                ),
              ),
            ),
            child: Text(
              encouragement,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _PrimaryAction(
                  label: 'Tools',
                  onTap: onOpenTools ?? onPlan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SecondaryAction(
                  label: "Today's plan",
                  onTap: onPlan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.today,
    required this.goals,
    required this.busy,
    required this.onLogWater,
    required this.onAddMeal,
    required this.onStartWorkout,
    required this.onLogWeight,
    required this.onChangeMood,
    required this.onLogSleep,
    required this.onOpenJournal,
  });

  final TodayState today;
  final List<ActiveGoal> goals;
  final bool busy;
  final VoidCallback onLogWater;
  final VoidCallback onAddMeal;
  final VoidCallback onStartWorkout;
  final VoidCallback onLogWeight;
  final VoidCallback onChangeMood;
  final VoidCallback onLogSleep;
  final VoidCallback onOpenJournal;

  @override
  Widget build(BuildContext context) {
    final glassesLogged = (today.waterLiters / 0.25).floor();
    final goalGlasses = (today.waterGoal / 0.25).round().clamp(4, 16);
    final waterDetail = today.waterLiters <= 0
        ? null
        : glassesLogged >= 1
            ? '${today.waterLiters.toStringAsFixed(1)} L'
            : '${(today.waterLiters * 1000).round()} ml logged';
    final waterProgress = today.waterGoal == 0
        ? 0.0
        : (today.waterLiters / today.waterGoal).clamp(0.0, 1.0);
    final calorieProgress = today.calorieGoal == 0
        ? 0.0
        : (today.calories / today.calorieGoal).clamp(0.0, 1.0);
    final exerciseProgress = today.exerciseGoal == 0
        ? 0.0
        : (today.exerciseMinutes / today.exerciseGoal).clamp(0.0, 1.0);
    final sleepGoal = _goalSleepHours();
    final sleepProgress = today.sleepHours == null || sleepGoal <= 0
        ? 0.0
        : (today.sleepHours! / sleepGoal).clamp(0.0, 1.0);
    final done = today.tasks.where((t) => t.done).length;
    final total = today.tasks.length;
    final taskProgress = total == 0 ? 0.0 : done / total;
    final dayScore =
        ((taskProgress + waterProgress + exerciseProgress) / 3).clamp(0.0, 1.0);

    final remaining = (total - done).clamp(0, total);
    final status = total == 0
        ? 'Set a few habits to shape your day'
        : done >= total
            ? 'All set for today'
            : remaining == 1
                ? '1 habit left'
                : '$remaining habits left';

    final weightGoal = _goalWeight();
    final sleepLogged = today.sleepHours != null;
    final sleepNudge = sleepLogged &&
            today.sleepHours! < sleepGoal
        ? _sleepNudge(today.sleepHours!, sleepGoal)
        : null;
    final mood = today.mood;
    final moodColor = _MoodVisual.valueColor(mood);
    final moodAccent = _MoodVisual.accentColor(mood);
    final moodNudge = _MoodVisual.nudge(mood);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const HarmoniousSectionHeader(title: 'Today'),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.3,
                        ),
                  ),
                ],
              ),
            ),
            _CircularDayGauge(progress: dayScore),
          ],
        ),
        const SizedBox(height: 16),
        _FullWidthMetricCard(
          icon: Icons.water_drop_outlined,
          label: 'Water',
          value: '$glassesLogged / $goalGlasses glasses',
          detail: waterDetail,
          progress: waterProgress,
          actionLabel: 'Log water',
          onAction: busy ? null : onLogWater,
          stackAction: true,
        ),
        const SizedBox(height: 12),
        _FullWidthMetricCard(
          icon: Icons.restaurant_outlined,
          label: 'Calories',
          value: '${today.calories} / ${today.calorieGoal} kcal',
          progress: calorieProgress,
          actionLabel: 'Log meal',
          onAction: busy ? null : onAddMeal,
          stackAction: true,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GridMetricCard(
                icon: Icons.fitness_center_outlined,
                label: 'Exercise',
                value: '${today.exerciseMinutes} / ${today.exerciseGoal} min',
                subtext:
                    'Goal: ${intl.NumberFormat('#,###').format(today.stepsGoal)} steps/day',
                progress: exerciseProgress,
                actionLabel: 'Log exercise',
                onAction: busy ? null : onStartWorkout,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GridMetricCard(
                icon: Icons.monitor_weight_outlined,
                label: 'Weight',
                value: today.weight == null
                    ? '—'
                    : '${today.weight!.toStringAsFixed(0)} kg',
                subtext: weightGoal == '—'
                    ? null
                    : 'Target $weightGoal',
                actionLabel: 'Log weight',
                onAction: busy ? null : onLogWeight,
                metricValue: today.weight != null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _GridMetricCard(
                icon: Icons.bedtime_outlined,
                label: 'Sleep',
                value: sleepLogged
                    ? '${_formatHours(today.sleepHours!)} h'
                    : 'Not logged',
                valueWidget: sleepLogged
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.nights_stay_outlined,
                            size: 16,
                            color: AppColors.amber.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Not logged',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontSize: 17,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                subtext: sleepLogged
                    ? 'Goal ${_formatHours(sleepGoal)} h'
                    : 'Goal ${_formatHours(sleepGoal)} h · Tap to log',
                hint: sleepNudge,
                hintColor: AppColors.amber,
                progress: sleepProgress,
                actionLabel: 'Log sleep',
                onAction: busy ? null : onLogSleep,
                accentColor: sleepLogged ? null : AppColors.amber,
                badge: sleepLogged ? null : 'Log tonight',
                badgeColor: AppColors.amber,
                metricValue: sleepLogged,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _GridMetricCard(
                icon: _MoodVisual.iconFor(mood),
                label: 'Mood',
                value: mood ?? 'Not set',
                valueColor: moodColor,
                subtext: mood == null ? 'How are you feeling?' : null,
                hint: moodNudge,
                hintColor: moodColor ?? AppColors.coral,
                onHintTap: moodNudge != null && !busy
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const EmotionalSupportPage(),
                          ),
                        );
                      }
                    : null,
                actionLabel: mood == null ? 'Set mood' : 'Update',
                onAction: busy ? null : onChangeMood,
                accentColor: moodAccent,
                metricValue: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        MoodEntertainmentPrompt(mood: mood),
        const SizedBox(height: 12),
        _JournalCard(onOpen: busy ? null : onOpenJournal),
      ],
    );
  }

  String _formatHours(double hours) {
    return hours % 1 == 0 ? hours.toStringAsFixed(0) : hours.toStringAsFixed(1);
  }

  String? _sleepNudge(double hours, double goal) {
    if (hours >= goal) return null;
    final remaining = goal - hours;
    if (hours < 6) {
      return 'Short night — try for ${remaining.toStringAsFixed(remaining % 1 == 0 ? 0 : 1)} more h tonight';
    }
    if (remaining >= 1) {
      return 'A bit under your ${goal.toStringAsFixed(goal % 1 == 0 ? 0 : 1)} h goal — rest when you can';
    }
    return 'Almost there — a little extra rest helps recovery';
  }

  double _goalSleepHours() {
    for (final goal in goals) {
      if (goal.kind == 'sleep' && goal.target is num) {
        return (goal.target as num).toDouble();
      }
    }
    return 8;
  }

  String _goalWeight() {
    ActiveGoal? weightGoal;
    for (final goal in goals) {
      if (goal.kind == 'weight') {
        weightGoal = goal;
        break;
      }
    }
    final target = weightGoal?.target;
    if (target is num) return '${target.toStringAsFixed(0)} kg';
    return '—';
  }
}

class _FullWidthMetricCard extends StatelessWidget {
  const _FullWidthMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.actionLabel,
    this.detail,
    this.progress,
    this.onAction,
    this.stackAction = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? detail;
  final double? progress;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool stackAction;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricCardHeader(
            icon: icon,
            label: label,
            actionLabel: actionLabel,
            onAction: onAction,
            stackAction: stackAction,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.12),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    value,
                    key: ValueKey(value),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              if (detail != null)
                Text(
                  detail!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 14),
            _AnimatedProgressBar(progress: progress!.clamp(0, 1)),
          ],
          const SizedBox(height: 12),
          _MetricLogButton(
            label: actionLabel,
            onTap: onAction,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}

class _GridMetricCard extends StatelessWidget {
  const _GridMetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.actionLabel,
    this.subtext,
    this.progress,
    this.onAction,
    this.valueColor,
    this.valueWidget,
    this.hint,
    this.hintColor,
    this.onHintTap,
    this.accentColor,
    this.badge,
    this.badgeColor,
    this.metricValue = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? subtext;
  final double? progress;
  final String actionLabel;
  final VoidCallback? onAction;
  final Color? valueColor;
  final Widget? valueWidget;
  final String? hint;
  final Color? hintColor;
  final VoidCallback? onHintTap;
  final Color? accentColor;
  final String? badge;
  final Color? badgeColor;
  final bool metricValue;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onAction,
      borderRadius: BorderRadius.circular(16),
      scale: 0.985,
      child: _DashboardCard(
        padding: const EdgeInsets.all(14),
        accentColor: accentColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MetricCardHeader(
              icon: icon,
              label: label,
              actionLabel: actionLabel,
              onAction: onAction,
              compact: true,
              showActionLink: true,
            ),
          if (badge != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: _StatusChip(
                label: badge!,
                color: badgeColor ?? AppColors.amber,
              ),
            ),
          ],
          SizedBox(height: badge != null ? 8 : 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: valueWidget ??
                Text(
                  value,
                  key: ValueKey(value),
                  style: metricValue
                      ? Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: valueColor,
                          )
                      : Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 17,
                            color: valueColor ?? AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
          ),
          if (subtext != null) ...[
            const SizedBox(height: 4),
            Text(
              subtext!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: accentColor != null && valueWidget != null
                        ? AppColors.textMuted.withValues(alpha: 0.95)
                        : AppColors.textMuted,
                    fontSize: 11,
                    height: 1.25,
                    letterSpacing: 0.2,
                  ),
            ),
          ],
          if (hint != null) ...[
            const SizedBox(height: 6),
            _Pressable(
              onTap: onHintTap,
              borderRadius: BorderRadius.circular(4),
              scale: 0.98,
              child: Row(
                children: [
                  Icon(
                    Icons.spa_outlined,
                    size: 12,
                    color: (hintColor ?? AppColors.coral).withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      hint!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: (hintColor ?? AppColors.coral)
                                .withValues(alpha: 0.9),
                            fontSize: 10.5,
                            height: 1.25,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  if (onHintTap != null)
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: (hintColor ?? AppColors.coral).withValues(alpha: 0.65),
                    ),
                ],
              ),
            ),
          ],
          if (progress != null) ...[
            const SizedBox(height: 10),
            _AnimatedProgressBar(
              progress: progress!.clamp(0, 1),
              height: 4,
            ),
          ],
        ],
      ),
    ),
    );
  }
}

class _JournalCard extends StatelessWidget {
  const _JournalCard({required this.onOpen});

  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(16),
      scale: 0.985,
      child: _DashboardCard(
        child: Row(
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 18,
              color: AppColors.textMuted.withValues(alpha: 0.9),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Journal',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Reflections & notes',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            _MetricActionLink(
              label: 'Write',
              onTap: onOpen,
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textMuted.withValues(alpha: 0.75),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCardHeader extends StatelessWidget {
  const _MetricCardHeader({
    required this.icon,
    required this.label,
    required this.actionLabel,
    this.onAction,
    this.compact = false,
    this.stackAction = false,
    this.showActionLink = false,
  });

  final IconData icon;
  final String label;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool compact;
  final bool stackAction;
  final bool showActionLink;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: compact ? 15 : 16,
          color: AppColors.textMuted.withValues(alpha: 0.9),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textMuted,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (showActionLink)
          _MetricActionLink(
            label: 'Log',
            onTap: onAction,
          ),
      ],
    );
  }
}

class _AnimatedProgressBar extends StatelessWidget {
  const _AnimatedProgressBar({
    required this.progress,
    this.height = 5,
  });

  final double progress;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: progress),
        duration: const Duration(milliseconds: 780),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return SizedBox(
            height: height,
            child: Stack(
              children: [
                Container(
                  color: AppColors.cardBorder.withValues(alpha: 0.8),
                ),
                FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.cyanGradientStart,
                          AppColors.cyanGradientEnd,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TasksSection extends StatelessWidget {
  const _TasksSection({
    required this.tasks,
    required this.onToggle,
    required this.onAddHabit,
    required this.onRemove,
  });

  final List<HomeTask> tasks;
  final void Function(HomeTask task) onToggle;
  final VoidCallback onAddHabit;
  final void Function(HomeTask task) onRemove;

  @override
  Widget build(BuildContext context) {
    final done = tasks.where((t) => t.done).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(child: HarmoniousSectionHeader(title: 'Habits')),
            TextButton.icon(
              onPressed: onAddHabit,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add habit'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.cyanAccent,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            if (tasks.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                '$done / ${tasks.length}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        _DashboardCard(
          padding: EdgeInsets.zero,
          child: tasks.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: HarmoniousEmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'No habits yet',
                    message: 'Tap Add habit to build your routine.',
                    compact: true,
                  ),
                )
              : Column(
                  children: [
                    for (var i = 0; i < tasks.length; i++) ...[
                      _TaskRow(
                        task: tasks[i],
                        onToggle: () => onToggle(tasks[i]),
                        onRemove: () => onRemove(tasks[i]),
                      ),
                      if (i != tasks.length - 1)
                        Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: AppColors.cardBorder.withValues(alpha: 0.85),
                        ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.onToggle,
    required this.onRemove,
  });

  final HomeTask task;
  final VoidCallback onToggle;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final done = task.done;
    return _Pressable(
      onTap: onToggle,
      scale: 0.985,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            AnimatedScale(
              scale: done ? 1 : 0.92,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: done
                      ? AppColors.cyanAccent.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color: done
                        ? AppColors.cyanAccent
                        : AppColors.cardBorder,
                    width: 1.5,
                  ),
                ),
                child: AnimatedOpacity(
                  opacity: done ? 1 : 0,
                  duration: const Duration(milliseconds: 160),
                  child: const Icon(
                    Icons.check,
                    size: 14,
                    color: AppColors.cyanAccent,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      decoration: done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: AppColors.textMuted,
                      color:
                          done ? AppColors.textMuted : AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.3,
                    ),
                child: Text(task.label),
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.close_rounded, size: 18),
              color: AppColors.textMuted,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              tooltip: 'Remove habit',
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekSection extends StatelessWidget {
  const _WeekSection({
    required this.history,
    required this.today,
  });

  final List<DailyHistory> history;
  final TodayState today;

  List<DailyHistory> get _points {
    final points = [...history];
    final todayDate = DateTime.now();
    final hasToday = points.any(
      (item) =>
          item.date.year == todayDate.year &&
          item.date.month == todayDate.month &&
          item.date.day == todayDate.day,
    );
    if (!hasToday) {
      points.add(
        DailyHistory(
          date: todayDate,
          weight: today.weight,
          waterLiters: today.waterLiters,
          calories: today.calories,
          exerciseMinutes: today.exerciseMinutes,
          completedTasks: today.tasks.where((task) => task.done).length,
          totalTasks: today.tasks.length,
        ),
      );
    }
    points.sort((a, b) => a.date.compareTo(b.date));
    return points.length > 7 ? points.sublist(points.length - 7) : points;
  }

  double _dayScore(DailyHistory point) {
    final taskScore = point.totalTasks == 0
        ? 0.0
        : point.completedTasks / point.totalTasks;
    final waterScore = (point.waterLiters / 2.5).clamp(0.0, 1.0);
    final exerciseScore = (point.exerciseMinutes / 30).clamp(0.0, 1.0);
    return ((taskScore + waterScore + exerciseScore) / 3).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final points = _points;
    final scores = points.map(_dayScore).toList();
    final avgScore = scores.isEmpty
        ? 0.0
        : scores.reduce((a, b) => a + b) / scores.length;
    final avgWater = points.isEmpty
        ? 0.0
        : points.map((p) => p.waterLiters).reduce((a, b) => a + b) /
            points.length;
    final avgExercise = points.isEmpty
        ? 0.0
        : points.map((p) => p.exerciseMinutes).reduce((a, b) => a + b) /
            points.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Expanded(child: HarmoniousSectionHeader(title: 'This week')),
            Text(
              'avg ${(avgScore * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cyanAccent,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Day score and water trend',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.3,
              ),
        ),
        const SizedBox(height: 14),
        _DashboardCard(
          child: Column(
            children: [
              SizedBox(
                height: 148,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(
                    scores.map((s) => s.toStringAsFixed(2)).join(','),
                  ),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 920),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, _) {
                    return CustomPaint(
                      painter: _DayScoreBarsPainter(
                        points: points,
                        scores: scores,
                        growth: t,
                      ),
                      child: const SizedBox.expand(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _WeekStatChip(
                      icon: Icons.water_drop_outlined,
                      label: 'Water',
                      value: '${avgWater.toStringAsFixed(1)} L avg',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _WeekStatChip(
                      icon: Icons.directions_run_outlined,
                      label: 'Exercise',
                      value: '${avgExercise.round()} min avg',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 56,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(
                    points
                        .map((p) => p.waterLiters.toStringAsFixed(2))
                        .join(','),
                  ),
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOutCubic,
                  builder: (context, t, _) {
                    return CustomPaint(
                      painter: _WaterSparklinePainter(points, progress: t),
                      child: const SizedBox.expand(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeekStatChip extends StatelessWidget {
  const _WeekStatChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.cyanAccent.withValues(alpha: 0.85)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayScoreBarsPainter extends CustomPainter {
  const _DayScoreBarsPainter({
    required this.points,
    required this.scores,
    this.growth = 1,
  });

  final List<DailyHistory> points;
  final List<double> scores;
  final double growth;

  @override
  void paint(Canvas canvas, Size size) {
    final chartBottom = size.height - 22;
    final chartTop = 10.0;
    final chartHeight = chartBottom - chartTop;

    final gridPaint = Paint()
      ..color = AppColors.surfaceBorder.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final y = chartTop + chartHeight * i / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) return;

    final now = DateTime.now();
    final count = points.length;
    final slotWidth = size.width / count;
    final barWidth = (slotWidth * 0.48).clamp(10.0, 28.0);
    final g = growth.clamp(0.0, 1.0);

    final labelPainter = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < count; i++) {
      // Stagger each bar slightly so they grow left → right.
      final barStart = (i / count) * 0.4;
      final localT =
          ((g - barStart) / (1.0 - barStart).clamp(0.4, 1.0)).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(localT);

      final score = scores[i].clamp(0.0, 1.0);
      final centerX = slotWidth * i + slotWidth / 2;
      final fullHeight = (score <= 0 ? 4.0 : score * chartHeight).clamp(
        4.0,
        chartHeight,
      );
      final barHeight = (4.0 + (fullHeight - 4.0) * eased).clamp(4.0, chartHeight);
      final top = chartBottom - barHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, top + barHeight / 2),
          width: barWidth,
          height: barHeight,
        ),
        const Radius.circular(7),
      );

      final isToday = points[i].date.year == now.year &&
          points[i].date.month == now.month &&
          points[i].date.day == now.day;

      final fill = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            isToday
                ? AppColors.cyanAccent.withValues(alpha: 0.35 * eased)
                : AppColors.cyanBright.withValues(alpha: 0.18 * eased),
            (isToday ? AppColors.cyanAccent : AppColors.cyanBright)
                .withValues(alpha: 0.25 + 0.75 * eased),
          ],
        ).createShader(rect.outerRect);

      canvas.drawRRect(rect, fill);

      if (isToday && eased > 0.85) {
        canvas.drawCircle(
          Offset(centerX, top - 5),
          2.4 * ((eased - 0.85) / 0.15).clamp(0.0, 1.0),
          Paint()..color = AppColors.cyanAccent,
        );
      }

      labelPainter.text = TextSpan(
        text: intl.DateFormat('E').format(points[i].date).substring(0, 1),
        style: TextStyle(
          color: isToday ? AppColors.textPrimary : AppColors.textMuted,
          fontSize: 10,
          fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
        ),
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(centerX - labelPainter.width / 2, size.height - 13),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DayScoreBarsPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.scores != scores ||
      oldDelegate.growth != growth;
}

class _WaterSparklinePainter extends CustomPainter {
  const _WaterSparklinePainter(this.points, {this.progress = 1});

  final List<DailyHistory> points;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final chartTop = 8.0;
    final chartBottom = size.height - 6;
    final chartHeight = chartBottom - chartTop;
    final maxWater = points
        .map((p) => p.waterLiters)
        .fold<double>(2.5, (prev, v) => v > prev ? v : prev);
    final span = points.length == 1 ? 1 : points.length - 1;
    final t = progress.clamp(0.0, 1.0);

    Offset pointFor(int index, double liters) {
      final x =
          points.length == 1 ? size.width / 2 : size.width * index / span;
      final y = chartBottom -
          (liters / maxWater).clamp(0.0, 1.0) * chartHeight * t;
      return Offset(x, y);
    }

    final pathPoints = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      pathPoints.add(pointFor(i, points[i].waterLiters));
    }

    final fillPath = Path()
      ..moveTo(pathPoints.first.dx, chartBottom)
      ..lineTo(pathPoints.first.dx, pathPoints.first.dy);
    for (var i = 1; i < pathPoints.length; i++) {
      final previous = pathPoints[i - 1];
      final current = pathPoints[i];
      final midpoint = (previous.dx + current.dx) / 2;
      fillPath.cubicTo(
        midpoint,
        previous.dy,
        midpoint,
        current.dy,
        current.dx,
        current.dy,
      );
    }
    fillPath
      ..lineTo(pathPoints.last.dx, chartBottom)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.cyanAccent.withValues(alpha: 0.28 * t),
            AppColors.cyanAccent.withValues(alpha: 0.02 * t),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final linePath = Path()
      ..moveTo(pathPoints.first.dx, pathPoints.first.dy);
    for (var i = 1; i < pathPoints.length; i++) {
      final previous = pathPoints[i - 1];
      final current = pathPoints[i];
      final midpoint = (previous.dx + current.dx) / 2;
      linePath.cubicTo(
        midpoint,
        previous.dy,
        midpoint,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    // Reveal the stroke left → right as progress advances.
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width * t, size.height));
    canvas.drawPath(
      linePath,
      Paint()
        ..color = AppColors.cyanAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    for (final point in pathPoints) {
      if (point.dx > size.width * t + 1) continue;
      canvas.drawCircle(point, 3.2, Paint()..color = AppColors.cardSurface);
      canvas.drawCircle(point, 2.2, Paint()..color = AppColors.cyanAccent);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WaterSparklinePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.progress != progress;
}

class _GoalsSection extends StatelessWidget {
  const _GoalsSection({required this.goals});

  final List<ActiveGoal> goals;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HarmoniousSectionHeader(title: 'Goals'),
        const SizedBox(height: 12),
        for (var i = 0; i < goals.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _DashboardCard(
            child: _GoalRow(goal: goals[i]),
          ),
        ],
      ],
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal});

  final ActiveGoal goal;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          goal.title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          '${goal.current ?? '—'} ${goal.unit ?? ''}  →  ${goal.target ?? '—'} ${goal.unit ?? ''}'
              .trim(),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: 10),
        _AnimatedProgressBar(
          progress: goal.progress.clamp(0, 1),
        ),
      ],
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      scale: 0.96,
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              AppColors.cyanGradientStart,
              AppColors.cyanGradientEnd,
            ],
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: AppColors.onPrimaryButton,
              ),
        ),
      ),
    );
  }
}

class _SecondaryAction extends StatelessWidget {
  const _SecondaryAction({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      scale: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: AppColors.textPrimary,
              ),
        ),
      ),
    );
  }
}
