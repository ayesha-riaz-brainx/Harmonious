import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:slot_1_tasks/core/services/entertainment_service.dart';
import 'package:slot_1_tasks/core/theme/app_colors.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_background.dart';
import 'package:slot_1_tasks/shared/widgets/harmonious_ui.dart';

class EntertainmentRecommendationsPage extends StatefulWidget {
  const EntertainmentRecommendationsPage({
    super.key,
    this.initialMood = 'neutral',
  });

  final String initialMood;

  @override
  State<EntertainmentRecommendationsPage> createState() =>
      _EntertainmentRecommendationsPageState();
}

class _EntertainmentRecommendationsPageState
    extends State<EntertainmentRecommendationsPage> {
  final _service = EntertainmentService();

  EntertainmentGenreCatalog? _catalog;
  List<EntertainmentRecommendation> _recommendations = const [];
  final Set<String> _selectedGenres = {};
  String _mediaType = 'both';
  String? _message;
  String? _error;
  bool _loadingCatalog = true;
  bool _loadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loadingCatalog = true;
      _error = null;
    });
    try {
      final catalog = await _service.fetchGenres(mood: widget.initialMood);
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _selectedGenres
          ..clear()
          ..addAll(catalog.suggestedGenres.take(2));
        _loadingCatalog = false;
      });
      await _fetchRecommendations(auto: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingCatalog = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Future<void> _fetchRecommendations({bool auto = false}) async {
    if (_selectedGenres.isEmpty) {
      setState(() {
        _error = auto
            ? null
            : 'Choose at least one genre to see recommendations.';
      });
      return;
    }
    if (_selectedGenres.length > 2) {
      setState(() => _error = 'Choose up to 2 genres.');
      return;
    }

    setState(() {
      _loadingRecommendations = true;
      _error = null;
      _message = null;
    });

    try {
      final result = await _service.fetchRecommendations(
        mood: widget.initialMood,
        genres: _selectedGenres.toList(),
        mediaType: _mediaType,
      );
      if (!mounted) return;
      setState(() {
        _recommendations = result.recommendations;
        _message = result.message;
        _loadingRecommendations = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingRecommendations = false;
        _error = e.toString().replaceFirst('Exception: ', '');
        _recommendations = const [];
      });
    }
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (_selectedGenres.contains(genre)) {
        _selectedGenres.remove(genre);
      } else if (_selectedGenres.length < 2) {
        _selectedGenres.add(genre);
      } else {
        _error = 'Choose up to 2 genres.';
      }
    });
  }

  Future<void> _openWatchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the watch link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return HarmoniousBackground(
      child: HarmoniousDetailScaffold(
        title: 'Something to watch',
        loading: _loadingCatalog,
        body: RefreshIndicator(
          color: AppColors.cyanAccent,
          onRefresh: _loadCatalog,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              HarmoniousSpacing.screenHorizontal,
              8,
              HarmoniousSpacing.screenHorizontal,
              36,
            ),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            children: [
              HarmoniousPageHeader(
                icon: Icons.movie_filter_outlined,
                title: 'Watch picks',
                iconColor: AppColors.cyanAccent,
              ),
              const SizedBox(height: 20),
              if (_error != null) ...[
                HarmoniousCard(
                  accentColor: AppColors.coral,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.coral.withValues(alpha: 0.9),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const HarmoniousSectionHeader(
                title: 'Genres',
                subtitle: 'Pick 1–2 categories',
              ),
              const SizedBox(height: 12),
              if (_catalog != null)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final genre in _catalog!.allowedGenres)
                      FilterChip(
                        label: Text(genre),
                        selected: _selectedGenres.contains(genre),
                        onSelected: (_) => _toggleGenre(genre),
                        selectedColor:
                            AppColors.cyanAccent.withValues(alpha: 0.18),
                        checkmarkColor: AppColors.cyanAccent,
                        side: BorderSide(
                          color: _selectedGenres.contains(genre)
                              ? AppColors.cyanAccent.withValues(alpha: 0.65)
                              : AppColors.cardBorder,
                        ),
                        labelStyle: TextStyle(
                          color: _selectedGenres.contains(genre)
                              ? AppColors.cyanAccent
                              : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MediaTypeChip(
                      label: 'Movies & TV',
                      selected: _mediaType == 'both',
                      onTap: () => setState(() => _mediaType = 'both'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MediaTypeChip(
                      label: 'Movies',
                      selected: _mediaType == 'movie',
                      onTap: () => setState(() => _mediaType = 'movie'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MediaTypeChip(
                      label: 'TV',
                      selected: _mediaType == 'tv',
                      onTap: () => setState(() => _mediaType = 'tv'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              HarmoniousPrimaryChipButton(
                label: _loadingRecommendations ? 'Finding picks…' : 'Get recommendations',
                onTap: _loadingRecommendations ? () {} : _fetchRecommendations,
              ),
              const SizedBox(height: 24),
              if (_loadingRecommendations)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_recommendations.isEmpty)
                HarmoniousEmptyState(
                  icon: Icons.tv_off_outlined,
                  title: 'No picks yet',
                  message: _message ??
                      'Choose genres above, then tap Get recommendations.',
                  actionLabel: _selectedGenres.isNotEmpty ? 'Try again' : null,
                  onAction:
                      _selectedGenres.isNotEmpty ? _fetchRecommendations : null,
                )
              else ...[
                const HarmoniousSectionHeader(title: 'For you'),
                const SizedBox(height: 12),
                for (final item in _recommendations) ...[
                  _RecommendationCard(
                    item: item,
                    onWatch: () => _openWatchUrl(item.watchUrl),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaTypeChip extends StatelessWidget {
  const _MediaTypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HarmoniousPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.cyanAccent.withValues(alpha: 0.12)
              : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.cyanAccent.withValues(alpha: 0.55)
                : AppColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: selected ? AppColors.cyanAccent : AppColors.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({
    required this.item,
    required this.onWatch,
  });

  final EntertainmentRecommendation item;
  final VoidCallback onWatch;

  @override
  Widget build(BuildContext context) {
    return HarmoniousCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.posterUrl == null
                ? Container(
                    width: 72,
                    height: 108,
                    color: AppColors.cardBorder.withValues(alpha: 0.35),
                    child: Icon(
                      Icons.movie_outlined,
                      color: AppColors.textMuted.withValues(alpha: 0.8),
                    ),
                  )
                : Image.network(
                    item.posterUrl!,
                    width: 72,
                    height: 108,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 72,
                      height: 108,
                      color: AppColors.cardBorder.withValues(alpha: 0.35),
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: AppColors.textMuted.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                      ),
                    ),
                    _Badge(
                      label: item.isTv ? 'TV' : 'Movie',
                      color: AppColors.cyanAccent,
                    ),
                  ],
                ),
                if (item.rating != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '${item.rating!.toStringAsFixed(1)}/10',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.amber,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
                if (item.genre != null && item.genre!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.genre!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11.5,
                        ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  item.reason,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                        fontSize: 12.5,
                      ),
                ),
                if (item.streamingProvider != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (item.streamingLogoUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            item.streamingLogoUrl!,
                            width: 18,
                            height: 18,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                      if (item.streamingLogoUrl != null)
                        const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'On ${item.streamingProvider}',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: onWatch,
                    icon: const Icon(Icons.play_circle_outline, size: 16),
                    label: Text(
                      item.streamingProvider != null ? 'Watch' : 'View on TMDB',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.cyanAccent,
                      side: BorderSide(
                        color: AppColors.cyanAccent.withValues(alpha: 0.55),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
