import 'package:flutter/material.dart';
import 'package:pylek/components/app_icons.dart';
import 'package:pylek/theme/apple_colors.dart';

class PollutantCardData {
  final String code;
  final String title;
  final String value;
  final String subtitle;
  final AppIconKind iconKind;
  final Color badgeForeground;
  final Color badgeBackground;

  const PollutantCardData({
    required this.code,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.iconKind,
    required this.badgeForeground,
    required this.badgeBackground,
  });
}

String formatPollutantUnit(String? unit) {
  switch (unit) {
    case 'MICROGRAMS_PER_CUBIC_METER':
      return 'µg/m³';
    case 'PARTS_PER_BILLION':
      return 'ppb';
    default:
      return '';
  }
}

Color pollutantColor(String code) {
  switch (code.toLowerCase()) {
    case 'pm25':
    case 'pm10':
      return AppColors.systemOrange;
    case 'o3':
      return AppColors.systemBlue;
    case 'no2':
      return AppColors.systemPurple;
    case 'so2':
      return AppColors.systemYellow;
    case 'co':
      return AppColors.secondaryTextLight;
    default:
      return AppColors.systemTeal;
  }
}

String _pollutantStatus(String code, num? rawValue, String? rawUnit) {
  if (rawValue == null || rawUnit == null || rawUnit.isEmpty) return '';

  final value = rawValue.toDouble();
  final normalizedCode = code.toLowerCase();

  if (rawUnit == 'MICROGRAMS_PER_CUBIC_METER') {
    switch (normalizedCode) {
      case 'pm25':
        if (value <= 12) return 'Dobre';
        if (value <= 35.4) return 'Umiarkowane';
        if (value <= 55.4) return 'Niezdrowe';
        return 'Zła';
      case 'pm10':
        if (value <= 54) return 'Dobre';
        if (value <= 154) return 'Umiarkowane';
        if (value <= 254) return 'Niezdrowe';
        return 'Zła';
    }
  }

  if (rawUnit == 'PARTS_PER_BILLION') {
    switch (normalizedCode) {
      case 'o3':
        if (value <= 54) return 'Dobre';
        if (value <= 70) return 'Umiarkowane';
        return 'Niezdrowe';
      case 'no2':
        if (value <= 53) return 'Dobre';
        if (value <= 100) return 'Umiarkowane';
        if (value <= 360) return 'Niezdrowe';
        return 'Zła';
      case 'so2':
        if (value <= 35) return 'Dobre';
        if (value <= 75) return 'Umiarkowane';
        if (value <= 185) return 'Niezdrowe';
        return 'Zła';
      case 'co':
        if (value <= 4400) return 'Dobre';
        if (value <= 9400) return 'Umiarkowane';
        if (value <= 12400) return 'Niezdrowe';
        return 'Zła';
    }
  }

  return '';
}

List<PollutantCardData> buildPollutantCards(List<dynamic> pollutants) {
  final cards = <PollutantCardData>[];

  for (final pollutant in pollutants) {
    if (pollutant is! Map) continue;

    final code = pollutant['code']?.toString() ?? '';
    final displayName = pollutant['displayName']?.toString() ?? code.toUpperCase();

    final concentration = pollutant['concentration'];
    if (concentration is! Map) continue;

    final rawValue = concentration['value'];
    final rawUnit = concentration['units']?.toString();
    final unit = formatPollutantUnit(rawUnit);

    final value = rawValue is num
        ? rawValue.toStringAsFixed(rawValue >= 10 ? 0 : 1)
        : '—';

    final color = pollutantColor(code);
    final subtitle = _pollutantStatus(code, rawValue, rawUnit);

    cards.add(
      PollutantCardData(
        code: code,
        title: displayName,
        value: '$value $unit',
        subtitle: subtitle,
        iconKind: AppIconKind.air,
        badgeForeground: color,
        badgeBackground: color.withOpacity(0.14),
      ),
    );
  }

  const priority = ['pm25', 'pm10', 'o3', 'no2', 'so2', 'co'];

  cards.sort((a, b) {
    final ai = priority.indexOf(a.code.toLowerCase());
    final bi = priority.indexOf(b.code.toLowerCase());

    return (ai == -1 ? 999 : ai).compareTo(bi == -1 ? 999 : bi);
  });

  return cards;
}