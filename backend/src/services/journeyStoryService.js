const MOOD_RANK = {
  terrible: 1,
  awful: 1,
  sad: 2,
  low: 2,
  meh: 3,
  okay: 3,
  ok: 3,
  neutral: 3,
  fine: 4,
  good: 4,
  happy: 5,
  great: 5,
  amazing: 6,
  excellent: 6,
};

function num(v) {
  const n = Number(v);
  return Number.isFinite(n) ? n : null;
}

function dayKey(value) {
  if (!value) return null;
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) {
    const s = String(value);
    return s.length >= 10 ? s.slice(0, 10) : null;
  }
  return d.toISOString().slice(0, 10);
}

function moodScore(mood) {
  if (!mood) return null;
  const key = String(mood).trim().toLowerCase();
  if (MOOD_RANK[key] != null) return MOOD_RANK[key];
  if (key.includes('amaz') || key.includes('great') || key.includes('excel')) return 6;
  if (key.includes('happ') || key.includes('good')) return 5;
  if (key.includes('fine') || key.includes('ok')) return 4;
  if (key.includes('meh') || key.includes('neutr')) return 3;
  if (key.includes('sad') || key.includes('low')) return 2;
  if (key.includes('terr') || key.includes('awful')) return 1;
  return 3;
}

function moodLabel(mood) {
  if (!mood) return '—';
  const score = moodScore(mood);
  if (score == null) return String(mood);
  if (score >= 5) return 'Good';
  if (score >= 4) return 'Okay';
  if (score >= 3) return 'Neutral';
  if (score >= 2) return 'Low';
  return 'Hard day';
}

function eventMeta(type, payload = {}) {
  switch (type) {
    case 'water': {
      const ml =
        num(payload.ml) ??
        (num(payload.liters) != null ? Math.round(num(payload.liters) * 1000) : null);
      return {
        icon: 'water',
        title: 'Water logged',
        detail: ml != null ? `${ml} ml` : 'Hydration',
      };
    }
    case 'meal':
      return {
        icon: 'meal',
        title: payload.name ? String(payload.name) : 'Meal logged',
        detail:
          num(payload.calories) != null
            ? `${Math.round(num(payload.calories))} kcal`
            : 'Meal',
      };
    case 'workout':
      return {
        icon: 'workout',
        title: payload.activity ? String(payload.activity) : 'Workout completed',
        detail:
          num(payload.minutes) != null
            ? `${Math.round(num(payload.minutes))} min`
            : 'Movement',
      };
    case 'mood':
      return {
        icon: 'mood',
        title: 'Mood check-in',
        detail: payload.mood ? String(payload.mood) : 'Logged mood',
      };
    case 'sleep':
      return {
        icon: 'sleep',
        title: 'Sleep logged',
        detail:
          num(payload.hours) != null
            ? `${num(payload.hours).toFixed(1)} h`
            : 'Rest',
      };
    case 'weight':
      return {
        icon: 'weight',
        title: 'Weight logged',
        detail:
          num(payload.weight) != null
            ? `${num(payload.weight).toFixed(1)} kg`
            : 'Weight',
      };
    case 'journal':
      return {
        icon: 'journal',
        title: 'Journal added',
        detail: payload.text ? String(payload.text).slice(0, 120) : 'Reflection',
      };
    case 'health_report':
      return {
        icon: 'report',
        title: 'Health report uploaded',
        detail: payload.name ? String(payload.name) : 'Report saved',
      };
    case 'ai_report':
      return {
        icon: 'ai',
        title: 'AI progress report',
        detail: payload.period ? `${payload.period} review` : 'AI reflection',
      };
    case 'diet_plan':
      return {
        icon: 'meal',
        title: 'AI meal plan',
        detail: 'Personalized nutrition plan',
      };
    case 'workout_plan':
      return {
        icon: 'workout',
        title: 'AI workout plan',
        detail: 'Personalized training plan',
      };
    default:
      return {
        icon: 'event',
        title: String(type || 'Event').replace(/_/g, ' '),
        detail: 'Logged event',
      };
  }
}

function consecutiveLoggingDays(logs) {
  const days = [
    ...new Set(logs.map((l) => dayKey(l.log_date)).filter(Boolean)),
  ].sort();
  if (!days.length) return 0;
  let best = 1;
  let cur = 1;
  for (let i = 1; i < days.length; i += 1) {
    const prev = new Date(`${days[i - 1]}T00:00:00Z`);
    const next = new Date(`${days[i]}T00:00:00Z`);
    const diff = (next - prev) / 86400000;
    if (diff === 1) {
      cur += 1;
      best = Math.max(best, cur);
    } else {
      cur = 1;
    }
  }
  return best;
}

function currentStreak(logs) {
  const days = new Set(logs.map((l) => dayKey(l.log_date)).filter(Boolean));
  if (!days.size) return 0;
  let streak = 0;
  const cursor = new Date();
  for (;;) {
    const key = cursor.toISOString().slice(0, 10);
    if (!days.has(key)) break;
    streak += 1;
    cursor.setUTCDate(cursor.getUTCDate() - 1);
  }
  return streak;
}

function firstCapture(captures, type) {
  const matches = captures
    .filter((c) => c.type === type)
    .map((c) => ({ ...c, _t: new Date(c.captured_at).getTime() }))
    .filter((c) => Number.isFinite(c._t))
    .sort((a, b) => a._t - b._t);
  return matches[0] || null;
}

function avgField(rows, key) {
  const vals = rows.map((r) => num(r[key])).filter((v) => v != null);
  if (!vals.length) return null;
  return vals.reduce((a, b) => a + b, 0) / vals.length;
}

function buildStoryMilestones({ profile, captures, logs, waterGoal }) {
  const story = [];
  const startedAt =
    profile?.created_at ||
    logs[0]?.log_date ||
    captures[captures.length - 1]?.captured_at;
  if (startedAt) {
    story.push({
      id: 'started',
      title: 'Started your journey',
      at: startedAt,
      unlocked: true,
    });
  }

  const waterGoalHit = logs.find(
    (l) => num(l.water_liters) != null && num(l.water_liters) >= waterGoal,
  );
  if (waterGoalHit) {
    story.push({
      id: 'first_water_goal',
      title: 'First water goal completed',
      at: waterGoalHit.log_date,
      unlocked: true,
    });
  }

  const firstWorkout =
    firstCapture(captures, 'workout') ||
    logs.find((l) => (num(l.exercise_minutes) || 0) > 0);
  if (firstWorkout) {
    story.push({
      id: 'first_workout',
      title: 'First workout completed',
      at: firstWorkout.captured_at || firstWorkout.log_date,
      unlocked: true,
    });
  }

  if (logs.length >= 7) {
    const early = logs.slice(0, Math.min(7, logs.length));
    const late = logs.slice(Math.max(0, logs.length - 7));
    const earlyMood = avgField(
      early.map((l) => ({ mood: moodScore(l.mood) })),
      'mood',
    );
    const lateMood = avgField(
      late.map((l) => ({ mood: moodScore(l.mood) })),
      'mood',
    );
    if (earlyMood != null && lateMood != null && lateMood > earlyMood + 0.3) {
      story.push({
        id: 'mood_week',
        title: 'First week with improved mood',
        at: late[late.length - 1]?.log_date,
        unlocked: true,
      });
    }
  }

  const weights = logs
    .map((l) => ({ at: l.log_date, w: num(l.weight) }))
    .filter((x) => x.w != null);
  if (weights.length >= 2) {
    const startW = weights[0].w;
    const drop = weights.find((x) => startW - x.w >= 2);
    if (drop) {
      story.push({
        id: 'lost_2kg',
        title: 'Lost first 2kg',
        at: drop.at,
        unlocked: true,
      });
    }
  }

  const bestStreak = consecutiveLoggingDays(logs);
  if (bestStreak >= 30) {
    const at = logs[Math.min(logs.length - 1, 29)]?.log_date;
    story.push({
      id: 'streak_30',
      title: '30-day streak',
      at,
      unlocked: true,
    });
  }

  return story;
}

function buildMilestones({ captures, logs }) {
  const meals = captures.filter((c) => c.type === 'meal').length;
  const workouts = captures.filter((c) => c.type === 'workout').length;
  const waterL = logs.reduce((sum, l) => sum + (num(l.water_liters) || 0), 0);
  const bestStreak = consecutiveLoggingDays(logs);
  const weights = logs.map((l) => num(l.weight)).filter((v) => v != null);
  const lostKg =
    weights.length >= 2 ? Math.max(0, weights[0] - weights[weights.length - 1]) : 0;
  const activeDays = new Set(logs.map((l) => dayKey(l.log_date)).filter(Boolean))
    .size;

  const defs = [
    {
      id: 'streak_7',
      title: 'First 7-Day Streak',
      target: 7,
      current: bestStreak,
      unit: 'days',
    },
    {
      id: 'lost_5kg',
      title: 'Lost 5kg',
      target: 5,
      current: Number(lostKg.toFixed(1)),
      unit: 'kg',
    },
    {
      id: 'meals_100',
      title: '100 Meals Logged',
      target: 100,
      current: meals,
      unit: 'meals',
    },
    {
      id: 'workouts_50',
      title: 'Completed 50 Workouts',
      target: 50,
      current: workouts,
      unit: 'workouts',
    },
    {
      id: 'water_100l',
      title: '100L Water',
      target: 100,
      current: Number(waterL.toFixed(1)),
      unit: 'L',
    },
    {
      id: 'month_1',
      title: 'First Month Completed',
      target: 30,
      current: activeDays,
      unit: 'days',
    },
  ];

  return defs.map((d) => {
    const progress = Math.min(1, d.current / d.target);
    return {
      ...d,
      progress: Math.round(progress * 100),
      unlocked: progress >= 1,
    };
  });
}

function buildBeforeVsNow({ profile, logs }) {
  const comparisons = [];
  const weights = logs
    .map((l) => ({ at: l.log_date, w: num(l.weight) }))
    .filter((x) => x.w != null);
  const startWeight = weights[0]?.w ?? num(profile?.weight);
  const nowWeight =
    (weights.length ? weights[weights.length - 1].w : null) ??
    num(profile?.weight);
  if (startWeight != null && nowWeight != null) {
    comparisons.push({
      id: 'weight',
      label: 'Weight',
      started: `${startWeight.toFixed(1)} kg`,
      now: `${nowWeight.toFixed(1)} kg`,
      delta:
        nowWeight < startWeight
          ? `−${(startWeight - nowWeight).toFixed(1)} kg`
          : nowWeight > startWeight
            ? `+${(nowWeight - startWeight).toFixed(1)} kg`
            : 'Same',
      improved: nowWeight <= startWeight,
    });
  }

  if (logs.length >= 4) {
    const early = logs.slice(0, Math.min(7, logs.length));
    const late = logs.slice(Math.max(0, logs.length - 7));
    const startSleep = avgField(early, 'sleep_hours');
    const nowSleep = avgField(late, 'sleep_hours');
    if (startSleep != null && nowSleep != null) {
      comparisons.push({
        id: 'sleep',
        label: 'Average Sleep',
        started: `${startSleep.toFixed(1)} h`,
        now: `${nowSleep.toFixed(1)} h`,
        delta:
          nowSleep >= startSleep
            ? `+${(nowSleep - startSleep).toFixed(1)} h`
            : `−${(startSleep - nowSleep).toFixed(1)} h`,
        improved: nowSleep >= startSleep,
      });
    }

    const earlyMoodLogs = early.filter((l) => l.mood);
    const lateMoodLogs = late.filter((l) => l.mood);
    if (earlyMoodLogs.length && lateMoodLogs.length) {
      const startMood = earlyMoodLogs[0].mood;
      const nowMood = lateMoodLogs[lateMoodLogs.length - 1].mood;
      comparisons.push({
        id: 'mood',
        label: 'Mood',
        started: moodLabel(startMood),
        now: moodLabel(nowMood),
        delta: String(nowMood),
        improved: (moodScore(nowMood) || 0) >= (moodScore(startMood) || 0),
      });
    }

    const startWater = avgField(early, 'water_liters');
    const nowWater = avgField(late, 'water_liters');
    if (startWater != null && nowWater != null) {
      comparisons.push({
        id: 'water',
        label: 'Daily Water',
        started: `${startWater.toFixed(1)} L`,
        now: `${nowWater.toFixed(1)} L`,
        delta:
          nowWater >= startWater
            ? `+${(nowWater - startWater).toFixed(1)} L`
            : `−${(startWater - nowWater).toFixed(1)} L`,
        improved: nowWater >= startWater,
      });
    }
  }

  return comparisons;
}

function buildMemories({ captures, logs }) {
  const memories = [];

  const journals = captures
    .filter((c) => c.type === 'journal' && c.payload?.text)
    .slice(0, 8);
  for (const j of journals) {
    memories.push({
      id: `journal_${j.id || j.captured_at}`,
      title: 'Journal',
      detail: String(j.payload.text).slice(0, 160),
      at: j.captured_at,
      type: 'journal',
      payload: j.payload,
    });
  }

  const meals = captures.filter((c) => c.type === 'meal').slice(0, 3);
  if (meals[0]) {
    memories.push({
      id: `meal_${meals[0].id || meals[0].captured_at}`,
      title: 'First healthy meal logged',
      detail:
        num(meals[0].payload?.calories) != null
          ? `${Math.round(num(meals[0].payload.calories))} kcal`
          : meals[0].payload?.name || 'Meal moment',
      at: meals[0].captured_at,
      type: 'meal',
      payload: meals[0].payload,
    });
  }

  const workouts = captures
    .filter((c) => c.type === 'workout')
    .map((c) => ({
      ...c,
      minutes: num(c.payload?.minutes) || 0,
    }))
    .sort((a, b) => b.minutes - a.minutes);
  if (workouts[0] && workouts[0].minutes > 0) {
    memories.push({
      id: `workout_${workouts[0].id || workouts[0].captured_at}`,
      title: 'Longest workout',
      detail: `${workouts[0].minutes} min · ${workouts[0].payload?.activity || 'Workout'}`,
      at: workouts[0].captured_at,
      type: 'workout',
      payload: workouts[0].payload,
    });
  }

  const reports = captures.filter((c) => c.type === 'health_report').slice(0, 2);
  for (const r of reports) {
    memories.push({
      id: `report_${r.id || r.captured_at}`,
      title: 'Health report',
      detail: r.payload?.name || 'Uploaded report',
      at: r.captured_at,
      type: 'health_report',
      payload: r.payload,
    });
  }

  const moodUp = logs
    .filter((l) => moodScore(l.mood) != null && moodScore(l.mood) >= 5)
    .slice(-2);
  for (const m of moodUp) {
    memories.push({
      id: `mood_${m.log_date}`,
      title: 'Mood lifted',
      detail: `${m.mood} on ${m.log_date}`,
      at: `${m.log_date}T12:00:00.000Z`,
      type: 'mood',
      payload: { mood: m.mood },
    });
  }

  return memories
    .sort((a, b) => new Date(b.at) - new Date(a.at))
    .slice(0, 12);
}

function pickNextMilestone(milestones) {
  const pending = milestones
    .filter((m) => !m.unlocked)
    .sort((a, b) => b.progress - a.progress);
  const next = pending[0] || milestones.find((m) => m.unlocked);
  if (!next) return null;

  const remaining = Math.max(0, next.target - next.current);
  let expectedDays = 14;
  if (next.id === 'streak_7' || next.id === 'month_1') {
    expectedDays = Math.max(1, Math.ceil(remaining));
  } else if (next.id === 'lost_5kg') {
    expectedDays = Math.max(7, Math.ceil(remaining * 10));
  } else if (next.id === 'water_100l') {
    expectedDays = Math.max(3, Math.ceil(remaining / 2.5));
  } else if (next.id === 'meals_100' || next.id === 'workouts_50') {
    expectedDays = Math.max(3, Math.ceil(remaining / 2));
  }

  return {
    title: next.title,
    expected_days: expectedDays,
    progress: next.progress,
    encouragement: next.unlocked
      ? 'You already earned this — keep the momentum.'
      : 'Keep going.',
    remaining,
    unit: next.unit,
  };
}

function enrichTimeline(captures) {
  return (captures || []).map((entry) => {
    const payload =
      entry.payload && typeof entry.payload === 'object' ? entry.payload : {};
    const meta = eventMeta(entry.type, payload);
    return {
      ...entry,
      icon: meta.icon,
      title: meta.title,
      detail: meta.detail,
    };
  });
}

function buildJourneyStory({ profile, captures = [], logs = [] }) {
  const waterGoal =
    num(profile?.ai_profile?.water_goal_liters) ||
    num(profile?.water_goal_liters) ||
    2.5;

  const orderedLogs = [...logs].sort((a, b) =>
    String(a.log_date).localeCompare(String(b.log_date)),
  );
  const orderedCaptures = [...captures].sort(
    (a, b) => new Date(b.captured_at) - new Date(a.captured_at),
  );

  const milestones = buildMilestones({
    captures: orderedCaptures,
    logs: orderedLogs,
  });
  const nextMilestone = pickNextMilestone(milestones);

  return {
    story: buildStoryMilestones({
      profile,
      captures: orderedCaptures,
      logs: orderedLogs,
      waterGoal,
    }),
    timeline: enrichTimeline(orderedCaptures),
    milestones,
    before_vs_now: buildBeforeVsNow({ profile, logs: orderedLogs }),
    memories: buildMemories({
      captures: orderedCaptures,
      logs: orderedLogs,
    }),
    next_milestone: nextMilestone,
    stats: {
      logging_days: new Set(orderedLogs.map((l) => dayKey(l.log_date)).filter(Boolean))
        .size,
      current_streak: currentStreak(orderedLogs),
      best_streak: consecutiveLoggingDays(orderedLogs),
      capture_count: orderedCaptures.length,
    },
  };
}

module.exports = {
  buildJourneyStory,
  eventMeta,
};
