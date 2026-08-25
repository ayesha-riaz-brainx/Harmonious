function safeNum(value, fallback = 0, { min, max } = {}) {
  const n = Number(value);
  if (!Number.isFinite(n)) return fallback;
  let out = n;
  if (min != null) out = Math.max(min, out);
  if (max != null) out = Math.min(max, out);
  return out;
}

function safeOptionalNum(value, { min, max } = {}) {
  if (value == null || value === '') return null;
  const n = Number(value);
  if (!Number.isFinite(n)) return null;
  if (min != null && n < min) return null;
  if (max != null && n > max) return null;
  return n;
}

function todayUtcDate() {
  return new Date().toISOString().slice(0, 10);
}

/** Prefer the device calendar day from X-Client-Date when valid. */
function resolveLogDate(req) {
  const header = req?.headers?.['x-client-date'];

  if (
    typeof header === 'string' &&
    /^\d{4}-\d{2}-\d{2}$/.test(header.trim())
  ) {
    return header.trim();
  }

  return todayUtcDate();
}

const HABIT_PRESETS = {
  water: {
    id: 'water',
    label: 'Drink water',
  },
  breakfast: {
    id: 'breakfast',
    label: 'Log breakfast',
  },
  workout: {
    id: 'workout',
    label: 'Move / exercise',
  },
  journal: {
    id: 'journal',
    label: 'Journal',
  },
  sleep: {
    id: 'sleep',
    label: null,
  },
};

/** Old auto-seeded set — never inject these unless the user chose them. */
const LEGACY_DEFAULT_HABIT_IDS = [
  'water',
  'breakfast',
  'workout',
  'journal',
  'sleep',
];

function sleepHabitLabel(aiProfile = {}, onboarding = {}) {
  const raw =
    onboarding.preferred_bedtime ||
    onboarding.routine_bedtime ||
    aiProfile.sleep_goal_hours ||
    '10:30 PM';

  const text = String(raw);

  if (text.includes(':')) {
    return `Sleep before ${text}`;
  }

  const match = text.match(/(\d+(\.\d+)?)/);
  const hours = match ? match[1] : '10:30';

  return `Sleep before ${hours}:30`;
}

function stepsGoalFromActivityLevel(activityLevel) {
  switch (activityLevel) {
    case 'Mostly Sitting':
      return 6000;

    case 'Lightly Active':
      return 8000;

    case 'Moderately Active':
      return 10000;

    case 'Very Active':
      return 12000;

    default:
      return 8000;
  }
}

function resolveStepsGoal(aiProfile = {}, onboarding = {}) {
  const fromProfile = safeNum(
    aiProfile?.steps_goal,
    NaN,
    {
      min: 1000,
      max: 50000,
    },
  );

  if (Number.isFinite(fromProfile)) {
    return Math.round(fromProfile);
  }

  const activity =
    onboarding.activity_level ||
    aiProfile.activity_level ||
    onboarding.activityLevel;

  return stepsGoalFromActivityLevel(activity);
}

function isLegacyDefaultHabitSet(ids = []) {
  if (!Array.isArray(ids) || ids.length !== LEGACY_DEFAULT_HABIT_IDS.length) {
    return false;
  }
  const normalized = ids.map((id) => String(id)).sort().join(',');
  const legacy = [...LEGACY_DEFAULT_HABIT_IDS].sort().join(',');
  return normalized === legacy;
}

function resolveHabitIds(aiProfile = {}, onboarding = {}) {
  // Prefer explicit onboarding choice (including empty = user skipped).
  if (Array.isArray(onboarding.selected_habits)) {
    return onboarding.selected_habits.map((id) => String(id));
  }

  const selected =
    aiProfile.habit_templates ||
    aiProfile.selected_habits;

  if (Array.isArray(selected)) {
    // Drop the old auto-injected 5 defaults when the user never chose habits.
    if (isLegacyDefaultHabitSet(selected)) {
      return [];
    }
    return selected.map((id) => String(id));
  }

  return [];
}

function taskFromHabitId(habitId, aiProfile = {}, onboarding = {}) {
  const preset = HABIT_PRESETS[habitId];

  if (preset) {
    if (habitId === 'sleep') {
      return {
        id: 'sleep',
        label: sleepHabitLabel(aiProfile, onboarding),
        done: false,
      };
    }

    return {
      ...preset,
      done: false,
    };
  }

  const label = String(habitId).startsWith('custom_')
    ? String(habitId)
        .slice(7)
        .replace(/_/g, ' ')
    : String(habitId);

  return {
    id: String(habitId),
    label,
    done: false,
  };
}

function normalizeTaskLabels(tasks) {
  return (Array.isArray(tasks) ? tasks : []).map((task) => {
    if (task?.id === 'water' && typeof task.label === 'string') {
      const label = task.label.trim();
      if (
        /^drink\s*water(\s*\(habit\))?$/i.test(label) ||
        /\(habit\)/i.test(label)
      ) {
        return { ...task, label: 'Drink water' };
      }
    }

    if (task?.id === 'workout' && typeof task.label === 'string') {
      const label = task.label.trim();
      if (/^workout$/i.test(label) || /^move goal$/i.test(label)) {
        return { ...task, label: 'Move / exercise' };
      }
    }

    if (task?.id === 'breakfast' && typeof task.label === 'string') {
      if (/^breakfast$/i.test(task.label.trim())) {
        return { ...task, label: 'Log breakfast' };
      }
    }

    return task;
  });
}

/** Strip legacy auto-seeded habits when the user never picked any. */
function sanitizeTasks(tasks, aiProfile = {}, onboarding = {}) {
  const list = Array.isArray(tasks) ? tasks : [];
  const ids = list.map((t) => t?.id).filter(Boolean);
  const legacyTasks = isLegacyDefaultHabitSet(ids);

  if (!legacyTasks) {
    return normalizeTaskLabels(list);
  }

  // Today's log still has the old 5 defaults — replace with the user's real choice.
  if (Array.isArray(onboarding.selected_habits)) {
    return onboarding.selected_habits.map((id) =>
      taskFromHabitId(String(id), aiProfile, onboarding),
    );
  }

  const templates = aiProfile.habit_templates || aiProfile.selected_habits;
  if (isLegacyDefaultHabitSet(templates || [])) {
    return [];
  }

  if (Array.isArray(templates) && templates.length > 0) {
    return templates.map((id) =>
      taskFromHabitId(String(id), aiProfile, onboarding),
    );
  }

  return [];
}

function defaultTasks(aiProfile = {}, onboarding = {}) {
  const habitIds = resolveHabitIds(
    aiProfile,
    onboarding,
  );

  return habitIds.map((id) =>
    taskFromHabitId(
      id,
      aiProfile,
      onboarding,
    ),
  );
}

function parseSleepGoalHours(aiProfile = {}) {
  const raw = aiProfile.sleep_goal_hours;

  if (
    typeof raw === 'number' &&
    Number.isFinite(raw)
  ) {
    return raw;
  }

  if (typeof raw === 'string') {
    const match = raw.match(/(\d+(\.\d+)?)/);

    if (match) {
      return Number(match[1]);
    }
  }

  return 8;
}

function markTaskDone(tasks, taskId) {
  return (Array.isArray(tasks) ? tasks : []).map(
    (task) =>
      task?.id === taskId
        ? {
            ...task,
            done: true,
          }
        : task,
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

  return id
    ? markTaskDone(tasks, id)
    : tasks;
}

function buildHomePayload({
  profile,
  log,
  aiProfile,
}) {
  // Initialize onboarding BEFORE using it.
  const onboarding =
    profile?.onboarding_data || {};

  const waterGoal = safeNum(
    aiProfile?.water_goal_liters,
    2.5,
    {
      min: 0.5,
      max: 10,
    },
  );

  const calorieGoal = safeNum(
    aiProfile?.calorie_target,
    1800,
    {
      min: 500,
      max: 10000,
    },
  );

  const exerciseGoal = safeNum(
    aiProfile?.exercise_goal_minutes,
    30,
    {
      min: 1,
      max: 600,
    },
  );

  const stepsGoal = resolveStepsGoal(
    aiProfile,
    onboarding,
  );

  // Today's weight must come from today's log only —
  // never profile/onboarding defaults.
  const weightLogged = safeOptionalNum(
    log?.weight,
    {
      min: 1,
      max: 500,
    },
  );

  const profileWeight = safeOptionalNum(
    profile?.weight,
    {
      min: 1,
      max: 500,
    },
  );

  const weightGoal =
    onboarding.target_weight ??
    aiProfile?.target_weight ??
    (
      profileWeight != null
        ? Number(profileWeight) - 4
        : null
    );

  const goals = [];

  if (
    aiProfile?.primary_goal ||
    weightGoal != null
  ) {
    let progress = 0;

    if (
      weightLogged != null &&
      weightGoal != null
    ) {
      const start =
        Number(
          onboarding.start_weight ??
          profileWeight ??
          weightLogged,
        ) ||
        Number(weightLogged);

      const span = Math.max(
        Math.abs(
          start -
          Number(weightGoal),
        ),
        0.5,
      );

      progress = Math.min(
        1,
        Math.max(
          0,
          1 -
            Math.abs(
              Number(weightLogged) -
              Number(weightGoal),
            ) /
              span,
        ),
      );
    }

    goals.push({
      id: 'primary',
      title:
        aiProfile?.primary_goal ||
        'Reach goal weight',
      current: weightLogged,
      target: weightGoal,
      unit:
        profile?.weight_unit ||
        'kg',
      kind: 'weight',
      progress,
    });
  }

  const sleepTarget =
    parseSleepGoalHours(aiProfile);

  const sleepCurrent = safeNum(
    log?.sleep_hours,
    0,
    {
      min: 0,
      max: 24,
    },
  );

  goals.push({
    id: 'sleep',
    title: 'Sleep Better',
    current:
      sleepCurrent > 0
        ? sleepCurrent
        : null,
    target: sleepTarget,
    unit: 'h',
    kind: 'sleep',
    progress:
      sleepCurrent > 0
        ? Math.min(
            1,
            Math.max(
              0,
              sleepCurrent /
                sleepTarget,
            ),
          )
        : 0,
  });

  goals.push({
    id: 'steps',
    title: 'Daily steps',
    current: null,
    target: stepsGoal,
    unit: 'steps',
    kind: 'steps',
    progress: 0,
  });

  return {
    greeting_name:
      profile?.display_name ||
      profile?.full_name ||
      'Friend',

    profile,

    ai_profile:
      aiProfile || {},

    today: {
      date:
        log?.log_date ||
        todayUtcDate(),

      weight: weightLogged,

      water_liters: safeNum(
        log?.water_liters,
        0,
        {
          min: 0,
        },
      ),

      water_goal: waterGoal,

      calories: Math.round(
        safeNum(
          log?.calories,
          0,
          {
            min: 0,
          },
        ),
      ),

      calorie_goal:
        Math.round(calorieGoal),

      exercise_minutes:
        Math.round(
          safeNum(
            log?.exercise_minutes,
            0,
            {
              min: 0,
            },
          ),
        ),

      exercise_goal:
        Math.round(exerciseGoal),

      steps_goal: stepsGoal,

      mood:
        log?.mood &&
        String(log.mood).trim()
          ? String(log.mood).trim()
          : null,

      sleep_hours: safeNum(
        log?.sleep_hours,
        0,
        {
          min: 0,
          max: 24,
        },
      ),

      tasks: sanitizeTasks(
        Array.isArray(log?.tasks)
          ? log.tasks
          : defaultTasks(
              aiProfile,
              onboarding,
            ),
        aiProfile,
        onboarding,
      ),

      ai_brief:
        log?.ai_brief || {},

      ai_insights:
        Array.isArray(
          log?.ai_insights,
        )
          ? log.ai_insights
          : [],
    },

    active_goals: goals,
  };
}

function validateCapturePayload(
  type,
  payload = {},
) {
  switch (type) {
    case 'meal': {
      const calories =
        Number(payload.calories);

      if (
        !Number.isFinite(calories) ||
        calories <= 0
      ) {
        return 'Enter a valid calorie amount greater than 0.';
      }

      break;
    }

    case 'weight': {
      const weight =
        Number(payload.weight);

      if (
        !Number.isFinite(weight) ||
        weight <= 0 ||
        weight > 500
      ) {
        return 'Enter a valid weight in kg.';
      }

      break;
    }

    case 'workout': {
      const minutes =
        Number(payload.minutes);

      if (
        !Number.isFinite(minutes) ||
        minutes <= 0 ||
        minutes > 600
      ) {
        return 'Enter valid workout minutes.';
      }

      break;
    }

    case 'mood': {
      if (
        !payload.mood ||
        !String(payload.mood).trim()
      ) {
        return 'Select a mood.';
      }

      break;
    }

    case 'sleep': {
      const hours =
        Number(payload.hours);

      if (
        !Number.isFinite(hours) ||
        hours <= 0 ||
        hours > 24
      ) {
        return 'Enter valid sleep hours (0–24).';
      }

      break;
    }

    case 'journal': {
      if (
        !payload.text ||
        !String(payload.text).trim()
      ) {
        return 'Write a short note first.';
      }

      break;
    }

    default:
      break;
  }

  return null;
}

module.exports = {
  HABIT_PRESETS,
  LEGACY_DEFAULT_HABIT_IDS,
  DEFAULT_HABIT_IDS: LEGACY_DEFAULT_HABIT_IDS,
  defaultTasks,
  normalizeTaskLabels,
  sanitizeTasks,
  isLegacyDefaultHabitSet,
  resolveHabitIds,
  resolveStepsGoal,
  stepsGoalFromActivityLevel,
  taskFromHabitId,
  todayUtcDate,
  resolveLogDate,
  buildHomePayload,
  tasksForCaptureType,
  parseSleepGoalHours,
  validateCapturePayload,
  safeNum,
  safeOptionalNum,
};