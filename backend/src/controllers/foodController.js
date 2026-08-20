const { hasFdcKey, searchFoods } = require('../services/foodSearchService');

async function search(req, res, next) {
  try {
    const query = (req.query.query || '').trim();
    if (query.length < 2) {
      return res.status(400).json({
        message: 'Enter at least 2 characters to search.',
        code: 'FOOD_SEARCH_QUERY_TOO_SHORT',
      });
    }

    if (!hasFdcKey()) {
      return res.status(503).json({
        message:
          'Food search is not set up. Enter calories manually below.',
        code: 'FOOD_SEARCH_NOT_CONFIGURED',
        foods: [],
      });
    }

    const foods = await searchFoods(query);
    return res.json({ foods });
  } catch (error) {
    return next(error);
  }
}

module.exports = { search };
