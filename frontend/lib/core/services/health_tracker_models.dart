import 'dart:math';

String healthNewId() {
  final stamp = DateTime.now().toUtc().microsecondsSinceEpoch;
  final salt = Random().nextInt(99999);
  return 'h_${stamp}_$salt';
}

enum HealthConditionStatus {
  improving,
  stable,
  worse,
  resolved;

  String get label => switch (this) {
        HealthConditionStatus.improving => 'Improving',
        HealthConditionStatus.stable => 'Stable',
        HealthConditionStatus.worse => 'Getting worse',
        HealthConditionStatus.resolved => 'Resolved',
      };

  static HealthConditionStatus fromId(String? raw) {
    return switch ((raw ?? '').toLowerCase()) {
      'improving' => HealthConditionStatus.improving,
      'worse' || 'getting_worse' || 'getting worse' =>
        HealthConditionStatus.worse,
      'resolved' => HealthConditionStatus.resolved,
      _ => HealthConditionStatus.stable,
    };
  }

  String get id => name;
}

class HealthConditionUpdate {
  const HealthConditionUpdate({
    required this.id,
    required this.status,
    required this.at,
    this.notes = '',
  });

  factory HealthConditionUpdate.fromJson(Map<String, dynamic> json) {
    return HealthConditionUpdate(
      id: json['id']?.toString() ?? healthNewId(),
      status: HealthConditionStatus.fromId(json['status']?.toString()),
      notes: (json['notes'] ?? '').toString(),
      at: DateTime.tryParse(json['at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final HealthConditionStatus status;
  final String notes;
  final DateTime at;

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status.id,
        'notes': notes,
        'at': at.toUtc().toIso8601String(),
      };
}

class HealthCondition {
  const HealthCondition({
    required this.id,
    required this.name,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.details = '',
    this.updates = const [],
  });

  factory HealthCondition.fromJson(Map<String, dynamic> json) {
    final updates = ((json['updates'] as List?) ?? [])
        .whereType<Map>()
        .map((e) => HealthConditionUpdate.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.at.compareTo(a.at));

    return HealthCondition(
      id: json['id']?.toString() ?? healthNewId(),
      name: (json['name'] ?? '').toString(),
      details: (json['details'] ?? '').toString(),
      status: HealthConditionStatus.fromId(json['status']?.toString()),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
              DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at']?.toString() ?? '') ??
              DateTime.now(),
      updates: updates,
    );
  }

  final String id;
  final String name;
  final String details;
  final HealthConditionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<HealthConditionUpdate> updates;

  HealthCondition copyWith({
    String? name,
    String? details,
    HealthConditionStatus? status,
    DateTime? updatedAt,
    List<HealthConditionUpdate>? updates,
  }) {
    return HealthCondition(
      id: id,
      name: name ?? this.name,
      details: details ?? this.details,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updates: updates ?? this.updates,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'details': details,
        'status': status.id,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'updates': updates.map((e) => e.toJson()).toList(),
      };
}

class HealthRecord {
  const HealthRecord({
    required this.id,
    required this.name,
    required this.date,
    required this.createdAt,
    this.value = '',
    this.notes = '',
  });

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      id: json['id']?.toString() ?? healthNewId(),
      name: (json['name'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      notes: (json['notes'] ?? '').toString(),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  final String id;
  final String name;
  final String value;
  final String notes;
  final DateTime date;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'value': value,
        'notes': notes,
        'date': date.toIso8601String().split('T').first,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}

class HealthSymptom {
  const HealthSymptom({
    required this.id,
    required this.name,
    required this.severity,
    required this.date,
    required this.createdAt,
    this.notes = '',
  });

  factory HealthSymptom.fromJson(Map<String, dynamic> json) {
    final severity = (json['severity'] as num?)?.round() ?? 1;
    return HealthSymptom(
      id: json['id']?.toString() ?? healthNewId(),
      name: (json['name'] ?? '').toString(),
      severity: severity.clamp(1, 5),
      notes: (json['notes'] ?? '').toString(),
      date: DateTime.tryParse(json['date']?.toString() ?? '') ?? DateTime.now(),
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
              DateTime.now(),
    );
  }

  final String id;
  final String name;
  final int severity;
  final String notes;
  final DateTime date;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'severity': severity,
        'notes': notes,
        'date': date.toIso8601String().split('T').first,
        'created_at': createdAt.toUtc().toIso8601String(),
      };
}

class HealthTrackerData {
  const HealthTrackerData({
    this.conditions = const [],
    this.records = const [],
    this.symptoms = const [],
  });

  factory HealthTrackerData.fromJson(Map<String, dynamic>? json) {
    final map = json ?? const <String, dynamic>{};
    return HealthTrackerData(
      conditions: ((map['conditions'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => HealthCondition.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)),
      records: ((map['records'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => HealthRecord.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)),
      symptoms: ((map['symptoms'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => HealthSymptom.fromJson(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date)),
    );
  }

  final List<HealthCondition> conditions;
  final List<HealthRecord> records;
  final List<HealthSymptom> symptoms;

  Map<String, dynamic> toJson() => {
        'conditions': conditions.map((e) => e.toJson()).toList(),
        'records': records.map((e) => e.toJson()).toList(),
        'symptoms': symptoms.map((e) => e.toJson()).toList(),
      };

  HealthTrackerData copyWith({
    List<HealthCondition>? conditions,
    List<HealthRecord>? records,
    List<HealthSymptom>? symptoms,
  }) {
    return HealthTrackerData(
      conditions: conditions ?? this.conditions,
      records: records ?? this.records,
      symptoms: symptoms ?? this.symptoms,
    );
  }
}
