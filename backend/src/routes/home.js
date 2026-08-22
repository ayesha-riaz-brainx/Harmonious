const express = require('express');

const { requireUser } = require('../middleware/auth');
const { getToday, updateToday } = require('../controllers/homeController');

const router = express.Router();

router.get('/today', requireUser, getToday);
router.patch('/today', requireUser, updateToday);

module.exports = router;
