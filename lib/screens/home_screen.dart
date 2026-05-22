import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pylek/components/app_icons.dart';
import 'package:pylek/theme/apple_colors.dart';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:pylek/screens/alerts_screen.dart';
import 'package:pylek/screens/journal_screen.dart';

import 'package:pylek/components/small_card.dart';

const int _tileZoom = 13;
const double _mercatorOriginShift = 20037508.342789244;
const double _tileSizeMeters = 40075016.685578488 / (1 << _tileZoom);

Color _aqiColor(int aqi) {
  if (aqi <= 50) return AppColors.systemGreen;
  if (aqi <= 100) return AppColors.systemGreenLight;
  if (aqi <= 150) return AppColors.systemYellow;
  if (aqi <= 200) return AppColors.systemOrange;
  if (aqi <= 300) return AppColors.systemRed;
  return AppColors.systemRedDark;
}

String _tileIdFromCoordinates(double latitude, double longitude) {
  final clampedLatitude = latitude.clamp(-85.05112878, 85.05112878);
  final latRadians = clampedLatitude * math.pi / 180;
  final xMeters = longitude * _mercatorOriginShift / 180;
  final yMeters = math.log(math.tan(math.pi / 4 + latRadians / 2)) * _mercatorOriginShift / math.pi;

  final tileX = ((xMeters + _mercatorOriginShift) / _tileSizeMeters).floor();
  final tileY = ((_mercatorOriginShift - yMeters) / _tileSizeMeters).floor();

  return 'wmz${_tileZoom}:x$tileX:y$tileY';
}

String _shortenCategory(String s) {
  return s.replaceAll(RegExp(r'\s*jakość powietrza\s*$', caseSensitive: false), '').trim();
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

  int upiValue = 0;
  String pollenFetchedAt = '';

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

      if (mode == 'manual') {
        lat = prefs.getDouble('manual_lat') ?? 52.2297;
        lng = prefs.getDouble('manual_lng') ?? 21.0122;
      } else {
        final position = await _getLocation();
        lat = position.latitude;
        lng = position.longitude;
      }

      final resolvedCityName = await _resolveCityName(lat, lng);
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
      final fetchedAt = _formatFetchTime(pollenRes.data['fetched_at']);
      final today = pollenData['dailyInfo'][0];
      final pollenTypes = today['pollenTypeInfo'] ?? [];

      int total = 0;
      int count = 0;

      for (final type in pollenTypes) {
        final value = type['indexInfo']?['value'];

        if (value != null) {
          total += value as int;
          count++;
        }
      }

      final pollenNormalized =
          count == 0 ? 0 : ((total / (count * 5)) * 100).round();

      final aqRes = results[1];
      final aqData = aqRes.data['data'];
      final fetchedAtAir = _formatFetchTime(aqRes.data['fetched_at']);
      final index = aqData['indexes']?[0];
      final aqi = index?['aqi'] ?? 0;
      final category = index?['category'] ?? "Brak danych";

      if (!mounted) return;

      setState(() {
        upiValue = pollenNormalized;
        pollenFetchedAt = fetchedAt;
        airAqi = aqi;
        airCategory = category;
        airFetchedAt = fetchedAtAir;
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

  Color _upiColor(int value) {
    if (value <= 20) {
      return AppColors.systemGreenLight;
    } else if (value <= 40) {
      return AppColors.systemGreen;
    } else if (value <= 60) {
      return AppColors.systemOrange;
    } else if (value <= 80) {
      return AppColors.systemRed;
    } else {
      return AppColors.systemRedDark;
    }
  }

  Future<Position> _getLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();

    if (!enabled) {
      throw Exception("Włącz lokalizację.");
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        "Brak uprawnień do lokalizacji.",
      );
    }

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

  Future<void> _sendFeedback() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'jakubgorzny@icloud.com',
      query: Uri.encodeFull(
        'subject=Opinia o Pyłku &body=Wpisz tutaj swoją opinię...',
      ),
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
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
                "Prognoza dla $cityName",
                style: TextStyle(
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onBackground,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: SmallCard(
                    title: "Pylenie",
                    value: _upiLabel(upiValue),
                    text: "$upiValue w skali UPI",
                    iconKind: AppIconKind.grass,
                    fetchedAt: pollenFetchedAt.isEmpty ? null : pollenFetchedAt,
                    badgeForeground: _upiColor(upiValue),
                    badgeBackground: _upiColor(upiValue).withOpacity(0.14),
                    onTap: () => _openDetails("air"),
                  ),
                ),
              ],
            ),

            SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: SmallCard(
                    title: "Jakość powietrza",
                    value: _shortenCategory(airCategory),
                    text: "$airAqi w skali AQI",
                    iconKind: AppIconKind.air,
                    fetchedAt: airFetchedAt.isEmpty ? null : airFetchedAt,
                    badgeForeground: _aqiColor(airAqi),
                    badgeBackground: _aqiColor(airAqi).withOpacity(0.14),
                    onTap: () => _openDetails("air"),
                  ),
                ),
              ],
            ),

            SizedBox(height: 32),

            Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text(
                "Dla Ciebie",
                style: TextStyle(
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onBackground,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 32) / 2;

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: SmallCard(
                          title: "Prognoza",
                          value: "Sprawdź",
                          valueSize: "small",
                          text: "Przygotuj się",
                          iconKind: AppIconKind.forecast,
                          badgeForeground: AppColors.systemTeal,
                          badgeBackground: AppColors.systemTeal.withOpacity(0.12),
                          onTap: () => _openDetails("forecast"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: cardWidth,
                        child: SmallCard(
                          title: "Dzienniczek",
                          value: "Uzupełnij",
                          valueSize: "small",
                          text: "Otwórz dzienniczek",
                          iconKind: AppIconKind.journal,
                          badgeForeground: AppColors.systemYellow,
                          badgeBackground: AppColors.systemYellow.withOpacity(0.12),
                          onTap: () => _openDetails("journal"),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: cardWidth,
                        child: SmallCard(
                          title: "Alerty",
                          value: "Brak",
                          valueSize: "small",
                          text: "Skonfiguruj alerty",
                          iconKind: AppIconKind.alerts,
                          badgeForeground: AppColors.systemPink,
                          badgeBackground: AppColors.systemPink.withOpacity(0.12),
                          onTap: () => _openDetails("alerts"),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            SizedBox(height: 32),

            Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text(
                "Pozostałe",
                style: TextStyle(
                  fontSize: 20,
                  height: 1,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onBackground,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            Row(
              children: [
                Expanded(
                  child: SmallCard(
                    title: "Masz propozycję?",
                    value: "Wyślij opinię",
                    valueSize: "small",
                    text: "Pomóż ulepszyć Pyłka",
                    iconKind: AppIconKind.feedback,
                    badgeForeground: AppColors.systemPurple,
                    badgeBackground: AppColors.systemPurple.withOpacity(0.12),
                    onTap: () => _sendFeedback(),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _upiLabel(int value) {
    if (value <= 20) {
      return "Niskie";
    } else if (value <= 40) {
      return "Dobre";
    } else if (value <= 60) {
      return "Umiarkowane";
    } else if (value <= 80) {
      return "Wysokie";
    } else {
      return "Bardzo wysokie";
    }
  }
}
