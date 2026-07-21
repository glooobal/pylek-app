import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'preferences_service.dart';

class FcmService {
  static const _fcmTokenKey = 'fcm_device_token';
  static const _enabledKey = 'forecast_reminder_enabled';

  static StreamSubscription<String>? _tokenSubscription;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('[FCM] Notification permission denied');
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    final token = await messaging.getToken();
    if (token != null) {
      await _persistToken(token);
      await _syncTokenToServer(token);
    }

    _tokenSubscription = messaging.onTokenRefresh.listen((newToken) async {
      await _persistToken(newToken);
      await _syncTokenToServer(newToken);
    });
  }

  static void dispose() {
    _tokenSubscription?.cancel();
    _tokenSubscription = null;
    _initialized = false;
  }

  static Future<bool> isEnabled() async {
    final value = await PreferencesService.instance.getBool(_enabledKey);
    return value ?? true;
  }

  static Future<void> setEnabled(bool enabled) async {
    await PreferencesService.instance.setBool(_enabledKey, enabled);
    await _syncPreferenceToServer(enabled);
  }

  static Future<void> _persistToken(String token) async {
    await PreferencesService.instance.setString(_fcmTokenKey, token);
  }

  static Future<String?> _getPersistedToken() async {
    return PreferencesService.instance.getString(_fcmTokenKey);
  }

  static Future<void> _syncTokenToServer(String token) async {
    try {
      final enabled = await isEnabled();
      await Supabase.instance.client.functions
          .invoke(
            'register_device',
            body: {
              'token': token,
              'forecast_reminder_enabled': enabled,
            },
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Server sync failure is non-fatal – will retry on next launch
    }
  }

  static Future<void> _syncPreferenceToServer(bool enabled) async {
    try {
      final token = await _getPersistedToken();
      if (token == null) return;
      await Supabase.instance.client.functions
          .invoke(
            'register_device',
            body: {
              'token': token,
              'forecast_reminder_enabled': enabled,
            },
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Non-fatal
    }
  }
}
