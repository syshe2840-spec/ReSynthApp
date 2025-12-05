import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

/// Firebase Cloud Messaging Service
/// Handles push notifications
class FirebaseMessagingService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static String? _fcmToken;

  /// Initialize Firebase Cloud Messaging
  static Future<void> initialize() async {
    try {
      // Request permission for iOS
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Get FCM token
        _fcmToken = await _messaging.getToken();

        if (_fcmToken != null) {
          // Save token to Firebase Database
          await _saveTokenToDatabase(_fcmToken!);
        }

        // Listen for token refresh
        _messaging.onTokenRefresh.listen(_saveTokenToDatabase);

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

        // Handle background messages
        FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

        // Handle notification tap (app opened from notification)
        FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      }
    } catch (e) {
      // Silent error handling
    }
  }

  /// Save FCM token to Firebase Database
  static Future<void> _saveTokenToDatabase(String token) async {
    try {
      _fcmToken = token;
      final deviceId = await _getDeviceId();
      await _database.ref('device_tokens/$deviceId').set({
        'token': token,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Silent error handling
    }
  }

  /// Handle foreground messages (when app is open)
  static void _handleForegroundMessage(RemoteMessage message) {
    // Notification received while app is in foreground
    // You can show in-app notification here
  }

  /// Handle background messages (when app is in background)
  @pragma('vm:entry-point')
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    // Handle background notification
  }

  /// Handle notification tap (when user taps notification)
  static void _handleNotificationTap(RemoteMessage message) {
    // Handle notification tap - navigate to specific screen
  }

  /// Get FCM token
  static String? get fcmToken => _fcmToken;

  /// Get device ID (simplified version)
  static Future<String> _getDeviceId() async {
    // Use a simple timestamp-based ID for token storage
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      // Silent error handling
    }
  }

  /// Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      // Silent error handling
    }
  }
}
