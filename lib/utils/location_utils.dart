import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

const int tileZoom = 13;
const double _mercatorOriginShift = 20037508.342789244;
const double _tileSizeMeters = 40075016.685578488 / (1 << tileZoom);

String tileIdFromCoordinates(double latitude, double longitude) {
  final clampedLatitude = latitude.clamp(-85.05112878, 85.05112878);
  final latRadians = clampedLatitude * math.pi / 180;
  final xMeters = longitude * _mercatorOriginShift / 180;
  final yMeters = math.log(math.tan(math.pi / 4 + latRadians / 2)) * _mercatorOriginShift / math.pi;

  final tileX = ((xMeters + _mercatorOriginShift) / _tileSizeMeters).floor();
  final tileY = ((_mercatorOriginShift - yMeters) / _tileSizeMeters).floor();

  return 'wmz$tileZoom:x$tileX:y$tileY';
}

Future<Position?> tryGetLocation() async {
  final enabled = await Geolocator.isLocationServiceEnabled();
  if (!enabled) return null;

  final permission = await Geolocator.checkPermission();
  if (permission != LocationPermission.always &&
      permission != LocationPermission.whileInUse) {
    return null;
  }

  return Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
  ).timeout(const Duration(seconds: 15));
}

Future<String> resolveCityName(double latitude, double longitude) async {
  try {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isEmpty) return 'Twoja lokalizacja';

    final placemark = placemarks.first;
    final candidates = [
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
    ];

    for (final candidate in candidates) {
      final value = candidate?.trim();
      if (value != null && value.isNotEmpty) return value;
    }

    return 'Twoja lokalizacja';
  } catch (_) {
    return 'Twoja lokalizacja';
  }
}
