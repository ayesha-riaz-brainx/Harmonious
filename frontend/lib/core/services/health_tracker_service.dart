import 'package:slot_1_tasks/core/services/feature_service.dart';
import 'package:slot_1_tasks/core/services/health_tracker_models.dart';

class HealthTrackerService {
  HealthTrackerService({FeatureService? api}) : _api = api ?? FeatureService();

  final FeatureService _api;

  Future<HealthTrackerData> load() async {
    final data = await _api.get('settings');
    return _parseTracker(data);
  }

  Future<HealthTrackerData> save(HealthTrackerData tracker) async {
    final payload = tracker.toJson();
    final data = await _api.patch('settings', {
      'health_tracker': payload,
    });
    final parsed = _parseTracker(data);
    // Keep what we saved if the API response omits tracker content
    // (older backend / missing column / empty {}).
    if (_isEmpty(parsed) && !_isEmpty(tracker)) {
      return tracker;
    }
    return parsed;
  }

  HealthTrackerData _parseTracker(Map<String, dynamic> data) {
    final direct = data['health_tracker'];
    if (direct is Map && !_isEmptyMap(direct)) {
      return HealthTrackerData.fromJson(Map<String, dynamic>.from(direct));
    }

    final settings = data['settings'];
    if (settings is Map) {
      final nested = settings['health_tracker'];
      if (nested is Map) {
        return HealthTrackerData.fromJson(Map<String, dynamic>.from(nested));
      }
    }

    if (direct is Map) {
      return HealthTrackerData.fromJson(Map<String, dynamic>.from(direct));
    }
    return const HealthTrackerData();
  }

  bool _isEmpty(HealthTrackerData data) =>
      data.conditions.isEmpty && data.records.isEmpty && data.symptoms.isEmpty;

  bool _isEmptyMap(Map map) {
    final records = map['records'];
    final conditions = map['conditions'];
    final symptoms = map['symptoms'];
    final recordCount = records is List ? records.length : 0;
    final conditionCount = conditions is List ? conditions.length : 0;
    final symptomCount = symptoms is List ? symptoms.length : 0;
    return recordCount + conditionCount + symptomCount == 0;
  }
}
