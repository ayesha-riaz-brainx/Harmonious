import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:slot_1_tasks/core/config/api_config.dart';

double? _optionalDouble(dynamic value, {double min = 0}) {
  if (value == null) return null;
  final parsed =
      value is num ? value.toDouble() : double.tryParse(value.toString());
  if (parsed == null || !parsed.isFinite || parsed < min) return null;
  return parsed;
}

int _nonNegativeInt(dynamic value) {
  if (value == null) return 0;
  final parsed = value is num ? value.toInt() : int.tryParse('$value');
  if (parsed == null || parsed < 0) return 0;
  return parsed;
}

double _nonNegativeDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  final parsed =
      value is num ? value.toDouble() : double.tryParse(value.toString());
  if (parsed == null || !parsed.isFinite || parsed < 0) return fallback;
  return parsed;
}

class HomeDashboard {
  HomeDashboard({
    required this.greetingName,
    required this.aiEnabled,
    required this.today,
    required this.activeGoals,
    required this.weeklyHistory,
    this.aiProfile = const {},
  });

  factory HomeDashboard.fromJson(Map<String, dynamic> json) {
    return HomeDashboard(
      greetingName: (json['greeting_name'] as String?) ?? 'Friend',
      aiEnabled: json['ai_enabled'] == true,
      aiProfile: Map<String, dynamic>.from(json['ai_profile'] as Map? ?? {}),
      today: TodayState.fromJson(
        Map<String, dynamic>.from(json['today'] as Map? ?? {}),
      ),
      activeGoals: ((json['active_goals'] as List?) ?? [])
          .map((e) => ActiveGoal.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      weeklyHistory: ((json['weekly_history'] as List?) ?? [])
          .map((e) => DailyHistory.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  final String greetingName;
  final bool aiEnabled;
  final Map<String, dynamic> aiProfile;
  final TodayState today;
  final List<ActiveGoal> activeGoals;
  final List<DailyHistory> weeklyHistory;
}

class DailyHistory {
  const DailyHistory({
    required this.date,
    required this.waterLiters,
    required this.calories,
    required this.exerciseMinutes,
    required this.completedTasks,
    required this.totalTasks,
    this.weight,
    this.mood,
    this.sleepHours,
  });

  factory DailyHistory.fromJson(Map<String, dynamic> json) {
    final tasks = (json['tasks'] as List?) ?? const [];
    final sleep = _nonNegativeDouble(json['sleep_hours']);
    return DailyHistory(
      date: DateTime.tryParse(json['log_date']?.toString() ?? '') ??
          DateTime.now(),
      weight: _optionalDouble(json['weight'], min: 0.1),
      waterLiters: _nonNegativeDouble(json['water_liters']),
      calories: _nonNegativeInt(json['calories']),
      exerciseMinutes: _nonNegativeInt(json['exercise_minutes']),
      completedTasks: tasks
          .where((task) => task is Map && task['done'] == true)
          .length,
      totalTasks: tasks.length,
      mood: json['mood'] as String?,
      sleepHours: sleep > 0 ? sleep : null,
    );
  }

  final DateTime date;
  final double? weight;
  final double waterLiters;
  final int calories;
  final int exerciseMinutes;
  final int completedTasks;
  final int totalTasks;
  final String? mood;
  final double? sleepHours;

  double get habitRatio =>
      totalTasks == 0 ? 0 : completedTasks / totalTasks;
}

class TodayState {
  TodayState({
    required this.date,
    required this.waterLiters,
    required this.waterGoal,
    required this.calories,
    required this.calorieGoal,
    required this.exerciseMinutes,
    required this.exerciseGoal,
    required this.stepsGoal,
    required this.tasks,
    required this.aiBrief,
    required this.aiInsights,
    this.weight,
    this.mood,
    this.sleepHours,
  });

  factory TodayState.fromJson(Map<String, dynamic> json) {
    final sleep = _nonNegativeDouble(json['sleep_hours']);
    return TodayState(
      date: (json['date'] as String?) ?? '',
      weight: _optionalDouble(json['weight'], min: 0.1),
      waterLiters: _nonNegativeDouble(json['water_liters']),
      waterGoal: _nonNegativeDouble(json['water_goal'], fallback: 2.5),
      calories: _nonNegativeInt(json['calories']),
      calorieGoal: _nonNegativeInt(json['calorie_goal'] ?? 1800),
      exerciseMinutes: _nonNegativeInt(json['exercise_minutes']),
      exerciseGoal: _nonNegativeInt(json['exercise_goal'] ?? 30),
      stepsGoal: _nonNegativeInt(json['steps_goal'] ?? 8000),
      mood: json['mood'] as String?,
      sleepHours: sleep > 0 ? sleep : null,
      tasks: ((json['tasks'] as List?) ?? [])
          .map((e) => HomeTask.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      aiBrief: Map<String, dynamic>.from(json['ai_brief'] as Map? ?? {}),
      aiInsights: ((json['ai_insights'] as List?) ?? [])
          .map((e) {
            if (e is String) return e;
            if (e is Map && e['text'] != null) return e['text'].toString();
            return e.toString();
          })
          .toList(),
    );
  }

  final String date;
  final double? weight;
  final double waterLiters;
  final double waterGoal;
  final int calories;
  final int calorieGoal;
  final int exerciseMinutes;
  final int exerciseGoal;
  final int stepsGoal;
  final String? mood;
  final double? sleepHours;
  final List<HomeTask> tasks;
  final Map<String, dynamic> aiBrief;
  final List<String> aiInsights;
}

class HomeTask {
  HomeTask({required this.id, required this.label, required this.done});

  factory HomeTask.fromJson(Map<String, dynamic> json) {
    return HomeTask(
      id: (json['id'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      done: json['done'] == true,
    );
  }

  final String id;
  final String label;
  bool done;

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'done': done,
      };
}

class ActiveGoal {
  ActiveGoal({
    required this.id,
    required this.title,
    required this.progress,
    this.current,
    this.target,
    this.unit,
    this.kind,
  });

  factory ActiveGoal.fromJson(Map<String, dynamic> json) {
    return ActiveGoal(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      current: json['current'],
      target: json['target'],
      unit: json['unit'] as String?,
      kind: json['kind'] as String?,
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
    );
  }

  final String id;
  final String title;
  final dynamic current;
  final dynamic target;
  final String? unit;
  final String? kind;
  final double progress;
}

class HomeService {
  Future<HomeDashboard> fetchToday() async {
    final response = await http
        .get(ApiConfig.homeToday, headers: ApiConfig.authHeaders())
        .timeout(const Duration(seconds: 30));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Unable to load home.');
    }
    return HomeDashboard.fromJson(body);
  }

  Future<HomeDashboard> updateToday(Map<String, dynamic> patch) async {
    final response = await http
        .patch(
          ApiConfig.homeToday,
          headers: ApiConfig.authHeaders(),
          body: jsonEncode(patch),
        )
        .timeout(const Duration(seconds: 20));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Unable to update today.');
    }
    return HomeDashboard.fromJson(body);
  }
}
