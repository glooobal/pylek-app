import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static PreferencesService? _instance;
  SharedPreferences? _prefs;
  Future<void>? _lastMutexOp;

  PreferencesService._();

  static Future<PreferencesService> init() async {
    if (_instance != null) return _instance!;
    _instance = PreferencesService._();
    _instance!._prefs = await SharedPreferences.getInstance();
    return _instance!;
  }

  static PreferencesService get instance {
    assert(_instance != null && _instance!._prefs != null,
        'PreferencesService not initialized. Call PreferencesService.init() in main()');
    return _instance!;
  }

  SharedPreferences get _p => _prefs!;

  /// Synchronous access to the underlying SharedPreferences instance.
  /// Use only for read operations that need to be synchronous (e.g. in cache lookup).
  SharedPreferences get raw => _prefs!;

  Future<T> synchronized<T>(Future<T> Function() fn) async {
    while (_lastMutexOp != null) {
      await _lastMutexOp;
    }
    final future = fn();
    _lastMutexOp = future.then((_) => null, onError: (_) => null);
    return future;
  }

  Future<String?> getString(String key) async {
    try {
      return _p.getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<bool?> getBool(String key) async {
    try {
      return _p.getBool(key);
    } catch (_) {
      return null;
    }
  }

  Future<double?> getDouble(String key) async {
    try {
      return _p.getDouble(key);
    } catch (_) {
      return null;
    }
  }

  Future<List<String>?> getStringList(String key) async {
    try {
      return _p.getStringList(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> setString(String key, String value) async {
    try {
      await _p.setString(key, value);
    } catch (_) {}
  }

  Future<void> setBool(String key, bool value) async {
    try {
      await _p.setBool(key, value);
    } catch (_) {}
  }

  Future<void> setDouble(String key, double value) async {
    try {
      await _p.setDouble(key, value);
    } catch (_) {}
  }

  Future<void> setStringList(String key, List<String> value) async {
    try {
      await _p.setStringList(key, value);
    } catch (_) {}
  }

  Future<bool> containsKey(String key) async {
    try {
      return _p.containsKey(key);
    } catch (_) {
      return false;
    }
  }
}
