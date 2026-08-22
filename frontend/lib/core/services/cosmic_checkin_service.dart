import 'package:shared_preferences/shared_preferences.dart';

import 'package:slot_1_tasks/core/astrology/cosmic_checkin.dart';
import 'package:slot_1_tasks/core/astrology/cosmic_checkin_library.dart';
import 'package:slot_1_tasks/core/astrology/zodiac_sign.dart';

/// Serves pre-written daily cosmic check-ins — no AI, no network.
/// Content is loaded once per calendar day per sign and cached locally.
class CosmicCheckInService {
  CosmicCheckInService({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  CosmicCheckIn? _memoryCache;
  String? _memoryKey;

  Future<CosmicCheckIn?> forSign(ZodiacSign? sign, {DateTime? onDate}) async {
    if (sign == null) return null;

    final date = onDate ?? DateTime.now();
    final dateKey = _dateKey(date);
    final cacheKey = 'cosmic_${sign.id}_$dateKey';

    if (_memoryKey == cacheKey && _memoryCache != null) {
      return _memoryCache;
    }

    _prefs ??= await SharedPreferences.getInstance();
    final storedTheme = _prefs!.getString('$cacheKey.theme');
    if (storedTheme != null) {
      final checkIn = CosmicCheckIn(
        sign: sign,
        theme: storedTheme,
        relationships: _prefs!.getString('$cacheKey.relationships') ?? '',
        productivity: _prefs!.getString('$cacheKey.productivity') ?? '',
        wellness: _prefs!.getString('$cacheKey.wellness') ?? '',
        dateKey: dateKey,
      );
      _memoryCache = checkIn;
      _memoryKey = cacheKey;
      return checkIn;
    }

    final fresh = CosmicCheckInLibrary.resolve(sign: sign, date: date);
    await _prefs!.setString('$cacheKey.theme', fresh.theme);
    await _prefs!.setString('$cacheKey.relationships', fresh.relationships);
    await _prefs!.setString('$cacheKey.productivity', fresh.productivity);
    await _prefs!.setString('$cacheKey.wellness', fresh.wellness);

    _memoryCache = fresh;
    _memoryKey = cacheKey;
    return fresh;
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }
}
