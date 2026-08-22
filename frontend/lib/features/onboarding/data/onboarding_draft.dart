class OnboardingDraft {
  OnboardingDraft({
    this.birthday,
    this.age,
    this.gender,
    this.height,
    this.weight,
    this.heightUnit = 'cm',
    this.weightUnit = 'kg',
    this.activityLevel,
    this.healthConditions = const [],
    this.medications,
    this.sleepHours,
    this.waterIntake,
    this.exercises = false,
    this.exerciseFrequency,
    this.workStress,
    this.screenTime,
    this.workHours,
    this.moods = const [],
    this.moodTriggers = const [],
    this.goals = const [],
    this.selectedHabits = const ['water', 'breakfast', 'workout', 'journal', 'sleep'],
    this.targetWeight,
    this.targetDate,
    this.workoutPreference,
    this.dietPreference,
    this.preferredBedtime,
    this.wakeTime,
    this.sleepGoalHours,
    this.relaxationActivities = const [],
    this.dietType,
    this.foodAllergies,
    this.favoriteFoods,
    this.foodsToAvoid,
    this.dailyFoodBudget,
    this.mealsPerDay,
    this.routineWakeUp,
    this.workStarts,
    this.workEnds,
    this.lunchTime,
    this.exerciseTime,
    this.routineBedtime,
    this.daysOff = const [],
    this.zodiacSign,
  });

  DateTime? birthday;
  int? age;
  String? gender;
  String? zodiacSign;
  double? height;
  double? weight;
  String heightUnit;
  String weightUnit;
  String? activityLevel;

  List<String> healthConditions;
  String? medications;

  String? sleepHours;
  String? waterIntake;
  bool exercises;
  String? exerciseFrequency;
  String? workStress;
  String? screenTime;
  String? workHours;

  List<String> moods;
  List<String> moodTriggers;

  List<String> goals;
  List<String> selectedHabits;

  // Goal details
  double? targetWeight;
  DateTime? targetDate;
  String? workoutPreference;
  String? dietPreference;
  String? preferredBedtime;
  String? wakeTime;
  String? sleepGoalHours;
  List<String> relaxationActivities;

  // Food
  String? dietType;
  String? foodAllergies;
  String? favoriteFoods;
  String? foodsToAvoid;
  String? dailyFoodBudget;
  String? mealsPerDay;

  // Daily routine
  String? routineWakeUp;
  String? workStarts;
  String? workEnds;
  String? lunchTime;
  String? exerciseTime;
  String? routineBedtime;
  List<String> daysOff;

  bool get wantsWeightLoss => goals.contains('Lose Weight');
  bool get wantsBetterSleep => goals.contains('Improve Sleep');
  bool get wantsLessStress => goals.contains('Reduce Stress');
  bool get needsGoalDetails =>
      wantsWeightLoss || wantsBetterSleep || wantsLessStress;

  Map<String, dynamic> toJson() {
    return {
      'birthday': birthday?.toIso8601String(),
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'height_unit': heightUnit,
      'weight_unit': weightUnit,
      'activity_level': activityLevel,
      'health_conditions': healthConditions,
      'medications': medications,
      'sleep_hours': sleepHours,
      'water_intake': waterIntake,
      'exercises': exercises,
      'exercise_frequency': exerciseFrequency,
      'work_stress': workStress,
      'screen_time': screenTime,
      'work_hours': workHours,
      'moods': moods,
      'mood_triggers': moodTriggers,
      'goals': goals,
      'selected_habits': selectedHabits,
      'target_weight': targetWeight,
      'target_date': targetDate?.toIso8601String(),
      'workout_preference': workoutPreference,
      'diet_preference': dietPreference,
      'preferred_bedtime': preferredBedtime,
      'wake_time': wakeTime,
      'sleep_goal_hours': sleepGoalHours,
      'relaxation_activities': relaxationActivities,
      'diet_type': dietType,
      'food_allergies': foodAllergies,
      'favorite_foods': favoriteFoods,
      'foods_to_avoid': foodsToAvoid,
      'daily_food_budget': dailyFoodBudget,
      'meals_per_day': mealsPerDay,
      'routine_wake_up': routineWakeUp,
      'work_starts': workStarts,
      'work_ends': workEnds,
      'lunch_time': lunchTime,
      'exercise_time': exerciseTime,
      'routine_bedtime': routineBedtime,
      'days_off': daysOff,
      if (zodiacSign != null) 'zodiac_sign': zodiacSign,
    };
  }
}
