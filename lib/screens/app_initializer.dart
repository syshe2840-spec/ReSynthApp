import 'package:flutter/material.dart';
import 'package:resynth/common/firebase_analytics_service.dart';
import 'package:resynth/common/firebase_crashlytics_service.dart';
import 'package:resynth/common/firebase_firestore_service.dart';
import 'package:resynth/common/firebase_messaging_service.dart';
import 'package:resynth/common/firebase_performance_service.dart';
import 'package:resynth/common/firebase_remote_config_service.dart';
import 'package:resynth/common/firebase_tracker.dart';
import 'package:resynth/screens/splash_screen.dart';

class AppInitializer extends StatefulWidget {
  final Widget child;

  const AppInitializer({super.key, required this.child});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize all Firebase services in parallel
      await Future.wait([
        FirebaseCrashlyticsService.initialize(),
        FirebaseAnalyticsService.initialize(),
        FirebasePerformanceService.initialize(),
        FirebaseFirestoreService.initialize(),
        FirebaseMessagingService.initialize(),
        FirebaseRemoteConfigService.initialize(),
      ]);

      // Initialize user tracking
      await FirebaseTracker.initUser();
      await FirebaseTracker.trackAppOpen();
      await FirebaseAnalyticsService.logAppOpen();
    } catch (e) {
      // Silent error handling
    }

    // Mark as initialized
    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const SplashScreen();
    }

    return widget.child;
  }
}
