const { getSupabaseAdmin } = require('../config/supabase');

async function getSettings(req, res, next) {
  try {
    const supabase = getSupabaseAdmin();
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', req.user.id)
      .maybeSingle();
    if (error) throw error;
    return res.json({
      profile: data,
      settings: data?.app_settings || {},
      health_info: data?.health_info || {},
      goals: data?.onboarding_data?.goals || [],
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

    if (body.profile) {
      const profile = body.profile;
      if (profile.display_name !== undefined) {
        patch.display_name = profile.display_name;
        patch.full_name = profile.display_name;
      }
      for (const key of ['age', 'height', 'weight', 'country']) {
        if (profile[key] !== undefined) patch[key] = profile[key];
      }
    }
    if (body.goals) {
      patch.onboarding_data = {
        ...(existing?.onboarding_data || {}),
        goals: body.goals,
      };
    }
    if (body.health_info) {
      patch.health_info = {
        ...(existing?.health_info || {}),
        ...body.health_info,
      };
    }
    if (body.settings) {
      patch.app_settings = {
        ...(existing?.app_settings || {}),
        ...body.settings,
      };
    }

    const { data, error } = await supabase
      .from('profiles')
      .update(patch)
      .eq('id', req.user.id)
      .select('*')
      .single();
    if (error) throw error;

    return res.json({
      message: 'Settings saved.',
      profile: data,
      settings: data.app_settings || {},
      health_info: data.health_info || {},
      goals: data.onboarding_data?.goals || [],
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
      profile: profile.data,
      captures: captures.data || [],
      ai_messages: messages.data || [],
      daily_logs: logs.data || [],
    });
  } catch (error) {
    return next(error);
  }
}

module.exports = { getSettings, updateSettings, exportData };
