import 'package:flutter/material.dart';

import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/services/health_snapshot_service.dart';
import 'package:slot_1_tasks/core/services/home_service.dart';
import 'package:slot_1_tasks/core/services/streak_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/health_snapshot_card.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_gradient_button.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

class HealthSnapshotPage extends StatefulWidget {
  const HealthSnapshotPage({
    super.key,
    this.initialSnapshot,
    this.initialFocus,
  });

  final HealthSnapshot? initialSnapshot;
  final ActiveFocus? initialFocus;

  @override
  State<HealthSnapshotPage> createState() => _HealthSnapshotPageState();
}

class _HealthSnapshotPageState extends State<HealthSnapshotPage> {
  final _home = HomeService();
  final _features = FeatureService();
  final _streakService = StreakService();
  final _snapshotService = HealthSnapshotService();

  HealthSnapshot? _snapshot;
  ActiveFocus? _activeFocus;
  bool _loading = true;
  bool _startingFocus = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _snapshot = widget.initialSnapshot;
    _activeFocus = widget.initialFocus;
    if (_snapshot != null) {
      _loading = false;
      _refreshFocus();
    } else {
      _load();
    }
  }

  Future<void> _refreshFocus() async {
    final focus = await _snapshotService.getActiveFocus();
    if (!mounted) return;
    setState(() => _activeFocus = focus);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _home.fetchToday(),
        _features.get('captures?limit=100'),
      ]);
      final dashboard = results[0] as HomeDashboard;
      final capturesResult = results[1] as Map<String, dynamic>;
      final captures = (capturesResult['captures'] as List?) ?? const [];
      final streak = await _streakService.evaluate(dashboard.today);
      final snapshot = HealthSnapshotService.compute(
        dashboard: dashboard,
        streak: streak,
        captures: captures,
      );
      final focus = await _snapshotService.getActiveFocus();
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _activeFocus = focus;
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

  Future<void> _startFocus() async {
    final snapshot = _snapshot;
    if (snapshot == null || _startingFocus) return;
    setState(() => _startingFocus = true);
    try {
      await _snapshotService.startFocus(snapshot.focusCategory);
      final focus = await _snapshotService.getActiveFocus();
      if (!mounted) return;
      setState(() {
        _activeFocus = focus;
        _startingFocus = false;
      });
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            '7-day focus started: ${snapshot.focusCategory.displayName}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _startingFocus = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Health Snapshot'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(_activeFocus),
        ),
      ),
      body: HarmoniousBackground(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? HarmoniousErrorState(message: _error!, onRetry: _load)
                  : RefreshIndicator(
                      color: AppColors.cyanAccent,
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        children: [
                          if (_activeFocus != null && _activeFocus!.isActive)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: FocusBanner(focus: _activeFocus!),
                            ),
                          _OverallSection(snapshot: _snapshot!),
                          const SizedBox(height: 20),
                          _WeekCategoriesSection(
                            categories: _snapshot!.categories,
                          ),
                          const SizedBox(height: 20),
                          _PatternSection(insight: _snapshot!.patternInsight),
                          const SizedBox(height: 20),
                          _FocusSection(
                            focusText: _snapshot!.focusText,
                            category: _snapshot!.focusCategory,
                            hasActiveFocus: _activeFocus?.isActive == true,
                            starting: _startingFocus,
                            onStart: _startFocus,
                          ),
                        ],
                      ),
                    ),
        ),
      ),
    );
  }
}

class _OverallSection extends StatelessWidget {
  const _OverallSection({required this.snapshot});

  final HealthSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final progress = snapshot.overallScore / 100;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyanAccent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🌱', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'My Health Snapshot',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Overall',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
              ),
              const Spacer(),
              Text(
                '${snapshot.overallScore}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 42,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cyanAccent,
                      height: 1,
                    ),
              ),
              Text(
                '/100',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.cardBorder.withValues(alpha: 0.8),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.cyanAccent,
              ),
            ),
          ),
          if (snapshot.streak.currentStreak > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  '${snapshot.streak.currentStreak}-day streak',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.amber,
                      ),
                ),
                if (snapshot.streak.bestStreak > snapshot.streak.currentStreak)
                  Text(
                    ' · Best ${snapshot.streak.bestStreak}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _WeekCategoriesSection extends StatelessWidget {
  const _WeekCategoriesSection({required this.categories});

  final List<CategoryStatus> categories;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.85)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This week',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < categories.length; i++) ...[
            if (i > 0)
              Divider(
                height: 20,
                color: AppColors.cardBorder.withValues(alpha: 0.7),
              ),
            _CategoryRow(category: categories[i]),
          ],
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category});

  final CategoryStatus category;

  @override
  Widget build(BuildContext context) {
    final color = SnapshotStatusColors.forStatus(category.status);
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(category.category.icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            category.category.displayName,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
          ),
        ),
        SnapshotStatusLabel(label: category.status),
      ],
    );
  }
}

class _PatternSection extends StatelessWidget {
  const _PatternSection({required this.insight});

  final String insight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder.withValues(alpha: 0.85)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 18,
                color: AppColors.cyanAccent.withValues(alpha: 0.9),
              ),
              const SizedBox(width: 8),
              Text(
                'Your pattern',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
          ),
        ],
      ),
    );
  }
}

class _FocusSection extends StatelessWidget {
  const _FocusSection({
    required this.focusText,
    required this.category,
    required this.hasActiveFocus,
    required this.starting,
    required this.onStart,
  });

  final String focusText;
  final SnapshotCategory category;
  final bool hasActiveFocus;
  final bool starting;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.amber.withValues(alpha: 0.35),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.amber.withValues(alpha: 0.06),
            AppColors.cardSurface,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🎯', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                "This week's focus",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(category.icon, size: 18, color: AppColors.amber),
              const SizedBox(width: 8),
              Text(
                focusText,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (hasActiveFocus)
            Text(
              'You already have an active 7-day focus. Keep it up!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
            )
          else
            HarmoniousGradientButton(
              label: 'Start 7-Day Focus',
              isLoading: starting,
              onPressed: starting ? null : onStart,
            ),
        ],
      ),
    );
  }
}

