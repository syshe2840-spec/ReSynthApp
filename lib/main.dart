import 'package:begzar/common/theme.dart';
import 'package:begzar/screens/about_screen.dart';
import 'package:begzar/screens/home_screen.dart';
import 'package:begzar/screens/settings_screen.dart';
import 'package:begzar/widgets/navigation_rail_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax/iconsax.dart';
import 'package:safe_device/safe_device.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool isJailBroken = await SafeDevice.isJailBroken;
  if (isJailBroken != true) {
    await EasyLocalization.ensureInitialized();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      systemNavigationBarColor: ThemeColor.backgroundColor,
      systemNavigationBarIconBrightness: Brightness.light,
    ));
    runApp(
      EasyLocalization(
        supportedLocales: [
          Locale('en', 'US'),
          Locale('fa', 'IR'),
          Locale('zh', 'CN'),
          Locale('ru', 'RU'),
        ],
        path: 'assets/translations',
        fallbackLocale: Locale('en', 'US'),
        startLocale: Locale('en', 'US'),
        saveLocale: true,
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
    final defaultTextStyle =
        TextStyle(fontFamily: 'sm', color: Color(0xffF7FAFF));
    return MaterialApp(
      title: 'Begzar VPN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: TextTheme(
          titleLarge: defaultTextStyle,
          titleMedium: defaultTextStyle,
          titleSmall: defaultTextStyle,
          bodyLarge: defaultTextStyle,
          bodyMedium: defaultTextStyle,
          bodySmall: defaultTextStyle,
          labelLarge: defaultTextStyle,
          labelMedium: defaultTextStyle,
          labelSmall: defaultTextStyle,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: ThemeColor.backgroundColor,
        brightness: Brightness.dark,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: RootScreen(),
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
      bottomNavigationBar: !isWideScreen
          ? Container(
              decoration: BoxDecoration(
                color: Color(0xff192028),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
              child: NavigationBar(
                backgroundColor: Color(0xff192028),
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  setState(() => _selectedIndex = index);
                },
                destinations: [
                  NavigationDestination(
                    icon: Icon(Iconsax.setting, color: Colors.grey),
                    selectedIcon: Icon(Iconsax.setting, color: Colors.white),
                    label: '',
                  ),
                  NavigationDestination(
                    icon: Icon(Iconsax.home, color: Colors.grey),
                    selectedIcon: Icon(Iconsax.home, color: Colors.white),
                    label: '',
                  ),
                  NavigationDestination(
                    icon: Icon(Iconsax.info_circle, color: Colors.grey),
                    selectedIcon:
                        Icon(Iconsax.info_circle, color: Colors.white),
                    label: '',
                  ),
                ],
              ),
            )
          : null,
    );
  }
}
