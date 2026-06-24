import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  static Future<void> logPollenForecastView() =>
      _analytics.logEvent(name: 'pollen_forecast_view');

  static Future<void> logAirQualityView() =>
      _analytics.logEvent(name: 'air_quality_view');

  static Future<void> logJournalEntryAdded() =>
      _analytics.logEvent(name: 'journal_entry_added');

  static Future<void> logOnboardingCompleted() =>
      _analytics.logEvent(name: 'onboarding_completed');
}
