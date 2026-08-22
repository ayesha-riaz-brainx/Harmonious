const express = require('express');

const { requireUser } = require('../middleware/auth');
const { runTool } = require('../controllers/aiCoachController');
const {
  capture,
  listCaptures,
} = require('../controllers/captureController');
const { getJourney } = require('../controllers/journeyController');
const {
  getSettings,
  updateSettings,
  exportData,
} = require('../controllers/settingsController');
const { search: searchFoods } = require('../controllers/foodController');
const {
  listGenres: listEntertainmentGenres,
  recommendations: entertainmentRecommendations,
} = require('../controllers/entertainmentController');

const router = express.Router();

router.post('/ai/tool', requireUser, runTool);

router.get('/captures', requireUser, listCaptures);
router.post('/captures', requireUser, capture);

router.get('/foods/search', requireUser, searchFoods);

router.get('/entertainment/genres', requireUser, listEntertainmentGenres);
router.get('/entertainment/recommendations', requireUser, entertainmentRecommendations);

router.get('/journey', requireUser, getJourney);

router.get('/settings', requireUser, getSettings);
router.patch('/settings', requireUser, updateSettings);
router.get('/settings/export', requireUser, exportData);

module.exports = router;
