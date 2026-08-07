import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;

import 'package:slot_1_tasks/core/services/home_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/features/home/presentation/widgets/quick_add_sheet.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';

class TodayTab extends StatefulWidget {
  const TodayTab({
    super.key,
    this.onDataChanged,
    this.onOpenChat,
    this.onOpenAiTab,
  });

  final Future<void> Function({bool refreshAi, bool includeToday})?
      onDataChanged;
  final Future<void> Function()? onOpenChat;
  final VoidCallback? onOpenAiTab;

  @override
  TodayTabState createState() => TodayTabState();
}

class TodayTabState extends State<TodayTab> with TickerProviderStateMixin {
  final _home = HomeService();
  final _scroll = ScrollController();

  HomeDashboard? _data;
  String? _error;
  bool _loading = true;
  bool _busy = false;

  late final AnimationController _entrance;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _load();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> reload({bool refreshAi = false, bool silent = false}) =>
      _load(refreshAi: refreshAi, silent: silent);

  void applyHome(Map<String, dynamic> home) {
    if (!mounted) return;
    setState(() {
      _data = HomeDashboard.fromJson(home);
      _loading = false;
      _error = null;
    });
  }

  Future<void> _load({bool refreshAi = false, bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final data =
          refreshAi ? await _home.refreshAi() : await _home.fetchToday();
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
        _error = null;
      });
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
      setState(() => _data = data);
      // Only refresh Journey/AI — Today already updated.
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
        if (outcome.home != null) {
          applyHome(outcome.home!);
        } else {
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
    // Fire-and-forget; do not await rebuilds mid-frame.
    widget.onDataChanged?.call(refreshAi: false, includeToday: false);
  }

  void _scrollToPlan() {
    // Progress + tasks sit below the brief; jump far enough to show them.
    if (!_scroll.hasClients) return;
    _scroll.animateTo(
      420,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    return HarmoniousBackground(
      child: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorState(message: _error!, onRetry: _load)
                : RefreshIndicator(
                    color: AppColors.lavender,
                    onRefresh: () => _load(refreshAi: true),
                    child: CustomScrollView(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate([
                              _fadeSlide(
                                0,
                                _Header(
                                  greeting: _greeting(),
                                  name: _data!.greetingName,
                                ),
                              ),
                              const SizedBox(height: 18),
                              _fadeSlide(
                                1,
                                _AiBriefCard(
                                  brief: _data!.today.aiBrief,
                                  onChat: () {
                                    widget.onOpenChat?.call();
                                  },
                                  onPlan: _scrollToPlan,
                                ),
                              ),
                              const SizedBox(height: 18),
                              _fadeSlide(
                                2,
                                _WeeklyTrendsSection(
                                  history: _data!.weeklyHistory,
                                  today: _data!.today,
                                ),
                              ),
                              const SizedBox(height: 18),
                              _fadeSlide(
                                3,
                                _ProgressSection(
                                  today: _data!.today,
                                  goals: _data!.activeGoals,
                                  busy: _busy,
                                  onAddMeal: () =>
                                      handleQuickAdd(QuickAddAction.meal),
                                  onStartWorkout: () =>
                                      handleQuickAdd(QuickAddAction.workout),
                                  onChangeMood: () =>
                                      handleQuickAdd(QuickAddAction.mood),
                                ),
                              ),
                              const SizedBox(height: 18),
                              _fadeSlide(
                                4,
                                _TasksSection(
                                  tasks: _data!.today.tasks,
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
                              const SizedBox(height: 18),
                              _fadeSlide(
                                5,
                                _GoalsSection(goals: _data!.activeGoals),
                              ),
                              const SizedBox(height: 18),
                              _fadeSlide(
                                6,
                                _InsightsSection(
                                  insights: _data!.today.aiInsights,
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
    final start = (index * 0.08).clamp(0.0, 0.7);
    final end = (start + 0.35).clamp(0.0, 1.0);
    final animation = CurvedAnimation(
      parent: _entrance,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation),
        child: child,
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

  @override
  Widget build(BuildContext context) {
    final date = intl.DateFormat('EEEE, MMMM d').format(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting, $name 👋',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
        ),
        const SizedBox(height: 6),
        Text(
          date,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _AiBriefCard extends StatelessWidget {
  const _AiBriefCard({
    required this.brief,
    required this.onChat,
    required this.onPlan,
  });

  final Map<String, dynamic> brief;
  final VoidCallback onChat;
  final VoidCallback onPlan;

  @override
  Widget build(BuildContext context) {
    final title = (brief['title'] as String?) ?? "Today's Focus";
    final items = ((brief['focus_items'] as List?) ?? [])
        .map((e) => e.toString())
        .toList();
    final encouragement = (brief['encouragement'] as String?) ??
        "You're progressing well. Keep it up!";

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.lavender.withValues(alpha: 0.22),
            AppColors.tealDeep.withValues(alpha: 0.55),
            AppColors.surface,
          ],
        ),
        border: Border.all(color: AppColors.lavender.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.lavender.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('✦', style: TextStyle(color: AppColors.lavenderBright)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final item in items) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('✔  ', style: TextStyle(color: AppColors.lavenderBright)),
                  Expanded(child: Text(item, style: const TextStyle(height: 1.35))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            encouragement,
            style: const TextStyle(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniButton(label: 'Chat with AI', onTap: onChat),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniButton(label: "View Today's Plan", onTap: onPlan),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WeeklyTrendsSection extends StatelessWidget {
  const _WeeklyTrendsSection({
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

  @override
  Widget build(BuildContext context) {
    final points = _points;
    final done = today.tasks.where((task) => task.done).length;
    final total = today.tasks.length;
    final taskProgress = total == 0 ? 0.0 : done / total;
    final waterProgress = today.waterGoal == 0
        ? 0.0
        : (today.waterLiters / today.waterGoal).clamp(0.0, 1.0);
    final exerciseProgress = today.exerciseGoal == 0
        ? 0.0
        : (today.exerciseMinutes / today.exerciseGoal).clamp(0.0, 1.0);
    final score =
        ((taskProgress + waterProgress + exerciseProgress) / 3).clamp(0.0, 1.0);
    final remaining = (total - done).clamp(0, total);
    final motivator = total == 0
        ? 'Add a few habits to start your day'
        : done == 0
            ? "You're just getting started"
            : done >= total
                ? 'Great job! You completed your wellness goals today'
                : remaining == 1
                    ? '1 more habit to complete your day'
                    : '$remaining more habits to complete your day';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Your Week'),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.lavender.withValues(alpha: 0.14),
                AppColors.surface,
                AppColors.aqua.withValues(alpha: 0.08),
              ],
            ),
            border: Border.all(color: AppColors.surfaceBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _ScoreRing(score: score),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Weekly progress',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          score >= .75
                              ? 'Strong day'
                              : score >= .4
                                  ? 'Building momentum'
                                  : 'A fresh start',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          motivator,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    '$done of $total tasks',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(taskProgress * 100).round()}%',
                    style: const TextStyle(
                      color: AppColors.lavenderBright,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: taskProgress),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 10,
                      backgroundColor: AppColors.surfaceBorder,
                      color: AppColors.lavender,
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 130,
                child: CustomPaint(
                  painter: _TrendChartPainter(points),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: 10),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LegendDot(color: AppColors.aqua, label: 'Water'),
                  SizedBox(width: 18),
                  _LegendDot(color: AppColors.lavender, label: 'Exercise'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: score),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutCubic,
        builder: (context, value, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: value,
                  strokeWidth: 8,
                  strokeCap: StrokeCap.round,
                  backgroundColor: AppColors.surfaceBorder,
                  color: AppColors.aqua,
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}

class _TrendChartPainter extends CustomPainter {
  const _TrendChartPainter(this.points);

  final List<DailyHistory> points;

  @override
  void paint(Canvas canvas, Size size) {
    final chartBottom = size.height - 22;
    final chartTop = 8.0;
    final chartHeight = chartBottom - chartTop;

    final gridPaint = Paint()
      ..color = AppColors.surfaceBorder.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = chartTop + chartHeight * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) return;
    final span = points.length == 1 ? 1 : points.length - 1;

    Offset pointFor(int index, double value) {
      final x = points.length == 1
          ? size.width / 2
          : size.width * index / span;
      final y = chartBottom - value.clamp(0.0, 1.0) * chartHeight;
      return Offset(x, y);
    }

    final water = <Offset>[];
    final exercise = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      water.add(pointFor(i, points[i].waterLiters / 3));
      exercise.add(pointFor(i, points[i].exerciseMinutes / 30));
    }

    void drawSeries(List<Offset> values, Color color) {
      final path = Path()..moveTo(values.first.dx, values.first.dy);
      for (var i = 1; i < values.length; i++) {
        final previous = values[i - 1];
        final current = values[i];
        final midpoint = (previous.dx + current.dx) / 2;
        path.cubicTo(
          midpoint,
          previous.dy,
          midpoint,
          current.dy,
          current.dx,
          current.dy,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );
      for (final point in values) {
        canvas.drawCircle(point, 4, Paint()..color = AppColors.surface);
        canvas.drawCircle(
          point,
          3,
          Paint()
            ..color = color
            ..style = PaintingStyle.fill,
        );
      }
    }

    drawSeries(water, AppColors.aqua);
    drawSeries(exercise, AppColors.lavender);

    final labelPainter = TextPainter(textDirection: TextDirection.ltr);
    for (var i = 0; i < points.length; i++) {
      labelPainter.text = TextSpan(
        text: intl.DateFormat('E').format(points[i].date).substring(0, 1),
        style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
      );
      labelPainter.layout();
      final x = points.length == 1
          ? size.width / 2
          : size.width * i / span;
      labelPainter.paint(
        canvas,
        Offset(x - labelPainter.width / 2, size.height - 13),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartPainter oldDelegate) =>
      oldDelegate.points != points;
}

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({
    required this.today,
    required this.goals,
    required this.busy,
    required this.onAddMeal,
    required this.onStartWorkout,
    required this.onChangeMood,
  });

  final TodayState today;
  final List<ActiveGoal> goals;
  final bool busy;
  final VoidCallback onAddMeal;
  final VoidCallback onStartWorkout;
  final VoidCallback onChangeMood;

  @override
  Widget build(BuildContext context) {
    final glasses = today.waterLiters / 0.25;
    final goalGlasses = (today.waterGoal / 0.25).round().clamp(4, 16);
    final waterProgress = today.waterGoal == 0
        ? 0.0
        : (today.waterLiters / today.waterGoal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle("Today's Progress"),
        const SizedBox(height: 10),
        _WideStatCard(
          label: 'Water',
          icon: Icons.water_drop_rounded,
          accent: AppColors.sky,
          value:
              '${glasses.toStringAsFixed(1)} / $goalGlasses glasses · ${today.waterLiters.toStringAsFixed(2)} L',
          progress: waterProgress,
          action: null,
          onAction: null,
        ),
        const SizedBox(height: 10),
        _WideStatCard(
          label: 'Calories',
          icon: Icons.local_fire_department_rounded,
          accent: AppColors.amber,
          value: '${today.calories} / ${today.calorieGoal} kcal',
          progress: today.calorieGoal == 0
              ? 0
              : (today.calories / today.calorieGoal).clamp(0, 1),
          action: '+ Add Meal',
          onAction: busy ? null : onAddMeal,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Weight',
                value: today.weight == null
                    ? '—'
                    : '${today.weight!.toStringAsFixed(0)} kg',
                hint: 'Goal ${_goalWeight()}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                label: 'Exercise',
                value: '${today.exerciseMinutes} / ${today.exerciseGoal} min',
                action: 'Start',
                onAction: busy ? null : onStartWorkout,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _WideStatCard(
          label: 'Mood',
          icon: Icons.mood_rounded,
          accent: AppColors.mint,
          value: today.mood ?? 'Not set yet',
          progress: today.mood == null ? 0 : 1,
          action: 'Change Mood',
          onAction: busy ? null : onChangeMood,
        ),
      ],
    );
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
    if (today.weight == null) return '—';
    return '${(today.weight! - 4).toStringAsFixed(0)} kg';
  }
}

class _TasksSection extends StatelessWidget {
  const _TasksSection({required this.tasks, required this.onToggle});

  final List<HomeTask> tasks;
  final void Function(HomeTask task) onToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle("Today's Tasks"),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            children: [
              for (var i = 0; i < tasks.length; i++) ...[
                _TaskRow(
                  task: tasks[i],
                  onToggle: () => onToggle(tasks[i]),
                ),
                if (i != tasks.length - 1)
                  const Divider(height: 1, color: AppColors.surfaceBorder),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.onToggle});

  final HomeTask task;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final done = task.done;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(12),
        splashColor: AppColors.lavender.withValues(alpha: 0.18),
        highlightColor: AppColors.lavender.withValues(alpha: 0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: done ? AppColors.lavender : Colors.transparent,
                  border: Border.all(
                    color: done ? AppColors.lavender : AppColors.surfaceBorder,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check, size: 16, color: Colors.black)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 220),
                  style: TextStyle(
                    decoration:
                        done ? TextDecoration.lineThrough : TextDecoration.none,
                    color: done ? AppColors.textMuted : AppColors.textPrimary,
                    fontSize: 15,
                  ),
                  child: Text(task.label),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalsSection extends StatelessWidget {
  const _GoalsSection({required this.goals});

  final List<ActiveGoal> goals;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Goal Progress'),
        const SizedBox(height: 10),
        for (final goal in goals) ...[
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${goal.current ?? '—'} ${goal.unit ?? ''}  →  ${goal.target ?? '—'} ${goal.unit ?? ''}',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: goal.progress.clamp(0, 1)),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return LinearProgressIndicator(
                        value: value,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceBorder,
                        color: AppColors.lavender,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _InsightsSection extends StatelessWidget {
  const _InsightsSection({required this.insights});

  final List<String> insights;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('AI Insights'),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: insights.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return Container(
                width: 220,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Text(
                  insights[index],
                  style: const TextStyle(height: 1.4, fontSize: 14),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _WideStatCard extends StatelessWidget {
  const _WideStatCard({
    required this.label,
    required this.icon,
    required this.accent,
    required this.value,
    required this.progress,
    this.action,
    this.onAction,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final String value;
  final double progress;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: 0.12),
            AppColors.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: accent),
              ),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (action != null)
                GestureDetector(
                  onTap: onAction,
                  child: Text(
                    action!,
                    style: const TextStyle(
                      color: AppColors.lavenderBright,
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0, 1)),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 8,
                  backgroundColor: AppColors.surfaceBorder,
                  color: accent,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.hint,
    this.action,
    this.onAction,
  });

  final String label;
  final String value;
  final String? hint;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              height: 1.25,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: const TextStyle(
                  color: AppColors.lavenderBright,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.black.withValues(alpha: 0.25),
          border: Border.all(color: AppColors.lavender.withValues(alpha: 0.4)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
            const SizedBox(height: 8),
            const Text(
              'Tip: run supabase/daily_logs.sql and keep the backend running.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
