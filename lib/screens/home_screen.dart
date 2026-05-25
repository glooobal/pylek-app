import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pylek/components/app_icons.dart';
import 'package:pylek/theme/apple_colors.dart';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pylek/screens/alerts_screen.dart';
import 'package:pylek/screens/allergen_selection_screen.dart';
import 'package:pylek/screens/journal_screen.dart';

import 'package:pylek/components/insight_card.dart';
import 'package:pylek/components/small_card.dart';
import 'package:pylek/utils/allergen_data.dart';
import 'package:pylek/utils/pollen_home.dart';
import 'package:pylek/utils/air_quality_home.dart';

const int _tileZoom = 13;
const double _mercatorOriginShift = 20037508.342789244;
const double _tileSizeMeters = 40075016.685578488 / (1 << _tileZoom);

String _tileIdFromCoordinates(double latitude, double longitude) {
  final clampedLatitude = latitude.clamp(-85.05112878, 85.05112878);
  final latRadians = clampedLatitude * math.pi / 180;
  final xMeters = longitude * _mercatorOriginShift / 180;
  final yMeters = math.log(math.tan(math.pi / 4 + latRadians / 2)) * _mercatorOriginShift / math.pi;

  final tileX = ((xMeters + _mercatorOriginShift) / _tileSizeMeters).floor();
  final tileY = ((_mercatorOriginShift - yMeters) / _tileSizeMeters).floor();

  return 'wmz${_tileZoom}:x$tileX:y$tileY';
}

String _formatFetchTime(dynamic rawValue) {
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

  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _client = Supabase.instance.client;

  bool loading = true;
  String? error;

  int pollenColorScore = 0;
  String pollenFetchedAt = '';
  String insightTitle = '';
  String insightDescription = '';
  String insightRecommendation = '';
  bool hasSelectedAllergens = false;
  List<AllergenPollenCardData> allergenPollenCards = [];
  List<PollutantCardData> pollutantCards = [];

  int airAqi = 0;
  String airCategory = "Dobra";
  String cityName = "Twoja lokalizacja";
  String airFetchedAt = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<String> _getLocationMode() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString('location_mode') ?? 'auto';
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final mode = await _getLocationMode();

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
      final tileId = _tileIdFromCoordinates(lat, lng);

      final results = await Future.wait([
        _client.functions.invoke(
          'get_pollen',
          body: {
            "latitude": lat,
            "longitude": lng,
            "tile_id": tileId,
            "tile_zoom": _tileZoom,
          },
        ),
        _client.functions.invoke(
          'get_aq',
          body: {
            "latitude": lat,
            "longitude": lng,
            "tile_id": tileId,
            "tile_zoom": _tileZoom,
          },
        ),
      ]);

      final pollenRes = results[0];
      final pollenData = pollenRes.data['data'];
      final pollenDateLabel = formatPollenFetchDate(pollenRes.data['fetched_at']);
      final today = pollenData['dailyInfo'][0];
      final pollenTypes = today['pollenTypeInfo'] ?? [];
      final plants = today['plantInfo'] ?? [];
      final selectedAllergens = prefs.getStringList('selected_allergens') ?? [];
      final hasSelected = selectedAllergens.isNotEmpty;
      final allergensToShow = hasSelected
          ? selectedAllergens
          : allergenGroups.expand((g) => g.items).map((o) => o.name).toList();
      final pollenCard = resolvePollenCard(
        pollenTypes: pollenTypes,
        plants: plants,
        selectedAllergens: selectedAllergens,
      );
      final allergenCards = buildSelectedAllergenCards(
        selectedAllergens: allergensToShow,
        pollenTypes: pollenTypes,
        plants: plants,
      );

      final aqRes = results[1];
      final aqData = aqRes.data['data'];
      final fetchedAtAir = _formatFetchTime(aqRes.data['fetched_at']);
      final index = aqData['indexes']?[0];
      final aqi = index?['aqi'] ?? 0;
      final category = index?['category'] ?? "Brak danych";
      final pollutants = aqData['pollutants'] ?? [];
      final builtPollutantCards = buildPollutantCards(pollutants);

      if (!mounted) return;

      final title = insightSeverityTitle(pollenCard.colorScore);
      final desc = buildInsightDescription(pollenCard.colorScore, pollenTypes, plants, selectedAllergens);
      final rec = buildInsightRecommendation(pollenCard.colorScore);

      setState(() {
        pollenColorScore = pollenCard.colorScore;
        pollenFetchedAt = pollenDateLabel;
        insightTitle = title;
        insightDescription = desc;
        insightRecommendation = rec;
        hasSelectedAllergens = hasSelected;
        allergenPollenCards = allergenCards;
        airAqi = aqi;
        airCategory = category;
        airFetchedAt = fetchedAtAir;
        pollutantCards = builtPollutantCards;
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

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  Future<String> _resolveCityName(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        return 'Twoja lokalizacja';
      }

      final placemark = placemarks.first;

      final candidates = [
        placemark.locality,
        placemark.subAdministrativeArea,
        placemark.administrativeArea,
      ];

      for (final candidate in candidates) {
        final value = candidate?.trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }

      return 'Twoja lokalizacja';
    } catch (_) {
      return 'Twoja lokalizacja';
    }
  }

  void _openDetails(String type) {
    switch (type) {
      case 'journal':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const JournalScreen(),
          ),
        );
        break;
      case 'alerts':
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const AlertsScreen(),
          ),
        );
        break;
      default:
        break;
    }
  }

  void _openAllergenSelection() async {
    final prefs = await SharedPreferences.getInstance();
    final selected = prefs.getStringList('selected_allergens') ?? [];

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AllergenSelectionScreen(initialAllergens: selected),
      ),
    );

    _init();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (loading) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: Text(
            error!,
            style: TextStyle(color: colorScheme.onBackground),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            SizedBox(height: 16),

            Padding(
              padding: EdgeInsets.only(bottom: 24),
                  child: Text(
                cityName,
                style: TextStyle(
                  fontSize: 18,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onBackground,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            InsightCard(
              label: "Podsumowanie",
              title: insightTitle,
              description: insightDescription,
              recommendation: insightRecommendation,
              iconKind: AppIconKind.grass,
              fetchedAt: pollenFetchedAt.isEmpty ? null : pollenFetchedAt,
              badgeForeground: pollenSeverityColor(pollenColorScore),
              badgeBackground: pollenSeverityColor(pollenColorScore).withOpacity(0.14),
            ),

            if (allergenPollenCards.isNotEmpty) ...[
              SizedBox(height: 32),

              Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Row(
                  children: [
                    Text(
                      hasSelectedAllergens ? "Twoje alergeny" : "Alergeny",
                      style: TextStyle(
                      fontSize: 18,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _openAllergenSelection,
                      child: Text(
                        'Edytuj',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.systemOrange,
                        ),
                      ),
                    ),
                  ],
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
                        for (var i = 0; i < allergenPollenCards.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          SizedBox(
                            width: cardWidth,
                            child: SmallCard(
                              title: allergenPollenCards[i].name,
                              value: allergenPollenCards[i].valueLabel,
                              subtitle: allergenPollenCards[i].upiLabel,
                              iconKind: allergenPollenCards[i].iconKind,
                              badgeForeground: pollenSeverityColor(allergenPollenCards[i].colorScore),
                              badgeBackground: pollenSeverityColor(allergenPollenCards[i].colorScore).withOpacity(0.14),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],

            SizedBox(height: 32),

            if (pollutantCards.isNotEmpty) ...[
              Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Text(
                      "Jakość powietrza",
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
                        for (var i = 0; i < pollutantCards.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          SizedBox(
                            width: cardWidth,
                            child: SmallCard(
                              title: pollutantCards[i].title,
                              value: pollutantCards[i].subtitle.isNotEmpty
                                  ? pollutantCards[i].subtitle
                                  : pollutantCards[i].value,
                              subtitle: pollutantCards[i].subtitle.isNotEmpty
                                  ? pollutantCards[i].value
                                  : null,
                              iconKind: pollutantCards[i].iconKind,
                              badgeForeground: pollutantCards[i].badgeForeground,
                              badgeBackground: pollutantCards[i].badgeBackground,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ],

            SizedBox(height: 32),

            Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text(
                "Na skróty",
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
                final cardWidth = (constraints.maxWidth - 32) / 2.35;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: SmallCard(
                          title: "Prognoza",
                          value: "Najbliższe dni",
                          iconKind: AppIconKind.forecast,
                          badgeForeground: AppColors.systemTeal,
                          badgeBackground: AppColors.systemTeal.withOpacity(0.12),
                          onTap: () => _openDetails("forecast"),
                          showChevron: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: cardWidth,
                        child: SmallCard(
                          title: "Dzienniczek",
                          value: "Zapisz wpis",
                          iconKind: AppIconKind.journal,
                          badgeForeground: AppColors.systemYellow,
                          badgeBackground: AppColors.systemYellow.withOpacity(0.12),
                          onTap: () => _openDetails("journal"),
                          showChevron: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: cardWidth,
                        child: SmallCard(
                          title: "Alerty",
                          value: "Dodaj alert",
                          iconKind: AppIconKind.alerts,
                          badgeForeground: AppColors.systemPink,
                          badgeBackground: AppColors.systemPink.withOpacity(0.12),
                          onTap: () => _openDetails("alerts"),
                          showChevron: true,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

}
