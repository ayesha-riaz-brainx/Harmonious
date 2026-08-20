const {
  generateDailyBrief,
  generateInsights,
  hasAiKey,
  fallbackBrief,
  fallbackInsights,
} = require('../services/aiService');
const {
  defaultTasks,
  resolveLogDate,
  buildHomePayload,
  safeNum,
  safeOptionalNum,
} = require('../services/homeService');
const { getSupabaseAdmin } = require('../config/supabase');

async function getOrCreateTodayLog(supabase, userId, aiProfile, logDate, onboarding = {}) {
  const date = logDate || resolveLogDate();
  const { data: existing, error } = await supabase
    .from('daily_logs')
    .select('*')
    .eq('user_id', userId)
    .eq('log_date', date)
    .maybeSingle();

  if (error) throw error;
  if (existing) return existing;

  const insert = {
    user_id: userId,
    log_date: date,
    tasks: defaultTasks(aiProfile, onboarding),
    ai_brief: {},
    ai_insights: [],
  };

  const { data: created, error: createError } = await supabase
    .from('daily_logs')
    .insert(insert)
    .select('*')
    .single();

  if (createError) throw createError;
  return created;
}

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

async function getToday(req, res, next) {
  try {
    const supabase = getSupabaseAdmin();
    const userId = req.user.id;

    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .maybeSingle();

    if (profileError) {
      return res.status(400).json({ message: profileError.message });
    }

    const aiProfile = profile?.ai_profile || {};
    const onboarding = profile?.onboarding_data || {};
    const logDate = resolveLogDate(req);
    let log = await getOrCreateTodayLog(
      supabase,
      userId,
      aiProfile,
      logDate,
      onboarding,
    );

    // MVP cost gate: never auto-call OpenAI on Today load.
    // Keep an explicit AI brief if the user generated one; otherwise refresh
    // free rule-based focus/insights from current log numbers.
    const source = log.ai_brief?.source;
    const keepAiBrief = source === 'openai' && Array.isArray(log.ai_brief?.focus_items);

    if (!keepAiBrief) {
      const brief = fallbackBrief(profile, aiProfile, log);
      const insights = fallbackInsights(profile, aiProfile, log);

      const { data: updated, error: updateError } = await supabase
        .from('daily_logs')
        .update({
          ai_brief: brief,
          ai_insights: insights,
          updated_at: new Date().toISOString(),
        })
        .eq('id', log.id)
        .select('*')
        .single();

      if (updateError) throw updateError;
      log = updated;
    }

    const weeklyHistory = await getWeeklyHistory(supabase, userId, logDate);

    return res.json({
      ...buildHomePayload({ profile, log, aiProfile }),
      ai_enabled: hasAiKey(),
      weekly_history: weeklyHistory,
    });
  } catch (error) {
    return next(error);
  }
}

async function updateToday(req, res, next) {
  try {
    const supabase = getSupabaseAdmin();
    const userId = req.user.id;
    const {
      weight,
      waterLiters,
      calories,
      exerciseMinutes,
      mood,
      tasks,
      habitTemplates,
      addWater,
      addCalories,
      addExercise,
    } = req.body;

    const { data: profile } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .maybeSingle();

    let aiProfile = profile?.ai_profile || {};
    const onboarding = profile?.onboarding_data || {};
    const logDate = resolveLogDate(req);
    let log = await getOrCreateTodayLog(
      supabase,
      userId,
      aiProfile,
      logDate,
      onboarding,
    );

    const patch = {
      updated_at: new Date().toISOString(),
    };

    if (weight !== undefined) {
      patch.weight = safeOptionalNum(weight, { min: 1, max: 500 });
    }
    if (waterLiters !== undefined) {
      patch.water_liters = safeNum(waterLiters, 0, { min: 0 });
    }
    if (calories !== undefined) {
      patch.calories = Math.round(safeNum(calories, 0, { min: 0 }));
    }
    if (exerciseMinutes !== undefined) {
      patch.exercise_minutes = Math.round(safeNum(exerciseMinutes, 0, { min: 0 }));
    }
    if (mood !== undefined) {
      patch.mood = mood && String(mood).trim() ? String(mood).trim() : null;
    }
    if (Array.isArray(tasks)) patch.tasks = tasks;

    if (Array.isArray(habitTemplates) && habitTemplates.length > 0) {
      aiProfile = {
        ...aiProfile,
        habit_templates: habitTemplates.map((id) => String(id)),
      };
      await supabase
        .from('profiles')
        .update({
          ai_profile: aiProfile,
          updated_at: new Date().toISOString(),
        })
        .eq('id', userId);
    }

    if (typeof addWater === 'number' && Number.isFinite(addWater)) {
      patch.water_liters = safeNum(log.water_liters, 0) + addWater;
    }
    if (typeof addCalories === 'number' && Number.isFinite(addCalories)) {
      patch.calories = Math.round(safeNum(log.calories, 0) + addCalories);
    }
    if (typeof addExercise === 'number' && Number.isFinite(addExercise)) {
      patch.exercise_minutes =
        Math.round(safeNum(log.exercise_minutes, 0) + addExercise);
    }

    const { data: updated, error } = await supabase
      .from('daily_logs')
      .update(patch)
      .eq('id', log.id)
      .select('*')
      .single();

    if (error) {
      return res.status(400).json({ message: error.message });
    }

    if (weight !== undefined) {
      const safeWeight = safeOptionalNum(weight, { min: 1, max: 500 });
      if (safeWeight != null) {
        await supabase
          .from('profiles')
          .update({ weight: safeWeight, updated_at: new Date().toISOString() })
          .eq('id', userId);
      }
    }

    const weeklyHistory = await getWeeklyHistory(supabase, userId, logDate);

    return res.json({
      ...buildHomePayload({
        profile: { ...profile, weight: weight ?? profile?.weight },
        log: updated,
        aiProfile,
      }),
      ai_enabled: hasAiKey(),
      weekly_history: weeklyHistory,
    });
  } catch (error) {
    return next(error);
  }
}

async function refreshAi(req, res, next) {
  try {
    const supabase = getSupabaseAdmin();
    const userId = req.user.id;

    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .maybeSingle();

    if (profileError) {
      return res.status(400).json({ message: profileError.message });
    }

    const aiProfile = profile?.ai_profile || {};
    const onboarding = profile?.onboarding_data || {};
    const logDate = resolveLogDate(req);
    let log = await getOrCreateTodayLog(
      supabase,
      userId,
      aiProfile,
      logDate,
      onboarding,
    );

    let brief;
    let insights;
    try {
      brief = await generateDailyBrief({
        profile,
        aiProfile,
        onboardingData: profile?.onboarding_data,
        today: log,
      });
      insights = await generateInsights({
        profile,
        aiProfile,
        onboardingData: profile?.onboarding_data,
        today: log,
      });
    } catch (aiError) {
      if (aiError.code === 'AI_KEY_MISSING') {
        brief = fallbackBrief(profile, aiProfile, log);
        insights = fallbackInsights(profile, aiProfile, log);
      } else {
        throw aiError;
      }
    }

    const { data: updated, error } = await supabase
      .from('daily_logs')
      .update({
        ai_brief: brief,
        ai_insights: insights,
        updated_at: new Date().toISOString(),
      })
      .eq('id', log.id)
      .select('*')
      .single();

    if (error) {
      return res.status(400).json({ message: error.message });
    }

    const weeklyHistory = await getWeeklyHistory(supabase, userId, logDate);

    return res.json({
      ...buildHomePayload({ profile, log: updated, aiProfile }),
      ai_enabled: hasAiKey(),
      weekly_history: weeklyHistory,
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  getToday,
  updateToday,
  refreshAi,
};
