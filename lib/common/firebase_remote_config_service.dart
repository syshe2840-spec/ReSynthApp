import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Firebase Remote Config Service
/// Allows changing app configuration remotely without update
class FirebaseRemoteConfigService {
  static final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;
  static bool _initialized = false;

  /// Initialize Firebase Remote Config
  static Future<void> initialize() async {
    try {
      // Set config settings
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      // Set default values
      await _remoteConfig.setDefaults({
        // App Settings
        'app_maintenance_mode': false,
        'app_force_update': false,
        'app_latest_version': '1.0.0',
        'app_update_url': '',

        // VPN Settings
        'vpn_auto_connect': false,
        'vpn_default_protocol': 'vmess',
        'vpn_connection_timeout': 30,

        // Server Configuration
        'servers_update_interval': 3600, // seconds
        'servers_config_url': '',

        // Feature Flags
        'feature_dark_mode': true,
        'feature_auto_reconnect': true,
        'feature_split_tunneling': false,

        // Messages
        'message_welcome': 'Welcome to ReSynth VPN!',
        'message_maintenance': 'App is under maintenance. Please try again later.',

        // Analytics
        'analytics_enabled': true,
      });

      // Fetch and activate
      await _remoteConfig.fetchAndActivate();
      _initialized = true;
    } catch (e) {
      // Silent error handling
      _initialized = false;
    }
  }

  /// Fetch latest config from server
  static Future<void> fetch() async {
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      // Silent error handling
    }
  }

  /// Get boolean value
  static bool getBool(String key) {
    try {
      return _remoteConfig.getBool(key);
    } catch (e) {
      return false;
    }
  }

  /// Get string value
  static String getString(String key) {
    try {
      return _remoteConfig.getString(key);
    } catch (e) {
      return '';
    }
  }

  /// Get int value
  static int getInt(String key) {
    try {
      return _remoteConfig.getInt(key);
    } catch (e) {
      return 0;
    }
  }

  /// Get double value
  static double getDouble(String key) {
    try {
      return _remoteConfig.getDouble(key);
    } catch (e) {
      return 0.0;
    }
  }

  /// Check if initialized
  static bool get isInitialized => _initialized;

  // Quick access methods for common settings

  /// Check if app is in maintenance mode
  static bool get isMaintenanceMode => getBool('app_maintenance_mode');

  /// Check if force update is required
  static bool get isForceUpdate => getBool('app_force_update');

  /// Get latest app version
  static String get latestAppVersion => getString('app_latest_version');

  /// Get app update URL
  static String get appUpdateUrl => getString('app_update_url');

  /// Get VPN auto-connect setting
  static bool get vpnAutoConnect => getBool('vpn_auto_connect');

  /// Get VPN default protocol
  static String get vpnDefaultProtocol => getString('vpn_default_protocol');

  /// Get VPN connection timeout
  static int get vpnConnectionTimeout => getInt('vpn_connection_timeout');

  /// Get servers update interval
  static int get serversUpdateInterval => getInt('servers_update_interval');

  /// Get servers config URL
  static String get serversConfigUrl => getString('servers_config_url');

  /// Check if dark mode feature is enabled
  static bool get featureDarkMode => getBool('feature_dark_mode');

  /// Check if auto-reconnect feature is enabled
  static bool get featureAutoReconnect => getBool('feature_auto_reconnect');

  /// Check if split tunneling feature is enabled
  static bool get featureSplitTunneling => getBool('feature_split_tunneling');

  /// Get welcome message
  static String get welcomeMessage => getString('message_welcome');

  /// Get maintenance message
  static String get maintenanceMessage => getString('message_maintenance');

  /// Check if analytics is enabled
  static bool get analyticsEnabled => getBool('analytics_enabled');
}
