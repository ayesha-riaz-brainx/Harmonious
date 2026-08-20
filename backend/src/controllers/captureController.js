const { getSupabaseAdmin } = require('../config/supabase');
const { hasAiKey } = require('../services/aiService');
const {
  defaultTasks,
  resolveLogDate,
  buildHomePayload,
  tasksForCaptureType,
  validateCapturePayload,
  safeNum,
} = require('../services/homeService');

async function getWeeklyHistory(supabase, userId, anchorDate) {
  const end = anchorDate || resolveLogDate();
  const endAt = new Date(`${end}T12:00:00Z`);
  const start = new Date(endAt);
  start.setUTCDate(start.getUTCDate() - 6);
  const { data, error } = await supabase
    .from('daily_logs')
    .select(
      'log_date,weight,water_liters,calories,exercise_minutes,mood,sleep_hours,tasks',
    )
    .eq('user_id', userId)
    .gte('log_date', start.toISOString().slice(0, 10))
    .lte('log_date', end)
    .order('log_date', { ascending: true });
  if (error) throw error;
  return data || [];
}

async function loadHomeSnapshot(supabase, userId, logDate) {
  const { data: profile, error: profileError } = await supabase
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .maybeSingle();
  if (profileError) throw profileError;

  const date = logDate || resolveLogDate();
  const { data: log, error: logError } = await supabase
    .from('daily_logs')
    .select('*')
    .eq('user_id', userId)
    .eq('log_date', date)
    .maybeSingle();
  if (logError) throw logError;

  const weeklyHistory = await getWeeklyHistory(supabase, userId, date);
  const aiProfile = profile?.ai_profile || {};

  return {
    ...buildHomePayload({ profile, log, aiProfile }),
    weekly_history: weeklyHistory,
    ai_enabled: hasAiKey(),
  };
}

async function capture(req, res, next) {
  try {
    const { type, payload = {} } = req.body || {};
    const allowed = [
      'meal',
      'water',
      'weight',
      'workout',
      'mood',
      'sleep',
      'journal',
    ];
    if (!allowed.includes(type)) {
      return res.status(400).json({ message: 'Invalid capture type.' });
    }

    const validationError = validateCapturePayload(type, payload);
    if (validationError) {
      return res.status(400).json({ message: validationError });
    }

    const normalized = { ...payload };
    if (type === 'water') {
      let liters = Number(normalized.liters);
      if (!Number.isFinite(liters) || liters <= 0) {
        if (Number.isFinite(Number(normalized.ml)) && Number(normalized.ml) > 0) {
          liters = Number(normalized.ml) / 1000;
        } else if (
          Number.isFinite(Number(normalized.glasses)) &&
          Number(normalized.glasses) > 0
        ) {
          liters = Number(normalized.glasses) * 0.25;
        } else {
          liters = 0.25;
        }
      }
      const glasses = Number(
        Number.isFinite(Number(normalized.glasses))
          ? normalized.glasses
          : Number((liters / 0.25).toFixed(2)),
      );
      normalized.liters = Number(liters.toFixed(3));
      normalized.glasses = glasses;
      normalized.ml = Math.round(normalized.liters * 1000);
    }

    const supabase = getSupabaseAdmin();
    const { data: item, error: captureError } = await supabase
      .from('captures')
      .insert({ user_id: req.user.id, type, payload: normalized })
      .select('*')
      .single();
    if (captureError) throw captureError;

    const date = resolveLogDate(req);
    const { data: existing, error: readError } = await supabase
      .from('daily_logs')
      .select('*')
      .eq('user_id', req.user.id)
      .eq('log_date', date)
      .maybeSingle();
    if (readError) throw readError;

    const { data: profile } = await supabase
      .from('profiles')
      .select('ai_profile, onboarding_data')
      .eq('id', req.user.id)
      .maybeSingle();

    const baseTasks =
      existing?.tasks ||
      defaultTasks(profile?.ai_profile || {}, profile?.onboarding_data || {});
    const patch = {
      user_id: req.user.id,
      log_date: date,
      updated_at: new Date().toISOString(),
      tasks: tasksForCaptureType(baseTasks, type),
    };

    // Do not clear ai_brief on capture — Today uses rule-based briefs by
    // default, and OpenAI regen is explicit via refreshAi only.

    if (type === 'water') {
      patch.water_liters =
        safeNum(existing?.water_liters, 0) + safeNum(normalized.liters, 0);
    }
    if (type === 'meal') {
      patch.calories =
        Math.round(safeNum(existing?.calories, 0) + safeNum(normalized.calories, 0));
    }
    if (type === 'workout') {
      patch.exercise_minutes =
        Math.round(safeNum(existing?.exercise_minutes, 0) + safeNum(normalized.minutes, 0));
    }
    if (type === 'weight') patch.weight = safeNum(normalized.weight, 0, { min: 1, max: 500 });
    if (type === 'mood') patch.mood = String(normalized.mood || '').trim();
    if (type === 'sleep') patch.sleep_hours = safeNum(normalized.hours, 0, { min: 0, max: 24 });

    // Preserve other fields on upsert.
    if (existing) {
      if (patch.water_liters === undefined) {
        patch.water_liters = existing.water_liters;
      }
      if (patch.calories === undefined) patch.calories = existing.calories;
      if (patch.exercise_minutes === undefined) {
        patch.exercise_minutes = existing.exercise_minutes;
      }
      if (patch.weight === undefined) patch.weight = existing.weight;
      if (patch.mood === undefined) patch.mood = existing.mood;
      if (patch.sleep_hours === undefined) {
        patch.sleep_hours = existing.sleep_hours;
      }
    }

    const { error: logError } = await supabase
      .from('daily_logs')
      .upsert(patch, { onConflict: 'user_id,log_date' });
    if (logError) throw logError;

    if (type === 'weight') {
      await supabase
        .from('profiles')
        .update({
          weight: safeNum(normalized.weight, 0, { min: 1, max: 500 }),
          updated_at: new Date().toISOString(),
        })
        .eq('id', req.user.id);
    }

    const message =
      type === 'water'
        ? `${normalized.ml} ml logged (~${normalized.glasses} glass${
            Number(normalized.glasses) === 1 ? '' : 'es'
          }).`
        : `${type.replace('_', ' ')} logged.`;

    const home = await loadHomeSnapshot(supabase, req.user.id, date);

    return res.status(201).json({
      message,
      capture: item,
      home,
    });
  } catch (error) {
    return next(error);
  }
}

async function listCaptures(req, res, next) {
  try {
    const limit = Math.min(Number(req.query.limit || 100), 300);
    const supabase = getSupabaseAdmin();
    const { data, error } = await supabase
      .from('captures')
      .select('*')
      .eq('user_id', req.user.id)
      .order('captured_at', { ascending: false })
      .limit(limit);
    if (error) throw error;
    return res.json({ captures: data || [] });
  } catch (error) {
    return next(error);
  }
}

module.exports = { capture, listCaptures, loadHomeSnapshot, getWeeklyHistory };
