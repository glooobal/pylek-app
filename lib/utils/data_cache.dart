import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const Duration _cacheTtl = Duration(minutes: 30);

const String _pollenKey = 'cache_pollen_response';
const String _pollenLatKey = 'cache_pollen_lat';
const String _pollenLngKey = 'cache_pollen_lng';

const String _airKey = 'cache_air_response';
const String _airLatKey = 'cache_air_lat';
const String _airLngKey = 'cache_air_lng';

Future<Map<String, dynamic>?> cachedPollenResponse(
    double lat, double lng) async {
  final prefs = await SharedPreferences.getInstance();

  final storedLat = prefs.getDouble(_pollenLatKey);
  final storedLng = prefs.getDouble(_pollenLngKey);
  if (storedLat == null || storedLng == null) return null;

  const tol = 0.01;
  if ((storedLat - lat).abs() > tol || (storedLng - lng).abs() > tol) {
    return null;
  }

  final cachedAt = prefs.getString('${_pollenKey}_cached_at');
  if (cachedAt == null) return null;
  final cachedTime = DateTime.tryParse(cachedAt);
  if (cachedTime == null) return null;
  if (DateTime.now().difference(cachedTime) > _cacheTtl) return null;

  return _readPollenCache(prefs);
}

Future<Map<String, dynamic>?> staleCachedPollenResponse(
    double lat, double lng) async {
  final prefs = await SharedPreferences.getInstance();

  final storedLat = prefs.getDouble(_pollenLatKey);
  final storedLng = prefs.getDouble(_pollenLngKey);
  if (storedLat == null || storedLng == null) return null;

  const tol = 0.01;
  if ((storedLat - lat).abs() > tol || (storedLng - lng).abs() > tol) {
    return null;
  }

  return _readPollenCache(prefs);
}

Future<Map<String, dynamic>?> _readPollenCache(
    SharedPreferences prefs) async {
  final raw = prefs.getString(_pollenKey);
  if (raw == null) return null;

  try {
    return jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

Future<void> storeCachedPollenResponse(
    double lat, double lng, dynamic response) async {
  if (response is! Map) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_pollenKey, jsonEncode(response));
  await prefs.setDouble(_pollenLatKey, lat);
  await prefs.setDouble(_pollenLngKey, lng);
  await prefs.setString(
      '${_pollenKey}_cached_at', DateTime.now().toIso8601String());
}

Future<Map<String, dynamic>?> cachedAirResponse(double lat, double lng) async {
  final prefs = await SharedPreferences.getInstance();

  final storedLat = prefs.getDouble(_airLatKey);
  final storedLng = prefs.getDouble(_airLngKey);
  if (storedLat == null || storedLng == null) return null;

  const tol = 0.01;
  if ((storedLat - lat).abs() > tol || (storedLng - lng).abs() > tol) {
    return null;
  }

  final cachedAt = prefs.getString('${_airKey}_cached_at');
  if (cachedAt == null) return null;
  final cachedTime = DateTime.tryParse(cachedAt);
  if (cachedTime == null) return null;
  if (DateTime.now().difference(cachedTime) > _cacheTtl) return null;

  return _readAirCache(prefs);
}

Future<Map<String, dynamic>?> staleCachedAirResponse(double lat, double lng) async {
  final prefs = await SharedPreferences.getInstance();

  final storedLat = prefs.getDouble(_airLatKey);
  final storedLng = prefs.getDouble(_airLngKey);
  if (storedLat == null || storedLng == null) return null;

  const tol = 0.01;
  if ((storedLat - lat).abs() > tol || (storedLng - lng).abs() > tol) {
    return null;
  }

  return _readAirCache(prefs);
}

Future<Map<String, dynamic>?> _readAirCache(SharedPreferences prefs) async {
  final raw = prefs.getString(_airKey);
  if (raw == null) return null;

  try {
    return jsonDecode(raw) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

Future<void> storeCachedAirResponse(
    double lat, double lng, dynamic response) async {
  if (response is! Map) return;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_airKey, jsonEncode(response));
  await prefs.setDouble(_airLatKey, lat);
  await prefs.setDouble(_airLngKey, lng);
  await prefs.setString(
      '${_airKey}_cached_at', DateTime.now().toIso8601String());
}
