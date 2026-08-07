const express = require('express');

const { requireUser } = require('../middleware/auth');
const { aiSummary } = require('../controllers/onboardingController');

const router = express.Router();

router.post('/ai-summary', requireUser, aiSummary);

module.exports = router;
