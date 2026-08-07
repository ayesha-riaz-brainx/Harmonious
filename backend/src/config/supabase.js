const { createClient } = require('@supabase/supabase-js');

function getSupabaseAdmin() {
  const url = process.env.SUPABASE_URL;
  const serviceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (
    !url ||
    !serviceRoleKey ||
    url.includes('PASTE_YOUR_') ||
    serviceRoleKey.includes('PASTE_YOUR_')
  ) {
    const error = new Error(
      'Supabase keys missing. Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY in backend/.env',
    );
    error.status = 500;
    throw error;
  }

  return createClient(url, serviceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });
}

module.exports = {
  getSupabaseAdmin,
};
