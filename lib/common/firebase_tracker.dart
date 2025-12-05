import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class FirebaseTracker {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static String? _userId;

  /// Initialize user tracking
  static Future<void> initUser() async {
    print('🔥 FirebaseTracker: initUser() started');
    try {
      // Generate unique user ID based on device
      _userId = await _getDeviceId();
      print('🔥 FirebaseTracker: Device ID = $_userId');

      // Create user entry in Firebase
      print('🔥 FirebaseTracker: Sending user data to Firebase...');
      await _database.ref('users/$_userId').set({
        'first_seen': DateTime.now().toIso8601String(),
        'last_seen': DateTime.now().toIso8601String(),
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'app_version': '1.0.0',
        'status': 'active',
      });
      print('🔥 FirebaseTracker: User data sent successfully!');

      // Track in daily stats
      final today = DateTime.now().toIso8601String().split('T')[0];
      print('🔥 FirebaseTracker: Updating daily stats for $today...');
      await _database.ref('stats/daily/$today/active_users').set(
        ServerValue.increment(1),
      );
      print('🔥 FirebaseTracker: Daily stats updated!');
      print('✅ FirebaseTracker: initUser() completed successfully!');

    } catch (e, stackTrace) {
      print('❌ Firebase tracking error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Track VPN connection
  static Future<void> trackConnection({
    required String serverName,
    required bool connected,
  }) async {
    if (_userId == null) {
      print('⚠️ FirebaseTracker: trackConnection() called but _userId is null');
      return;
    }

    try {
      print('🔥 FirebaseTracker: Tracking connection - Server: $serverName, Connected: $connected');
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
      print('✅ FirebaseTracker: Connection tracked successfully!');
    } catch (e, stackTrace) {
      print('❌ Firebase tracking error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Track app open
  static Future<void> trackAppOpen() async {
    print('🔥 FirebaseTracker: trackAppOpen() started');
    if (_userId == null) {
      print('⚠️ FirebaseTracker: trackAppOpen() called but _userId is null');
      return;
    }

    try {
      await _database.ref('users/$_userId').update({
        'last_seen': DateTime.now().toIso8601String(),
      });

      final today = DateTime.now().toIso8601String().split('T')[0];
      await _database.ref('stats/daily/$today/app_opens').set(
        ServerValue.increment(1),
      );
      print('✅ FirebaseTracker: trackAppOpen() completed!');
    } catch (e, stackTrace) {
      print('❌ Firebase tracking error: $e');
      print('Stack trace: $stackTrace');
    }
  }

  /// Get device ID for unique user identification
  static Future<String> _getDeviceId() async {
    print('🔥 FirebaseTracker: Getting device ID...');
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      // Replace invalid characters for Firebase paths
      final deviceId = 'android_${androidInfo.id}'
          .replaceAll('.', '_')
          .replaceAll('#', '_')
          .replaceAll('\$', '_')
          .replaceAll('[', '_')
          .replaceAll(']', '_');
      print('🔥 FirebaseTracker: Android device ID = $deviceId');
      return deviceId;
    } else {
      final iosInfo = await deviceInfo.iosInfo;
      final deviceId = 'ios_${iosInfo.identifierForVendor}'
          .replaceAll('.', '_')
          .replaceAll('#', '_')
          .replaceAll('\$', '_')
          .replaceAll('[', '_')
          .replaceAll(']', '_');
      print('🔥 FirebaseTracker: iOS device ID = $deviceId');
      return deviceId;
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
