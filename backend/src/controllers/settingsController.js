const { getSupabaseAdmin } = require('../config/supabase');

function scoreTracker(tracker) {
  if (!tracker || typeof tracker !== 'object' || Array.isArray(tracker)) return 0;
  return (
    (Array.isArray(tracker.records) ? tracker.records.length : 0) +
    (Array.isArray(tracker.conditions) ? tracker.conditions.length : 0) +
    (Array.isArray(tracker.symptoms) ? tracker.symptoms.length : 0)
  );
}

function resolveTracker(data) {
  const column = data?.health_tracker;
  const nested = data?.app_settings?.health_tracker;
  if (scoreTracker(column) >= scoreTracker(nested)) {
    return column && typeof column === 'object' ? column : nested || {};
  }
  return nested && typeof nested === 'object' ? nested : column || {};
}

/** Fill missing profile columns from onboarding_data so You / BMI show real values. */
function hydrateProfile(data) {
  if (!data || typeof data !== 'object') return data;
  const onboarding =
    data.onboarding_data && typeof data.onboarding_data === 'object'
      ? data.onboarding_data
      : {};

  const pick = (columnKey, onboardingKeys = [columnKey]) => {
    const current = data[columnKey];
    if (current !== null && current !== undefined && current !== '') {
      return current;
    }
    for (const key of onboardingKeys) {
      const value = onboarding[key];
      if (value !== null && value !== undefined && value !== '') return value;
    }
    return current;
  };

  return {
    ...data,
    display_name: pick('display_name', ['display_name', 'name', 'full_name']),
    full_name: pick('full_name', ['full_name', 'display_name', 'name']),
    age: pick('age'),
    gender: pick('gender'),
    height: pick('height'),
    weight: pick('weight'),
    height_unit: pick('height_unit') || 'cm',
    weight_unit: pick('weight_unit') || 'kg',
    activity_level: pick('activity_level'),
    birthday: pick('birthday'),
    zodiac_sign: pick('zodiac_sign', ['zodiac_sign', 'zodiac']),
  };
}

function goalsFrom(data) {
  const goals = data?.onboarding_data?.goals;
  if (!Array.isArray(goals)) return [];
  return goals.map((g) => String(g)).filter(Boolean);
}

async function getSettings(req, res, next) {
  try {
    const supabase = getSupabaseAdmin();
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', req.user.id)
      .maybeSingle();
    if (error) throw error;

    const profile = hydrateProfile(data);

    return res.json({
      profile,
      settings: data?.app_settings || {},
      health_info: data?.health_info || {},
      health_tracker: resolveTracker(data),
      goals: goalsFrom(data),
      onboarding_data: data?.onboarding_data || {},
    });
  } catch (error) {
    return next(error);
  }
}

async function updateSettings(req, res, next) {
  try {
    const supabase = getSupabaseAdmin();
    const { data: existing, error: readError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', req.user.id)
      .maybeSingle();
    if (readError) throw readError;

    const patch = { updated_at: new Date().toISOString() };
    const body = req.body || {};
    let nextOnboarding = {
      ...(existing?.onboarding_data || {}),
    };
    let onboardingTouched = false;

    if (body.profile && typeof body.profile === 'object') {
      const profile = body.profile;

      if (
        typeof profile.display_name === 'string' &&
        profile.display_name.trim()
      ) {
        const name = profile.display_name.trim();
        patch.display_name = name;
        patch.full_name = name;
      }

      for (const key of ['age', 'height', 'weight', 'country', 'gender']) {
        const value = profile[key];
        if (value === undefined || value === null || value === '') continue;
        if (key === 'age') {
          const age = Number.parseInt(String(value), 10);
          if (!Number.isFinite(age)) continue;
          patch.age = age;
          nextOnboarding.age = age;
          onboardingTouched = true;
          continue;
        }
        if (key === 'height' || key === 'weight') {
          const num = Number.parseFloat(String(value));
          if (!Number.isFinite(num)) continue;
          patch[key] = num;
          nextOnboarding[key] = num;
          onboardingTouched = true;
          continue;
        }
        patch[key] = value;
        nextOnboarding[key] = value;
        onboardingTouched = true;
      }

      for (const key of ['height_unit', 'weight_unit']) {
        if (typeof profile[key] === 'string' && profile[key].trim()) {
          patch[key] = profile[key].trim();
          nextOnboarding[key] = profile[key].trim();
          onboardingTouched = true;
        }
      }
    }

    if (body.goals) {
      nextOnboarding = {
        ...nextOnboarding,
        goals: body.goals,
      };
      onboardingTouched = true;
    }

    if (onboardingTouched) {
      patch.onboarding_data = nextOnboarding;
    }

    if (body.health_info) {
      patch.health_info = {
        ...(existing?.health_info || {}),
        ...body.health_info,
      };
    }

    // Dual-write: column + app_settings so it works even if column is missing.
    const nextSettings = {
      ...(existing?.app_settings || {}),
      ...(body.settings || {}),
    };
    if (body.health_tracker && typeof body.health_tracker === 'object') {
      patch.health_tracker = body.health_tracker;
      nextSettings.health_tracker = body.health_tracker;
    }
    if (body.settings || body.health_tracker) {
      patch.app_settings = nextSettings;
    }

    let { data, error } = await supabase
      .from('profiles')
      .update(patch)
      .eq('id', req.user.id)
      .select('*')
      .single();

    if (
      error &&
      body.health_tracker &&
      typeof body.health_tracker === 'object' &&
      /health_tracker/i.test(`${error.message || ''} ${error.details || ''}`)
    ) {
      const fallbackPatch = { ...patch };
      delete fallbackPatch.health_tracker;
      fallbackPatch.app_settings = {
        ...(existing?.app_settings || {}),
        ...(body.settings || {}),
        health_tracker: body.health_tracker,
      };
      const retry = await supabase
        .from('profiles')
        .update(fallbackPatch)
        .eq('id', req.user.id)
        .select('*')
        .single();
      data = retry.data;
      error = retry.error;
    }

    if (error) throw error;

    const resolved = resolveTracker(data);
    const tracker =
      scoreTracker(resolved) > 0
        ? resolved
        : body.health_tracker && typeof body.health_tracker === 'object'
          ? body.health_tracker
          : resolved;

    const profile = hydrateProfile(data);

    return res.json({
      message: 'Settings saved.',
      profile,
      settings: data.app_settings || {},
      health_info: data.health_info || {},
      health_tracker: tracker,
      goals: goalsFrom(data),
      onboarding_data: data.onboarding_data || {},
    });
  } catch (error) {
    return next(error);
  }
}

async function exportData(req, res, next) {
  try {
    const supabase = getSupabaseAdmin();
    const [profile, captures, messages, logs] = await Promise.all([
      supabase.from('profiles').select('*').eq('id', req.user.id).maybeSingle(),
      supabase.from('captures').select('*').eq('user_id', req.user.id),
      supabase.from('ai_messages').select('*').eq('user_id', req.user.id),
      supabase.from('daily_logs').select('*').eq('user_id', req.user.id),
    ]);
    for (const result of [profile, captures, messages, logs]) {
      if (result.error) throw result.error;
    }
    return res.json({
      exported_at: new Date().toISOString(),
      profile: hydrateProfile(profile.data),
      captures: captures.data || [],
      ai_messages: messages.data || [],
      daily_logs: logs.data || [],
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = { getSettings, updateSettings, exportData };
