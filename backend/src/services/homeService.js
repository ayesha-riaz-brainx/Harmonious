function defaultTasks(aiProfile = {}) {
  const sleep = aiProfile.sleep_goal_hours || '10:30 PM';
  return [
    { id: 'water', label: 'Drink Water', done: false },
    { id: 'breakfast', label: 'Breakfast', done: false },
    { id: 'workout', label: 'Workout', done: false },
    { id: 'journal', label: 'Journal', done: false },
    {
      id: 'sleep',
      label: `Sleep Before ${String(sleep).includes(':') ? sleep : '10:30'}`,
      done: false,
    },
  ];
}

function todayUtcDate() {
  return new Date().toISOString().slice(0, 10);
}

function parseSleepGoalHours(aiProfile = {}) {
  const raw = aiProfile.sleep_goal_hours;
  if (typeof raw === 'number' && Number.isFinite(raw)) return raw;
  if (typeof raw === 'string') {
    const match = raw.match(/(\d+(\.\d+)?)/);
    if (match) return Number(match[1]);
  }
  return 8;
}

function markTaskDone(tasks, taskId) {
  return (Array.isArray(tasks) ? tasks : []).map((task) =>
    task?.id === taskId ? { ...task, done: true } : task,
  );
}

function tasksForCaptureType(tasks, type) {
  const map = {
    water: 'water',
    meal: 'breakfast',
    workout: 'workout',
    journal: 'journal',
    sleep: 'sleep',
  };
  const id = map[type];
  return id ? markTaskDone(tasks, id) : tasks;
}

function buildHomePayload({ profile, log, aiProfile }) {
  const waterGoal = Number(aiProfile?.water_goal_liters || 2.5);
  const calorieGoal = Number(aiProfile?.calorie_target || 1800);
  const exerciseGoal = Number(aiProfile?.exercise_goal_minutes || 30);
  const weightCurrent = log?.weight ?? profile?.weight ?? null;
  const onboarding = profile?.onboarding_data || {};
  const weightGoal =
    onboarding.target_weight ??
    aiProfile?.target_weight ??
    (weightCurrent != null ? Number(weightCurrent) - 4 : null);

  const goals = [];
  if (aiProfile?.primary_goal || weightCurrent != null) {
    let progress = 0;
    if (weightCurrent != null && weightGoal != null) {
      const start =
        Number(onboarding.start_weight ?? profile?.weight ?? weightCurrent) ||
        Number(weightCurrent);
      const span = Math.max(Math.abs(start - Number(weightGoal)), 0.5);
      progress = Math.min(
        1,
        Math.max(0, 1 - Math.abs(Number(weightCurrent) - Number(weightGoal)) / span),
      );
    }
    goals.push({
      id: 'primary',
      title: aiProfile?.primary_goal || 'Reach goal weight',
      current: weightCurrent,
      target: weightGoal,
      unit: profile?.weight_unit || 'kg',
      kind: 'weight',
      progress,
    });
  }

  const sleepTarget = parseSleepGoalHours(aiProfile);
  const sleepCurrent = Number(log?.sleep_hours || 0);
  goals.push({
    id: 'sleep',
    title: 'Sleep Better',
    current: sleepCurrent > 0 ? sleepCurrent : null,
    target: sleepTarget,
    unit: 'h',
    kind: 'sleep',
    progress:
      sleepCurrent > 0
        ? Math.min(1, Math.max(0, sleepCurrent / sleepTarget))
        : 0,
  });

  return {
    greeting_name: profile?.display_name || profile?.full_name || 'Friend',
    profile,
    ai_profile: aiProfile || {},
    today: {
      date: log?.log_date || todayUtcDate(),
      weight: weightCurrent,
      water_liters: Number(log?.water_liters || 0),
      water_goal: waterGoal,
      calories: Number(log?.calories || 0),
      calorie_goal: calorieGoal,
      exercise_minutes: Number(log?.exercise_minutes || 0),
      exercise_goal: exerciseGoal,
      mood: log?.mood || null,
      sleep_hours: Number(log?.sleep_hours || 0),
      tasks: Array.isArray(log?.tasks) ? log.tasks : defaultTasks(aiProfile),
      ai_brief: log?.ai_brief || {},
      ai_insights: Array.isArray(log?.ai_insights) ? log.ai_insights : [],
    },
    active_goals: goals,
  };
}

module.exports = {
  defaultTasks,
  todayUtcDate,
  buildHomePayload,
  tasksForCaptureType,
  parseSleepGoalHours,
};
