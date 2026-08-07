const {
  generateDailyBrief,
  generateInsights,
  hasAiKey,
  fallbackBrief,
  fallbackInsights,
} = require('../services/aiService');
const {
  defaultTasks,
  todayUtcDate,
  buildHomePayload,
} = require('../services/homeService');
const { getSupabaseAdmin } = require('../config/supabase');

async function getOrCreateTodayLog(supabase, userId, aiProfile) {
  const date = todayUtcDate();
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
    tasks: defaultTasks(aiProfile),
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

async function getWeeklyHistory(supabase, userId) {
  const start = new Date();
  start.setUTCDate(start.getUTCDate() - 6);

  const { data, error } = await supabase
    .from('daily_logs')
    .select(
      'log_date,weight,water_liters,calories,exercise_minutes,mood,sleep_hours,tasks',
    )
    .eq('user_id', userId)
    .gte('log_date', start.toISOString().slice(0, 10))
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
    let log = await getOrCreateTodayLog(supabase, userId, aiProfile);

    const briefEmpty =
      !log.ai_brief ||
      Object.keys(log.ai_brief).length === 0 ||
      !Array.isArray(log.ai_brief.focus_items);

    if (briefEmpty) {
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
          brief = fallbackBrief(profile, aiProfile);
          insights = fallbackInsights(profile, aiProfile);
        } else {
          throw aiError;
        }
      }

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

    const weeklyHistory = await getWeeklyHistory(supabase, userId);

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
      addWater,
      addCalories,
      addExercise,
    } = req.body;

    const { data: profile } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .maybeSingle();

    const aiProfile = profile?.ai_profile || {};
    let log = await getOrCreateTodayLog(supabase, userId, aiProfile);

    const patch = {
      updated_at: new Date().toISOString(),
    };

    if (weight !== undefined) patch.weight = weight;
    if (waterLiters !== undefined) patch.water_liters = waterLiters;
    if (calories !== undefined) patch.calories = calories;
    if (exerciseMinutes !== undefined) patch.exercise_minutes = exerciseMinutes;
    if (mood !== undefined) patch.mood = mood;
    if (Array.isArray(tasks)) patch.tasks = tasks;

    if (typeof addWater === 'number') {
      patch.water_liters = Number(log.water_liters || 0) + addWater;
    }
    if (typeof addCalories === 'number') {
      patch.calories = Number(log.calories || 0) + addCalories;
    }
    if (typeof addExercise === 'number') {
      patch.exercise_minutes =
        Number(log.exercise_minutes || 0) + addExercise;
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
      await supabase
        .from('profiles')
        .update({ weight, updated_at: new Date().toISOString() })
        .eq('id', userId);
    }

    const weeklyHistory = await getWeeklyHistory(supabase, userId);

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
    let log = await getOrCreateTodayLog(supabase, userId, aiProfile);

    const brief = await generateDailyBrief({
      profile,
      aiProfile,
      onboardingData: profile?.onboarding_data,
      today: log,
    });
    const insights = await generateInsights({
      profile,
      aiProfile,
      onboardingData: profile?.onboarding_data,
      today: log,
    });

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

    const weeklyHistory = await getWeeklyHistory(supabase, userId);

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
