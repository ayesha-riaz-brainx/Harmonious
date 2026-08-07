const express = require('express');

const { requireUser } = require('../middleware/auth');
const {
  signUpValidation,
  loginValidation,
  forgotValidation,
  resetValidation,
  signUp,
  login,
  forgotPassword,
  resetPassword,
  deleteAccount,
} = require('../controllers/authController');

const router = express.Router();

router.post('/signup', signUpValidation, signUp);
router.post('/login', loginValidation, login);
router.post('/forgot-password', forgotValidation, forgotPassword);
router.post('/reset-password', resetValidation, resetPassword);
router.delete('/account', requireUser, deleteAccount);

module.exports = router;
