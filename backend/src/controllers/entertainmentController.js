const {
  hasTmdbKey,
  parseGenresParam,
  getGenreCatalog,
  getRecommendations,
} = require('../services/entertainmentService');

async function listGenres(req, res, next) {
  try {
    if (!hasTmdbKey()) {
      return res.status(503).json({
        message:
          'Entertainment recommendations are not set up. Add TMDB_API_KEY to backend/.env.',
        code: 'TMDB_NOT_CONFIGURED',
        allowed_genres: [],
        suggested_genres: [],
      });
    }

    const mood = req.query.mood || 'neutral';
    return res.json(getGenreCatalog(mood));
  } catch (error) {
    return next(error);
  }
}

async function recommendations(req, res, next) {
  try {
    if (!hasTmdbKey()) {
      return res.status(503).json({
        message:
          'Entertainment recommendations are not set up. Add TMDB_API_KEY to backend/.env.',
        code: 'TMDB_NOT_CONFIGURED',
        recommendations: [],
      });
    }

    const mood = (req.query.mood || 'neutral').trim();
    const parsedGenres = parseGenresParam(req.query.genres || '');
    const mediaType = (req.query.media_type || 'both').trim().toLowerCase();

    if (!['movie', 'tv', 'both'].includes(mediaType)) {
      return res.status(400).json({
        message: 'media_type must be movie, tv, or both.',
        code: 'ENTERTAINMENT_INVALID_MEDIA_TYPE',
      });
    }

    const result = await getRecommendations({
      userId: req.user.id,
      mood,
      genres: parsedGenres.genres,
      genreInputInvalid: parsedGenres.invalid,
      mediaType,
    });

    return res.json(result);
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  listGenres,
  recommendations,
};
