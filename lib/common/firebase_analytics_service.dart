import 'package:firebase_analytics/firebase_analytics.dart';

/// Firebase Analytics Service
/// Track user behavior and events
class FirebaseAnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseAnalyticsObserver _observer =
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Get observer for MaterialApp
  static FirebaseAnalyticsObserver get observer => _observer;

  /// Initialize Analytics
  static Future<void> initialize() async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
    } catch (e) {
      // Silent error handling
    }
  }

  /// Log app open
  static Future<void> logAppOpen() async {
    try {
      await _analytics.logAppOpen();
    } catch (e) {
      // Silent error handling
    }
  }

  /// Log screen view
  static Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      // Silent error handling
    }
  }

  /// Log VPN connection
  static Future<void> logVPNConnection({
    required String serverName,
    required String serverCountry,
    required bool success,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'vpn_connection',
        parameters: {
          'server_name': serverName,
          'server_country': serverCountry,
          'success': success,
        },
      );
    } catch (e) {
      // Silent error handling
    }
  }

  /// Log VPN disconnection
  static Future<void> logVPNDisconnection({
    required String serverName,
    required int durationSeconds,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'vpn_disconnection',
        parameters: {
          'server_name': serverName,
          'duration_seconds': durationSeconds,
        },
      );
    } catch (e) {
      // Silent error handling
    }
  }

  /// Log server selection
  static Future<void> logServerSelection({
    required String serverName,
    required String serverCountry,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'server_selected',
        parameters: {
          'server_name': serverName,
          'server_country': serverCountry,
        },
      );
    } catch (e) {
      // Silent error handling
    }
  }

  /// Log settings change
  static Future<void> logSettingsChange({
    required String setting,
    required String value,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'settings_changed',
        parameters: {
          'setting': setting,
          'value': value,
        },
      );
    } catch (e) {
      // Silent error handling
    }
  }

  /// Set user property
  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      // Silent error handling
    }
  }

  /// Set user ID
  static Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      // Silent error handling
    }
  }

  /// Log custom event
  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      // Silent error handling
    }
  }
}
