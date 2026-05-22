import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:pylek/screens/alerts_screen.dart';
import 'package:pylek/screens/journal_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer';

const Color _cardBackground = Color(0xFF202426);
const Color _secondaryText = Color(0xFF758F9F);
const Color _primaryText = Color(0xFFFEFEFE);
const int _tileZoom = 13;
const double _mercatorOriginShift = 20037508.342789244;
const double _tileSizeMeters = 40075016.685578488 / (1 << _tileZoom);

String _formatPolishDate(DateTime date) {
  const months = [
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

  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

Widget _iconBadge({
  required IconData icon,
  required Color background,
  required Color foreground,
  double size = 42,
  double iconSize = 20,
}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: background,
    ),
    child: Icon(
      icon,
      color: foreground,
      size: iconSize,
    ),
  );
}

Color _aqiColor(int aqi) {
  if (aqi <= 50) return const Color(0xFF57B108); // Bardzo dobra
  if (aqi <= 100) return const Color(0xFFB0DD10); // Dobra
  if (aqi <= 150) return const Color(0xFFFFD911); // Umiarkowana
  if (aqi <= 200) return const Color(0xFFE58100); // Dostateczna
  if (aqi <= 300) return const Color(0xFFE50000); // Zła
  return const Color(0xFF990000); // Bardzo zła
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

  int airAqi = 0;
  String airCategory = "Dobra";
  String cityName = "Twoja lokalizacja";

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
      final index = aqData['indexes']?[0];
      final aqi = index?['aqi'] ?? 0;
      final category = index?['category'] ?? "Brak danych";

      if (!mounted) return;

      setState(() {
        upiValue = pollenNormalized;
        airAqi = aqi;
        airCategory = category;
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

  Color _upiColor(int value) {
    if (value <= 20) {
      return const Color(0xFF9BE15D);
    } else if (value <= 40) {
      return const Color(0xFF34C759);
    } else if (value <= 60) {
      return const Color(0xFFFF9F0A);
    } else if (value <= 80) {
      return const Color(0xFFFF453A);
    } else {
      return const Color(0xFF7D0A0A);
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
    if (loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            error!,
            style: const TextStyle(color: _primaryText),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          children: [
            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      cityName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        color: _secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _formatPolishDate(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 16,
                      color: _secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            _buildMainCard(),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: _SmallCard(
                    title: "Jakość powietrza",
                    value: _shortenCategory(airCategory),
                    text: "$airAqi w skali AQI",
                    icon: Icons.air_rounded,
                    badgeForeground: _aqiColor(airAqi),
                    badgeBackground: _aqiColor(airAqi).withOpacity(0.14),
                    onTap: () => _openDetails("air"),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _SmallCard(
                    title: "Prognoza na 5 dni",
                    value: "Sprawdź",
                    text: "Kolejne dni",
                    icon: Icons.calendar_view_week_rounded,
                    badgeForeground: const Color(0xFF6BD7F3),
                    badgeBackground: const Color(0x1F6BD7F3),
                    onTap: () => _openDetails("forecast"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _SmallCard(
                    title: "Dzienniczek",
                    value: "Brak",
                    text: "Otwórz dzienniczek",
                    icon: Icons.menu_book_rounded,
                    badgeForeground: const Color(0xFFFFC76A),
                    badgeBackground: const Color(0x1FFFC76A),
                    onTap: () => _openDetails("journal"),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: _SmallCard(
                    title: "Alerty",
                    value: "Brak",
                    text: "Skonfiguruj alerty",
                    icon: Icons.notifications_active_rounded,
                    badgeForeground: const Color(0xFFFF6B8A),
                    badgeBackground: const Color(0x1FFF6B8A),
                    onTap: () => _openDetails("alerts"),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _SmallCard(
                    title: "Masz propozycję?",
                    value: "Wyślij opinię",
                    text: "Pomóż ulepszyć Pyłka",
                    icon: Icons.feedback_rounded,
                    badgeForeground: const Color(0xFFD6B4FC),
                    badgeBackground: const Color(0x1FD6B4FC),
                    onTap: () => _sendFeedback(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    final color = _upiColor(upiValue);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: 26,
      ),
      decoration: BoxDecoration(
        color: _cardBackground,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _iconBadge(
                icon: Icons.air,
                background: const Color(0xFF2A332B),
                foreground: const Color(0xFF93D37D),
                size: 34,
                iconSize: 17,
              ),
              const SizedBox(width: 10),
              const Text(
                "Pylenie",
                style: TextStyle(
                  fontSize: 15,
                  color: _secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: _secondaryText.withOpacity(0.55),
              ),
            ],
          ),

          const SizedBox(height: 24),

          SizedBox(
            width: 260,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  top: 0,
                  child: SizedBox(
                    width: 220,
                    height: 130,
                    child: CustomPaint(
                      painter: _GaugePainter(
                        value: upiValue,
                        color: color,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: 18,
                  child: Column(
                    children: [
                      Text(
                        "$upiValue",
                        style: const TextStyle(
                          fontSize: 74,
                          height: 1,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -4,
                          color: _primaryText,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        _upiLabel(upiValue),
                        style: const TextStyle(
                          fontSize: 14,
                          color: _secondaryText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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

class _GaugePainter extends CustomPainter {
  final int value;
  final Color color;

  _GaugePainter({
    required this.value,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 12.0;

    final center = Offset(
      size.width / 2,
      size.height,
    );

    final radius = (size.width / 2) - strokeWidth;

    final backgroundPaint = Paint()
      ..color = const Color(0xFFE8E8ED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      math.pi,
      math.pi,
      false,
      backgroundPaint,
    );

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweep = math.pi * (value / 100);

    canvas.drawArc(
      Rect.fromCircle(
        center: center,
        radius: radius,
      ),
      math.pi,
      sweep,
      false,
      progressPaint,
    );

    final angle = math.pi + sweep;

    final dx = center.dx + radius * math.cos(angle);
    final dy = center.dy + radius * math.sin(angle);

    canvas.drawCircle(
      Offset(dx, dy),
      9,
      Paint()..color = color,
    );

    canvas.drawCircle(
      Offset(dx, dy),
      3.5,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class _SmallCard extends StatelessWidget {
  final String title;
  final String value;
  final String text;
  final IconData icon;
  final Color? badgeBackground;
  final Color? badgeForeground;
  final VoidCallback onTap;

  const _SmallCard({
    required this.title,
    required this.value,
    required this.text,
    required this.icon,
    this.badgeBackground,
    this.badgeForeground,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _cardBackground,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Builder(builder: (context) {
                  final fg = badgeForeground ?? (icon == Icons.air_rounded
                      ? _aqiColor(0)
                      : const Color(0xFFFFB57B));
                  final bg = badgeBackground ?? (icon == Icons.air_rounded
                      ? fg.withOpacity(0.14)
                      : const Color(0xFF2D2A35));

                  return _iconBadge(
                    icon: icon,
                    background: bg,
                    foreground: fg,
                    size: 40,
                    iconSize: 19,
                  );
                }),

                const Spacer(),

                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: _secondaryText.withOpacity(0.55),
                ),
              ],
            ),

            const SizedBox(height: 18),

            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: _secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                height: 1,
                letterSpacing: -1,
                fontWeight: FontWeight.w700,
                color: _primaryText,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                color: _secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
