const { generateOnboardingSummary, hasAiKey } = require('../services/aiService');

async function aiSummary(req, res, next) {
  try {
    const { draft, ruleBased } = req.body || {};
    if (!draft || !ruleBased) {
      return res.status(400).json({ message: 'draft and ruleBased are required.' });
    }

    if (!hasAiKey()) {
      return res.status(503).json({
        code: 'AI_KEY_MISSING',
        message:
          'Add OPENAI_API_KEY to backend/.env to generate AI onboarding summaries.',
        profile: ruleBased,
      });
    }

    const profile = await generateOnboardingSummary({
      profile: { name: draft.display_name || draft.full_name },
      draft,
      ruleBased,
    });

    return res.json({ profile, ai_enabled: true });
  } catch (error) {
    return next(error);
  }
}

module.exports = { aiSummary };
