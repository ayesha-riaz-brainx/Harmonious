import 'package:slot_1_tasks/core/services/feature_service.dart';

class EntertainmentRecommendation {
  const EntertainmentRecommendation({
    required this.id,
    required this.mediaType,
    required this.title,
    this.posterUrl,
    this.rating,
    this.genre,
    required this.reason,
    this.streamingProvider,
    this.streamingLogoUrl,
    required this.watchUrl,
  });

  factory EntertainmentRecommendation.fromJson(Map<String, dynamic> json) {
    final streaming = json['streaming'] is Map
        ? Map<String, dynamic>.from(json['streaming'] as Map)
        : <String, dynamic>{};

    return EntertainmentRecommendation(
      id: json['id'] as int? ?? 0,
      mediaType: (json['media_type'] as String?) ?? 'movie',
      title: (json['title'] as String?) ?? 'Untitled',
      posterUrl: json['poster_url'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      genre: json['genre'] as String?,
      reason: (json['reason'] as String?) ?? '',
      streamingProvider: streaming['provider'] as String?,
      streamingLogoUrl: streaming['logo_url'] as String?,
      watchUrl: (streaming['watch_url'] as String?) ?? '',
    );
  }

  final int id;
  final String mediaType;
  final String title;
  final String? posterUrl;
  final double? rating;
  final String? genre;
  final String reason;
  final String? streamingProvider;
  final String? streamingLogoUrl;
  final String watchUrl;

  bool get isTv => mediaType == 'tv';
}

class EntertainmentGenreCatalog {
  const EntertainmentGenreCatalog({
    required this.allowedGenres,
    required this.suggestedGenres,
    required this.mood,
  });

  factory EntertainmentGenreCatalog.fromJson(Map<String, dynamic> json) {
    return EntertainmentGenreCatalog(
      allowedGenres: ((json['allowed_genres'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      suggestedGenres: ((json['suggested_genres'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      mood: (json['mood'] as String?) ?? 'neutral',
    );
  }

  final List<String> allowedGenres;
  final List<String> suggestedGenres;
  final String mood;
}

class EntertainmentService {
  EntertainmentService({FeatureService? api}) : _api = api ?? FeatureService();

  final FeatureService _api;

  Future<EntertainmentGenreCatalog> fetchGenres({String? mood}) async {
    final result = await _api.get(
      'entertainment/genres',
      query: mood == null ? null : {'mood': mood},
    );
    return EntertainmentGenreCatalog.fromJson(result);
  }

  Future<({
    List<EntertainmentRecommendation> recommendations,
    String? message,
    String mood,
    List<String> genres,
  })> fetchRecommendations({
    required String mood,
    List<String> genres = const [],
    String mediaType = 'both',
  }) async {
    final query = <String, String>{
      'mood': mood,
      'media_type': mediaType,
    };
    if (genres.isNotEmpty) {
      query['genres'] = genres.join(',');
    }

    final result = await _api.get('entertainment/recommendations', query: query);
    final raw = (result['recommendations'] as List?) ?? const [];
    final recommendations = raw
        .whereType<Map>()
        .map((item) => EntertainmentRecommendation.fromJson(
              Map<String, dynamic>.from(item),
            ))
        .toList();

    return (
      recommendations: recommendations,
      message: result['message'] as String?,
      mood: (result['mood'] as String?) ?? mood,
      genres: ((result['genres'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
    );
  }
}

/// Moods that may show the optional entertainment card.
bool isNegativeMoodForEntertainment(String? mood) {
  if (mood == null || mood.trim().isEmpty) return false;
  switch (mood.trim().toLowerCase()) {
    case 'stressed':
    case 'anxious':
    case 'tired':
    case 'sad':
    case 'lonely':
    case 'bored':
    case 'low':
    case 'low energy':
      return true;
    default:
      return false;
  }
}

String normalizeEntertainmentMood(String? mood) {
  if (mood == null || mood.trim().isEmpty) return 'neutral';
  final value = mood.trim().toLowerCase();
  if (value.contains('stress')) return 'stressed';
  if (value.contains('anxious')) return 'anxious';
  if (value.contains('tired')) return 'tired';
  if (value.contains('lonely')) return 'lonely';
  if (value.contains('bored')) return 'bored';
  if (value.contains('sad')) return 'sad';
  if (value.contains('low')) return 'low';
  if (value.contains('happy')) return 'happy';
  if (value.contains('angry')) return 'angry';
  return value;
}
