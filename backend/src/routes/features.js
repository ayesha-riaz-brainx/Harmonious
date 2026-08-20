const express = require('express');

const { requireUser } = require('../middleware/auth');
const {
  getContext,
  chat,
  runTool,
  clearMemory,
  transcribe,
} = require('../controllers/aiCoachController');
const {
  capture,
  listCaptures,
} = require('../controllers/captureController');
const {
  getJourney,
  createReview,
} = require('../controllers/journeyController');
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

router.get('/ai/context', requireUser, getContext);
router.post('/ai/chat', requireUser, chat);
router.post('/ai/tool', requireUser, runTool);
router.post('/ai/transcribe', requireUser, transcribe);
router.delete('/ai/memory', requireUser, clearMemory);

router.get('/captures', requireUser, listCaptures);
router.post('/captures', requireUser, capture);

router.get('/foods/search', requireUser, searchFoods);

router.get('/entertainment/genres', requireUser, listEntertainmentGenres);
router.get('/entertainment/recommendations', requireUser, entertainmentRecommendations);

router.get('/journey', requireUser, getJourney);
router.post('/journey/review', requireUser, createReview);

router.get('/settings', requireUser, getSettings);
router.patch('/settings', requireUser, updateSettings);
router.get('/settings/export', requireUser, exportData);

module.exports = router;
