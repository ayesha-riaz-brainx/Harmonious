const { getSupabaseAdmin } = require('../config/supabase');

function authHeader(req) {
  const header = req.headers.authorization || '';
  const [type, token] = header.split(' ');
  if (type !== 'Bearer' || !token) {
    return null;
  }
  return token;
}

async function requireUser(req, res, next) {
  try {
    const token = authHeader(req);
    if (!token) {
      return res.status(401).json({ message: 'Missing or invalid authorization token.' });
    }

    const supabase = getSupabaseAdmin();
    const { data, error } = await supabase.auth.getUser(token);

    if (error || !data?.user) {
      return res.status(401).json({ message: 'Session expired. Please log in again.' });
    }

    req.user = data.user;
    req.accessToken = token;
    return next();
  } catch (error) {
    return next(error);
  }
}

module.exports = {
  requireUser,
};
