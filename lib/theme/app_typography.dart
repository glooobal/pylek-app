import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const String iosFontFamily = '.SF Pro Text';
  static const String androidFontFamily = 'Roboto';

  static String? fontFamilyFor(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return iosFontFamily;
      case TargetPlatform.android:
        return androidFontFamily;
      default:
        return null;
    }
  }

  static TextTheme applyPlatformFont(TextTheme base, TargetPlatform platform) {
    final family = fontFamilyFor(platform);
    if (family == null) {
      return base;
    }

    return base.apply(fontFamily: family);
  }
}
