const { getSupabaseAdmin } = require('../config/supabase');
const { generateProgressReport } = require('../services/aiService');
const { buildJourneyStory } = require('../services/journeyStoryService');

async function getJourney(req, res, next) {
  try {
    const supabase = getSupabaseAdmin();
    const since = new Date();
    since.setUTCDate(since.getUTCDate() - 365);

    const [profileResult, capturesResult, logsResult] = await Promise.all([
      supabase.from('profiles').select('*').eq('id', req.user.id).maybeSingle(),
      supabase
        .from('captures')
        .select('*')
        .eq('user_id', req.user.id)
        .order('captured_at', { ascending: false })
        .limit(150),
      supabase
        .from('daily_logs')
        .select(
          'log_date,weight,water_liters,calories,exercise_minutes,mood,sleep_hours,tasks',
        )
        .eq('user_id', req.user.id)
        .gte('log_date', since.toISOString().slice(0, 10))
        .order('log_date', { ascending: true }),
    ]);
    if (profileResult.error) throw profileResult.error;
    if (capturesResult.error) throw capturesResult.error;
    if (logsResult.error) throw logsResult.error;

    const profile = profileResult.data;
    const captures = capturesResult.data || [];
    const trends = logsResult.data || [];
    const story = buildJourneyStory({ profile, captures, logs: trends });

    return res.json({
      profile,
      timeline: story.timeline,
      trends,
      story: story.story,
      milestones: story.milestones,
      before_vs_now: story.before_vs_now,
      memories: story.memories,
      next_milestone: story.next_milestone,
      stats: story.stats,
    });
  } catch (error) {
    return next(error);
  }
}

async function createReview(req, res, next) {
  try {
    const period = ['Weekly', 'Monthly', 'Yearly'].includes(req.body?.period)
      ? req.body.period
      : 'Weekly';
    const days = period === 'Yearly' ? 365 : period === 'Monthly' ? 31 : 7;
    const since = new Date();
    since.setUTCDate(since.getUTCDate() - days);

    const supabase = getSupabaseAdmin();
    const [profileResult, capturesResult, logsResult] = await Promise.all([
      supabase.from('profiles').select('*').eq('id', req.user.id).maybeSingle(),
      supabase
        .from('captures')
        .select('type,payload,captured_at')
        .eq('user_id', req.user.id)
        .gte('captured_at', since.toISOString())
        .order('captured_at', { ascending: true }),
      supabase
        .from('daily_logs')
        .select(
          'log_date,weight,water_liters,calories,exercise_minutes,mood,sleep_hours,tasks',
        )
        .eq('user_id', req.user.id)
        .gte('log_date', since.toISOString().slice(0, 10))
        .order('log_date', { ascending: true }),
    ]);
    if (profileResult.error) throw profileResult.error;
    if (capturesResult.error) throw capturesResult.error;
    if (logsResult.error) throw logsResult.error;

    const report = await generateProgressReport({
      period,
      profile: profileResult.data,
      captures: capturesResult.data,
      logs: logsResult.data,
    });

    await supabase.from('captures').insert({
      user_id: req.user.id,
      type: 'ai_report',
      payload: { period, report },
    });

    return res.json({ report });
  } catch (error) {
    return next(error);
  }
}

module.exports = { getJourney, createReview };
