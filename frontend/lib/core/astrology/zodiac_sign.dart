enum ZodiacSign {
  aries('Aries', '♈', 3, 21, 4, 19),
  taurus('Taurus', '♉', 4, 20, 5, 20),
  gemini('Gemini', '♊', 5, 21, 6, 20),
  cancer('Cancer', '♋', 6, 21, 7, 22),
  leo('Leo', '♌', 7, 23, 8, 22),
  virgo('Virgo', '♍', 8, 23, 9, 22),
  libra('Libra', '♎', 9, 23, 10, 22),
  scorpio('Scorpio', '♏', 10, 23, 11, 21),
  sagittarius('Sagittarius', '♐', 11, 22, 12, 21),
  capricorn('Capricorn', '♑', 12, 22, 1, 19),
  aquarius('Aquarius', '♒', 1, 20, 2, 18),
  pisces('Pisces', '♓', 2, 19, 3, 20);

  const ZodiacSign(
    this.label,
    this.symbol,
    this.startMonth,
    this.startDay,
    this.endMonth,
    this.endDay,
  );

  final String label;
  final String symbol;
  final int startMonth;
  final int startDay;
  final int endMonth;
  final int endDay;

  String get id => name;

  static ZodiacSign? fromId(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final key = raw.trim().toLowerCase();
    for (final sign in ZodiacSign.values) {
      if (sign.name == key || sign.label.toLowerCase() == key) {
        return sign;
      }
    }
    return null;
  }

  /// Western tropical zodiac from birthday (month/day only).
  static ZodiacSign? fromBirthday(DateTime date) {
    final month = date.month;
    final day = date.day;

    for (final sign in ZodiacSign.values) {
      if (sign.startMonth <= sign.endMonth) {
        final afterStart =
            month > sign.startMonth ||
            (month == sign.startMonth && day >= sign.startDay);
        final beforeEnd =
            month < sign.endMonth ||
            (month == sign.endMonth && day <= sign.endDay);
        if (afterStart && beforeEnd) return sign;
      } else {
        // Capricorn spans Dec–Jan
        final inDec = month == sign.startMonth && day >= sign.startDay;
        final inJan = month == sign.endMonth && day <= sign.endDay;
        if (inDec || inJan) return sign;
      }
    }
    return null;
  }
}
