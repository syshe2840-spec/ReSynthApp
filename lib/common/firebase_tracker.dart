import 'package:firebase_database/firebase_database.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class FirebaseTracker {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static String? _userId;

  /// Initialize user tracking
  static Future<void> initUser() async {
    try {
      // Generate unique user ID based on device
      _userId = await _getDeviceId();

      // Create user entry in Firebase
      await _database.ref('users/$_userId').set({
        'first_seen': DateTime.now().toIso8601String(),
        'last_seen': DateTime.now().toIso8601String(),
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'app_version': '1.0.0',
        'status': 'active',
      });

      // Track in daily stats
      final today = DateTime.now().toIso8601String().split('T')[0];
      await _database.ref('stats/daily/$today/active_users').set(
        ServerValue.increment(1),
      );

    } catch (e) {
      print('Firebase tracking error: $e');
    }
  }

  /// Track VPN connection
  static Future<void> trackConnection({
    required String serverName,
    required bool connected,
  }) async {
    if (_userId == null) return;

    try {
      await _database.ref('users/$_userId').update({
        'last_seen': DateTime.now().toIso8601String(),
        'current_server': connected ? serverName : null,
        'is_connected': connected,
      });

      // Track connection stats
      if (connected) {
        final today = DateTime.now().toIso8601String().split('T')[0];
        await _database.ref('stats/daily/$today/connections').set(
          ServerValue.increment(1),
        );
        await _database.ref('stats/servers/$serverName/connections').set(
          ServerValue.increment(1),
        );
      }
    } catch (e) {
      print('Firebase tracking error: $e');
    }
  }

  /// Track app open
  static Future<void> trackAppOpen() async {
    if (_userId == null) return;

    try {
      await _database.ref('users/$_userId').update({
        'last_seen': DateTime.now().toIso8601String(),
      });

      final today = DateTime.now().toIso8601String().split('T')[0];
      await _database.ref('stats/daily/$today/app_opens').set(
        ServerValue.increment(1),
      );
    } catch (e) {
      print('Firebase tracking error: $e');
    }
  }

  /// Get device ID for unique user identification
  static Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return 'android_${androidInfo.id}';
    } else {
      final iosInfo = await deviceInfo.iosInfo;
      return 'ios_${iosInfo.identifierForVendor}';
    }
  }

  /// Get total active users (last 30 days)
  static Future<int> getActiveUsersCount() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(Duration(days: 30));
      final snapshot = await _database.ref('users').get();

      if (!snapshot.exists) return 0;

      int count = 0;
      final users = snapshot.value as Map<dynamic, dynamic>;

      users.forEach((key, value) {
        final lastSeen = DateTime.parse(value['last_seen']);
        if (lastSeen.isAfter(thirtyDaysAgo)) {
          count++;
        }
      });

      return count;
    } catch (e) {
      print('Error getting active users: $e');
      return 0;
    }
  }
}
