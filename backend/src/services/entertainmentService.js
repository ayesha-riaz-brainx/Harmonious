const { getSupabaseAdmin } = require('../config/supabase');

const TMDB_BASE = 'https://api.themoviedb.org/3';
const TMDB_IMAGE_BASE = 'https://image.tmdb.org/t/p/w500';

const ALLOWED_GENRES = [
  'Comedy',
  'Feel-Good',
  'Animation',
  'Adventure',
  'Drama',
  'Mystery',
  'Sci-Fi',
  'Fantasy',
  'Documentary',
  'Family',
  'Action',
  'Thriller',
];

const MOOD_GENRE_MAP = {
  sad: ['Comedy', 'Feel-Good', 'Animation', 'Family'],
  stressed: ['Comedy', 'Feel-Good', 'Documentary', 'Animation', 'Family'],
  lonely: ['Comedy', 'Family', 'Feel-Good', 'Drama'],
  bored: ['Adventure', 'Mystery', 'Comedy', 'Sci-Fi'],
  happy: ['Comedy', 'Adventure', 'Animation', 'Feel-Good'],
  anxious: ['Comedy', 'Feel-Good', 'Animation', 'Documentary', 'Family'],
  tired: ['Comedy', 'Feel-Good', 'Animation', 'Documentary', 'Family'],
  angry: ['Comedy', 'Adventure', 'Action'],
  low: ['Comedy', 'Feel-Good', 'Animation', 'Family'],
  neutral: ['Comedy', 'Feel-Good', 'Documentary', 'Family'],
};

const TMDB_GENRE_IDS = {
  Comedy: [35],
  'Feel-Good': [35, 10751],
  Animation: [16],
  Adventure: [12],
  Drama: [18],
  Mystery: [9648],
  'Sci-Fi': [878],
  Fantasy: [14],
  Documentary: [99],
  Family: [10751],
  Action: [28],
  Thriller: [53],
};

const DISTRESSED_MOODS = new Set([
  'sad',
  'stressed',
  'anxious',
  'tired',
  'lonely',
  'low',
  'bored',
]);

const HEAVY_GENRE_BLACKLIST = {
  sad: [27, 53, 80],
  anxious: [27, 53, 80],
  stressed: [27, 53, 80],
  tired: [27, 53, 80],
  lonely: [27, 53],
  low: [27, 53, 80],
  bored: [27],
  angry: [27],
};

const BLOCKED_OVERVIEW_KEYWORDS = [
  'explicit sexual',
  'self-harm',
  'self harm',
  'suicide',
  'terrorist',
  'extremist',
  'mass shooting',
  'graphic violence',
  'rape',
  'nazi',
];

const COUNTRY_NAME_TO_CODE = {
  'united states': 'US',
  usa: 'US',
  'united kingdom': 'GB',
  uk: 'GB',
  canada: 'CA',
  australia: 'AU',
  india: 'IN',
  germany: 'DE',
  france: 'FR',
  spain: 'ES',
  italy: 'IT',
  brazil: 'BR',
  mexico: 'MX',
  japan: 'JP',
  'south korea': 'KR',
  netherlands: 'NL',
  sweden: 'SE',
  norway: 'NO',
  denmark: 'DK',
  ireland: 'IE',
  'new zealand': 'NZ',
  pakistan: 'PK',
  singapore: 'SG',
};

const CERT_ORDER = ['G', 'PG', 'PG-13', 'R', 'NC-17'];

function hasTmdbKey() {
  const key = (process.env.TMDB_API_KEY || '').trim();
  return key.length > 0 && !key.includes('PASTE_YOUR_');
}

function normalizeMood(mood) {
  const value = String(mood || '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z\s-]/g, '')
    .replace(/\s+/g, ' ');
  if (!value) return 'neutral';
  if (value.includes('stress')) return 'stressed';
  if (value.includes('anxious') || value.includes('anxiety')) return 'anxious';
  if (value.includes('tired') || value.includes('exhaust')) return 'tired';
  if (value.includes('lonely') || value.includes('alone')) return 'lonely';
  if (value.includes('bored')) return 'bored';
  if (value.includes('sad') || value.includes('low')) return value.includes('low') ? 'low' : 'sad';
  if (value.includes('angry') || value.includes('frustrat')) return 'angry';
  if (value.includes('happy')) return 'happy';
  return value;
}

function isDistressedMood(mood) {
  return DISTRESSED_MOODS.has(normalizeMood(mood));
}

function normalizeGenre(name) {
  const trimmed = String(name || '').trim();
  const match = ALLOWED_GENRES.find(
    (genre) => genre.toLowerCase() === trimmed.toLowerCase(),
  );
  return match || null;
}

function parseGenresParam(raw) {
  if (!raw) return { genres: [], invalid: false };
  const parts = String(raw)
    .split(',')
    .map((part) => part.trim())
    .filter(Boolean);
  const genres = parts
    .map((part) => normalizeGenre(part))
    .filter(Boolean);
  return {
    genres,
    invalid: parts.length > 0 && genres.length !== parts.length,
  };
}

function suggestedGenresForMood(mood) {
  const normalized = normalizeMood(mood);
  return MOOD_GENRE_MAP[normalized] || MOOD_GENRE_MAP.neutral;
}

function resolveCountryCode(country) {
  const raw = String(country || '').trim();
  if (!raw) return 'US';
  if (/^[A-Za-z]{2}$/.test(raw)) return raw.toUpperCase();
  return COUNTRY_NAME_TO_CODE[raw.toLowerCase()] || 'US';
}

function maxCertificationForProfile(mood, age) {
  const distressed = isDistressedMood(mood);
  if (!distressed) {
    if (Number.isFinite(age) && age >= 18) return 'R';
    if (Number.isFinite(age) && age >= 13) return 'PG-13';
    return 'PG';
  }
  if (Number.isFinite(age) && age < 13) return 'PG';
  return 'PG-13';
}

function certIndex(cert) {
  const idx = CERT_ORDER.indexOf(String(cert || '').toUpperCase());
  return idx === -1 ? CERT_ORDER.length : idx;
}

function genreIdsForSelection(selectedGenres) {
  const ids = new Set();
  for (const genre of selectedGenres) {
    const mapped = TMDB_GENRE_IDS[genre] || [];
    for (const id of mapped) ids.add(id);
  }
  return [...ids];
}

function onboardingFavoriteGenres(onboarding = {}) {
  const candidates = [
    ...(onboarding.favorite_genres || []),
    ...(onboarding.favoriteGenres || []),
    ...(onboarding.relaxation_activities || []),
    ...(onboarding.relaxationActivities || []),
  ];
  return candidates
    .map((item) => normalizeGenre(item))
    .filter(Boolean);
}

function hasBlockedOverview(text) {
  const lower = String(text || '').toLowerCase();
  return BLOCKED_OVERVIEW_KEYWORDS.some((term) => lower.includes(term));
}

function passesGenreBlacklist(item, mood) {
  const normalized = normalizeMood(mood);
  const blacklist = HEAVY_GENRE_BLACKLIST[normalized] || [27];
  const genreIds = item.genre_ids || [];
  return !genreIds.some((id) => blacklist.includes(id));
}

function passesRatingFilter(item, maxCert) {
  const cert = item.certification || item.content_rating;
  if (!cert) return true;
  return certIndex(cert) <= certIndex(maxCert);
}

function safetyFilter(items, { mood, maxCert }) {
  return items.filter((item) => {
    if (item.adult === true) return false;
    if (hasBlockedOverview(item.overview)) return false;
    if (!passesGenreBlacklist(item, mood)) return false;
    if (!passesRatingFilter(item, maxCert)) return false;
    return true;
  });
}

function posterUrl(path) {
  if (!path) return null;
  return `${TMDB_IMAGE_BASE}${path}`;
}

function buildReason(item, mood, selectedGenres) {
  const genreLabel = selectedGenres[0] || 'feel-good';
  const normalized = normalizeMood(mood);
  const moodPhrase = {
    sad: 'a gentle lift when you are feeling down',
    stressed: 'something light while you unwind',
    anxious: 'a calming escape from racing thoughts',
    tired: 'easy viewing when your energy is low',
    lonely: 'warm company on a quiet night',
    bored: 'an engaging story to pull you in',
    happy: 'a fun match for your good mood',
    angry: 'a lively pick to shift your focus',
    low: 'something comforting for a low day',
  }[normalized] || 'a well-rated pick for your mood';

  const rating = item.vote_average ? `${item.vote_average.toFixed(1)}/10` : 'well reviewed';
  return `A ${genreLabel.toLowerCase()} ${item.media_type === 'tv' ? 'series' : 'film'} — ${moodPhrase}. Rated ${rating}.`;
}

function scoreItem(item, { selectedGenres, favoriteGenres, mood }) {
  let score = Number(item.vote_average || 0) * 10;
  score += Math.min(Number(item.popularity || 0) * 0.02, 12);

  const genreIds = new Set(item.genre_ids || []);
  for (const genre of selectedGenres) {
    for (const id of TMDB_GENRE_IDS[genre] || []) {
      if (genreIds.has(id)) score += 8;
    }
  }

  for (const genre of favoriteGenres) {
    for (const id of TMDB_GENRE_IDS[genre] || []) {
      if (genreIds.has(id)) score += 4;
    }
  }

  if (isDistressedMood(mood)) {
    if (genreIds.has(35) || genreIds.has(10751) || genreIds.has(16)) score += 6;
    if (genreIds.has(53) || genreIds.has(27) || genreIds.has(80)) score -= 20;
  }

  if (item.provider) score += 3;
  return score;
}

async function tmdbFetch(path, params = {}) {
  if (!hasTmdbKey()) {
    const error = new Error(
      'TMDB is not configured. Add TMDB_API_KEY to backend/.env.',
    );
    error.status = 503;
    error.code = 'TMDB_NOT_CONFIGURED';
    throw error;
  }

  const url = new URL(`${TMDB_BASE}${path}`);
  url.searchParams.set('api_key', process.env.TMDB_API_KEY.trim());
  for (const [key, value] of Object.entries(params)) {
    if (value !== undefined && value !== null && value !== '') {
      url.searchParams.set(key, String(value));
    }
  }

  const response = await fetch(url.toString());
  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    const message = body?.status_message || `TMDB request failed (${response.status})`;
    const error = new Error(message);
    error.status = response.status >= 500 ? 502 : 400;
    error.code = 'TMDB_UPSTREAM';
    throw error;
  }
  return body;
}

async function discoverMedia({
  mediaType,
  genreIds,
  country,
  maxCert,
  page = 1,
}) {
  const path = mediaType === 'tv' ? '/discover/tv' : '/discover/movie';
  const params = {
    with_genres: genreIds.join('|'),
    sort_by: 'popularity.desc',
    include_adult: 'false',
    'vote_count.gte': 80,
    'vote_average.gte': 6,
    page,
    watch_region: country,
  };

  if (mediaType === 'movie') {
    params.certification_country = country;
    params['certification.lte'] = maxCert;
  } else {
    params.without_genres = '27';
  }

  const body = await tmdbFetch(path, params);
  return (body.results || []).map((item) => ({
    ...item,
    media_type: mediaType,
  }));
}

async function fetchWatchProviders(item, country) {
  const path =
    item.media_type === 'tv'
      ? `/tv/${item.id}/watch/providers`
      : `/movie/${item.id}/watch/providers`;
  try {
    const body = await tmdbFetch(path);
    const region = body.results?.[country] || body.results?.US || null;
    if (!region) return null;

    const flatrate = region.flatrate?.[0];
    const rent = region.rent?.[0];
    const buy = region.buy?.[0];
    const provider = flatrate || rent || buy;
    if (!provider) return null;

    return {
      name: provider.provider_name,
      logo: posterUrl(provider.logo_path),
      link: region.link || null,
    };
  } catch (_) {
    return null;
  }
}

async function enrichWithProviders(items, country) {
  const enriched = [];
  for (const item of items) {
    const provider = await fetchWatchProviders(item, country);
    enriched.push({
      ...item,
      provider,
    });
  }
  return enriched;
}

function formatRecommendation(item, { mood, selectedGenres, country }) {
  const title = item.title || item.name || 'Untitled';
  const provider = item.provider;
  const tmdbUrl =
    item.media_type === 'tv'
      ? `https://www.themoviedb.org/tv/${item.id}`
      : `https://www.themoviedb.org/movie/${item.id}`;

  return {
    id: item.id,
    media_type: item.media_type,
    title,
    poster_url: posterUrl(item.poster_path),
    rating: item.vote_average ? Number(item.vote_average.toFixed(1)) : null,
    genre: selectedGenres.join(', '),
    reason: item.reason || buildReason(item, mood, selectedGenres),
    streaming: provider
      ? {
          provider: provider.name,
          logo_url: provider.logo,
          watch_url: provider.link || tmdbUrl,
        }
      : {
          provider: null,
          logo_url: null,
          watch_url: tmdbUrl,
        },
    region: country,
  };
}

async function loadUserContext(userId) {
  const supabase = getSupabaseAdmin();
  const { data: profile } = await supabase
    .from('profiles')
    .select('age, country, onboarding_data')
    .eq('id', userId)
    .maybeSingle();

  const age = Number.isFinite(Number(profile?.age))
    ? Number(profile.age)
    : null;
  const country = resolveCountryCode(profile?.country);
  const favoriteGenres = onboardingFavoriteGenres(profile?.onboarding_data || {});

  return { age, country, favoriteGenres };
}

async function getRecommendations({
  userId,
  mood,
  genres: selectedFromParam = [],
  genreInputInvalid = false,
  mediaType = 'both',
}) {
  const normalizedMood = normalizeMood(mood);
  if (genreInputInvalid) {
    const error = new Error(
      "That category isn't available. Please choose from the available genres.",
    );
    error.status = 400;
    error.code = 'ENTERTAINMENT_INVALID_GENRE';
    throw error;
  }

  const selectedGenres =
    selectedFromParam.length > 0
      ? selectedFromParam.slice(0, 2)
      : suggestedGenresForMood(normalizedMood).slice(0, 2);

  if (selectedFromParam.length > 2) {
    const error = new Error('Choose up to 2 genres.');
    error.status = 400;
    error.code = 'ENTERTAINMENT_TOO_MANY_GENRES';
    throw error;
  }

  const { age, country, favoriteGenres } = await loadUserContext(userId);
  const maxCert = maxCertificationForProfile(normalizedMood, age);
  const genreIds = genreIdsForSelection(selectedGenres);
  if (genreIds.length === 0) {
    return {
      mood: normalizedMood,
      genres: selectedGenres,
      recommendations: [],
      message: 'No safe matches found for those genres right now. Try another mood or genre.',
    };
  }

  const types =
    mediaType === 'movie' || mediaType === 'tv'
      ? [mediaType]
      : ['movie', 'tv'];

  let rawItems = [];
  for (const type of types) {
    const pageOne = await discoverMedia({
      mediaType: type,
      genreIds,
      country,
      maxCert,
      page: 1,
    });
    rawItems = rawItems.concat(pageOne);
  }

  const filtered = safetyFilter(rawItems, { mood: normalizedMood, maxCert });
  if (filtered.length === 0) {
    return {
      mood: normalizedMood,
      genres: selectedGenres,
      recommendations: [],
      message: 'No safe matches found for those genres right now. Try another mood or genre.',
    };
  }

  const ranked = filtered
    .map((item) => ({
      ...item,
      _score: scoreItem(item, {
        selectedGenres,
        favoriteGenres,
        mood: normalizedMood,
      }),
    }))
    .sort((a, b) => b._score - a._score);

  const candidatePool = ranked.slice(0, 15);
  // TMDB ranking only — no OpenAI (avoids per-request cost for Mood picks).
  const withProviders = await enrichWithProviders(candidatePool, country);
  const top = withProviders.slice(0, 3).map((item) => ({
    ...item,
    reason: buildReason(item, normalizedMood, selectedGenres),
  }));

  const recommendations = top
    .slice(0, 3)
    .map((item) =>
      formatRecommendation(item, {
        mood: normalizedMood,
        selectedGenres,
        country,
      }),
    );

  return {
    mood: normalizedMood,
    genres: selectedGenres,
    recommendations,
    message:
      recommendations.length === 0
        ? 'No safe matches found for those genres right now. Try another mood or genre.'
        : null,
  };
}

function getGenreCatalog(mood) {
  const normalized = normalizeMood(mood);
  return {
    allowed_genres: ALLOWED_GENRES,
    suggested_genres: suggestedGenresForMood(normalized),
    mood: normalized,
  };
}

module.exports = {
  ALLOWED_GENRES,
  MOOD_GENRE_MAP,
  TMDB_GENRE_IDS,
  hasTmdbKey,
  normalizeMood,
  normalizeGenre,
  parseGenresParam,
  suggestedGenresForMood,
  isDistressedMood,
  safetyFilter,
  scoreItem,
  buildReason,
  getGenreCatalog,
  getRecommendations,
};
