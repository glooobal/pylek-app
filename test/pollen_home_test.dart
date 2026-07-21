import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pylek/components/app_icons.dart';
import 'package:pylek/utils/pollen_home.dart';

void main() {
  group('resolveInsightSeverity', () {
    test('returns none for 0', () {
      expect(resolveInsightSeverity(0), InsightSeverity.none);
    });

    test('returns veryLow for scores 1-20', () {
      expect(resolveInsightSeverity(1), InsightSeverity.veryLow);
      expect(resolveInsightSeverity(20), InsightSeverity.veryLow);
    });

    test('returns low for scores 21-40', () {
      expect(resolveInsightSeverity(21), InsightSeverity.low);
      expect(resolveInsightSeverity(40), InsightSeverity.low);
    });

    test('returns moderate for scores 41-60', () {
      expect(resolveInsightSeverity(41), InsightSeverity.moderate);
      expect(resolveInsightSeverity(60), InsightSeverity.moderate);
    });

    test('returns high for scores 61-80', () {
      expect(resolveInsightSeverity(61), InsightSeverity.high);
      expect(resolveInsightSeverity(80), InsightSeverity.high);
    });

    test('returns veryHigh for scores 81-100', () {
      expect(resolveInsightSeverity(81), InsightSeverity.veryHigh);
      expect(resolveInsightSeverity(100), InsightSeverity.veryHigh);
    });
  });

  group('pollenLabelFromApiValue', () {
    test('returns correct label for each value', () {
      expect(pollenLabelFromApiValue(0), 'Brak pylenia');
      expect(pollenLabelFromApiValue(1), 'Bardzo niskie');
      expect(pollenLabelFromApiValue(2), 'Niskie');
      expect(pollenLabelFromApiValue(3), 'Umiarkowane');
      expect(pollenLabelFromApiValue(4), 'Wysokie');
      expect(pollenLabelFromApiValue(5), 'Bardzo wysokie');
      expect(pollenLabelFromApiValue(999), 'Brak danych');
    });
  });

  group('categoryToPolishLabel', () {
    test('returns correct label for English categories', () {
      expect(categoryToPolishLabel('None', 0), 'Brak pylenia');
      expect(categoryToPolishLabel('Very Low', 1), 'Bardzo niskie');
      expect(categoryToPolishLabel('Low', 2), 'Niskie');
      expect(categoryToPolishLabel('Moderate', 3), 'Umiarkowane');
      expect(categoryToPolishLabel('High', 4), 'Wysokie');
      expect(categoryToPolishLabel('Very High', 5), 'Bardzo wysokie');
    });

    test('returns correct label for Polish categories', () {
      expect(categoryToPolishLabel('Brak', 0), 'Brak pylenia');
      expect(categoryToPolishLabel('bardzo niskie', 1), 'Bardzo niskie');
      expect(categoryToPolishLabel('niskie', 2), 'Niskie');
      expect(categoryToPolishLabel('umiarkowane', 3), 'Umiarkowane');
      expect(categoryToPolishLabel('wysokie', 4), 'Wysokie');
      expect(categoryToPolishLabel('bardzo wysokie', 5), 'Bardzo wysokie');
    });

    test('falls back to api value when category is null or empty', () {
      expect(categoryToPolishLabel(null, 3), 'Umiarkowane');
      expect(categoryToPolishLabel('', 3), 'Umiarkowane');
    });
  });

  group('colorScoreFromApiValue', () {
    test('returns 0 for value 0', () {
      expect(colorScoreFromApiValue(0), 0);
    });

    test('calculates percentage correctly', () {
      expect(colorScoreFromApiValue(1), 20);
      expect(colorScoreFromApiValue(2), 40);
      expect(colorScoreFromApiValue(3), 60);
      expect(colorScoreFromApiValue(4), 80);
      expect(colorScoreFromApiValue(5), 100);
    });

    test('clamps value to 0-100 range', () {
      expect(colorScoreFromApiValue(-1), 0);
    });
  });

  group('resolvePollenCard', () {
    test('returns generic card when no allergens selected', () {
      final result = resolvePollenCard(
        pollenTypes: [],
        plants: [],
        selectedAllergens: [],
      );
      expect(result.valueLabel, 'Bardzo niskie');
      expect(result.colorScore, 0);
    });

    test('returns personalized card when allergens are selected but no matches',
        () {
      final result = resolvePollenCard(
        pollenTypes: [],
        plants: [],
        selectedAllergens: ['Brzoza'],
      );
      expect(result.valueLabel, 'Żaden z Twoich alergenów nie pyli');
      expect(result.colorScore, 0);
    });

    test('returns worst match for selected allergens', () {
      final result = resolvePollenCard(
        pollenTypes: [],
        plants: [
          {
            'code': 'BIRCH',
            'displayName': 'Brzoza',
            'indexInfo': {'value': 4, 'category': 'High'},
          },
        ],
        selectedAllergens: ['Brzoza'],
      );
      expect(result.valueLabel, 'Wysokie');
      expect(result.colorScore, 80);
    });
  });

  group('buildInsightDescription', () {
    test('returns no symptoms message for score 0', () {
      final result = buildInsightDescription(0, [], [], []);
      expect(result, 'Nie powinieneś czuć objawów alergii');
    });

    test('returns top allergens at moderate+ severity', () {
      final result = buildInsightDescription(60, [], [
        {
          'code': 'BIRCH',
          'displayName': 'Brzoza',
          'indexInfo': {'value': 3, 'category': 'Moderate'},
        },
      ], ['Brzoza']);
      expect(result, 'Najsilniej pylą brzoza.');
    });
  });

  group('buildInsightRecommendation', () {
    test('returns outdoor activity for none/veryLow', () {
      expect(
        buildInsightRecommendation(0),
        'To dobry dzień na aktywność na świeżym powietrzu.',
      );
      expect(
        buildInsightRecommendation(20),
        'To dobry dzień na aktywność na świeżym powietrzu.',
      );
    });

    test('returns limit outdoors for moderate', () {
      expect(
        buildInsightRecommendation(50),
        'Warto ograniczyć dłuższy pobyt na zewnątrz.',
      );
    });

    test('returns wash advice for high', () {
      expect(
        buildInsightRecommendation(70),
        'Po powrocie do domu warto umyć włosy i twarz.',
      );
    });
  });

  group('formatPollenFetchDate', () {
    test('returns empty string for null', () {
      expect(formatPollenFetchDate(null), '');
    });

    test('formats DateTime correctly', () {
      final dt = DateTime(2026, 7, 21);
      expect(formatPollenFetchDate(dt), '21 lipca');
    });

    test('parses ISO string', () {
      expect(formatPollenFetchDate('2026-07-21 10:00:00'), '21 lipca');
    });
  });

  group('allergenVisualStyle', () {
    test('returns grass icon for trawy', () {
      final style = allergenVisualStyle('Trawy');
      expect(style.icon, AppIconKind.grass);
    });

    test('returns tree icon for drzewa', () {
      final style = allergenVisualStyle('Brzoza');
      expect(style.icon, AppIconKind.tree);
    });
  });

  group('buildSelectedAllergenCards', () {
    test('returns sorted list by score descending', () {
      final cards = buildSelectedAllergenCards(
        selectedAllergens: ['Brzoza', 'Dąb'],
        pollenTypes: [],
        plants: [
          {
            'code': 'BIRCH',
            'displayName': 'Brzoza',
            'indexInfo': {'value': 2, 'category': 'Low'},
          },
          {
            'code': 'OAK',
            'displayName': 'Dąb',
            'indexInfo': {'value': 4, 'category': 'High'},
          },
        ],
      );
      expect(cards.length, 2);
      expect(cards[0].name, 'Dąb');
      expect(cards[1].name, 'Brzoza');
    });
  });

  group('colorScoreFromNormalizedUpi', () {
    test('clamps to 0-100', () {
      expect(colorScoreFromNormalizedUpi(-10), 0);
      expect(colorScoreFromNormalizedUpi(50), 50);
      expect(colorScoreFromNormalizedUpi(150), 100);
    });
  });
}
