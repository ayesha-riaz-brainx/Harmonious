import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:slot_1_tasks/core/config/api_config.dart';

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
  });

  factory DailyHistory.fromJson(Map<String, dynamic> json) {
    final tasks = (json['tasks'] as List?) ?? const [];
    return DailyHistory(
      date: DateTime.tryParse(json['log_date']?.toString() ?? '') ??
          DateTime.now(),
      weight: (json['weight'] as num?)?.toDouble(),
      waterLiters: (json['water_liters'] as num?)?.toDouble() ?? 0,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      exerciseMinutes: (json['exercise_minutes'] as num?)?.toInt() ?? 0,
      completedTasks: tasks
          .where((task) => task is Map && task['done'] == true)
          .length,
      totalTasks: tasks.length,
    );
  }

  final DateTime date;
  final double? weight;
  final double waterLiters;
  final int calories;
  final int exerciseMinutes;
  final int completedTasks;
  final int totalTasks;
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
    required this.tasks,
    required this.aiBrief,
    required this.aiInsights,
    this.weight,
    this.mood,
  });

  factory TodayState.fromJson(Map<String, dynamic> json) {
    return TodayState(
      date: (json['date'] as String?) ?? '',
      weight: (json['weight'] as num?)?.toDouble(),
      waterLiters: (json['water_liters'] as num?)?.toDouble() ?? 0,
      waterGoal: (json['water_goal'] as num?)?.toDouble() ?? 2.5,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      calorieGoal: (json['calorie_goal'] as num?)?.toInt() ?? 1800,
      exerciseMinutes: (json['exercise_minutes'] as num?)?.toInt() ?? 0,
      exerciseGoal: (json['exercise_goal'] as num?)?.toInt() ?? 30,
      mood: json['mood'] as String?,
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
  final String? mood;
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

  Future<HomeDashboard> refreshAi() async {
    final response = await http
        .post(ApiConfig.homeRefreshAi, headers: ApiConfig.authHeaders())
        .timeout(const Duration(seconds: 45));

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw Exception(body['message'] ?? 'Unable to refresh AI.');
    }
    return HomeDashboard.fromJson(body);
  }
}
