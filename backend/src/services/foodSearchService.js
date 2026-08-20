const FDC_SEARCH_URL = 'https://api.nal.usda.gov/fdc/v1/foods/search';

const DATA_TYPE_PRIORITY = {
  Foundation: 0,
  'SR Legacy': 1,
  'Survey (FNDDS)': 2,
  Branded: 3,
};

function hasFdcKey() {
  const key = (process.env.USDA_FDC_API_KEY || '').trim();
  return key.length > 0 && !key.includes('PASTE_YOUR_');
}

function energyKcal(foodNutrients = []) {
  for (const nutrient of foodNutrients) {
    const id = nutrient.nutrientId ?? nutrient.nutrientNumber;
    const name = (nutrient.nutrientName || '').toLowerCase();
    if (id === 1008 || id === '1008' || name === 'energy') {
      const value = nutrient.value ?? nutrient.amount;
      if (Number.isFinite(Number(value))) {
        return Math.round(Number(value));
      }
    }
  }
  return null;
}

function simplifyFood(food) {
  if (!food) return null;

  const kcalPer100g = energyKcal(food.foodNutrients);
  const servingSize = Number(food.servingSize);
  const servingUnit = food.servingSizeUnit || null;

  let kcalPerServing = null;
  if (kcalPer100g != null && Number.isFinite(servingSize) && servingSize > 0) {
    kcalPerServing = Math.round((kcalPer100g * servingSize) / 100);
  }

  const name =
    food.description ||
    food.lowercaseDescription ||
    food.additionalDescriptions ||
    'Unknown food';

  return {
    id: food.fdcId,
    name: String(name).trim(),
    brand: food.brandOwner || food.brandName || null,
    data_type: food.dataType || null,
    kcal_per_100g: kcalPer100g,
    kcal_per_serving: kcalPerServing,
    serving_size: Number.isFinite(servingSize) && servingSize > 0 ? servingSize : null,
    serving_unit: servingUnit,
  };
}

function normalizeName(name) {
  return String(name || '')
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

function isGenericQuery(query) {
  const words = query.trim().toLowerCase().split(/\s+/).filter(Boolean);
  if (words.length === 0) return true;
  if (words.length > 4) return false;
  // Short, everyday food queries — prefer generic over branded listings.
  return !/\b(inc|llc|co\.|company|brand|®|™)\b/i.test(query);
}

function dataTypeRank(dataType) {
  if (!dataType) return 9;
  for (const [key, rank] of Object.entries(DATA_TYPE_PRIORITY)) {
    if (dataType.includes(key)) return rank;
  }
  return 8;
}

function relevanceScore(food, query) {
  const name = normalizeName(food.description || food.lowercaseDescription || '');
  const terms = query.trim().toLowerCase().split(/\s+/).filter(Boolean);
  if (!name || terms.length === 0) return 0;

  let matched = 0;
  for (const term of terms) {
    if (name.includes(term)) matched += 1;
  }
  const coverage = matched / terms.length;
  const startsWith = terms.every((term) => name.startsWith(term) || name.includes(` ${term}`));
  return coverage + (startsWith ? 0.25 : 0);
}

function rankAndFilterFoods(rawFoods, query) {
  const generic = isGenericQuery(query);
  const seen = new Set();
  const genericItems = [];
  const brandedItems = [];

  for (const food of rawFoods) {
    const item = simplifyFood(food);
    if (!item || !item.name || item.kcal_per_100g == null) continue;

    const hasBrand = Boolean(item.brand);
    const key = normalizeName(item.name);
    if (!key || seen.has(key)) continue;

    const entry = {
      item,
      rank: dataTypeRank(item.data_type),
      score: relevanceScore(food, query),
    };

    if (generic && hasBrand) {
      brandedItems.push(entry);
      continue;
    }

    seen.add(key);
    genericItems.push(entry);
  }

  const byQuality = (a, b) => {
    if (a.rank !== b.rank) return a.rank - b.rank;
    if (b.score !== a.score) return b.score - a.score;
    return a.item.name.length - b.item.name.length;
  };

  genericItems.sort(byQuality);
  brandedItems.sort(byQuality);

  const maxBranded = generic ? 2 : 5;
  const merged = [
    ...genericItems.map((e) => e.item),
    ...brandedItems.slice(0, maxBranded).map((e) => e.item),
  ];

  return merged.slice(0, 15);
}

async function fetchFoodSearch(url) {
  let lastError;
  for (let attempt = 0; attempt < 2; attempt += 1) {
    if (attempt > 0) {
      await new Promise((resolve) => setTimeout(resolve, 350));
    }

    let response;
    try {
      response = await fetch(url.toString());
    } catch (cause) {
      lastError = cause;
      continue;
    }

    const rawText = await response.text();
    let body = {};
    const looksJson =
      rawText.trim().startsWith('{') || rawText.trim().startsWith('[');

    if (looksJson) {
      try {
        body = JSON.parse(rawText);
      } catch {
        const error = new Error('Food database returned an invalid response.');
        error.status = 502;
        error.code = 'FOOD_SEARCH_UPSTREAM';
        throw error;
      }
    }

    if (response.ok) {
      return body;
    }

    if (!looksJson) {
      lastError = new Error('Food database is temporarily unavailable.');
      lastError.status = response.status >= 500 ? 502 : 503;
      lastError.code = 'FOOD_SEARCH_UPSTREAM';
      continue;
    }

    const message =
      body?.message || body?.error || `Food search failed (${response.status})`;
    const error = new Error(message);
    error.status = response.status >= 500 ? 502 : response.status;
    error.code = 'FOOD_SEARCH_UPSTREAM';
    throw error;
  }

  if (lastError instanceof Error) {
    if (!lastError.status) {
      lastError.status = 502;
      lastError.code = 'FOOD_SEARCH_NETWORK';
    }
    throw lastError;
  }

  const error = new Error('Could not reach the food database. Check your connection.');
  error.status = 502;
  error.code = 'FOOD_SEARCH_NETWORK';
  throw error;
}

async function searchFoods(query, pageSize = 15) {
  if (!hasFdcKey()) {
    const error = new Error(
      'USDA food search is not configured. Add USDA_FDC_API_KEY to backend/.env.',
    );
    error.status = 503;
    error.code = 'FOOD_SEARCH_NOT_CONFIGURED';
    throw error;
  }

  const apiKey = process.env.USDA_FDC_API_KEY.trim();
  const url = new URL(FDC_SEARCH_URL);
  url.searchParams.set('api_key', apiKey);
  url.searchParams.set('query', query);
  url.searchParams.set('pageSize', String(Math.min(Math.max(pageSize, 1), 20)));
  url.searchParams.set(
    'dataType',
    'Foundation,SR Legacy,Survey (FNDDS),Branded',
  );

  const body = await fetchFoodSearch(url);
  return rankAndFilterFoods(body.foods || [], query);
}

module.exports = { hasFdcKey, searchFoods };
