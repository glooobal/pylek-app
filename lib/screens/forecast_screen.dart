import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pylek/theme/apple_colors.dart';
import 'package:pylek/components/app_icons.dart';
import 'package:pylek/components/insight_card.dart';
import 'package:pylek/components/small_card.dart';
import 'package:pylek/utils/allergen_data.dart';
import 'package:pylek/utils/pollen_home.dart';
import 'package:pylek/utils/data_cache.dart';
import 'package:pylek/utils/location_utils.dart';

const List<String> _weekdayNames = [
  'poniedziałek', 'wtorek', 'środa', 'czwartek', 'piątek', 'sobota', 'niedziela',
];

const List<String> _monthNames = [
  'stycznia', 'lutego', 'marca', 'kwietnia', 'maja', 'czerwca',
  'lipca', 'sierpnia', 'września', 'października', 'listopada', 'grudnia',
];

String _capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

DateTime _parseDayDate(dynamic day) {
  if (day is! Map<String, dynamic>) return DateTime.now();
  final d = day['date'];
  if (d is! Map) return DateTime.now();
  final year = d['year'];
  final month = d['month'];
  final dayOfMonth = d['day'];
  if (year is! int || month is! int || dayOfMonth is! int) return DateTime.now();
  return DateTime(year, month, dayOfMonth);
}

String _weekdayName(DateTime dt) {
  return _weekdayNames[dt.weekday - 1];
}

String _formatDate(DateTime dt) {
  return '${dt.day} ${_monthNames[dt.month - 1]}';
}

String _severityLabel(int score) {
  switch (resolveInsightSeverity(score)) {
    case InsightSeverity.none:
      return 'Brak pylenia';
    case InsightSeverity.veryLow:
      return 'Bardzo niskie';
    case InsightSeverity.low:
      return 'Niskie';
    case InsightSeverity.moderate:
      return 'Umiarkowane';
    case InsightSeverity.high:
      return 'Wysokie';
    case InsightSeverity.veryHigh:
      return 'Bardzo wysokie';
  }
}

({int maxScore}) _dayPersonalizedForecast(
  dynamic day,
  List<String> allergensToShow,
) {
  final pollenTypes = day['pollenTypeInfo'] ?? [];
  final plants = day['plantInfo'] ?? [];

  final cards = buildSelectedAllergenCards(
    selectedAllergens: allergensToShow,
    pollenTypes: pollenTypes,
    plants: plants,
  );

  final maxScore = cards.isEmpty
      ? 0
      : cards.map((c) => c.colorScore).reduce((a, b) => a > b ? a : b);

  return (maxScore: maxScore);
}

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  final _client = Supabase.instance.client;

  bool loading = true;
  String? error;
  bool _locationFallback = false;
  String cityName = 'Twoja lokalizacja';

  List<dynamic> dailyInfo = [];
  List<String> selectedAllergens = [];
  int selectedDayIndex = 0;

  @override
  void initState() {
    super.initState();
    init();
  }

  Future<void> init() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await _fetchData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        error = "Nie udało się pobrać danych. Sprawdź połączenie z internetem.";
      });
    }
  }

  Future<void> _refresh() async {
    try {
      await _fetchData(forceRefresh: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Nie udało się odświeżyć danych."),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _fetchData({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    selectedAllergens = prefs.getStringList('selected_allergens') ?? [];

    final mode = prefs.getString('location_mode') ?? 'auto';
    double lat;
    double lng;
    String resolvedCityName;

    if (mode == 'manual') {
      lat = prefs.getDouble('manual_lat') ?? 52.2297;
      lng = prefs.getDouble('manual_lng') ?? 21.0122;
      resolvedCityName = prefs.getString('manual_city_name') ?? 'Twoja lokalizacja';
    } else {
      final position = await tryGetLocation();
      if (position != null) {
        lat = position.latitude;
        lng = position.longitude;
        resolvedCityName = await resolveCityName(lat, lng);
      } else {
        _locationFallback = true;
        lat = prefs.getDouble('auto_lat') ?? 52.2297;
        lng = prefs.getDouble('auto_lng') ?? 21.0122;
        resolvedCityName = prefs.getString('auto_city_name') ?? 'Twoja lokalizacja';
      }
    }

    if (!forceRefresh) {
      final cached = await cachedPollenResponse(lat, lng);
      if (cached != null) {
        final cachedData = cached['data'];
        if (cachedData is Map) {
          dailyInfo = (cachedData['dailyInfo'] as List<dynamic>?) ?? [];
        }
        if (!mounted) return;
        setState(() {
          cityName = resolvedCityName;
          loading = false;
        });
        return;
      }
    }

    final tileId = tileIdFromCoordinates(lat, lng);

    Map<String, dynamic>? pollenResData;
    try {
      final pollenRes = await _client.functions
          .invoke('get_pollen', body: {
            "latitude": lat,
            "longitude": lng,
            "tile_id": tileId,
            "tile_zoom": tileZoom,
          })
          .timeout(const Duration(seconds: 30));
      pollenResData = pollenRes.data is Map<String, dynamic>
          ? pollenRes.data as Map<String, dynamic>
          : null;
      if (pollenResData != null) {
        await storeCachedPollenResponse(lat, lng, pollenResData);
      }
    } catch (_) {
      pollenResData = await staleCachedPollenResponse(lat, lng);
    }

    final rawData = pollenResData?['data'];
    if (rawData is Map) {
      dailyInfo = (rawData['dailyInfo'] as List<dynamic>?) ?? [];
    } else {
      dailyInfo = [];
    }

    if (!mounted) return;
    setState(() {
      selectedDayIndex = 0;
      cityName = resolvedCityName;
      loading = false;
    });
    if (_locationFallback) {
      _locationFallback = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Nie udało się pobrać lokalizacji. Pokazujemy dane dla domyślnego miasta."),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (loading) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: init,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      "Spróbuj ponownie",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hasAllergens = selectedAllergens.isNotEmpty;
    final allergensToShow = hasAllergens
        ? selectedAllergens
        : allergenGroups.expand((g) => g.items).map((o) => o.name).toList();
    final futureDays = dailyInfo.length > 1 ? dailyInfo.sublist(1) : <dynamic>[];
    final forecastData = futureDays.map((d) => _dayPersonalizedForecast(d, allergensToShow)).toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          displacement: 60,
          color: AppColors.systemGray,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                cityName,
                style: TextStyle(
                  fontSize: 24,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            if (futureDays.isNotEmpty && selectedDayIndex < futureDays.length) ...[
              _DayDetailContent(
                day: futureDays[selectedDayIndex],
                selectedAllergens: selectedAllergens,
              ),
            ],

            const SizedBox(height: 32),

            if (futureDays.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  "Najbliższe dni",
                  style: TextStyle(
                    fontSize: 18,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 24) / 2.35;
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        for (var i = 0; i < futureDays.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => setState(() => selectedDayIndex = i),
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: selectedDayIndex == i
                                  ? 1.0
                                  : 0.45,
                              child: SizedBox(
                                width: cardWidth,
                                child: SmallCard(
                                  title: _capitalize(_weekdayName(_parseDayDate(futureDays[i]))),
                                  value: _severityLabel(forecastData[i].maxScore),
                                  subtitle: _formatDate(_parseDayDate(futureDays[i])),
                                  iconKind: AppIconKind.grass,
                                  badgeForeground: pollenSeverityColor(forecastData[i].maxScore),
                                  badgeBackground: pollenSeverityColor(forecastData[i].maxScore).withValues(alpha: 0.14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
          ),
      ),
    );
  }
}

class _DayDetailContent extends StatelessWidget {
  final dynamic day;
  final List<String> selectedAllergens;

  const _DayDetailContent({
    required this.day,
    required this.selectedAllergens,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pollenTypes = day['pollenTypeInfo'] ?? [];
    final plants = day['plantInfo'] ?? [];
    final hasSelected = selectedAllergens.isNotEmpty;
    final allergensToShow = hasSelected
        ? selectedAllergens
        : allergenGroups.expand((g) => g.items).map((o) => o.name).toList();

    final pollenCard = resolvePollenCard(
      pollenTypes: pollenTypes,
      plants: plants,
      selectedAllergens: selectedAllergens,
    );
    final title = insightSeverityTitle(pollenCard.colorScore);
    final desc = buildInsightDescription(
      pollenCard.colorScore, pollenTypes, plants, selectedAllergens,
    );
    final rec = buildInsightRecommendation(pollenCard.colorScore);

    final allergenCards = buildSelectedAllergenCards(
      selectedAllergens: allergensToShow,
      pollenTypes: pollenTypes,
      plants: plants,
    );

    final dt = _parseDayDate(day);
    final dayLabel = _capitalize(_weekdayName(dt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InsightCard(
          label: dayLabel,
          title: title,
          description: desc,
          recommendation: rec,
          iconKind: AppIconKind.forecast,
          badgeForeground: pollenSeverityColor(pollenCard.colorScore),
          badgeBackground: pollenSeverityColor(pollenCard.colorScore).withValues(alpha: 0.14),
        ),

        if (allergenCards.isNotEmpty) ...[
          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              hasSelected ? "Twoje alergeny" : "Alergeny",
              style: TextStyle(
                fontSize: 18,
                height: 1,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),

          LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = (constraints.maxWidth - 24) / 2.35;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    for (var i = 0; i < allergenCards.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      SizedBox(
                        width: cardWidth,
                        child: SmallCard(
                          title: allergenCards[i].name,
                          value: allergenCards[i].valueLabel,
                          subtitle: allergenCards[i].upiLabel,
                          iconKind: allergenCards[i].iconKind,
                          badgeForeground: pollenSeverityColor(allergenCards[i].colorScore),
                          badgeBackground: pollenSeverityColor(allergenCards[i].colorScore).withValues(alpha: 0.14),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}
