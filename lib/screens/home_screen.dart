import 'package:flutter/material.dart';
import 'package:pylek/components/app_icons.dart';
import 'package:pylek/theme/apple_colors.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pylek/screens/allergen_selection_screen.dart';

import 'package:pylek/components/insight_card.dart';
import 'package:pylek/components/small_card.dart';
import 'package:pylek/utils/allergen_data.dart';
import 'package:pylek/utils/analytics_service.dart';
import 'package:pylek/utils/pollen_home.dart';
import 'package:pylek/utils/air_quality_home.dart';
import 'package:pylek/utils/data_cache.dart';
import 'package:pylek/utils/location_utils.dart';

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
  final ValueChanged<int>? onNavigateToTab;
  final ValueChanged<PollutantCardData>? onShowPollutantDetail;

  const HomeScreen({super.key, this.onNavigateToTab, this.onShowPollutantDetail});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _client = Supabase.instance.client;

  bool loading = true;
  String? error;
  bool _locationFallback = false;

  bool hasPollenData = false;
  bool hasAirData = false;
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

    final mode = await _getLocationMode();

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

    final tileId = tileIdFromCoordinates(lat, lng);

    Map<String, dynamic>? pollenResponse;
    if (!forceRefresh) {
      pollenResponse = await cachedPollenResponse(lat, lng);
    }
    if (pollenResponse == null) {
      try {
        final res = await _client.functions
            .invoke('get_pollen', body: {
              "latitude": lat,
              "longitude": lng,
              "tile_id": tileId,
              "tile_zoom": tileZoom,
            })
            .timeout(const Duration(seconds: 30));
        if (res.data is Map) {
          pollenResponse = res.data as Map<String, dynamic>;
          await storeCachedPollenResponse(lat, lng, pollenResponse);
        }
      } catch (_) {
        pollenResponse = await staleCachedPollenResponse(lat, lng);
      }
    }

    Map<String, dynamic>? airResponse;
    if (!forceRefresh) {
      airResponse = await cachedAirResponse(lat, lng);
    }
    if (airResponse == null) {
      try {
        final res = await _client.functions
            .invoke('get_aq', body: {
              "latitude": lat,
              "longitude": lng,
              "tile_id": tileId,
              "tile_zoom": tileZoom,
            })
            .timeout(const Duration(seconds: 30));
        if (res.data is Map) {
          airResponse = res.data as Map<String, dynamic>;
          await storeCachedAirResponse(lat, lng, airResponse);
        }
      } catch (_) {
        airResponse = await staleCachedAirResponse(lat, lng);
      }
    }

    _applyResponses(pollenResponse, airResponse, prefs, resolvedCityName);
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

  void _applyResponses(
    Map<String, dynamic>? pollenResponse,
    Map<String, dynamic>? airResponse,
    SharedPreferences prefs,
    String resolvedCityName,
  ) {
    final selectedAllergens = prefs.getStringList('selected_allergens') ?? [];
    final hasSelected = selectedAllergens.isNotEmpty;
    bool pollenDataSet = false;

    if (pollenResponse != null) {
      final pollenData = pollenResponse['data'];
      final pollenDateLabel = formatPollenFetchDate(pollenResponse['fetched_at']);
      final dailyInfo = (pollenData is Map ? pollenData['dailyInfo'] as List<dynamic>? : null) ?? [];
      if (dailyInfo.isNotEmpty) {
        final today = dailyInfo[0];
        final pollenTypes = today['pollenTypeInfo'] ?? [];
        final plants = today['plantInfo'] ?? [];
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
        final title = insightSeverityTitle(pollenCard.colorScore);
        final desc = buildInsightDescription(
            pollenCard.colorScore, pollenTypes, plants, selectedAllergens);
        final rec = buildInsightRecommendation(pollenCard.colorScore);

        if (!mounted) return;
        setState(() {
          hasPollenData = true;
          pollenColorScore = pollenCard.colorScore;
          pollenFetchedAt = pollenDateLabel;
          insightTitle = title;
          insightDescription = desc;
          insightRecommendation = rec;
          hasSelectedAllergens = hasSelected;
          allergenPollenCards = allergenCards;
        });
        AnalyticsService.logPollenForecastView();
        pollenDataSet = true;
      }
    }

    if (!pollenDataSet) {
      if (!mounted) return;
      setState(() {
        hasPollenData = false;
        pollenColorScore = 0;
        pollenFetchedAt = '';
        insightTitle = '';
        insightDescription = '';
        insightRecommendation = '';
        hasSelectedAllergens = hasSelected;
        allergenPollenCards = [];
      });
    }

    if (airResponse != null) {
      final aqData = airResponse['data'];
      final fetchedAtAir = _formatFetchTime(airResponse['fetched_at']);
      final index = aqData is Map ? (aqData['indexes']?[0]) : null;
      final aqi = index?['aqi'] ?? 0;
      final category = index?['category'] ?? "Brak danych";
      final pollutants = aqData is Map ? aqData['pollutants'] ?? [] : [];
      final builtPollutantCards = buildPollutantCards(pollutants);

      if (!mounted) return;
      setState(() {
        hasAirData = true;
        airAqi = aqi;
        airCategory = category;
        airFetchedAt = fetchedAtAir;
        pollutantCards = builtPollutantCards;
        cityName = resolvedCityName;
        loading = false;
      });
      AnalyticsService.logAirQualityView();
    } else {
      if (!mounted) return;
      setState(() {
        hasAirData = false;
        airAqi = 0;
        airCategory = "Brak danych";
        airFetchedAt = '';
        pollutantCards = [];
        cityName = resolvedCityName;
        loading = false;
      });
    }
  }

  void _openDetails(String type) {
    switch (type) {
      case 'forecast':
        widget.onNavigateToTab?.call(1);
        break;
      case 'journal':
        widget.onNavigateToTab?.call(2);
        break;
      case 'alerts':
      case 'notifications':
        widget.onNavigateToTab?.call(3);
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
        backgroundColor: colorScheme.surface,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
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
                  onTap: _init,
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
            SizedBox(height: 16),

            Padding(
              padding: EdgeInsets.only(bottom: 24),
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

            if (hasPollenData)
              InsightCard(
                label: "Dzisiejsze podsumowanie",
                title: insightTitle,
                description: insightDescription,
                recommendation: insightRecommendation,
                iconKind: AppIconKind.grass,
                fetchedAt: pollenFetchedAt.isEmpty ? null : pollenFetchedAt,
                badgeForeground: pollenSeverityColor(pollenColorScore),
                badgeBackground: pollenSeverityColor(pollenColorScore).withValues(alpha: 0.14),
              )
            else
              InsightCard(
                label: "Dzisiejsze podsumowanie",
                title: "Brak danych o pyleniu",
                description: "Nie udało się pobrać dzisiejszych danych. Sprawdź połączenie z internetem.",
                iconKind: AppIconKind.grass,
                badgeForeground: AppColors.systemGray,
                badgeBackground: AppColors.systemGray.withValues(alpha: 0.14),
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
                              badgeBackground: pollenSeverityColor(allergenPollenCards[i].colorScore).withValues(alpha: 0.14),
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

            if (hasAirData) ...[
              Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: Text(
                      "Jakość powietrza",
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
                              showChevron: true,
                              onTap: () => widget.onShowPollutantDetail?.call(pollutantCards[i]),
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
                  color: colorScheme.onSurface,
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
                        child:   SmallCard(
                          title: "Prognoza",
                          value: "Najbliższe dni",
                          iconKind: AppIconKind.forecast,
                          badgeForeground: AppColors.systemTeal,
                          badgeBackground: AppColors.systemTeal.withValues(alpha: 0.12),
                          onTap: () => _openDetails("forecast"),
                          showChevron: true,
                          isSection: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: cardWidth,
                        child:   SmallCard(
                          title: "Dzienniczek",
                          value: "Zapisz wpis",
                          iconKind: AppIconKind.journal,
                          badgeForeground: AppColors.systemYellow,
                          badgeBackground: AppColors.systemYellow.withValues(alpha: 0.12),
                          onTap: () => _openDetails("journal"),
                          showChevron: true,
                          isSection: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: cardWidth,
                        child:   SmallCard(
                          title: "Powiadomienia",
                          value: "Sprawdź",
                          iconKind: AppIconKind.alerts,
                          badgeForeground: AppColors.systemOrange,
                          badgeBackground: AppColors.systemOrange.withValues(alpha: 0.12),
                          onTap: () => _openDetails("notifications"),
                          showChevron: true,
                          isSection: true,
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
      ),
    );
  }

}
