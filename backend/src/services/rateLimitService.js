const buckets = new Map();

function checkRateLimit(key, { maxHits, windowMs }) {
  const now = Date.now();
  let bucket = buckets.get(key);
  if (!bucket || bucket.resetAt <= now) {
    bucket = { hits: 0, resetAt: now + windowMs };
    buckets.set(key, bucket);
  }

  bucket.hits += 1;
  if (bucket.hits > maxHits) {
    const retryAfterSec = Math.max(1, Math.ceil((bucket.resetAt - now) / 1000));
    return { allowed: false, retryAfterSec };
  }

  return { allowed: true };
}

setInterval(() => {
  const now = Date.now();
  for (const [key, bucket] of buckets.entries()) {
    if (bucket.resetAt <= now) buckets.delete(key);
  }
}, 60 * 60 * 1000).unref();

module.exports = {
  checkRateLimit,
};
