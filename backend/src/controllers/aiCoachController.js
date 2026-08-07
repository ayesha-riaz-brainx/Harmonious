const { getSupabaseAdmin } = require('../config/supabase');
const {
  generateCoachResponse,
  generateToolResult,
  hasAiKey,
  transcribeAudio,
} = require('../services/aiService');

async function getContext(req, res, next) {
  try {
    const supabase = getSupabaseAdmin();
    const [profileResult, messagesResult] = await Promise.all([
      supabase.from('profiles').select('*').eq('id', req.user.id).maybeSingle(),
      supabase
        .from('ai_messages')
        .select('id,role,coach,content,created_at')
        .eq('user_id', req.user.id)
        .order('created_at', { ascending: true })
        .limit(50),
    ]);

    if (profileResult.error) throw profileResult.error;
    if (messagesResult.error) throw messagesResult.error;

    const profile = profileResult.data || {};
    return res.json({
      messages: messagesResult.data || [],
      memory: profile.ai_memory || {},
      settings: profile.app_settings || {},
      ai_enabled: hasAiKey(),
    });
  } catch (error) {
    return next(error);
  }
}

async function chat(req, res, next) {
  try {
    const {
      message,
      coach = 'Life Coach',
      history = [],
      persist = true,
    } = req.body || {};
    if (!message || typeof message !== 'string' || !message.trim()) {
      return res.status(400).json({ message: 'Message is required.' });
    }

    const supabase = getSupabaseAdmin();
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', req.user.id)
      .maybeSingle();
    if (profileError) throw profileError;

    let conversation = Array.isArray(history) ? history.slice(-12) : [];
    if (persist !== false) {
      const { data: historyData, error: historyError } = await supabase
        .from('ai_messages')
        .select('role,coach,content,created_at')
        .eq('user_id', req.user.id)
        .order('created_at', { ascending: false })
        .limit(12);
      if (historyError) throw historyError;
      conversation = (historyData || []).reverse();

      await supabase.from('ai_messages').insert({
        user_id: req.user.id,
        role: 'user',
        coach,
        content: message.trim(),
      });
    }

    const date = new Date().toISOString().slice(0, 10);
    const [{ data: todayLog }, { data: recentCaptures }] = await Promise.all([
      supabase
        .from('daily_logs')
        .select(
          'log_date,weight,water_liters,calories,exercise_minutes,mood,sleep_hours,tasks',
        )
        .eq('user_id', req.user.id)
        .eq('log_date', date)
        .maybeSingle(),
      supabase
        .from('captures')
        .select('type,payload,captured_at')
        .eq('user_id', req.user.id)
        .order('captured_at', { ascending: false })
        .limit(8),
    ]);

    const result = await generateCoachResponse({
      coach,
      message: message.trim(),
      history: conversation,
      profile: {
        display_name: profile?.display_name,
        age: profile?.age,
        goals: profile?.onboarding_data?.goals,
        ai_profile: profile?.ai_profile,
        health_info: profile?.health_info,
      },
      memory: persist === false ? {} : profile?.ai_memory || {},
      settings: profile?.app_settings || {},
      today: {
        log: todayLog || null,
        recent_captures: recentCaptures || [],
        water_goal_liters: profile?.ai_profile?.water_goal_liters || 2.5,
        calorie_target: profile?.ai_profile?.calorie_target || 1800,
      },
    });

    let assistantMessage = {
      role: 'assistant',
      coach,
      content: result.reply,
      created_at: new Date().toISOString(),
    };

    if (persist !== false) {
      const { data, error: insertError } = await supabase
        .from('ai_messages')
        .insert({
          user_id: req.user.id,
          role: 'assistant',
          coach,
          content: result.reply,
        })
        .select('id,role,coach,content,created_at')
        .single();
      if (insertError) throw insertError;
      assistantMessage = data;

      const memoryEnabled =
        profile?.app_settings?.memory_enabled !== false &&
        profile?.app_settings?.privacy_mode != 'Strict';
      let memory = profile?.ai_memory || {};
      if (memoryEnabled && result.memories.length > 0) {
        memory = { ...memory };
        for (const item of result.memories) {
          if (!item?.key || !item?.value) continue;
          let key = String(item.key);
          const category = String(item.category || '').toLowerCase();
          if (
            !key.startsWith('habit_') &&
            !key.startsWith('preference_') &&
            !key.startsWith('goal_')
          ) {
            if (category === 'habit') key = `habit_${key}`;
            else if (category === 'goal') key = `goal_${key}`;
            else key = `preference_${key}`;
          }
          memory[key] = item.value;
        }
        await supabase
          .from('profiles')
          .update({ ai_memory: memory, updated_at: new Date().toISOString() })
          .eq('id', req.user.id);
      }
      return res.json({ message: assistantMessage, memory });
    }

    return res.json({ message: assistantMessage, memory: {} });
  } catch (error) {
    return next(error);
  }
}

async function runTool(req, res, next) {
  try {
    const { tool, input = {} } = req.body || {};
    if (!tool) return res.status(400).json({ message: 'Tool is required.' });

    const supabase = getSupabaseAdmin();
    const since = new Date();
    since.setUTCDate(since.getUTCDate() - 30);

    const [profileResult, logsResult, capturesResult] = await Promise.all([
      supabase.from('profiles').select('*').eq('id', req.user.id).maybeSingle(),
      supabase
        .from('daily_logs')
        .select(
          'log_date,weight,water_liters,calories,exercise_minutes,mood,sleep_hours,tasks',
        )
        .eq('user_id', req.user.id)
        .gte('log_date', since.toISOString().slice(0, 10))
        .order('log_date', { ascending: true }),
      supabase
        .from('captures')
        .select('type,payload,captured_at')
        .eq('user_id', req.user.id)
        .gte('captured_at', since.toISOString())
        .order('captured_at', { ascending: false })
        .limit(40),
    ]);
    if (profileResult.error) throw profileResult.error;
    if (logsResult.error) throw logsResult.error;
    if (capturesResult.error) throw capturesResult.error;

    const profile = profileResult.data;
    const result = await generateToolResult({
      tool,
      input,
      profile: {
        age: profile?.age,
        height: profile?.height,
        weight: profile?.weight,
        goals: profile?.onboarding_data?.goals,
        food_preferences: profile?.onboarding_data?.diet_type,
        ai_profile: profile?.ai_profile,
      },
      logs: logsResult.data || [],
      captures: capturesResult.data || [],
    });

    await supabase.from('captures').insert({
      user_id: req.user.id,
      type: 'ai_tool',
      payload: { tool, input, result },
    });

    return res.json({ result });
  } catch (error) {
    return next(error);
  }
}

async function clearMemory(req, res, next) {
  try {
    const supabase = getSupabaseAdmin();
    const { error } = await supabase
      .from('profiles')
      .update({ ai_memory: {}, updated_at: new Date().toISOString() })
      .eq('id', req.user.id);
    if (error) throw error;
    return res.json({ message: 'AI memory cleared.', memory: {} });
  } catch (error) {
    return next(error);
  }
}

async function transcribe(req, res, next) {
  try {
    const {
      audio_base64: audioBase64,
      mime_type: mimeType,
      file_name: fileName,
    } = req.body || {};
    const result = await transcribeAudio({
      audioBase64,
      mimeType,
      fileName,
    });
    if (!result.text) {
      return res.status(422).json({
        message: 'Could not understand that clip. Try again a bit louder.',
      });
    }
    return res.json({ text: result.text });
  } catch (error) {
    return next(error);
  }
}

module.exports = { getContext, chat, runTool, clearMemory, transcribe };
