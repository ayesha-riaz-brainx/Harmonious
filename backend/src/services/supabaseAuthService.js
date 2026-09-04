const { createClient } = require('@supabase/supabase-js');

function getSupabasePublicAuthClient() {
  const url = (process.env.SUPABASE_URL || '').trim();
  const anonKey = (process.env.SUPABASE_ANON_KEY || '').trim();

  if (!url || !anonKey || url.includes('PASTE_YOUR_') || anonKey.includes('PASTE_YOUR_')) {
    const error = new Error(
      'Supabase auth keys missing. Set SUPABASE_URL and SUPABASE_ANON_KEY on the backend.',
    );
    error.status = 503;
    throw error;
  }

  return createClient(url, anonKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}

function resolvePasswordResetRedirect(req) {
  const configured = (process.env.PUBLIC_APP_URL || '').trim().replace(/\/$/, '');
  if (configured) {
    return `${configured}/auth/reset-password`;
  }

  const host = req.get('host');
  if (host) {
    const protocol = req.protocol === 'https' ? 'https' : 'http';
    return `${protocol}://${host}/auth/reset-password`;
  }

  return 'https://harmonious.onrender.com/auth/reset-password';
}

async function sendPasswordResetLink({ email, redirectTo, captchaToken }) {
  const supabase = getSupabasePublicAuthClient();
  const options = { redirectTo };
  if (captchaToken) {
    options.captchaToken = captchaToken;
  }

  const { error } = await supabase.auth.resetPasswordForEmail(email, options);

  if (error) {
    const message = (error.message || '').toLowerCase();
    if (
      message.includes('rate limit') ||
      message.includes('too many requests') ||
      message.includes('over_email_send_rate_limit')
    ) {
      const rateError = new Error(
        'Too many reset emails sent recently. Please wait and try again.',
      );
      rateError.status = 429;
      throw rateError;
    }
    throw error;
  }
}

module.exports = {
  resolvePasswordResetRedirect,
  sendPasswordResetLink,
};
