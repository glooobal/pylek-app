import 'package:flutter/material.dart';
import 'package:pylek/components/app_icons.dart';
import 'package:pylek/theme/apple_colors.dart';

const List<String> severityLevels = [
  'Brak',
  'Lekkie',
  'Umiarkowane',
  'Silne',
];

const List<String> symptomsList = [
  'Katar',
  'Kichanie',
  'Zatkany nos',
  'Łzawienie oczu',
  'Ból gardła',
  'Suchy kaszel',
  'Mokry kaszel',
  'Duszności',
  'Zmęczenie',
  'Ból głowy',
  'Ból brzucha',
  'Swędzenie skóry',
  'Pokrzywka',
  'Wysypka',
];

const List<String> monthNames = [
  'stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca',
  'lipca', 'sierpnia', 'września', 'października', 'listopada', 'grudnia',
];

Color severityColor(int level) {
  switch (level) {
    case 0:
      return AppColors.systemGreen;
    case 1:
      return AppColors.systemGreenLight;
    case 2:
      return AppColors.systemOrange;
    case 3:
      return AppColors.systemRed;
    default:
      return AppColors.systemGray;
  }
}

AppIconKind severityIcon(int level) {
  if (level <= 1) return AppIconKind.faceSmiling;
  if (level == 2) return AppIconKind.faceNeutral;
  return AppIconKind.faceFrowning;
}

String severityLabel(int level) {
  if (level >= 0 && level < severityLevels.length) {
    return severityLevels[level];
  }
  return '';
}

String formatDate(String isoDate) {
  final parts = isoDate.split('-');
  if (parts.length != 3) return isoDate;
  return '${int.parse(parts[2])} ${monthNames[int.parse(parts[1]) - 1]} ${parts[0]}';
}
