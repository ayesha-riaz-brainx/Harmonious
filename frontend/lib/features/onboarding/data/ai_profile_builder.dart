import 'package:slot_1_tasks/features/onboarding/data/onboarding_draft.dart';

/// Rule-based initial AI profile (no API key required).
class AiProfile {
  const AiProfile({
    required this.primaryGoal,
    required this.secondaryGoals,
    required this.calorieTarget,
    required this.waterGoalLiters,
    required this.sleepGoalHours,
    required this.workoutPlan,
    required this.focusAreas,
    required this.message,
    this.stepsGoal = 8000,
    this.exerciseGoalMinutes = 30,
    this.habitTemplates = const [],
  });

  final String primaryGoal;
  final List<String> secondaryGoals;
  final int calorieTarget;
  final double waterGoalLiters;
  final String sleepGoalHours;
  final String workoutPlan;
  final List<String> focusAreas;
  final String message;
  final int stepsGoal;
  final int exerciseGoalMinutes;
  final List<String> habitTemplates;

  Map<String, dynamic> toJson() => {
        'primary_goal': primaryGoal,
        'secondary_goals': secondaryGoals,
        'calorie_target': calorieTarget,
        'water_goal_liters': waterGoalLiters,
        'sleep_goal_hours': sleepGoalHours,
        'workout_plan': workoutPlan,
        'focus_areas': focusAreas,
        'message': message,
        'steps_goal': stepsGoal,
        'exercise_goal_minutes': exerciseGoalMinutes,
        'habit_templates': habitTemplates,
      };
}

class AiProfileBuilder {
  const AiProfileBuilder();

  AiProfile build(OnboardingDraft draft) {
    final goals = draft.goals;
    final primary = goals.isNotEmpty ? goals.first : 'General Wellness';
    final secondary = goals.length > 1 ? goals.skip(1).take(3).toList() : <String>[];

    final primaryLabel = _primaryLabel(draft, primary);
    final calories = _estimateCalories(draft);
    final water = _waterLiters(draft);
    final sleep = draft.sleepGoalHours ??
        (draft.wantsBetterSleep ? '8' : _defaultSleep(draft.sleepHours));
    final workout = _workoutPlan(draft);
    final focus = _focusAreas(draft);
    final stepsGoal = _stepsGoal(draft);
    final exerciseMinutes = _exerciseGoalMinutes(draft);
    final habits = List<String>.from(draft.selectedHabits);

    return AiProfile(
      primaryGoal: primaryLabel,
      secondaryGoals: secondary,
      calorieTarget: calories,
      waterGoalLiters: water,
      sleepGoalHours: '$sleep Hours',
      workoutPlan: workout,
      focusAreas: focus,
      message:
          'Great! We built your starting plan from your answers. As you log habits, your dashboard will keep adapting.',
      stepsGoal: stepsGoal,
      exerciseGoalMinutes: exerciseMinutes,
      habitTemplates: habits,
    );
  }

  String _primaryLabel(OnboardingDraft draft, String primary) {
    if (primary == 'Lose Weight' && draft.targetWeight != null) {
      final current = draft.weight;
      if (current != null && current > draft.targetWeight!) {
        final diff = (current - draft.targetWeight!).round();
        return 'Lose $diff ${draft.weightUnit}';
      }
      return 'Reach ${draft.targetWeight!.toStringAsFixed(0)} ${draft.weightUnit}';
    }
    return primary;
  }

  int _estimateCalories(OnboardingDraft draft) {
    final weight = draft.weight ?? 65;
    final height = draft.height ?? 170;
    final age = draft.age ?? 28;
    final isFemale = (draft.gender ?? '').toLowerCase().startsWith('f');

    // Mifflin-St Jeor (metric-ish; height assumed cm when unit is cm)
    final h = draft.heightUnit == 'ft' ? height * 30.48 : height;
    final w = draft.weightUnit == 'lb' ? weight * 0.453592 : weight;
    final bmr = isFemale
        ? (10 * w) + (6.25 * h) - (5 * age) - 161
        : (10 * w) + (6.25 * h) - (5 * age) + 5;

    final multiplier = switch (draft.activityLevel) {
      'Mostly Sitting' => 1.2,
      'Lightly Active' => 1.375,
      'Moderately Active' => 1.55,
      'Very Active' => 1.725,
      _ => 1.4,
    };

    var tdee = bmr * multiplier;
    if (draft.wantsWeightLoss) tdee -= 400;
    if (draft.goals.contains('Gain Muscle')) tdee += 250;
    return tdee.round().clamp(1200, 4000);
  }

  double _waterLiters(OnboardingDraft draft) {
    if (draft.goals.contains('Drink More Water')) return 3.0;
    return switch (draft.waterIntake) {
      'Under 1 L' => 2.5,
      '1–2 L' => 2.5,
      '2–3 L' => 3.0,
      '3 L+' => 3.0,
      _ => 2.5,
    };
  }

  String _defaultSleep(String? sleepHours) {
    return switch (sleepHours) {
      'Under 5' || '5–6' => '7–8',
      '6–7' => '8',
      _ => '8',
    };
  }

  int _stepsGoal(OnboardingDraft draft) {
    return switch (draft.activityLevel) {
      'Mostly Sitting' => 6000,
      'Lightly Active' => 8000,
      'Moderately Active' => 10000,
      'Very Active' => 12000,
      _ => 8000,
    };
  }

  int _exerciseGoalMinutes(OnboardingDraft draft) {
    return switch (draft.exerciseFrequency) {
      'Rarely' => 20,
      '1–2 days / week' => 25,
      '3–4 days / week' => 30,
      '5+ days / week' => 45,
      _ => switch (draft.activityLevel) {
          'Mostly Sitting' => 20,
          'Lightly Active' => 25,
          'Moderately Active' => 30,
          'Very Active' => 45,
          _ => 30,
        },
    };
  }

  String _workoutPlan(OnboardingDraft draft) {
    if (draft.exerciseFrequency != null) {
      return switch (draft.exerciseFrequency) {
        'Rarely' => '2 Days / Week',
        '1–2 days / week' => '3 Days / Week',
        '3–4 days / week' => '4 Days / Week',
        '5+ days / week' => '5 Days / Week',
        _ => '3 Days / Week',
      };
    }
    if (draft.goals.contains('Exercise Regularly') ||
        draft.goals.contains('Gain Muscle') ||
        draft.wantsWeightLoss) {
      return '4 Days / Week';
    }
    return '3 Days / Week';
  }

  List<String> _focusAreas(OnboardingDraft draft) {
    final areas = <String>[];
    if (draft.goals.contains('Eat Healthier') ||
        draft.wantsWeightLoss ||
        draft.dietType != null) {
      areas.add('Better Nutrition');
    }
    if (draft.wantsLessStress ||
        draft.moods.contains('Stressed') ||
        draft.moods.contains('Anxious') ||
        draft.moods.contains('Burned Out')) {
      areas.add('Stress Management');
    }
    if (draft.goals.contains('Exercise Regularly') ||
        draft.wantsWeightLoss ||
        draft.goals.contains('Gain Muscle')) {
      areas.add('Consistent Exercise');
    }
    if (draft.wantsBetterSleep) areas.add('Sleep Quality');
    if (draft.goals.contains('Improve Mental Health') ||
        draft.moods.contains('Lonely')) {
      areas.add('Mental Wellbeing');
    }
    if (areas.isEmpty) {
      areas.addAll(['General Wellness', 'Daily Consistency']);
    }
    return areas.take(4).toList();
  }
}
