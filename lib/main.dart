import 'package:resynth/common/ios_theme.dart';
import 'package:resynth/common/firebase_tracker.dart';
import 'package:resynth/common/firebase_messaging_service.dart';
import 'package:resynth/common/firebase_remote_config_service.dart';
import 'package:resynth/common/firebase_analytics_service.dart';
import 'package:resynth/common/firebase_crashlytics_service.dart';
import 'package:resynth/common/firebase_performance_service.dart';
import 'package:resynth/common/firebase_firestore_service.dart';
import 'package:resynth/screens/about_screen.dart';
import 'package:resynth/screens/app_initializer.dart';
import 'package:resynth/screens/home_screen.dart';
import 'package:resynth/screens/settings_screen.dart';
import 'package:resynth/screens/splash_screen.dart';
import 'package:resynth/widgets/navigation_rail_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_v2ray/model/v2ray_status.dart';
import 'package:iconsax/iconsax.dart';
import 'package:safe_device/safe_device.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Force English locale for numbers
  Intl.defaultLocale = 'en_US';

  // Initialize Firebase Core only (fast!)
  try {
    if (Firebase.apps.isEmpty) {
      try {
        final options = DefaultFirebaseOptions.currentPlatform;
        await Firebase.initializeApp(options: options);
      } catch (e) {
        if (!e.toString().contains('duplicate-app')) {
          rethrow;
        }
      }
    }
  } catch (e) {
    // Silent error handling
  }

  bool isJailBroken = await SafeDevice.isJailBroken;
  if (isJailBroken != true) {
    await EasyLocalization.ensureInitialized();

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: IOSColors.systemBackground,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));

    runApp(
      EasyLocalization(
        supportedLocales: [
          Locale('en', 'US'),
          Locale('zh', 'CN'),
          Locale('ru', 'RU'),
        ],
        path: 'assets/translations',
        fallbackLocale: Locale('en', 'US'),
        startLocale: Locale('en', 'US'),
        saveLocale: false,
        child: MyApp(),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final defaultTextStyle = TextStyle(
      fontFamily: 'sm',
      color: IOSColors.label,
    );

    return MaterialApp(
      title: 'ReSynth VPN',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        FirebaseAnalyticsService.observer,
      ],

      // iOS Theme
      theme: IOSTheme.lightTheme.copyWith(
        textTheme: TextTheme(
          titleLarge: defaultTextStyle.copyWith(fontSize: 28, fontWeight: FontWeight.w700),
          titleMedium: defaultTextStyle.copyWith(fontSize: 22, fontWeight: FontWeight.w700),
          titleSmall: defaultTextStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w600),
          bodyLarge: defaultTextStyle.copyWith(fontSize: 17, fontWeight: FontWeight.w400),
          bodyMedium: defaultTextStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w400),
          bodySmall: defaultTextStyle.copyWith(fontSize: 13, fontWeight: FontWeight.w400),
          labelLarge: defaultTextStyle.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
          labelMedium: defaultTextStyle.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
          labelSmall: defaultTextStyle.copyWith(fontSize: 13, fontWeight: FontWeight.w400),
        ),
      ),

      // Restore EasyLocalization but force English locale
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,

      home: AppInitializer(
        child: RootScreen(),
      ),
    );
  }
}

class RootScreen extends StatefulWidget {
  RootScreen({super.key});

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _selectedIndex = 1;
  final v2rayStatus = ValueNotifier<V2RayStatus>(V2RayStatus());
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [SettingsWidget(), HomePage(), AboutScreen()];
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: IOSColors.systemGroupedBackground,
      body: Row(
        children: [
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
          AnimatedSlide(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            offset: isWideScreen ? Offset.zero : Offset(1, 0),
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 200),
              opacity: isWideScreen ? 1 : 0,
              child: isWideScreen
                  ? NavigationRailWidget(
                      selectedIndex: _selectedIndex,
                      singStatus: v2rayStatus,
                      onDestinationSelected: (index) {
                        setState(() => _selectedIndex = index);
                      },
                    )
                  : SizedBox(),
            ),
          ),
        ],
      ),
      
      // iOS-style Bottom Navigation
      bottomNavigationBar: !isWideScreen
          ? Container(
              decoration: BoxDecoration(
                color: IOSColors.systemBackground,
                border: Border(
                  top: BorderSide(
                    color: IOSColors.separator,
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                child: Container(
                  height: 50,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildNavItem(
                        icon: Iconsax.setting,
                        index: 0,
                      ),
                      _buildNavItem(
                        icon: Iconsax.home,
                        index: 1,
                      ),
                      _buildNavItem(
                        icon: Iconsax.info_circle,
                        index: 2,
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
  }) {
    final isSelected = _selectedIndex == index;
    
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          setState(() => _selectedIndex = index);
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? IOSColors.systemBlue : IOSColors.secondaryLabel,
                size: 24,
              ),
              SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? IOSColors.systemBlue : Colors.transparent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
