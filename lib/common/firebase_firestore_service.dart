import 'package:cloud_firestore/cloud_firestore.dart';

/// Cloud Firestore Service
/// Advanced database with offline support
class FirebaseFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Initialize Firestore
  static Future<void> initialize() async {
    try {
      // Enable offline persistence
      await _firestore.enableNetwork();

      // Optional: Configure cache size (default is 100 MB)
      // _firestore.settings = Settings(
      //   cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      // );
    } catch (e) {
      // Silent error handling
    }
  }

  /// Save user data
  static Future<void> saveUserData({
    required String userId,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).set(
            userData,
            SetOptions(merge: true),
          );
    } catch (e) {
      // Silent error handling
    }
  }

  /// Get user data
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// Save VPN connection history
  static Future<void> saveConnectionHistory({
    required String userId,
    required String serverName,
    required String serverCountry,
    required DateTime connectedAt,
    required DateTime? disconnectedAt,
    required int durationSeconds,
  }) async {
    try {
      await _firestore.collection('connection_history').add({
        'user_id': userId,
        'server_name': serverName,
        'server_country': serverCountry,
        'connected_at': Timestamp.fromDate(connectedAt),
        'disconnected_at':
            disconnectedAt != null ? Timestamp.fromDate(disconnectedAt) : null,
        'duration_seconds': durationSeconds,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silent error handling
    }
  }

  /// Get connection history
  static Future<List<Map<String, dynamic>>> getConnectionHistory({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('connection_history')
          .where('user_id', isEqualTo: userId)
          .orderBy('connected_at', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save server list
  static Future<void> saveServerList(List<Map<String, dynamic>> servers) async {
    try {
      final batch = _firestore.batch();

      for (final server in servers) {
        final docRef = _firestore
            .collection('servers')
            .doc(server['name'] ?? 'unknown');
        batch.set(docRef, {
          ...server,
          'updated_at': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      // Silent error handling
    }
  }

  /// Get server list
  static Future<List<Map<String, dynamic>>> getServerList() async {
    try {
      final querySnapshot = await _firestore
          .collection('servers')
          .orderBy('name')
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Save user settings
  static Future<void> saveUserSettings({
    required String userId,
    required Map<String, dynamic> settings,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('preferences')
          .set(settings, SetOptions(merge: true));
    } catch (e) {
      // Silent error handling
    }
  }

  /// Get user settings
  static Future<Map<String, dynamic>?> getUserSettings(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('preferences')
          .get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// Listen to real-time updates
  static Stream<List<Map<String, dynamic>>> listenToServerList() {
    try {
      return _firestore
          .collection('servers')
          .orderBy('name')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList());
    } catch (e) {
      return Stream.value([]);
    }
  }

  /// Delete connection history
  static Future<void> deleteConnectionHistory(String historyId) async {
    try {
      await _firestore.collection('connection_history').doc(historyId).delete();
    } catch (e) {
      // Silent error handling
    }
  }

  /// Clear all connection history for user
  static Future<void> clearConnectionHistory(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('connection_history')
          .where('user_id', isEqualTo: userId)
          .get();

      final batch = _firestore.batch();
      for (final doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      // Silent error handling
    }
  }
}
