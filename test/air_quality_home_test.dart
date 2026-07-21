import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pylek/components/app_icons.dart';
import 'package:pylek/theme/apple_colors.dart';
import 'package:pylek/utils/air_quality_home.dart';

void main() {
  group('formatPollutantUnit', () {
    test('returns µg/m³ for MICROGRAMS_PER_CUBIC_METER', () {
      expect(formatPollutantUnit('MICROGRAMS_PER_CUBIC_METER'), 'µg/m³');
    });

    test('returns ppb for PARTS_PER_BILLION', () {
      expect(formatPollutantUnit('PARTS_PER_BILLION'), 'ppb');
    });

    test('returns empty string for unknown unit', () {
      expect(formatPollutantUnit(null), '');
      expect(formatPollutantUnit(''), '');
      expect(formatPollutantUnit('PERCENT'), '');
    });
  });

  group('pollutantColor', () {
    test('returns orange for PM2.5 and PM10', () {
      expect(pollutantColor('pm25'), AppColors.systemOrange);
      expect(pollutantColor('pm10'), AppColors.systemOrange);
      expect(pollutantColor('PM25'), AppColors.systemOrange);
    });

    test('returns blue for O3', () {
      expect(pollutantColor('o3'), AppColors.systemBlue);
      expect(pollutantColor('O3'), AppColors.systemBlue);
    });

    test('returns purple for NO2', () {
      expect(pollutantColor('no2'), AppColors.systemPurple);
    });

    test('returns yellow for SO2', () {
      expect(pollutantColor('so2'), AppColors.systemYellow);
    });

    test('returns teal for unknown code', () {
      expect(pollutantColor('unknown'), AppColors.systemTeal);
    });
  });

  group('buildPollutantCards', () {
    test('returns empty list for empty input', () {
      expect(buildPollutantCards([]), isEmpty);
    });

    test('ignores non-map pollutants', () {
      final cards = buildPollutantCards(['not a map', 42]);
      expect(cards, isEmpty);
    });

    test('builds card with correct values', () {
      final cards = buildPollutantCards([
        {
          'code': 'pm25',
          'displayName': 'PM2.5',
          'concentration': {
            'value': 5.5,
            'units': 'MICROGRAMS_PER_CUBIC_METER',
          },
        },
      ]);

      expect(cards.length, 1);
      expect(cards[0].code, 'pm25');
      expect(cards[0].title, 'PM2.5');
      expect(cards[0].value, '5.5 µg/m³');
      expect(cards[0].subtitle, 'Dobre');
      expect(cards[0].iconKind, AppIconKind.air);
    });

    test('sorts by priority order', () {
      final cards = buildPollutantCards([
        {
          'code': 'co',
          'displayName': 'CO',
          'concentration': {'value': 1, 'units': 'PARTS_PER_BILLION'},
        },
        {
          'code': 'pm25',
          'displayName': 'PM2.5',
          'concentration': {'value': 5, 'units': 'MICROGRAMS_PER_CUBIC_METER'},
        },
        {
          'code': 'o3',
          'displayName': 'O3',
          'concentration': {'value': 20, 'units': 'PARTS_PER_BILLION'},
        },
      ]);

      expect(cards.length, 3);
      expect(cards[0].code, 'pm25');
      expect(cards[1].code, 'o3');
      expect(cards[2].code, 'co');
    });

    test('handles missing concentration gracefully', () {
      final cards = buildPollutantCards([
        {
          'code': 'pm25',
          'displayName': 'PM2.5',
        },
      ]);
      expect(cards, isEmpty);
    });

    test('formats value with 0 decimal places when >= 10', () {
      final cards = buildPollutantCards([
        {
          'code': 'pm25',
          'displayName': 'PM25',
          'concentration': {
            'value': 12.345,
            'units': 'MICROGRAMS_PER_CUBIC_METER',
          },
        },
      ]);
      expect(cards[0].value, '12 µg/m³');
    });

    group('_pollutantStatus - PM2.5 thresholds', () {
      test('Dobre <= 12', () {
        final cards = buildPollutantCards([
          {
            'code': 'pm25',
            'displayName': 'PM2.5',
            'concentration': {
              'value': 12,
              'units': 'MICROGRAMS_PER_CUBIC_METER',
            },
          },
        ]);
        expect(cards[0].subtitle, 'Dobre');
      });

      test('Umiarkowane <= 35.4', () {
        final cards = buildPollutantCards([
          {
            'code': 'pm25',
            'displayName': 'PM2.5',
            'concentration': {
              'value': 35.4,
              'units': 'MICROGRAMS_PER_CUBIC_METER',
            },
          },
        ]);
        expect(cards[0].subtitle, 'Umiarkowane');
      });

      test('Zła above 55.4', () {
        final cards = buildPollutantCards([
          {
            'code': 'pm25',
            'displayName': 'PM2.5',
            'concentration': {
              'value': 60,
              'units': 'MICROGRAMS_PER_CUBIC_METER',
            },
          },
        ]);
        expect(cards[0].subtitle, 'Zła');
      });
    });

    group('_pollutantStatus - O3 thresholds', () {
      test('Dobre <= 54', () {
        final cards = buildPollutantCards([
          {
            'code': 'o3',
            'displayName': 'O3',
            'concentration': {
              'value': 50,
              'units': 'PARTS_PER_BILLION',
            },
          },
        ]);
        expect(cards[0].subtitle, 'Dobre');
      });

      test('Niezdrowe > 70', () {
        final cards = buildPollutantCards([
          {
            'code': 'o3',
            'displayName': 'O3',
            'concentration': {
              'value': 100,
              'units': 'PARTS_PER_BILLION',
            },
          },
        ]);
        expect(cards[0].subtitle, 'Niezdrowe');
      });
    });

    group('_pollutantStatus - NO2 thresholds', () {
      test('Dobre <= 53', () {
        final cards = buildPollutantCards([
          {
            'code': 'no2',
            'displayName': 'NO2',
            'concentration': {
              'value': 53,
              'units': 'PARTS_PER_BILLION',
            },
          },
        ]);
        expect(cards[0].subtitle, 'Dobre');
      });

      test('Zła above 360', () {
        final cards = buildPollutantCards([
          {
            'code': 'no2',
            'displayName': 'NO2',
            'concentration': {
              'value': 500,
              'units': 'PARTS_PER_BILLION',
            },
          },
        ]);
        expect(cards[0].subtitle, 'Zła');
      });
    });
  });
}
