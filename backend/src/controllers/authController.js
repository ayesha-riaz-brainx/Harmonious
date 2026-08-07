const { body, validationResult } = require('express-validator');

const { getSupabaseAdmin } = require('../config/supabase');
const { sendPasswordResetEmail } = require('../services/emailService');
const {
  createResetCode,
  consumeResetCode,
} = require('../services/passwordResetService');

const signUpValidation = [
  body('fullName').trim().notEmpty().withMessage('Full name is required.'),
  body('email')
    .trim()
    .isEmail()
    .withMessage('Enter a valid email address.')
    .normalizeEmail(),
  body('password')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters.'),
];

const loginValidation = [
  body('email')
    .trim()
    .isEmail()
    .withMessage('Enter a valid email address.')
    .normalizeEmail(),
  body('password').notEmpty().withMessage('Password is required.'),
];

const forgotValidation = [
  body('email')
    .trim()
    .isEmail()
    .withMessage('Enter a valid email address.')
    .normalizeEmail(),
];

const resetValidation = [
  body('email')
    .trim()
    .isEmail()
    .withMessage('Enter a valid email address.')
    .normalizeEmail(),
  body('code')
    .trim()
    .matches(/^\d{6}$/)
    .withMessage('Enter the 6-digit code from your email.'),
  body('password')
    .isLength({ min: 8 })
    .withMessage('Password must be at least 8 characters.'),
];

function validationFailed(req, res) {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    res
      .status(400)
      .json({ message: 'Validation failed.', errors: errors.array() });
    return true;
  }
  return false;
}

async function findUserByEmail(supabase, email) {
  const normalized = email.trim().toLowerCase();
  // Prefer profiles lookup, then Auth list.
  const { data: profile } = await supabase
    .from('profiles')
    .select('id,email')
    .eq('email', normalized)
    .maybeSingle();
  if (profile?.id) {
    const { data, error } = await supabase.auth.admin.getUserById(profile.id);
    if (!error && data?.user) return data.user;
  }

  let page = 1;
  while (page <= 5) {
    const { data, error } = await supabase.auth.admin.listUsers({
      page,
      perPage: 200,
    });
    if (error) throw error;
    const users = data?.users || [];
    const match = users.find(
      (item) => (item.email || '').toLowerCase() === normalized,
    );
    if (match) return match;
    if (users.length < 200) break;
    page += 1;
  }
  return null;
}

async function signUp(req, res, next) {
  try {
    if (validationFailed(req, res)) return;

    const { fullName, email, password } = req.body;
    const supabase = getSupabaseAdmin();

    const { data, error } = await supabase.auth.admin.createUser({
      email: email.trim().toLowerCase(),
      password,
      email_confirm: true,
      user_metadata: { full_name: fullName.trim() },
    });

    if (error) {
      const status = error.message?.toLowerCase().includes('already')
        ? 409
        : 400;
      return res.status(status).json({ message: error.message });
    }

    const user = data.user;
    const profilePayload = {
      id: user.id,
      full_name: fullName.trim(),
      email: email.trim().toLowerCase(),
      display_name: fullName.trim(),
    };
    let { error: profileError } = await supabase
      .from('profiles')
      .upsert(profilePayload);
    if (profileError) {
      const { display_name, ...basic } = profilePayload;
      await supabase.from('profiles').upsert(basic);
    }

    return res.status(201).json({
      message: 'Account created successfully.',
      user: { id: user.id, email: user.email, fullName: fullName.trim() },
    });
  } catch (error) {
    return next(error);
  }
}

async function login(req, res, next) {
  try {
    if (validationFailed(req, res)) return;

    const { email, password } = req.body;
    const supabase = getSupabaseAdmin();

    const { data, error } = await supabase.auth.signInWithPassword({
      email: email.trim().toLowerCase(),
      password,
    });

    if (error) {
      return res
        .status(401)
        .json({ message: error.message || 'Invalid credentials.' });
    }

    return res.json({
      message: 'Logged in successfully.',
      session: data.session,
      user: {
        id: data.user.id,
        email: data.user.email,
        fullName: data.user.user_metadata?.full_name || '',
      },
    });
  } catch (error) {
    return next(error);
  }
}

async function forgotPassword(req, res, next) {
  try {
    if (validationFailed(req, res)) return;

    const email = req.body.email.trim().toLowerCase();
    const supabase = getSupabaseAdmin();
    const user = await findUserByEmail(supabase, email);

    if (user) {
      const { code } = await createResetCode(email);
      await sendPasswordResetEmail({ to: email, code });
    }

    return res.json({
      message:
        'If an account exists for that email, a 6-digit reset code has been sent. Check your inbox (or Mailtrap Email Testing).',
    });
  } catch (error) {
    if (error.code === 'MAIL_NOT_CONFIGURED') {
      return res.status(503).json({ message: error.message });
    }
    return next(error);
  }
}

async function resetPassword(req, res, next) {
  try {
    if (validationFailed(req, res)) return;

    const email = req.body.email.trim().toLowerCase();
    const code = String(req.body.code).trim();
    const password = req.body.password;

    const valid = await consumeResetCode(email, code);
    if (!valid) {
      return res.status(400).json({
        message: 'Invalid or expired reset code. Request a new one.',
      });
    }

    const supabase = getSupabaseAdmin();
    const user = await findUserByEmail(supabase, email);
    if (!user) {
      return res.status(404).json({ message: 'Account not found.' });
    }

    const { error: updateError } = await supabase.auth.admin.updateUserById(
      user.id,
      { password },
    );
    if (updateError) {
      return res.status(400).json({ message: updateError.message });
    }

    return res.json({
      message: 'Password updated. You can sign in with your new password.',
    });
  } catch (error) {
    return next(error);
  }
}

async function deleteAccount(req, res, next) {
  try {
    const supabase = getSupabaseAdmin();
    const userId = req.user.id;

    await supabase.from('profiles').delete().eq('id', userId);
    const { error } = await supabase.auth.admin.deleteUser(userId);

    if (error) {
      return res.status(400).json({ message: error.message });
    }

    return res.json({ message: 'Account deleted successfully.' });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  signUpValidation,
  loginValidation,
  forgotValidation,
  resetValidation,
  signUp,
  login,
  forgotPassword,
  resetPassword,
  deleteAccount,
};
