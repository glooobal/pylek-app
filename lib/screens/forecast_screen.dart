import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pylek/components/app_icons.dart';
import 'package:pylek/components/insight_card.dart';
import 'package:pylek/components/small_card.dart';
import 'package:pylek/utils/allergen_data.dart';
import 'package:pylek/utils/pollen_home.dart';

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
  final d = day['date'];
  return DateTime(d['year'], d['month'], d['day']);
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

({int maxScore, String conditionText}) _dayPersonalizedForecast(
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

  if (maxScore <= 20) return (maxScore: maxScore, conditionText: 'Spokojny dzień');
  if (maxScore <= 40) return (maxScore: maxScore, conditionText: 'Niskie pylenie');

  final active = cards.where((c) => c.colorScore > 40).toList();
  active.sort((a, b) => b.colorScore.compareTo(a.colorScore));

  if (active.isEmpty) return (maxScore: maxScore, conditionText: 'Umiarkowane pylenie');

  final top = active.take(2).map((c) => c.name.toLowerCase()).toList();
  final text = top.length == 1 ? top[0] : '${top[0]} i ${top[1]}';
  return (maxScore: maxScore, conditionText: text);
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
        final position = await _tryGetLocation();
        if (position != null) {
          lat = position.latitude;
          lng = position.longitude;
          resolvedCityName = await _resolveCityName(lat, lng);
        } else {
          lat = prefs.getDouble('auto_lat') ?? 52.2297;
          lng = prefs.getDouble('auto_lng') ?? 21.0122;
          resolvedCityName = prefs.getString('auto_city_name') ?? 'Twoja lokalizacja';
        }
      }

      final pollenRes = await _client.functions.invoke(
        'get_pollen',
        body: {"latitude": lat, "longitude": lng},
      );

      final pollenData = pollenRes.data['data'];
      dailyInfo = pollenData['dailyInfo'] ?? [];

      if (!mounted) return;

      setState(() {
        cityName = resolvedCityName;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  Future<Position?> _tryGetLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return null;
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.always &&
        permission != LocationPermission.whileInUse) return null;
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
  }

  Future<String> _resolveCityName(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return 'Twoja lokalizacja';
      final p = placemarks.first;
      for (final c in [p.locality, p.subAdministrativeArea, p.administrativeArea]) {
        final v = c?.trim();
        if (v != null && v.isNotEmpty) return v;
      }
      return 'Twoja lokalizacja';
    } catch (_) {
      return 'Twoja lokalizacja';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (loading) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: Text(error!, style: TextStyle(color: colorScheme.onBackground)),
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
      backgroundColor: colorScheme.background,
      body: SafeArea(
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
                  color: colorScheme.onBackground,
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

            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Text(
                "Najbliższe dni",
                style: TextStyle(
                  fontSize: 18,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onBackground,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            if (futureDays.isNotEmpty) ...[
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
                              opacity: selectedDayIndex == i ? 1.0 : 0.65,
                              child: SizedBox(
                                width: cardWidth,
                                child: SmallCard(
                                  title: _capitalize(_weekdayName(_parseDayDate(futureDays[i]))),
                                  value: _severityLabel(forecastData[i].maxScore),
                                  subtitle: _formatDate(_parseDayDate(futureDays[i])),
                                  iconKind: AppIconKind.grass,
                                  badgeForeground: pollenSeverityColor(forecastData[i].maxScore),
                                  badgeBackground: pollenSeverityColor(forecastData[i].maxScore).withOpacity(0.14),
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
          badgeBackground: pollenSeverityColor(pollenCard.colorScore).withOpacity(0.14),
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
                color: colorScheme.onBackground,
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
                          badgeBackground: pollenSeverityColor(allergenCards[i].colorScore).withOpacity(0.14),
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
