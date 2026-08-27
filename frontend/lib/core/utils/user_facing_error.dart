/// Maps raw exceptions to short, user-safe copy (no SQL / provider names).
String userFacingError(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  final text = error.toString();
  final lower = text.toLowerCase();

  if (lower.contains('timeout') ||
      lower.contains('timed out') ||
      lower.contains('timeoutexception')) {
    return 'Unable to load right now. Please try again.';
  }

  if (lower.contains('socket') ||
      lower.contains('network') ||
      lower.contains('failed host lookup') ||
      lower.contains('connection') ||
      lower.contains('clientexception')) {
    return 'No internet connection. Check your network and try again.';
  }

  if (lower.contains('401') ||
      lower.contains('unauthorized') ||
      lower.contains('jwt') ||
      lower.contains('session')) {
    return 'Your session expired. Please sign in again.';
  }

  if (lower.contains('daily_logs') ||
      lower.contains('supabase') ||
      lower.contains('postgrest') ||
      lower.contains('sql') ||
      lower.contains('pgrst') ||
      lower.contains('column') ||
      lower.contains('relation')) {
    return 'Unable to load your dashboard right now. Please try again.';
  }

  // Never show long raw exception dumps.
  final cleaned = text
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .replaceFirst(RegExp(r'^TimeoutException.*?:\s*'), '')
      .split('\n')
      .first
      .trim();
  if (cleaned.isEmpty || cleaned.length > 120) return fallback;
  if (cleaned.toLowerCase().contains('exception')) return fallback;
  return cleaned;
}
