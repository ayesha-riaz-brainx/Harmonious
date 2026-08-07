const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const healthRouter = require('./routes/health');
const authRouter = require('./routes/auth');
const profileRouter = require('./routes/profile');
const homeRouter = require('./routes/home');
const onboardingRouter = require('./routes/onboarding');
const featuresRouter = require('./routes/features');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '12mb' }));
app.use(morgan('dev'));

app.get('/', (req, res) => {
  res.json({
    service: 'slot-1-tasks-backend',
    status: 'ok',
    message: 'Backend is running. Use the API routes below.',
    endpoints: {
      health: 'GET /api/health',
      signup: 'POST /api/auth/signup',
      login: 'POST /api/auth/login',
      forgotPassword: 'POST /api/auth/forgot-password',
      resetPassword: 'POST /api/auth/reset-password',
      deleteAccount: 'DELETE /api/auth/account',
      getProfile: 'GET /api/profile/me',
      updateProfile: 'PUT /api/profile/me',
      homeToday: 'GET /api/home/today',
      homeUpdate: 'PATCH /api/home/today',
      homeRefreshAi: 'POST /api/home/today/refresh-ai',
      onboardingAiSummary: 'POST /api/onboarding/ai-summary',
      aiChat: 'POST /api/features/ai/chat',
      aiTranscribe: 'POST /api/features/ai/transcribe',
      quickCapture: 'POST /api/features/captures',
      journey: 'GET /api/features/journey',
      settings: 'GET /api/features/settings',
    },
  });
});

app.use('/api/health', healthRouter);
app.use('/api/auth', authRouter);
app.use('/api/profile', profileRouter);
app.use('/api/home', homeRouter);
app.use('/api/onboarding', onboardingRouter);
app.use('/api/features', featuresRouter);

app.use((req, res) => {
  res.status(404).json({ message: 'Route not found' });
});

app.use((err, req, res, next) => {
  console.error(err);
  res.status(err.status || 500).json({
    message: err.message || 'Internal server error',
  });
});

module.exports = app;
