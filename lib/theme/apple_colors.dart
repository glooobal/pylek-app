import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static Color background(Brightness brightness) =>
      brightness == Brightness.dark ? backgroundDark : backgroundLight;

  static Color surface(Brightness brightness) =>
      brightness == Brightness.dark ? surfaceDark : surfaceLight;

  static Color surfaceVariant(Brightness brightness) =>
      brightness == Brightness.dark ? surfaceVariantDark : surfaceVariantLight;

  static Color primaryText(Brightness brightness) =>
      brightness == Brightness.dark ? primaryTextDark : primaryTextLight;

  static Color secondaryText(Brightness brightness) =>
      brightness == Brightness.dark ? secondaryTextDark : secondaryTextLight;

  // System semantic colors (Apple-like)
  static const Color systemBlue = Color(0xFF0A84FF);
  static const Color systemGreen = Color(0xFF34C759);
  static const Color systemGreenLight = Color(0xFF9BE15D);
  static const Color systemYellow = Color(0xFFFFD60A);
  static const Color systemOrange = Color(0xFFFF9F0A);
  static const Color systemRed = Color(0xFFFF3B30);
  static const Color systemRedDark = Color(0xFF7D0A0A);
  static const Color systemPink = Color(0xFFFF2D55);
  static const Color systemTeal = Color(0xFF6BD7F3);
  static const Color systemPurple = Color(0xFFD6B4FC);

  // Neutral / surfaces - dark
  static const Color backgroundDark = Color(0xFF000000);
  static const Color surfaceDark = Color(0xFF1C1C1E);
  static const Color surfaceVariantDark = Color(0xFF2C2C2E);
  static const Color primaryTextDark = Color(0xFFF5F5F7);
  static const Color secondaryTextDark = Color(0xFF8E8E93);

  // Neutral / surfaces - light
  static const Color backgroundLight = Color(0xFFF2F2F7);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFE5E5EA);
  static const Color primaryTextLight = Color(0xFF000000);
  static const Color secondaryTextLight = Color(0xFF6C6C70);

  static final ColorScheme darkColorScheme = ColorScheme.dark(
    primary: systemBlue,
    secondary: systemTeal,
    tertiary: systemPurple,
    error: systemRed,
    surface: surfaceDark,
  ).copyWith(
    background: backgroundDark,
    onBackground: primaryTextDark,
    onSurface: primaryTextDark,
    onSurfaceVariant: secondaryTextDark,
    surfaceVariant: surfaceVariantDark,
    outline: const Color(0xFF3A3A3C),
    primaryContainer: const Color(0xFF0F62B7),
    onPrimaryContainer: primaryTextDark,
    secondaryContainer: const Color(0xFF124C54),
    onSecondaryContainer: primaryTextDark,
    tertiaryContainer: const Color(0xFF3D2A5B),
    onTertiaryContainer: primaryTextDark,
    errorContainer: const Color(0xFF5A1A17),
    onErrorContainer: primaryTextDark,
    inverseSurface: backgroundLight,
    onInverseSurface: primaryTextLight,
    inversePrimary: systemBlue,
  );

  static final ColorScheme lightColorScheme = ColorScheme.light(
    primary: systemBlue,
    secondary: systemTeal,
    tertiary: systemPurple,
    error: systemRed,
    surface: surfaceLight,
  ).copyWith(
    background: backgroundLight,
    onBackground: primaryTextLight,
    onSurface: primaryTextLight,
    onSurfaceVariant: secondaryTextLight,
    surfaceVariant: surfaceVariantLight,
    outline: const Color(0xFFC6C6C8),
    primaryContainer: const Color(0xFFDCEEFF),
    onPrimaryContainer: const Color(0xFF001F3D),
    secondaryContainer: const Color(0xFFD8F5F1),
    onSecondaryContainer: const Color(0xFF062B26),
    tertiaryContainer: const Color(0xFFF0E6FF),
    onTertiaryContainer: const Color(0xFF2B1D40),
    errorContainer: const Color(0xFFFFDAD6),
    onErrorContainer: const Color(0xFF410002),
    inverseSurface: backgroundDark,
    onInverseSurface: primaryTextDark,
    inversePrimary: systemBlue,
  );
}
