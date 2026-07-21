import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FcmService {
  static const _fcmTokenKey = 'fcm_device_token';
  static const _enabledKey = 'forecast_reminder_enabled';

  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await messaging.getToken();
    if (token != null) {
      await _persistToken(token);
      await _syncTokenToServer(token);
    }

    messaging.onTokenRefresh.listen((newToken) async {
      await _persistToken(newToken);
      await _syncTokenToServer(newToken);
    });
  }

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? true;
  }

  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
    await _syncPreferenceToServer(enabled);
  }

  static Future<void> _persistToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
  }

  static Future<String?> _getPersistedToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fcmTokenKey);
  }

  static Future<void> _syncTokenToServer(String token) async {
    try {
      final enabled = await isEnabled();
      await Supabase.instance.client.functions.invoke(
        'register_device',
        body: {
          'token': token,
          'forecast_reminder_enabled': enabled,
        },
      );
    } catch (_) {
      // Server sync failure is non-fatal – will retry on next launch
    }
  }

  static Future<void> _syncPreferenceToServer(bool enabled) async {
    try {
      final token = await _getPersistedToken();
      if (token == null) return;
      await Supabase.instance.client.functions.invoke(
        'register_device',
        body: {
          'token': token,
          'forecast_reminder_enabled': enabled,
        },
      );
    } catch (_) {
      // Non-fatal
    }
  }
}
