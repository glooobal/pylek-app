import 'package:flutter/material.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';

enum AppIconKind {
  air,
  alerts,
  chevronRight,
  feedback,
  forecast,
  home,
  journal,
  location,
  locationCity,
  grass,
  mail,
  myLocation,
  settings,
}

class AppIcons {
  AppIcons._();

  static bool _usesSfSymbols(BuildContext context) {
    final platform = Theme.of(context).platform;
    return platform == TargetPlatform.iOS || platform == TargetPlatform.macOS;
  }

  static IconData of(BuildContext context, AppIconKind kind) {
    return _usesSfSymbols(context)
        ? _sfSymbols(kind)
        : _materialIcons(kind);
  }

  static IconData _sfSymbols(AppIconKind kind) {
    switch (kind) {
      case AppIconKind.air:
        return SFSymbols.wind;
      case AppIconKind.alerts:
        return SFSymbols.bell_fill;
      case AppIconKind.chevronRight:
        return SFSymbols.chevron_right;
      case AppIconKind.feedback:
        return SFSymbols.square_pencil;
      case AppIconKind.forecast:
        return SFSymbols.cloud_fill;
      case AppIconKind.home:
        return SFSymbols.house_fill;
      case AppIconKind.journal:
        return SFSymbols.book_fill;
      case AppIconKind.location:
        return SFSymbols.location_fill;
      case AppIconKind.locationCity:
        return SFSymbols.location_fill;
      case AppIconKind.grass:
        return SFSymbols.tree;
      case AppIconKind.mail:
        return SFSymbols.envelope_fill;
      case AppIconKind.myLocation:
        return SFSymbols.location_north_fill;
      case AppIconKind.settings:
        return SFSymbols.gear;
    }
  }

  static IconData _materialIcons(AppIconKind kind) {
    switch (kind) {
      case AppIconKind.air:
        return Icons.air_rounded;
      case AppIconKind.alerts:
        return Icons.notifications_active_rounded;
      case AppIconKind.chevronRight:
        return Icons.chevron_right_rounded;
      case AppIconKind.feedback:
        return Icons.feedback_rounded;
      case AppIconKind.forecast:
        return Icons.cloud_rounded;
      case AppIconKind.home:
        return Icons.home_rounded;
      case AppIconKind.journal:
        return Icons.menu_book_rounded;
      case AppIconKind.location:
        return Icons.location_on_rounded;
      case AppIconKind.locationCity:
        return Icons.location_city_rounded;
      case AppIconKind.grass:
        return Icons.grass_rounded;
      case AppIconKind.mail:
        return Icons.mail_rounded;
      case AppIconKind.myLocation:
        return Icons.my_location_rounded;
      case AppIconKind.settings:
        return Icons.settings_rounded;
    }
  }
}