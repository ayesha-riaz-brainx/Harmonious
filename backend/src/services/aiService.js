const OPENAI_URL = 'https://api.openai.com/v1/chat/completions';

function hasAiKey() {
  const key = (process.env.OPENAI_API_KEY || '').trim();
  return key.length > 0 && !key.includes('PASTE_YOUR_');
}

async function chatJson({ system, user, temperature = 0.7 }) {
  if (!hasAiKey()) {
    const error = new Error(
      'OPENAI_API_KEY missing. Add it to backend/.env to generate AI results.',
    );
    error.status = 503;
    error.code = 'AI_KEY_MISSING';
    throw error;
  }

  const model = process.env.OPENAI_MODEL || 'gpt-4o-mini';
  const apiKey = process.env.OPENAI_API_KEY.trim();
  const response = await fetch(OPENAI_URL, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model,
      temperature,
      response_format: { type: 'json_object' },
      messages: [
        { role: 'system', content: system },
        { role: 'user', content: user },
      ],
    }),
  });

  const body = await response.json();
  if (!response.ok) {
    const message =
      body?.error?.message || `OpenAI request failed (${response.status})`;
    const error = new Error(message);
    error.status = 502;
    throw error;
  }

  const content = body.choices?.[0]?.message?.content || '{}';
  try {
    return JSON.parse(content);
  } catch (_) {
    return { raw: content };
  }
}

function fallbackBrief(profile, aiProfile) {
  const water = aiProfile?.water_goal_liters || 2.5;
  const calories = aiProfile?.calorie_target || 1800;
  const sleep = aiProfile?.sleep_goal_hours || '8 Hours';
  const primary = aiProfile?.primary_goal || 'General Wellness';

  return {
    title: "Today's Focus",
    focus_items: [
      `Drink ${water}L Water`,
      'Walk 30 Minutes',
      `Stay under ${calories} Calories`,
      `Sleep goal: ${sleep}`,
    ],
    encouragement: "You're progressing well. Keep it up!",
    primary_goal: primary,
    source: 'fallback',
  };
}

function fallbackInsights(profile, aiProfile) {
  return [
    'You drink more water on workout days.',
    'Your mood improves after walking.',
    "You've stayed within your calorie goal recently.",
  ].map((text) => ({ text, source: 'fallback' }));
}

async function generateDailyBrief({ profile, aiProfile, onboardingData, today }) {
  try {
    const result = await chatJson({
      system:
        'You are Harmonious, a warm AI life companion. Return JSON only with keys: title (string), focus_items (array of 4 short actionable strings starting without checkmarks), encouragement (1-2 warm sentences), primary_goal (string). Keep language supportive and specific.',
      user: JSON.stringify({
        name: profile?.display_name || profile?.full_name || 'friend',
        ai_profile: aiProfile,
        onboarding: onboardingData,
        today,
      }),
    });

    return {
      title: result.title || "Today's Focus",
      focus_items: Array.isArray(result.focus_items)
        ? result.focus_items.slice(0, 5)
        : fallbackBrief(profile, aiProfile).focus_items,
      encouragement:
        result.encouragement ||
        fallbackBrief(profile, aiProfile).encouragement,
      primary_goal:
        result.primary_goal || aiProfile?.primary_goal || 'General Wellness',
      source: 'openai',
    };
  } catch (error) {
    if (error.code === 'AI_KEY_MISSING') throw error;
    console.error('AI brief failed, using fallback:', error.message);
    return fallbackBrief(profile, aiProfile);
  }
}

async function generateInsights({ profile, aiProfile, onboardingData, today }) {
  try {
    const result = await chatJson({
      system:
        'You are Harmonious. Return JSON only: { "insights": [string, string, string] }. Each insight is one short observational sentence about habits. No numbering.',
      user: JSON.stringify({
        name: profile?.display_name || profile?.full_name || 'friend',
        ai_profile: aiProfile,
        onboarding: onboardingData,
        today,
      }),
      temperature: 0.8,
    });

    const list = Array.isArray(result.insights) ? result.insights : [];
    if (list.length === 0) return fallbackInsights(profile, aiProfile);
    return list.slice(0, 4).map((text) => ({ text, source: 'openai' }));
  } catch (error) {
    if (error.code === 'AI_KEY_MISSING') throw error;
    console.error('AI insights failed, using fallback:', error.message);
    return fallbackInsights(profile, aiProfile);
  }
}

async function generateOnboardingSummary({ profile, draft, ruleBased }) {
  try {
    const result = await chatJson({
      system:
        'You are Harmonious. Create a personalized onboarding summary. Return JSON with: primary_goal, secondary_goals (array), calorie_target (int), water_goal_liters (number), sleep_goal_hours (string like "8 Hours"), workout_plan (string like "4 Days / Week"), focus_areas (array of short labels), message (warm 1-2 sentences).',
      user: JSON.stringify({ profile, draft, rule_based_seed: ruleBased }),
    });

    return {
      primary_goal: result.primary_goal || ruleBased.primaryGoal,
      secondary_goals: result.secondary_goals || ruleBased.secondaryGoals,
      calorie_target: result.calorie_target || ruleBased.calorieTarget,
      water_goal_liters: result.water_goal_liters || ruleBased.waterGoalLiters,
      sleep_goal_hours: result.sleep_goal_hours || ruleBased.sleepGoalHours,
      workout_plan: result.workout_plan || ruleBased.workoutPlan,
      focus_areas: result.focus_areas || ruleBased.focusAreas,
      message: result.message || ruleBased.message,
      source: 'openai',
    };
  } catch (error) {
    if (error.code === 'AI_KEY_MISSING') throw error;
    console.error('AI onboarding summary failed:', error.message);
    return {
      ...(ruleBased && typeof ruleBased === 'object' ? ruleBased : {}),
      source: 'fallback',
    };
  }
}

const coachPrompts = {
  'Nutrition Coach':
    'Focus on practical nutrition, balanced meals, allergies, budget, and sustainable eating. Never diagnose.',
  'Fitness Coach':
    'Focus on safe, progressive movement and workouts matched to ability. Avoid medical claims.',
  'Mental Wellness Coach':
    'You are an emotional wellness assistant. When the user feels stressed, anxious, overwhelmed, sad, or low: ' +
    '1) validate warmly, 2) offer a short concrete exercise (breathing 4-4-6, grounding, or 2-minute mindfulness), ' +
    '3) suggest one gentle relaxation activity, 4) ask one caring follow-up question about how they feel. ' +
    'Keep replies concise and actionable. Advise professional or emergency help when safety is at risk.',
  'Goal Coach':
    'Turn goals into small measurable next steps, check-ins, and realistic priorities.',
  'Habit Coach':
    'Focus on tiny habits, cues, environment design, consistency, and compassionate recovery after missed days.',
  'Life Coach':
    'Balance health, wellbeing, routines, goals, and productivity with a warm practical tone.',
};

async function generateCoachResponse({
  coach = 'Life Coach',
  message,
  history = [],
  profile,
  memory,
  settings,
  today = null,
}) {
  const personality = settings?.ai_personality || 'Supportive';
  const style = settings?.communication_style || 'Balanced';
  const result = await chatJson({
    system:
      `You are Harmonious's ${coach}. ${coachPrompts[coach] || coachPrompts['Life Coach']} ` +
      `Personality: ${personality}. Communication style: ${style}. ` +
      'Use today_progress when giving advice so replies match the user’s real water, calories, exercise, mood, and tasks. ' +
      'Return JSON only: {"reply":"concise helpful response","memories":[{"key":"habit_or_preference_or_goal_short_key","value":"useful durable user fact","category":"habit|preference|goal"}]}. ' +
      'Use key prefixes habit_, preference_, or goal_ when possible. Memories must only include durable preferences, goals, constraints, or recurring habits explicitly stated by the user. Never store sensitive medical details unless clearly needed and supplied. If privacy_mode is Strict, return an empty memories array.',
    user: JSON.stringify({
      message,
      recent_conversation: history.slice(-10),
      user_profile: profile,
      remembered_context: memory,
      today_progress: today,
      privacy_mode: settings?.privacy_mode || 'Standard',
    }),
  });

  return {
    reply:
      result.reply ||
      'I’m here with you. Tell me a little more so I can help with a useful next step.',
    memories: Array.isArray(result.memories) ? result.memories.slice(0, 4) : [],
  };
}

async function generateToolResult({ tool, input, profile, logs = [], captures = [] }) {
  const toolInstructions = {
    water_intake:
      'Analyze the user’s water intake from daily_logs. Treat 0.25L as 1 glass. Cover: glasses drunk today vs goal (usually ~8 glasses / water_goal_liters), whether they are drinking enough, patterns across recent days, and 2-4 personalized reminders/recommendations. Speak in glasses and liters. Be specific with numbers from the data when available.',
    emotional_support:
      'Act as an emotional wellness assistant. Validate feelings first. Choose ONE matching practice — never default everything to breathing. ' +
      'If the user asks for grounding or 5-4-3-2-1, walk through the five senses only and set exercise to "grounding" (do not recommend or switch to breathing). ' +
      'If they ask for a quiet pause or stillness, set exercise to "pause". ' +
      'Only set exercise to "breathing" when they ask for breathwork OR when acute stress/anxiety is the main issue and breathing is clearly the best fit. ' +
      'Otherwise set exercise to "none" and still give warm support + 2-3 gentle actions. ' +
      'End with one caring follow-up question. If self-harm or immediate danger appears, encourage local emergency/crisis support.',
    health_journey:
      'Write a long-term health journey analysis — not a daily dashboard. Focus on life-story patterns: discoveries (habits you notice over weeks), a warm coach-style reflection paragraph comparing early days vs now, and one predicted next milestone with progress. Use real numbers from daily_logs and captures. Never invent values. Avoid listing raw stats as the main message.',
    diet_plan:
      'Create a simple 7-day diet plan matching the profile, preferences, constraints, and budget.',
    workout_plan:
      'Create a safe, beginner-aware weekly workout plan matching goals, schedule, equipment, and ability. Prefer bodyweight if equipment is unclear. Include rest days when helpful.',
    progress_review:
      'Review progress data, celebrate wins, identify one pattern, and suggest three next actions.',
  };
  const instruction =
    toolInstructions[tool] || 'Help with the requested wellbeing task.';
  const workoutPlanShape =
    tool === 'workout_plan'
      ? ',"plan":{"days":[{"day":"Monday","focus":"Full body","notes":"optional","exercises":[{"name":"Squats","sets":"3x10","notes":"slow tempo"}]}]}'
      : '';
  const journeyShape =
    tool === 'health_journey'
      ? ',"journey":{"discoveries":["pattern insight with evidence"],"reflection":"2-4 sentence coach letter comparing started vs now","next_milestone":{"title":"Lose 2kg","expected_days":14,"progress":78,"encouragement":"Keep going."},"highlights":["win 1"],"habits":["habit insight"],"focus":["gentle next step"]}'
      : '';
  const system =
    `${instruction} Return JSON only: {"title":"short title","summary":"clear response","actions":["action 1","action 2","action 3"],"exercise":"breathing|grounding|pause|none"${workoutPlanShape}${journeyShape}}. ` +
    'For emotional_support, exercise must match the practice you actually gave — never set breathing when the user requested grounding or pause. ' +
    (tool === 'workout_plan'
      ? 'For workout_plan, always include plan.days with 3–7 days. Each day needs day, focus, and 3–6 exercises with name and sets. '
      : '') +
    (tool === 'health_journey'
      ? 'For health_journey, always include journey.discoveries (3-5 specific patterns like "you usually exercise after work"), journey.reflection (coach voice), journey.next_milestone (title, expected_days, progress 0-100, encouragement), plus optional highlights/habits/focus. '
      : '');

  let result;
  if (input?.image_base64) {
    if (!hasAiKey()) {
      const error = new Error('OPENAI_API_KEY missing.');
      error.status = 503;
      throw error;
    }
    const response = await fetch(OPENAI_URL, {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${process.env.OPENAI_API_KEY.trim()}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: process.env.OPENAI_MODEL || 'gpt-4o-mini',
        temperature: 0.4,
        response_format: { type: 'json_object' },
        messages: [
          { role: 'system', content: system },
          {
            role: 'user',
            content: [
              {
                type: 'text',
                text: JSON.stringify({
                  note: input.note || '',
                  profile,
                }),
              },
              {
                type: 'image_url',
                image_url: {
                  url: `data:${input.mime_type || 'image/jpeg'};base64,${input.image_base64}`,
                },
              },
            ],
          },
        ],
      }),
    });
    const body = await response.json();
    if (!response.ok) {
      const error = new Error(
        body?.error?.message || 'Image analysis failed.',
      );
      error.status = 502;
      throw error;
    }
    result = JSON.parse(body.choices?.[0]?.message?.content || '{}');
  } else {
    result = await chatJson({
      system,
      user: JSON.stringify({
        input,
        profile,
        daily_logs: logs,
        recent_captures: captures,
        water_goal_liters: profile?.ai_profile?.water_goal_liters || 2.5,
      }),
      temperature: tool === 'emotional_support' ? 0.7 : 0.55,
    });
  }
  const plan = result.plan && typeof result.plan === 'object' ? result.plan : null;
  const days = Array.isArray(plan?.days)
    ? plan.days.slice(0, 7).map((day) => ({
        day: day?.day || 'Day',
        focus: day?.focus || '',
        notes: day?.notes || '',
        exercises: Array.isArray(day?.exercises)
          ? day.exercises.slice(0, 8).map((ex) => ({
              name: ex?.name || 'Exercise',
              sets: ex?.sets || '',
              notes: ex?.notes || '',
            }))
          : [],
      }))
    : [];

  const journeyRaw =
    result.journey && typeof result.journey === 'object' ? result.journey : null;
  const nextRaw =
    journeyRaw?.next_milestone && typeof journeyRaw.next_milestone === 'object'
      ? journeyRaw.next_milestone
      : null;
  const journey = journeyRaw
    ? {
        discoveries: Array.isArray(journeyRaw.discoveries)
          ? journeyRaw.discoveries.map(String).slice(0, 6)
          : Array.isArray(journeyRaw.habits)
            ? journeyRaw.habits.map(String).slice(0, 6)
            : [],
        reflection:
          typeof journeyRaw.reflection === 'string' && journeyRaw.reflection.trim()
            ? journeyRaw.reflection.trim()
            : typeof result.summary === 'string'
              ? result.summary
              : '',
        next_milestone: nextRaw
          ? {
              title: String(nextRaw.title || 'Next milestone'),
              expected_days: Math.max(
                1,
                Math.min(90, Number(nextRaw.expected_days) || 14),
              ),
              progress: Math.max(
                0,
                Math.min(100, Math.round(Number(nextRaw.progress) || 0)),
              ),
              encouragement: String(nextRaw.encouragement || 'Keep going.'),
            }
          : null,
        highlights: Array.isArray(journeyRaw.highlights)
          ? journeyRaw.highlights.map(String).slice(0, 5)
          : [],
        trends: Array.isArray(journeyRaw.trends)
          ? journeyRaw.trends.slice(0, 6).map((t) => ({
              label: t?.label || 'Trend',
              detail: t?.detail || '',
              direction: ['up', 'down', 'steady'].includes(
                String(t?.direction || '').toLowerCase(),
              )
                ? String(t.direction).toLowerCase()
                : 'steady',
            }))
          : [],
        habits: Array.isArray(journeyRaw.habits)
          ? journeyRaw.habits.map(String).slice(0, 5)
          : [],
        focus: Array.isArray(journeyRaw.focus)
          ? journeyRaw.focus.map(String).slice(0, 5)
          : [],
      }
    : null;

  let exercise = String(result.exercise || 'none').toLowerCase();
  if (!['breathing', 'grounding', 'pause', 'none'].includes(exercise)) {
    exercise = 'none';
  }

  return {
    title: result.title || 'AI Result',
    summary: result.summary || result.raw || 'Analysis completed.',
    actions: Array.isArray(result.actions) ? result.actions.slice(0, 5) : [],
    exercise,
    plan: days.length ? { days } : plan,
    journey,
  };
}

async function generateProgressReport({ period, profile, captures, logs }) {
  const result = await chatJson({
    system:
      `Create a ${period} wellbeing progress report. Return JSON only: ` +
      '{"title":"report title","highlights":["..."],"summary":"2-3 sentences","next_steps":["..."]}. ' +
      'Use only supplied data; clearly avoid inventing progress.',
    user: JSON.stringify({ profile, captures, daily_logs: logs }),
    temperature: 0.5,
  });
  return {
    title: result.title || `Your ${period} Progress`,
    highlights: Array.isArray(result.highlights) ? result.highlights : [],
    summary: result.summary || 'Keep logging to unlock richer trends.',
    next_steps: Array.isArray(result.next_steps) ? result.next_steps : [],
  };
}

async function transcribeAudio({
  audioBase64,
  mimeType = 'audio/mp4',
  fileName = 'voice.m4a',
}) {
  if (!hasAiKey()) {
    const error = new Error(
      'OPENAI_API_KEY missing. Add it to backend/.env for voice transcription.',
    );
    error.status = 503;
    error.code = 'AI_KEY_MISSING';
    throw error;
  }
  if (!audioBase64 || typeof audioBase64 !== 'string') {
    const error = new Error('audio_base64 is required.');
    error.status = 400;
    throw error;
  }

  const buffer = Buffer.from(audioBase64, 'base64');
  if (buffer.length < 64) {
    const error = new Error('Audio clip is too short. Hold the mic a bit longer.');
    error.status = 400;
    throw error;
  }
  if (buffer.length > 12 * 1024 * 1024) {
    const error = new Error('Audio is too large. Try a shorter clip.');
    error.status = 400;
    throw error;
  }

  const form = new FormData();
  form.append(
    'file',
    new Blob([buffer], { type: mimeType || 'audio/mp4' }),
    fileName || 'voice.m4a',
  );
  form.append('model', process.env.OPENAI_TRANSCRIBE_MODEL || 'whisper-1');
  form.append('language', 'en');

  const response = await fetch(
    'https://api.openai.com/v1/audio/transcriptions',
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${process.env.OPENAI_API_KEY.trim()}`,
      },
      body: form,
    },
  );

  const body = await response.json().catch(() => ({}));
  if (!response.ok) {
    const error = new Error(
      body?.error?.message || `Transcription failed (${response.status})`,
    );
    error.status = 502;
    throw error;
  }

  return {
    text: String(body.text || '').trim(),
  };
}

module.exports = {
  hasAiKey,
  generateDailyBrief,
  generateInsights,
  generateOnboardingSummary,
  generateCoachResponse,
  generateToolResult,
  generateProgressReport,
  transcribeAudio,
  fallbackBrief,
  fallbackInsights,
};
