import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const background = Color(0xFF0E0E12);
  static const backgroundTop = Color(0xFF14141C);
  static const surface = Color(0xFF1A1A24);
  static const cardSurface = Color(0xFF131A2D);
  static const cardBorder = Color(0xFF1E2840);
  static const surfaceBorder = Color(0xFF2A2A36);

  /// Primary accent — cyan/teal CTAs, links, focus rings (Today tab standard).
  static const primary = Color(0xFF00F2FE);
  static const primaryBright = Color(0xFF4FACFE);
  static const primaryMuted = Color(0xFF5BD6C2);

  /// Secondary accent — lavender, use sparingly for AI/wellness highlights.
  static const secondary = Color(0xFFB8A8FF);
  static const secondaryBright = Color(0xFFC4B5FF);
  static const secondaryMuted = Color(0xFF8B7FD4);

  // Legacy aliases kept for gradual migration / semantic category colors.
  static const lavender = secondary;
  static const lavenderBright = secondaryBright;
  static const lavenderMuted = secondaryMuted;

  static const teal = Color(0xFF2E4A4A);
  static const tealDeep = Color(0xFF1E3333);
  static const aqua = Color(0xFF5BD6C2);
  static const cyanAccent = primary;
  static const cyanBright = primaryBright;
  static const sky = Color(0xFF66B8FF);
  static const coral = Color(0xFFFF8D8D);
  static const amber = Color(0xFFFFC56E);
  static const mint = Color(0xFF7ED9A7);

  static const textPrimary = Color(0xFFF2F0FA);
  static const textSecondary = Color(0xFF9B97AB);
  static const textMuted = Color(0xFF6E6A7C);
  static const inputLine = Color(0xFF3A3848);

  static const buttonGradientStart = primary;
  static const buttonGradientEnd = primaryBright;
  static const cyanGradientStart = primary;
  static const cyanGradientEnd = primaryBright;
  static const onPrimaryButton = Color(0xFF0A1628);

  static const glow = Color(0x3300F2FE);
}
