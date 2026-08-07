const { body, validationResult } = require('express-validator');

const { getSupabaseAdmin } = require('../config/supabase');

const profileValidation = [
  body('displayName').optional({ nullable: true }).trim().isLength({ max: 80 }),
  body('age').optional({ nullable: true }).isInt({ min: 1, max: 120 }),
  body('gender').optional({ nullable: true }).trim().isLength({ max: 40 }),
  body('height').optional({ nullable: true }).isFloat({ min: 0 }),
  body('weight').optional({ nullable: true }).isFloat({ min: 0 }),
  body('country').optional({ nullable: true }).trim().isLength({ max: 80 }),
  body('weightUnit').optional({ nullable: true }).isIn(['kg', 'lb']),
  body('heightUnit').optional({ nullable: true }).isIn(['cm', 'ft']),
  body('profileSetupCompleted').optional().isBoolean(),
  body('onboardingCompleted').optional().isBoolean(),
];

async function getProfile(req, res, next) {
  try {
    const supabase = getSupabaseAdmin();
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', req.user.id)
      .maybeSingle();

    if (error) {
      return res.status(400).json({ message: error.message });
    }

    return res.json({ profile: data });
  } catch (error) {
    return next(error);
  }
}

async function updateProfile(req, res, next) {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ message: 'Validation failed.', errors: errors.array() });
    }

    const {
      displayName,
      age,
      gender,
      height,
      weight,
      country,
      weightUnit,
      heightUnit,
      profileSetupCompleted,
      onboardingCompleted,
    } = req.body;

    const payload = {
      id: req.user.id,
      email: req.user.email,
      updated_at: new Date().toISOString(),
    };

    if (displayName !== undefined) {
      payload.display_name = displayName;
      payload.full_name = displayName;
    }
    if (age !== undefined) payload.age = age;
    if (gender !== undefined) payload.gender = gender;
    if (height !== undefined) payload.height = height;
    if (weight !== undefined) payload.weight = weight;
    if (country !== undefined) payload.country = country;
    if (weightUnit !== undefined) payload.weight_unit = weightUnit;
    if (heightUnit !== undefined) payload.height_unit = heightUnit;
    if (profileSetupCompleted !== undefined) {
      payload.profile_setup_completed = profileSetupCompleted;
    }
    if (onboardingCompleted !== undefined) {
      payload.onboarding_completed = onboardingCompleted;
    }

    const supabase = getSupabaseAdmin();
    const { data, error } = await supabase
      .from('profiles')
      .upsert(payload)
      .select('*')
      .single();

    if (error) {
      return res.status(400).json({ message: error.message });
    }

    return res.json({ message: 'Profile saved.', profile: data });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  profileValidation,
  getProfile,
  updateProfile,
};
