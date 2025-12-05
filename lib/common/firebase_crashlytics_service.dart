import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Crashlytics Service
/// Crash reporting and error tracking
class FirebaseCrashlyticsService {
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  /// Initialize Crashlytics
  static Future<void> initialize() async {
    try {
      // Enable crashlytics collection
      await _crashlytics.setCrashlyticsCollectionEnabled(true);

      // Pass all uncaught errors from Flutter framework to Crashlytics
      FlutterError.onError = _crashlytics.recordFlutterFatalError;

      // Pass all uncaught asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        _crashlytics.recordError(error, stack, fatal: true);
        return true;
      };
    } catch (e) {
      // Silent error handling
    }
  }

  /// Log non-fatal error
  static Future<void> logError({
    required dynamic exception,
    StackTrace? stackTrace,
    String? reason,
    bool fatal = false,
  }) async {
    try {
      await _crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      // Silent error handling
    }
  }

  /// Log message
  static Future<void> log(String message) async {
    try {
      await _crashlytics.log(message);
    } catch (e) {
      // Silent error handling
    }
  }

  /// Set user identifier
  static Future<void> setUserId(String userId) async {
    try {
      await _crashlytics.setUserIdentifier(userId);
    } catch (e) {
      // Silent error handling
    }
  }

  /// Set custom key
  static Future<void> setCustomKey(String key, Object value) async {
    try {
      await _crashlytics.setCustomKey(key, value);
    } catch (e) {
      // Silent error handling
    }
  }

  /// Check if crashlytics is enabled
  static Future<bool> isCrashlyticsCollectionEnabled() async {
    try {
      return _crashlytics.isCrashlyticsCollectionEnabled;
    } catch (e) {
      return false;
    }
  }

  /// Force crash (for testing only!)
  static void forceCrash() {
    _crashlytics.crash();
  }
}
