const crypto = require('crypto');

const { getSupabaseAdmin } = require('../config/supabase');

const CODE_TTL_MS = 15 * 60 * 1000;
const memoryStore = new Map();

function hashCode(code) {
  return crypto.createHash('sha256').update(String(code)).digest('hex');
}

function generateCode() {
  return String(crypto.randomInt(100000, 999999));
}

async function createResetCode(email) {
  const normalized = email.trim().toLowerCase();
  const code = generateCode();
  const codeHash = hashCode(code);
  const expiresAt = new Date(Date.now() + CODE_TTL_MS).toISOString();

  const supabase = getSupabaseAdmin();
  const { error } = await supabase.from('password_resets').insert({
    email: normalized,
    code_hash: codeHash,
    expires_at: expiresAt,
  });

  if (error) {
    // Fallback when SQL table is not created yet.
    memoryStore.set(normalized, {
      codeHash,
      expiresAt: Date.now() + CODE_TTL_MS,
      used: false,
    });
    console.warn(
      'password_resets insert failed; using memory store:',
      error.message,
    );
  } else {
    memoryStore.delete(normalized);
  }

  return { code, email: normalized, expiresAt };
}

async function consumeResetCode(email, code) {
  const normalized = email.trim().toLowerCase();
  const codeHash = hashCode(code);
  const now = Date.now();

  const supabase = getSupabaseAdmin();
  const { data, error } = await supabase
    .from('password_resets')
    .select('*')
    .eq('email', normalized)
    .is('used_at', null)
    .order('created_at', { ascending: false })
    .limit(5);

  if (!error && data?.length) {
    const match = data.find(
      (row) =>
        row.code_hash === codeHash &&
        new Date(row.expires_at).getTime() >= now,
    );
    if (!match) return false;
    await supabase
      .from('password_resets')
      .update({ used_at: new Date().toISOString() })
      .eq('id', match.id);
    memoryStore.delete(normalized);
    return true;
  }

  const local = memoryStore.get(normalized);
  if (!local || local.used) return false;
  if (local.expiresAt < now) {
    memoryStore.delete(normalized);
    return false;
  }
  if (local.codeHash !== codeHash) return false;
  local.used = true;
  return true;
}

module.exports = {
  createResetCode,
  consumeResetCode,
};
