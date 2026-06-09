import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static Color background(_) => backgroundLight;

  static Color surface(_) => surfaceLight;

  static Color surfaceVariant(_) => surfaceVariantLight;

  static Color primaryText(_) => primaryTextLight;

  static Color secondaryText(_) => secondaryTextLight;

  // System semantic colors (Apple-like)
  static const Color systemBlue = Color(0xFF0A84FF);
  static const Color systemGreen = Color(0xFF34C759);
  static const Color systemGreenLight = Color(0xFF9BE15D);
  static const Color systemYellow = Color(0xFFFFD60A);
  static const Color systemOrange = Color(0xFFFF9F0A);
  static const Color systemRed = Color(0xFFFF3B30);
  static const Color systemRedDark = Color(0xFF7D0A0A);
  static const Color systemGray = Color(0xFF8E8E93);
  static const Color systemPink = Color(0xFFFF2D55);
  static const Color systemTeal = Color(0xFF6BD7F3);
  static const Color systemPurple = Color(0xFFD6B4FC);

  // Neutral / surfaces
  static const Color backgroundLight = Color(0xFFF2F2F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFE5E5EA);
  static const Color primaryTextLight = Color(0xFF000000);
  static const Color secondaryTextLight = Color(0xFF6C6C70);

  static final ColorScheme lightColorScheme = ColorScheme.light(
    primary: systemBlue,
    secondary: systemTeal,
    tertiary: systemPurple,
    error: systemRed,
    surface: backgroundLight,
  ).copyWith(
    surfaceContainer: surfaceLight,
    surfaceContainerHigh: surfaceLight,
    surfaceContainerHighest: surfaceVariantLight,
    onSurface: primaryTextLight,
    onSurfaceVariant: secondaryTextLight,
    outline: const Color(0xFFC6C6C8),
    primaryContainer: const Color(0xFFDCEEFF),
    onPrimaryContainer: const Color(0xFF001F3D),
    secondaryContainer: const Color(0xFFD8F5F1),
    onSecondaryContainer: const Color(0xFF062B26),
    tertiaryContainer: const Color(0xFFF0E6FF),
    onTertiaryContainer: const Color(0xFF2B1D40),
    errorContainer: const Color(0xFFFFDAD6),
    onErrorContainer: const Color(0xFF410002),
    inverseSurface: backgroundLight,
    onInverseSurface: primaryTextLight,
    inversePrimary: systemBlue,
  );

}
