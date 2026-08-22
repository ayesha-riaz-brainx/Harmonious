import 'package:slot_1_tasks/core/astrology/zodiac_sign.dart';

class CosmicCheckIn {
  const CosmicCheckIn({
    required this.sign,
    required this.theme,
    required this.relationships,
    required this.productivity,
    required this.wellness,
    required this.dateKey,
  });

  final ZodiacSign sign;
  final String theme;
  final String relationships;
  final String productivity;
  final String wellness;
  final String dateKey;

  String get headline => '${sign.symbol} ${sign.label} — Today';
}
