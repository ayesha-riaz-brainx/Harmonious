import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:slot_1_tasks/core/services/home_service.dart';
import 'package:slot_1_tasks/core/services/streak_service.dart';
import 'package:slot_1_tasks/core/services/wellness_score_service.dart';

/// Health snapshot categories tracked weekly.
enum SnapshotCategory {
  sleep,
  hydration,
  nutrition,
  mood,
  activity,
}

extension SnapshotCategoryX on SnapshotCategory {
  String get id => name;

  String get displayName {
    switch (this) {
      case SnapshotCategory.sleep:
        return 'Sleep';
      case SnapshotCategory.hydration:
        return 'Hydration';
      case SnapshotCategory.nutrition:
        return 'Nutrition';
      case SnapshotCategory.mood:
        return 'Mood';
      case SnapshotCategory.activity:
        return 'Activity';
    }
  }

  IconData get icon {
    switch (this) {
      case SnapshotCategory.sleep:
        return Icons.bedtime_outlined;
      case SnapshotCategory.hydration:
        return Icons.water_drop_outlined;
      case SnapshotCategory.nutrition:
        return Icons.restaurant_outlined;
      case SnapshotCategory.mood:
        return Icons.sentiment_satisfied_alt_outlined;
      case SnapshotCategory.activity:
        return Icons.directions_walk_outlined;
    }
  }

  String get focusVerb {
    switch (this) {
      case SnapshotCategory.sleep:
        return 'Improve sleep';
      case SnapshotCategory.hydration:
        return 'Improve hydration';
      case SnapshotCategory.nutrition:
        return 'Improve nutrition';
      case SnapshotCategory.mood:
        return 'Improve mood';
      case SnapshotCategory.activity:
        return 'Increase activity';
    }
  }

  static SnapshotCategory? fromId(String? id) {
    if (id == null) return null;
    for (final c in SnapshotCategory.values) {
      if (c.id == id) return c;
    }
    return null;
  }
}

class CategoryStatus {
  const CategoryStatus({
    required this.category,
    required this.status,
    required this.weaknessScore,
  });

  final SnapshotCategory category;
  final String status;

  /// Higher = weaker category (used to pick weekly focus).
  final int weaknessScore;
}

class HealthSnapshot {
  const HealthSnapshot({
    required this.overallScore,
    required this.streak,
    required this.categories,
    required this.patternInsight,
    required this.focusCategory,
    required this.focusText,
  });

  final int overallScore;
  final StreakSnapshot streak;
  final List<CategoryStatus> categories;
  final String patternInsight;
  final SnapshotCategory focusCategory;
  final String focusText;
}

class ActiveFocus {
  const ActiveFocus({
    required this.category,
    required this.startDate,
    required this.currentDay,
    required this.isActive,
  });

  final SnapshotCategory category;
  final DateTime startDate;
  final int currentDay;
  final bool isActive;
}

/// Rule-based health snapshot (no AI).
class HealthSnapshotService {
  static const _focusCategoryKey = 'health_focus_category';
  static const _focusStartKey = 'health_focus_start';
  static const _focusDurationDays = 7;

  // Sleep thresholds (8 h goal reference).
  static const _sleepGoodHours = 7.5;
  static const _sleepFairHours = 6.0;

  // Hydration thresholds vs daily water goal.
  static const _hydrationGoodRatio = 0.9;
  static const _hydrationFairRatio = 0.6;

  // Nutrition: days with meaningful calorie logs in the week.
  static const _nutritionGoodDays = 5;
  static const _nutritionFairDays = 3;
  static const _nutritionMinCalories = 400;

  // Activity thresholds vs exercise goal.
  static const _activityExcellentRatio = 1.0;
  static const _activityGoodRatio = 0.7;
  static const _activityFairRatio = 0.4;

  static HealthSnapshot compute({
    required HomeDashboard dashboard,
    required StreakSnapshot streak,
    List<dynamic> captures = const [],
  }) {
    final week = _weekPoints(dashboard);
    final overall = _weeklyOverallScore(dashboard, week, captures);
    final categories = [
      _sleepStatus(week),
      _hydrationStatus(week, dashboard.today.waterGoal),
      _nutritionStatus(week),
      _moodStatus(week),
      _activityStatus(week, dashboard.today.exerciseGoal),
    ];
    final focus = _weakestCategory(categories);
    return HealthSnapshot(
      overallScore: overall,
      streak: streak,
      categories: categories,
      patternInsight: _detectPattern(week),
      focusCategory: focus.category,
      focusText: focus.category.focusVerb,
    );
  }

  static List<DailyHistory> _weekPoints(HomeDashboard dashboard) {
    final points = [...dashboard.weeklyHistory];
    final todayDate = DateTime.now();
    final hasToday = points.any(
      (item) =>
          item.date.year == todayDate.year &&
          item.date.month == todayDate.month &&
          item.date.day == todayDate.day,
    );
    if (!hasToday) {
      final today = dashboard.today;
      points.add(
        DailyHistory(
          date: todayDate,
          weight: today.weight,
          waterLiters: today.waterLiters,
          calories: today.calories,
          exerciseMinutes: today.exerciseMinutes,
          completedTasks: today.tasks.where((t) => t.done).length,
          totalTasks: today.tasks.length,
          mood: today.mood,
          sleepHours: today.sleepHours,
        ),
      );
    }
    points.sort((a, b) => a.date.compareTo(b.date));
    return points.length > 7 ? points.sublist(points.length - 7) : points;
  }

  static int _weeklyOverallScore(
    HomeDashboard dashboard,
    List<DailyHistory> week,
    List<dynamic> captures,
  ) {
    if (week.isEmpty) {
      return WellnessScoreService.calculate(
        today: dashboard.today,
        mealCount: WellnessScoreService.mealCountFromCaptures(
          captures,
          DateTime.now(),
        ),
      ).total;
    }

    var sum = 0;
    for (final day in week) {
      final state = _todayFromHistory(day, dashboard.today);
      final meals = WellnessScoreService.mealCountFromCaptures(captures, day.date);
      sum += WellnessScoreService.calculate(today: state, mealCount: meals).total;
    }
    return (sum / week.length).round().clamp(0, 100);
  }

  static TodayState _todayFromHistory(DailyHistory day, TodayState goals) {
    final tasks = <HomeTask>[];
    for (var i = 0; i < day.completedTasks; i++) {
      tasks.add(HomeTask(id: 'd$i', label: '', done: true));
    }
    for (var i = 0; i < day.totalTasks - day.completedTasks; i++) {
      tasks.add(HomeTask(id: 'p$i', label: '', done: false));
    }
    return TodayState(
      date: day.date.toIso8601String(),
      weight: day.weight,
      waterLiters: day.waterLiters,
      waterGoal: goals.waterGoal,
      calories: day.calories,
      calorieGoal: goals.calorieGoal,
      exerciseMinutes: day.exerciseMinutes,
      exerciseGoal: goals.exerciseGoal,
      stepsGoal: goals.stepsGoal,
      mood: day.mood,
      sleepHours: day.sleepHours,
      tasks: tasks,
      aiBrief: const {},
      aiInsights: const [],
    );
  }

  static CategoryStatus _sleepStatus(List<DailyHistory> week) {
    final logged = week.where((d) => d.sleepHours != null && d.sleepHours! > 0);
    if (logged.isEmpty) {
      return const CategoryStatus(
        category: SnapshotCategory.sleep,
        status: 'Needs attention',
        weaknessScore: 3,
      );
    }
    final avg = logged.map((d) => d.sleepHours!).reduce((a, b) => a + b) /
        logged.length;
    // Good ≥ 7.5 h, Fair ≥ 6 h, else Needs attention.
    if (avg >= _sleepGoodHours) {
      return const CategoryStatus(
        category: SnapshotCategory.sleep,
        status: 'Good',
        weaknessScore: 0,
      );
    }
    if (avg >= _sleepFairHours) {
      return const CategoryStatus(
        category: SnapshotCategory.sleep,
        status: 'Fair',
        weaknessScore: 2,
      );
    }
    return const CategoryStatus(
      category: SnapshotCategory.sleep,
      status: 'Needs attention',
      weaknessScore: 3,
    );
  }

  static CategoryStatus _hydrationStatus(
    List<DailyHistory> week,
    double waterGoal,
  ) {
    final logged = week.where((d) => d.waterLiters > 0).toList();
    if (logged.isEmpty || waterGoal <= 0) {
      return const CategoryStatus(
        category: SnapshotCategory.hydration,
        status: 'Needs attention',
        weaknessScore: 3,
      );
    }
    final avgRatio = logged
            .map((d) => (d.waterLiters / waterGoal).clamp(0.0, 1.5))
            .reduce((a, b) => a + b) /
        logged.length;
    // Good ≥ 90%, Fair ≥ 60%, else Needs attention.
    if (avgRatio >= _hydrationGoodRatio) {
      return const CategoryStatus(
        category: SnapshotCategory.hydration,
        status: 'Good',
        weaknessScore: 0,
      );
    }
    if (avgRatio >= _hydrationFairRatio) {
      return const CategoryStatus(
        category: SnapshotCategory.hydration,
        status: 'Fair',
        weaknessScore: 2,
      );
    }
    return const CategoryStatus(
      category: SnapshotCategory.hydration,
      status: 'Needs attention',
      weaknessScore: 3,
    );
  }

  static CategoryStatus _nutritionStatus(List<DailyHistory> week) {
    final loggedDays = week
        .where((d) => d.calories >= _nutritionMinCalories)
        .length;
    final avgCalories = week.isEmpty
        ? 0
        : week.map((d) => d.calories).reduce((a, b) => a + b) / week.length;
    // Good: 5+ days logged OR strong avg calories; Fair: 3–4 days; else Needs attention.
    if (loggedDays >= _nutritionGoodDays || avgCalories >= 1200) {
      return const CategoryStatus(
        category: SnapshotCategory.nutrition,
        status: 'Good',
        weaknessScore: 0,
      );
    }
    if (loggedDays >= _nutritionFairDays) {
      return const CategoryStatus(
        category: SnapshotCategory.nutrition,
        status: 'Fair',
        weaknessScore: 2,
      );
    }
    return const CategoryStatus(
      category: SnapshotCategory.nutrition,
      status: 'Needs attention',
      weaknessScore: 3,
    );
  }

  static CategoryStatus _moodStatus(List<DailyHistory> week) {
    final scored = week
        .map((d) => (day: d, score: _moodRank(d.mood)))
        .where((e) => e.score != null)
        .toList();
    if (scored.length < 2) {
      return const CategoryStatus(
        category: SnapshotCategory.mood,
        status: 'Stable',
        weaknessScore: 1,
      );
    }
    final mid = scored.length ~/ 2;
    final early =
        scored.take(mid).map((e) => e.score!).reduce((a, b) => a + b) / mid;
    final late = scored
            .skip(mid)
            .map((e) => e.score!)
            .reduce((a, b) => a + b) /
        (scored.length - mid);
    // Improving if late half ≥ early + 0.5; Needs attention if declining ≥ 0.5.
    if (late >= early + 0.5) {
      return const CategoryStatus(
        category: SnapshotCategory.mood,
        status: 'Improving',
        weaknessScore: 0,
      );
    }
    if (late <= early - 0.5 || late <= 2.5) {
      return const CategoryStatus(
        category: SnapshotCategory.mood,
        status: 'Needs attention',
        weaknessScore: 3,
      );
    }
    return const CategoryStatus(
      category: SnapshotCategory.mood,
      status: 'Stable',
      weaknessScore: 1,
    );
  }

  static CategoryStatus _activityStatus(
    List<DailyHistory> week,
    int exerciseGoal,
  ) {
    final logged = week.where((d) => d.exerciseMinutes > 0).toList();
    if (logged.isEmpty || exerciseGoal <= 0) {
      return const CategoryStatus(
        category: SnapshotCategory.activity,
        status: 'Low',
        weaknessScore: 3,
      );
    }
    final avgMinutes = logged
            .map((d) => d.exerciseMinutes)
            .reduce((a, b) => a + b) /
        logged.length;
    final ratio = avgMinutes / exerciseGoal;
    // Excellent ≥ goal, Good ≥ 70%, Fair ≥ 40%, else Low.
    if (ratio >= _activityExcellentRatio) {
      return const CategoryStatus(
        category: SnapshotCategory.activity,
        status: 'Excellent',
        weaknessScore: 0,
      );
    }
    if (ratio >= _activityGoodRatio) {
      return const CategoryStatus(
        category: SnapshotCategory.activity,
        status: 'Good',
        weaknessScore: 1,
      );
    }
    if (ratio >= _activityFairRatio) {
      return const CategoryStatus(
        category: SnapshotCategory.activity,
        status: 'Fair',
        weaknessScore: 2,
      );
    }
    return const CategoryStatus(
      category: SnapshotCategory.activity,
      status: 'Low',
      weaknessScore: 3,
    );
  }

  static CategoryStatus _weakestCategory(List<CategoryStatus> categories) {
    return categories.reduce(
      (a, b) => b.weaknessScore > a.weaknessScore ? b : a,
    );
  }

  static int? _moodRank(String? mood) {
    if (mood == null || mood.trim().isEmpty) return null;
    switch (mood.trim().toLowerCase()) {
      case 'happy':
      case 'great':
        return 5;
      case 'good':
        return 4;
      case 'neutral':
      case 'okay':
        return 3;
      case 'stressed':
        return 2;
      case 'tired':
      case 'low':
      case 'anxious':
        return 1;
      default:
        return 3;
    }
  }

  static String _detectPattern(List<DailyHistory> week) {
    if (week.length < 3) {
      return 'Keep logging daily — patterns emerge after a few days of tracking.';
    }

    final candidates = <({String text, double strength})>[];

    // Mood higher when habits mostly complete (≥ 75% vs < 50%).
    final highHabit = week
        .where((d) => d.totalTasks > 0 && d.habitRatio >= 0.75)
        .where((d) => _moodRank(d.mood) != null)
        .toList();
    final lowHabit = week
        .where((d) => d.totalTasks > 0 && d.habitRatio < 0.5)
        .where((d) => _moodRank(d.mood) != null)
        .toList();
    if (highHabit.length >= 2 && lowHabit.length >= 2) {
      final highAvg = highHabit
              .map((d) => _moodRank(d.mood)!)
              .reduce((a, b) => a + b) /
          highHabit.length;
      final lowAvg = lowHabit
              .map((d) => _moodRank(d.mood)!)
              .reduce((a, b) => a + b) /
          lowHabit.length;
      final delta = highAvg - lowAvg;
      if (delta >= 1) {
        candidates.add((
          text:
              'You feel better on days when you complete your morning routine.',
          strength: delta.toDouble(),
        ));
      }
    }

    // Hydration drops on high-exercise days (≥ 20 min vs < 10 min).
    final activeDays = week.where((d) => d.exerciseMinutes >= 20).toList();
    final quietDays = week.where((d) => d.exerciseMinutes < 10).toList();
    if (activeDays.length >= 2 && quietDays.length >= 2) {
      final activeWater = activeDays
              .map((d) => d.waterLiters)
              .reduce((a, b) => a + b) /
          activeDays.length;
      final quietWater = quietDays
              .map((d) => d.waterLiters)
              .reduce((a, b) => a + b) /
          quietDays.length;
      final delta = quietWater - activeWater;
      if (delta >= 0.4) {
        candidates.add((
          text: 'Hydration drops on busy days — plan extra water around workouts.',
          strength: delta,
        ));
      }
    }

    // Sleep improves when more habits are completed.
    final goodSleep = week
        .where((d) => d.sleepHours != null && d.sleepHours! >= _sleepGoodHours)
        .toList();
    final poorSleep = week
        .where((d) =>
            d.sleepHours != null &&
            d.sleepHours! > 0 &&
            d.sleepHours! < _sleepFairHours)
        .toList();
    if (goodSleep.length >= 2 && poorSleep.length >= 2) {
      final goodHabit = goodSleep
              .map((d) => d.habitRatio)
              .reduce((a, b) => a + b) /
          goodSleep.length;
      final poorHabit = poorSleep
              .map((d) => d.habitRatio)
              .reduce((a, b) => a + b) /
          poorSleep.length;
      final delta = goodHabit - poorHabit;
      if (delta >= 0.25) {
        candidates.add((
          text: 'Sleep improves when you stay consistent with daily habits.',
          strength: delta * 20,
        ));
      }
    }

    if (candidates.isEmpty) {
      return 'Keep logging daily — small patterns add up over the week.';
    }
    candidates.sort((a, b) => b.strength.compareTo(a.strength));
    return candidates.first.text;
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static DateTime _parseDate(String value) {
    final parts = value.split('-');
    return DateTime(
      int.tryParse(parts[0]) ?? 2000,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[2]) ?? 1,
    );
  }

  /// Returns active 7-day focus challenge, if any.
  Future<ActiveFocus?> getActiveFocus({DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final categoryId = prefs.getString(_focusCategoryKey);
    final startRaw = prefs.getString(_focusStartKey);
    final category = SnapshotCategoryX.fromId(categoryId);
    if (category == null || startRaw == null) return null;

    final today = DateTime(now?.year ?? DateTime.now().year,
        now?.month ?? DateTime.now().month, now?.day ?? DateTime.now().day);
    final start = _parseDate(startRaw);
    final startMidnight = DateTime(start.year, start.month, start.day);
    final dayNumber =
        today.difference(startMidnight).inDays + 1;

    if (dayNumber < 1 || dayNumber > _focusDurationDays) {
      await prefs.remove(_focusCategoryKey);
      await prefs.remove(_focusStartKey);
      return null;
    }

    return ActiveFocus(
      category: category,
      startDate: startMidnight,
      currentDay: dayNumber,
      isActive: true,
    );
  }

  Future<void> startFocus(SnapshotCategory category, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final today = now ?? DateTime.now();
    await prefs.setString(_focusCategoryKey, category.id);
    await prefs.setString(_focusStartKey, _dateKey(today));
  }

  Future<void> clearFocus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_focusCategoryKey);
    await prefs.remove(_focusStartKey);
  }
}
