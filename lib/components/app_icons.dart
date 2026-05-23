import 'package:flutter/material.dart';
import 'package:flutter_sfsymbols/flutter_sfsymbols.dart';

enum AppIconKind {
  air,
  alerts,
  checkMark,
  chevronLeft,
  chevronRight,
  circle,
  feedback,
  forecast,
  home,
  journal,
  location,
  locationCity,
  grass,
  mail,
  myLocation,
  search,
  settings,
  tree,
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
      case AppIconKind.checkMark:
        return SFSymbols.checkmark;
      case AppIconKind.chevronLeft:
        return SFSymbols.chevron_left;
      case AppIconKind.chevronRight:
        return SFSymbols.chevron_right;
      case AppIconKind.circle:
        return SFSymbols.circle;
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
        return Icons.grass_rounded;
      case AppIconKind.mail:
        return SFSymbols.envelope_fill;
      case AppIconKind.myLocation:
        return SFSymbols.location_north_fill;
      case AppIconKind.search:
        return SFSymbols.search;
      case AppIconKind.settings:
        return SFSymbols.gear;
      case AppIconKind.tree:
        return SFSymbols.tree;
    }
  }

  static IconData _materialIcons(AppIconKind kind) {
    switch (kind) {
      case AppIconKind.air:
        return Icons.air_rounded;
      case AppIconKind.alerts:
        return Icons.notifications_active_rounded;
      case AppIconKind.checkMark:
        return Icons.check_rounded;
      case AppIconKind.chevronLeft:
        return Icons.chevron_left_rounded;
      case AppIconKind.chevronRight:
        return Icons.chevron_right_rounded;
      case AppIconKind.circle:
        return Icons.circle_outlined;
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
      case AppIconKind.search:
        return Icons.search_rounded;
      case AppIconKind.settings:
        return Icons.settings_rounded;
      case AppIconKind.tree:
        return Icons.park_rounded;
    }
  }
}