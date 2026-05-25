import 'package:flutter/material.dart';
import 'package:pylek/components/app_icons.dart';
import 'package:pylek/theme/apple_colors.dart';

// Helpers for personalizing the Home screen pollen card from onboarding
// selections and Google Pollen API responses.

const Map<String, List<String>> allergenPlantCodes = {
  'Brzoza': ['BIRCH'],
  'Dąb': ['OAK'],
  'Jesion': ['ASH'],
  'Leszczyna': ['HAZEL'],
  'Olcha': ['ALDER'],
  'Oliwka': ['OLIVE'],
  'Sosna': ['PINE'],
  'Topola': ['COTTONWOOD'],
  'Trawy (ogólnie)': ['GRAMINALES'],
  'Trawy': ['GRAMINALES'],
  'Ambrozja': ['RAGWEED'],
  'Bylica': ['MUGWORT'],
};

const List<String> polishMonthNames = [
  'stycznia',
  'lutego',
  'marca',
  'kwietnia',
  'maja',
  'czerwca',
  'lipca',
  'sierpnia',
  'września',
  'października',
  'listopada',
  'grudnia',
];

class PollenCardResult {
  final String valueLabel;
  final String subtitle;
  final int colorScore;

  const PollenCardResult({
    required this.valueLabel,
    required this.subtitle,
    required this.colorScore,
  });
}

class AllergenPollenCardData {
  final String name;
  final String valueLabel;
  final int colorScore;
  final AppIconKind iconKind;
  final Color badgeForeground;
  final Color badgeBackground;
  final String? upiLabel;

  const AllergenPollenCardData({
    required this.name,
    required this.valueLabel,
    required this.colorScore,
    required this.iconKind,
    required this.badgeForeground,
    required this.badgeBackground,
    this.upiLabel,
  });
}

int _compareAllergenCardPriority(AllergenPollenCardData left, AllergenPollenCardData right) {
  final scoreComparison = right.colorScore.compareTo(left.colorScore);
  if (scoreComparison != 0) {
    return scoreComparison;
  }

  return left.name.compareTo(right.name);
}

String formatPollenFetchDate(dynamic rawValue) {
  if (rawValue == null) {
    return '';
  }

  final parsed = rawValue is DateTime
      ? rawValue
      : DateTime.tryParse(rawValue.toString().replaceFirst(' ', 'T'));

  if (parsed == null) {
    return '';
  }

  final local = parsed.toLocal();
  final monthName = polishMonthNames[local.month - 1];

  return '${local.day} $monthName';
}

String pollenLabelFromApiValue(int value) {
  switch (value) {
    case 0:
      return 'Brak pylenia';
    case 1:
      return 'Bardzo niskie';
    case 2:
      return 'Niskie';
    case 3:
      return 'Umiarkowane';
    case 4:
      return 'Wysokie';
    case 5:
      return 'Bardzo wysokie';
    default:
      return 'Brak danych';
  }
}

String categoryToPolishLabel(String? category, int value) {
  if (category != null && category.trim().isNotEmpty) {
    final normalized = category.trim().toLowerCase();

    if (normalized == 'none' || normalized.contains('brak')) {
      return 'Brak pylenia';
    }
    if (normalized.contains('very low') ||
        normalized.contains('bardzo nisk')) {
      return 'Bardzo niskie';
    }
    if (normalized == 'low' ||
        normalized == 'niski' ||
        normalized == 'niskie') {
      return 'Niskie';
    }
    if (normalized.contains('moderate') ||
        normalized.contains('umiark')) {
      return 'Umiarkowane';
    }
    if (normalized == 'high' ||
        normalized == 'wysoki' ||
        normalized == 'wysokie') {
      return 'Wysokie';
    }
    if (normalized.contains('very high') ||
        normalized.contains('bardzo wysok')) {
      return 'Bardzo wysokie';
    }

    return category;
  }

  return pollenLabelFromApiValue(value);
}

int colorScoreFromApiValue(int value) {
  if (value <= 0) {
    return 0;
  }

  return ((value / 5) * 100).round().clamp(0, 100);
}

int colorScoreFromNormalizedUpi(int normalized) {
  return normalized.clamp(0, 100);
}

Color pollenSeverityColor(int colorScore) {
  if (colorScore <= 0) return AppColors.systemGray;
  if (colorScore <= 20) return AppColors.systemGreenLight;
  if (colorScore <= 40) return AppColors.systemGreen;
  if (colorScore <= 60) return AppColors.systemOrange;
  if (colorScore <= 80) return AppColors.systemRed;
  return AppColors.systemRedDark;
}

Set<String> _plantCodesForSelections(List<String> selectedAllergens) {
  final codes = <String>{};

  for (final allergen in selectedAllergens) {
    final mapped = allergenPlantCodes[allergen];
    if (mapped != null) {
      codes.addAll(mapped);
    }
  }

  return codes;
}

bool _selectionIncludesGrasses(List<String> selectedAllergens) {
  return selectedAllergens.any(
    (name) => name == 'Trawy (ogólnie)' || name == 'Trawy',
  );
}

bool _matchesDisplayName(String selectedAllergen, String apiDisplayName) {
  final api = apiDisplayName.toLowerCase();
  final selected = selectedAllergen.toLowerCase();

  if (api.contains(selected) || selected.contains(api)) {
    return true;
  }

  final codes = allergenPlantCodes[selectedAllergen];
  if (codes == null) {
    return false;
  }

  return codes.any((code) => api.contains(code.toLowerCase().replaceAll('_', ' ')));
}

bool _plantMatchesSelection(
  Map<dynamic, dynamic> plant,
  List<String> selectedAllergens,
  Set<String> selectedPlantCodes,
) {
  final code = (plant['code'] as String?)?.toUpperCase();
  if (code != null && selectedPlantCodes.contains(code)) {
    return true;
  }

  final displayName = plant['displayName'] as String? ?? '';

  for (final allergen in selectedAllergens) {
    if (_matchesDisplayName(allergen, displayName)) {
      return true;
    }
  }

  return false;
}

bool _pollenTypeMatchesSelection(
  Map<dynamic, dynamic> pollenType,
  List<String> selectedAllergens,
) {
  final code = (pollenType['code'] as String?)?.toUpperCase() ?? '';

  if (code == 'GRASS' && _selectionIncludesGrasses(selectedAllergens)) {
    return true;
  }

  return false;
}

int? _readIndexValue(dynamic indexInfo) {
  if (indexInfo is! Map) {
    return null;
  }

  final value = indexInfo['value'];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }

  return null;
}

String _readIndexLabel(dynamic indexInfo, int value) {
  if (indexInfo is Map) {
    final category = indexInfo['category'] as String?;
    return categoryToPolishLabel(category, value);
  }

  return pollenLabelFromApiValue(value);
}

PollenCardResult computeGenericPollenCard(List<dynamic> pollenTypes) {
  var total = 0;
  var count = 0;

  for (final type in pollenTypes) {
    if (type is! Map) {
      continue;
    }

    final value = _readIndexValue(type['indexInfo']);
    if (value != null) {
      total += value;
      count++;
    }
  }

  final normalized = count == 0 ? 0 : ((total / (count * 5)) * 100).round();

  return PollenCardResult(
    valueLabel: _genericUpiLabel(normalized),
    subtitle: '$normalized w skali UPI',
    colorScore: colorScoreFromNormalizedUpi(normalized),
  );
}

String _genericUpiLabel(int value) {
  if (value <= 20) {
    return 'Bardzo niskie';
  } else if (value <= 40) {
    return 'Niskie';
  } else if (value <= 60) {
    return 'Umiarkowane';
  } else if (value <= 80) {
    return 'Wysokie';
  } else {
    return 'Bardzo wysokie';
  }
}

PollenCardResult computePersonalizedPollenCard({
  required List<dynamic> pollenTypes,
  required List<dynamic> plants,
  required List<String> selectedAllergens,
}) {
  if (selectedAllergens.isEmpty) {
    return computeGenericPollenCard(pollenTypes);
  }

  final selectedPlantCodes = _plantCodesForSelections(selectedAllergens);
  final matches = <({int value, String label})>[];

  for (final plant in plants) {
    if (plant is! Map) {
      continue;
    }

    if (!_plantMatchesSelection(plant, selectedAllergens, selectedPlantCodes)) {
      continue;
    }

    final value = _readIndexValue(plant['indexInfo']);
    if (value == null) {
      continue;
    }

    matches.add((
      value: value,
      label: _readIndexLabel(plant['indexInfo'], value),
    ));
  }

  for (final pollenType in pollenTypes) {
    if (pollenType is! Map) {
      continue;
    }

    if (!_pollenTypeMatchesSelection(pollenType, selectedAllergens)) {
      continue;
    }

    final value = _readIndexValue(pollenType['indexInfo']);
    if (value == null) {
      continue;
    }

    matches.add((
      value: value,
      label: _readIndexLabel(pollenType['indexInfo'], value),
    ));
  }

  if (matches.isEmpty || matches.every((match) => match.value <= 0)) {
    return const PollenCardResult(
      valueLabel: 'Żaden z Twoich alergenów nie pyli',
      subtitle: 'Brak pylenia wybranych alergenów',
      colorScore: 0,
    );
  }

  final worst = matches.reduce(
    (current, candidate) =>
        candidate.value > current.value ? candidate : current,
  );

  return PollenCardResult(
    valueLabel: worst.label,
    subtitle: '${worst.value} w skali UPI',
    colorScore: colorScoreFromApiValue(worst.value),
  );
}

PollenCardResult resolvePollenCard({
  required List<dynamic> pollenTypes,
  required List<dynamic> plants,
  required List<String> selectedAllergens,
}) {
  if (selectedAllergens.isEmpty) {
    return computeGenericPollenCard(pollenTypes);
  }

  return computePersonalizedPollenCard(
    pollenTypes: pollenTypes,
    plants: plants,
    selectedAllergens: selectedAllergens,
  );
}

bool _plantMatchesAllergen(Map<dynamic, dynamic> plant, String allergen) {
  final codes = allergenPlantCodes[allergen] ?? <String>[];
  final code = (plant['code'] as String?)?.toUpperCase();

  if (code != null && codes.contains(code)) {
    return true;
  }

  final displayName = plant['displayName'] as String? ?? '';
  return _matchesDisplayName(allergen, displayName);
}

bool _pollenTypeMatchesAllergen(
  Map<dynamic, dynamic> pollenType,
  String allergen,
) {
  final code = (pollenType['code'] as String?)?.toUpperCase() ?? '';

  if (code == 'GRASS' &&
      (allergen == 'Trawy (ogólnie)' || allergen == 'Trawy')) {
    return true;
  }

  return false;
}

({
  AppIconKind icon,
  Color badgeForeground,
  Color badgeBackground,
}) allergenVisualStyle(String allergen) {
  if (allergen == 'Trawy (ogólnie)' || allergen == 'Trawy') {
    return (
      icon: AppIconKind.grass,
      badgeForeground: AppColors.systemGreenLight,
      badgeBackground: AppColors.systemGreenLight.withOpacity(0.22),
    );
  }

  if (allergen == 'Ambrozja' || allergen == 'Bylica') {
    return (
      icon: AppIconKind.grass,
      badgeForeground: AppColors.systemGreenLight,
      badgeBackground: AppColors.systemGreenLight.withOpacity(0.22),
    );
  }

  return (
    icon: AppIconKind.tree,
    badgeForeground: AppColors.systemGreen,
    badgeBackground: AppColors.systemGreen.withOpacity(0.22),
  );
}

AllergenPollenCardData resolveAllergenPollenCard({
  required String allergen,
  required List<dynamic> pollenTypes,
  required List<dynamic> plants,
}) {
  final style = allergenVisualStyle(allergen);

  for (final plant in plants) {
    if (plant is! Map) {
      continue;
    }

    if (!_plantMatchesAllergen(plant, allergen)) {
      continue;
    }

    final value = _readIndexValue(plant['indexInfo']);
    if (value == null) {
      break;
    }

    return AllergenPollenCardData(
      name: allergen,
      valueLabel: _readIndexLabel(plant['indexInfo'], value),
      colorScore: colorScoreFromApiValue(value),
      iconKind: style.icon,
      badgeForeground: style.badgeForeground,
      badgeBackground: style.badgeBackground,
      upiLabel: '$value w skali UPI',
    );
  }

  if (allergen == 'Trawy (ogólnie)' || allergen == 'Trawy') {
    for (final pollenType in pollenTypes) {
      if (pollenType is! Map) {
        continue;
      }

      if (!_pollenTypeMatchesAllergen(pollenType, allergen)) {
        continue;
      }

      final value = _readIndexValue(pollenType['indexInfo']);
      if (value == null) {
        break;
      }

      return AllergenPollenCardData(
        name: allergen,
        valueLabel: _readIndexLabel(pollenType['indexInfo'], value),
        colorScore: colorScoreFromApiValue(value),
        iconKind: style.icon,
        badgeForeground: style.badgeForeground,
        badgeBackground: style.badgeBackground,
        upiLabel: '$value w skali UPI',
      );
    }
  }

  return AllergenPollenCardData(
    name: allergen,
    valueLabel: 'Nie pyli',
    colorScore: 0,
    iconKind: style.icon,
    badgeForeground: style.badgeForeground,
    badgeBackground: style.badgeBackground,
    upiLabel: '0 w skali UPI',
  );
}

List<AllergenPollenCardData> buildSelectedAllergenCards({
  required List<String> selectedAllergens,
  required List<dynamic> pollenTypes,
  required List<dynamic> plants,
}) {
  final cards = selectedAllergens
      .map(
        (allergen) => resolveAllergenPollenCard(
          allergen: allergen,
          pollenTypes: pollenTypes,
          plants: plants,
        ),
      )
      .toList();

  cards.sort(_compareAllergenCardPriority);
  return cards;
}
