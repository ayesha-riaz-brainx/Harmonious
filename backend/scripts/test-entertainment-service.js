/**
 * Lightweight sanity checks for entertainmentService logic.
 * Run: node backend/scripts/test-entertainment-service.js
 */

const {
  normalizeMood,
  normalizeGenre,
  suggestedGenresForMood,
  safetyFilter,
  scoreItem,
  isDistressedMood,
  parseGenresParam,
} = require('../src/services/entertainmentService');

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function run() {
  assert(normalizeMood('Stressed') === 'stressed', 'mood normalize stressed');
  assert(normalizeMood('Low energy') === 'low', 'mood normalize low energy');
  assert(normalizeGenre('sci-fi') === 'Sci-Fi', 'genre normalize sci-fi');
  assert(normalizeGenre('Horror') === null, 'genre rejects horror');

  const sadSuggestions = suggestedGenresForMood('sad');
  assert(sadSuggestions.includes('Comedy'), 'sad suggests comedy');
  assert(!sadSuggestions.includes('Thriller'), 'sad avoids thriller');

  const parsed = parseGenresParam('Comedy, Animation');
  assert(parsed.genres.length === 2, 'parses valid genres');
  assert(parsed.invalid === false, 'valid genres not invalid');

  const bad = parseGenresParam('Comedy, Horror');
  assert(bad.invalid === true, 'flags invalid genre input');

  const filtered = safetyFilter(
    [
      {
        adult: false,
        overview: 'A warm family comedy.',
        genre_ids: [35, 10751],
        vote_average: 7.5,
      },
      {
        adult: false,
        overview: 'A dark story about suicide.',
        genre_ids: [18],
        vote_average: 8,
      },
      {
        adult: false,
        overview: 'A horror thriller.',
        genre_ids: [27, 53],
        vote_average: 7,
      },
    ],
    { mood: 'sad', maxCert: 'PG-13' },
  );
  assert(filtered.length === 1, 'safety filter keeps one safe item');

  const scored = scoreItem(
    {
      vote_average: 8,
      popularity: 120,
      genre_ids: [35, 16],
      provider: { name: 'Netflix' },
    },
    {
      selectedGenres: ['Comedy', 'Animation'],
      favoriteGenres: ['Comedy'],
      mood: 'anxious',
    },
  );
  assert(scored > 80, 'scores boosted candidate sensibly');
  assert(isDistressedMood('anxious') === true, 'anxious is distressed');

  console.log('entertainmentService checks passed');
}

run();
