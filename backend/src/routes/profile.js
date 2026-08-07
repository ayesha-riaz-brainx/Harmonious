const express = require('express');

const { requireUser } = require('../middleware/auth');
const {
  profileValidation,
  getProfile,
  updateProfile,
} = require('../controllers/profileController');

const router = express.Router();

router.get('/me', requireUser, getProfile);
router.put('/me', requireUser, profileValidation, updateProfile);

module.exports = router;
