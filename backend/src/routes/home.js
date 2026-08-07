const express = require('express');

const { requireUser } = require('../middleware/auth');
const { getToday, updateToday, refreshAi } = require('../controllers/homeController');

const router = express.Router();

router.get('/today', requireUser, getToday);
router.patch('/today', requireUser, updateToday);
router.post('/today/refresh-ai', requireUser, refreshAi);

module.exports = router;
