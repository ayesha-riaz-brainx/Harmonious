const path = require('path');

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const healthRouter = require('./routes/health');
const authRouter = require('./routes/auth');
const profileRouter = require('./routes/profile');
const homeRouter = require('./routes/home');
const featuresRouter = require('./routes/features');

const app = express();
const publicDir = path.join(__dirname, '../public');

// Render / reverse proxies set X-Forwarded-For for rate limiting.
app.set('trust proxy', 1);

app.use(
  helmet({
    contentSecurityPolicy: false,
  }),
);
app.use(cors());
app.use(express.json({ limit: '12mb' }));
app.use(morgan('dev'));
app.use(express.static(publicDir));

app.get('/auth/email-confirmed', (req, res) => {
  res.sendFile(path.join(publicDir, 'auth', 'email-confirmed.html'));
});

app.get('/auth/reset-password', (req, res) => {
  res.sendFile(path.join(publicDir, 'auth', 'reset-password.html'));
});

app.get('/auth/client-config.json', (req, res) => {
  const supabaseUrl = (process.env.SUPABASE_URL || '').trim();
  const supabaseAnonKey = (process.env.SUPABASE_ANON_KEY || '').trim();
  if (!supabaseUrl || !supabaseAnonKey) {
    return res.status(503).json({
      message: 'Set SUPABASE_URL and SUPABASE_ANON_KEY on the backend.',
    });
  }
  return res.json({ supabaseUrl, supabaseAnonKey });
});

app.get('/auth/confirm', (req, res) => {
  res.redirect(302, `/auth/email-confirmed${req.url.includes('?') ? req.url.slice(req.url.indexOf('?')) : ''}`);
});

app.get('/', (req, res) => {
  res.json({
    service: 'slot-1-tasks-backend',
    status: 'ok',
    message: 'Backend is running. Use the API routes below.',
    pages: {
      emailConfirmed: 'GET /auth/email-confirmed',
      passwordReset: 'GET /auth/reset-password',
      privacyPolicy: 'GET /privacy-policy.html',
    },
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
      aiTool: 'POST /api/features/ai/tool',
      quickCapture: 'POST /api/features/captures',
      foodSearch: 'GET /api/features/foods/search?query=',
      journey: 'GET /api/features/journey',
      settings: 'GET /api/features/settings',
    },
  });
});

app.use('/api/health', healthRouter);
app.use('/api/auth', authRouter);
app.use('/api/profile', profileRouter);
app.use('/api/home', homeRouter);
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
