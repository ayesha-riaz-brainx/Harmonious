import 'package:slot_1_tasks/core/services/home_service.dart';

class WellnessScoreBreakdown {
  const WellnessScoreBreakdown({
    required this.total,
    required this.water,
    required this.meals,
    required this.habits,
    required this.mood,
    required this.label,
    required this.message,
  });

  final int total;
  final int water;
  final int meals;
  final int habits;
  final int mood;
  final String label;
  final String message;
}

/// Rule-based 0–100 wellness score (no AI).
class WellnessScoreService {
  static int waterPoints(TodayState today) {
    if (today.waterGoal <= 0) return 0;
    final ratio = (today.waterLiters / today.waterGoal).clamp(0.0, 1.0);
    return (ratio * 25).round();
  }

  static int mealPoints(int mealCount) {
    if (mealCount <= 0) return 0;
    if (mealCount == 1) return 8;
    if (mealCount == 2) return 16;
    return 25;
  }

  static int habitPoints(TodayState today) {
    final total = today.tasks.length;
    if (total == 0) return 0;
    final done = today.tasks.where((task) => task.done).length;
    return ((done / total) * 25).round();
  }

  static int moodPoints(String? mood) {
    if (mood == null || mood.trim().isEmpty) return 0;
    switch (mood.trim().toLowerCase()) {
      case 'happy':
      case 'great':
        return 25;
      case 'good':
        return 20;
      case 'neutral':
        return 18;
      case 'okay':
        return 15;
      case 'stressed':
        return 8;
      case 'tired':
      case 'low':
      case 'anxious':
        return 5;
      default:
        return 10;
    }
  }

  static ({String label, String message}) interpretation(int score) {
    if (score >= 90) {
      return (
        label: 'Excellent 🌟',
        message: "You're having a great wellness day!",
      );
    }
    if (score >= 75) {
      return (
        label: 'Doing Great 💚',
        message: "You're building a healthy routine.",
      );
    }
    if (score >= 50) {
      return (
        label: 'Good Start 🌱',
        message: 'A few small actions could make today even better.',
      );
    }
    if (score >= 25) {
      return (
        label: 'Room to Improve 💪',
        message: 'Focus on one small healthy action.',
      );
    }
    return (
      label: 'Fresh Start 🌱',
      message: 'Every day is a new opportunity.',
    );
  }

  static WellnessScoreBreakdown calculate({
    required TodayState today,
    required int mealCount,
  }) {
    final water = waterPoints(today);
    final meals = mealPoints(mealCount);
    final habits = habitPoints(today);
    final mood = moodPoints(today.mood);
    final total = (water + meals + habits + mood).clamp(0, 100);
    final band = interpretation(total);

    return WellnessScoreBreakdown(
      total: total,
      water: water,
      meals: meals,
      habits: habits,
      mood: mood,
      label: band.label,
      message: band.message,
    );
  }

  /// Count meal captures logged on [date] (local calendar day).
  static int mealCountFromCaptures(
    List<dynamic> captures,
    DateTime date,
  ) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    var count = 0;
    for (final raw in captures) {
      if (raw is! Map) continue;
      if (raw['type']?.toString() != 'meal') continue;
      final capturedAt = DateTime.tryParse(raw['captured_at']?.toString() ?? '');
      if (capturedAt == null) continue;
      final local = capturedAt.toLocal();
      if (!local.isBefore(start) && local.isBefore(end)) count++;
    }
    return count;
  }
}
