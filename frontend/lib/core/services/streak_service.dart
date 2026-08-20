import 'package:shared_preferences/shared_preferences.dart';

import 'package:slot_1_tasks/core/services/home_service.dart';

/// Client-side daily streak tracking (SharedPreferences).
class StreakSnapshot {
  const StreakSnapshot({
    required this.currentStreak,
    required this.bestStreak,
    this.lastCompletedDate,
  });

  final int currentStreak;
  final int bestStreak;
  final String? lastCompletedDate;
}

class StreakService {
  static const _currentKey = 'streak_current';
  static const _bestKey = 'streak_best';
  static const _lastCompletedKey = 'streak_last_completed';

  /// A day counts when all habits are done OR at least 3 meaningful activities.
  static bool isDayCompleted(TodayState today) {
    if (today.tasks.isNotEmpty && today.tasks.every((task) => task.done)) {
      return true;
    }
    return meaningfulActivityCount(today) >= 3;
  }

  /// Water, meal, mood, or any habit — each category counts once.
  static int meaningfulActivityCount(TodayState today) {
    var count = 0;
    if (today.waterLiters > 0) count++;
    if (today.calories > 0) count++;
    if (today.mood != null && today.mood!.trim().isNotEmpty) count++;
    if (today.tasks.any((task) => task.done)) count++;
    return count;
  }

  static String _dateKey(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  static DateTime _parseDate(String value) {
    final parts = value.split('-');
    if (parts.length != 3) return DateTime.now();
    return DateTime(
      int.tryParse(parts[0]) ?? 2000,
      int.tryParse(parts[1]) ?? 1,
      int.tryParse(parts[2]) ?? 1,
    );
  }

  static bool _isYesterday(String dateKey, DateTime now) {
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    return dateKey == _dateKey(yesterday);
  }

  static bool _isBeforeYesterday(String dateKey, DateTime now) {
    final yesterday = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 1));
    final completed = _parseDate(dateKey);
    final yMidnight = DateTime(yesterday.year, yesterday.month, yesterday.day);
    final cMidnight = DateTime(completed.year, completed.month, completed.day);
    return cMidnight.isBefore(yMidnight);
  }

  Future<StreakSnapshot> evaluate(TodayState today, {DateTime? now}) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _dateKey(now ?? DateTime.now());
    final completedToday = isDayCompleted(today);

    var current = prefs.getInt(_currentKey) ?? 0;
    var best = prefs.getInt(_bestKey) ?? 0;
    final lastCompleted = prefs.getString(_lastCompletedKey);

    if (completedToday) {
      if (lastCompleted == todayKey) {
        // Already counted today — keep stored streak.
      } else if (lastCompleted != null && _isYesterday(lastCompleted, now ?? DateTime.now())) {
        current += 1;
      } else {
        current = 1;
      }
      if (current > best) best = current;
      await prefs.setInt(_currentKey, current);
      await prefs.setInt(_bestKey, best);
      await prefs.setString(_lastCompletedKey, todayKey);
      return StreakSnapshot(
        currentStreak: current,
        bestStreak: best,
        lastCompletedDate: todayKey,
      );
    }

    // Today not completed — streak stays alive until yesterday was the last win.
    var displayStreak = current;
    if (lastCompleted == null) {
      displayStreak = 0;
    } else if (_isBeforeYesterday(lastCompleted, now ?? DateTime.now())) {
      displayStreak = 0;
    } else if (lastCompleted != todayKey && !_isYesterday(lastCompleted, now ?? DateTime.now())) {
      displayStreak = 0;
    }

    return StreakSnapshot(
      currentStreak: displayStreak,
      bestStreak: best,
      lastCompletedDate: lastCompleted,
    );
  }
}
