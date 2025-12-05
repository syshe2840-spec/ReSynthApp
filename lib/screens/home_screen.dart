import 'dart:async';
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:resynth/common/cha.dart';
import 'package:resynth/common/http_client.dart';
import 'package:resynth/common/secure_storage.dart';
import 'package:resynth/common/ios_theme.dart';
import 'package:resynth/common/encryption_helper.dart';
import 'package:resynth/widgets/ios_connection_widget.dart';
import 'package:resynth/widgets/ios_server_selection_modal.dart';
import 'package:resynth/widgets/ios_vpn_card.dart';
import 'package:resynth/widgets/ios_dialog.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:lottie/lottie.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  var v2rayStatus = ValueNotifier<V2RayStatus>(V2RayStatus());
  late final FlutterV2ray flutterV2ray = FlutterV2ray(
    onStatusChanged: (status) {
      v2rayStatus.value = status;
    },
  );

  bool proxyOnly = false;
  List<String> bypassSubnets = [];
  String? coreVersion;
  String? versionName;
  bool isLoading = false;
  int? connectedServerDelay;
  late SharedPreferences _prefs;
  String selectedServer = 'Automatic';
  String? selectedServerLogo;
  String? domainName;
  bool isFetchingPing = false;
  List<String> blockedApps = [];

  // Advanced logo animation controllers
  late AnimationController _logoMainController;
  late AnimationController _logoPulseController;
  late Animation<double> _logoRotation;
  late Animation<double> _logoScale;
  late Animation<double> _logoPulse;
  late Animation<double> _logoOpacity;
  late Animation<Color?> _logoColor;

  @override
  void initState() {
    super.initState();

    // Main animation controller
    _logoMainController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    // Pulse animation controller
    _logoPulseController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    // Rotation animation (360 degrees with bounce)
    _logoRotation = Tween<double>(
      begin: 0,
      end: 2 * 3.14159,
    ).animate(
      CurvedAnimation(
        parent: _logoMainController,
        curve: Curves.elasticOut,
      ),
    );

    // Scale animation (bounce effect)
    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.3).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.3, end: 0.9).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.0).chain(
          CurveTween(curve: Curves.bounceOut),
        ),
        weight: 40,
      ),
    ]).animate(_logoMainController);

    // Pulse animation
    _logoPulse = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _logoPulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Opacity animation (fade in/out)
    _logoOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.5),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.5, end: 1.0),
        weight: 50,
      ),
    ]).animate(_logoMainController);

    // Color animation (blue to purple and back)
    _logoColor = ColorTween(
      begin: IOSColors.systemBlue,
      end: Color(0xFF5856D6), // iOS purple
    ).animate(_logoMainController);

    getVersionName();
    _loadServerSelection();
    flutterV2ray
        .initializeV2Ray(
      notificationIconResourceType: "mipmap",
      notificationIconResourceName: "launcher_icon",
    )
        .then((value) async {
      coreVersion = await flutterV2ray.getCoreVersion();

      setState(() {});
      Future.delayed(
        Duration(seconds: 1),
        () {
          if (v2rayStatus.value.state == 'CONNECTED') {
            delay();
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _logoMainController.dispose();
    _logoPulseController.dispose();
    super.dispose();
  }

  void _animateLogo() {
    // Main animation
    _logoMainController.forward(from: 0).then((_) {
      // Start pulse animation
      _logoPulseController.repeat(reverse: true);
      Future.delayed(Duration(milliseconds: 800), () {
        _logoPulseController.stop();
        _logoPulseController.reset();
      });
    });
  }

String _toEnglishDigits(String input) {
  print("[NUMBER] home_screen toEnglishDigits INPUT: $input");
  const english = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];
  const persian = ["۰", "۱", "۲", "۳", "۴", "۵", "۶", "۷", "۸", "۹"];
  const arabic = ["٠", "١", "٢", "٣", "٤", "٥", "٦", "٧", "٨", "٩"];
  String result = input.toString();
  for (int i = 0; i < 10; i++) {
    result = result.replaceAll(persian[i], english[i]);
    result = result.replaceAll(arabic[i], english[i]);
  }
  print("[NUMBER] home_screen toEnglishDigits OUTPUT: $result");
  return result;
}

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bool isWideScreen = size.width > 600;

    return Scaffold(
      appBar: isWideScreen ? null : _buildAppBar(isWideScreen),
      backgroundColor: IOSColors.systemGroupedBackground,
      body: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showServerSelectionModal(context),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: IOSColors.systemBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Lottie.asset(
                          selectedServerLogo ?? 'assets/lottie/auto.json',
                          width: 20,
                          height: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        selectedServer,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.41,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.black.withOpacity(0.3),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: Align(
                alignment: Alignment(0, -0.15), // Slightly above center for better positioning
                child: ValueListenableBuilder(
                  valueListenable: v2rayStatus,
                  builder: (context, value, child) {
                    final size = MediaQuery.sizeOf(context);
                    final bool isWideScreen = size.width > 600;
                    return isWideScreen
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Expanded(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IOSConnectionWidget(
                                          onTap: () =>
                                              _handleConnectionTap(value),
                                          isLoading: isLoading,
                                          status: value.state,
                                        ),
                                        if (value.state == 'CONNECTED') ...[
                                          const SizedBox(height: 16),
                                          _buildDelayIndicator(),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (value.state == 'CONNECTED') ...[
                                    Expanded(
                                      child: IOSVpnCard(
                                        download: value.download,
                                        upload: value.upload,
                                        downloadSpeed: value.downloadSpeed,
                                        uploadSpeed: value.uploadSpeed,
                                        selectedServer: selectedServer,
                                        selectedServerLogo: selectedServerLogo ?? 'assets/lottie/auto.json',
                                        duration: value.duration,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IOSConnectionWidget(
                                onTap: () => _handleConnectionTap(value),
                                isLoading: isLoading,
                                status: value.state,
                              ),
                              if (value.state == 'CONNECTED') ...[
                                const SizedBox(height: 16),
                                _buildDelayIndicator(),
                                const SizedBox(height: 20),
                                IOSVpnCard(
                                  download: value.download,
                                  upload: value.upload,
                                  downloadSpeed: value.downloadSpeed,
                                  uploadSpeed: value.uploadSpeed,
                                  selectedServer: selectedServer,
                                  selectedServerLogo: selectedServerLogo ?? 'assets/lottie/auto.json',
                                  duration: value.duration,
                                ),
                              ],
                            ],
                          );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isWideScreen) {
    return AppBar(
      title: Text(
        context.tr('app_title'),
        style: TextStyle(
          color: IOSColors.label,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.41,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: _animateLogo,
            child: AnimatedBuilder(
              animation: Listenable.merge([_logoMainController, _logoPulseController]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoScale.value * _logoPulse.value,
                  child: Transform.rotate(
                    angle: _logoRotation.value,
                    child: Opacity(
                      opacity: _logoOpacity.value,
                      child: Image.asset(
                        'assets/images/logo_transparent.png',
                        color: _logoColor.value,
                        height: 32,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
      automaticallyImplyLeading: !isWideScreen,
      centerTitle: true,
      backgroundColor: IOSColors.systemBackground,
      elevation: 0,
    );
  }

  Widget _buildDelayIndicator() {
    return GestureDetector(
      onTap: () {
        if (!isFetchingPing && v2rayStatus.value.state == 'CONNECTED') {
          delay();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (connectedServerDelay == null || isFetchingPing)
              CupertinoActivityIndicator(radius: 10)
            else ...[
              Icon(
                CupertinoIcons.wifi,
                color: IOSColors.systemGreen,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                _toEnglishDigits('${connectedServerDelay}ms'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.24,
                  color: Colors.black,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleConnectionTap(V2RayStatus value) async {
    if (value.state == "DISCONNECTED") {
      getDomain();
    } else {
      flutterV2ray.stopV2Ray();
    }
  }

  void _showServerSelectionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return IOSServerSelectionModal(
          selectedServer: selectedServer,
          onServerSelected: (server) {
            if (v2rayStatus.value.state == "DISCONNECTED") {
              String logoPath = server == 'Automatic'
                  ? 'assets/lottie/auto.json'
                  : 'assets/lottie/server.json';

              setState(() {
                selectedServer = server;
              });
              _saveServerSelection(server, logoPath);
              Navigator.pop(context);
            } else {
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.tr('error_change_server'),
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  String getServerParam() {
    if (selectedServer == 'Server 1') {
      return 'server_1';
    } else if (selectedServer == 'Server 2') {
      return 'server_2';
    } else if (selectedServer == 'Server 3') {
      return 'server_3';
    } else {
      return 'auto';
    }
  }

  Future<void> _loadServerSelection() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedServer = _prefs.getString('selectedServers') ?? 'Automatic';
      selectedServerLogo =
          _prefs.getString('selectedServerLogos') ?? 'assets/lottie/auto.json';
    });
  }

  Future<void> _saveServerSelection(String server, String logoPath) async {
    await _prefs.setString('selectedServers', server);
    await _prefs.setString('selectedServerLogos', logoPath);
    setState(() {
      selectedServer = server;
      selectedServerLogo = logoPath;
    });
  }

  Future<List<String>> getDeviceArchitecture() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    return androidInfo.supportedAbis;
  }

  void getVersionName() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      versionName = packageInfo.version;
    });
  }

  Future<void> getDomain() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        isLoading = true;
        blockedApps = prefs.getStringList('blockedApps') ?? [];
      });

      domainName = 'resynth-api.syshe2840.workers.dev';

      // Auto-refresh server list on first launch and every 24 hours
      String? lastUpdate = prefs.getString('last_server_update');
      bool shouldUpdate = false;
      bool isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

      if (isFirstLaunch || lastUpdate == null) {
        shouldUpdate = true;
        await prefs.setBool('is_first_launch', false);
      } else {
        try {
          DateTime lastUpdateTime = DateTime.parse(lastUpdate);
          Duration difference = DateTime.now().difference(lastUpdateTime);

          if (difference.inHours >= 24) {
            shouldUpdate = true;
          }
        } catch (e) {
          shouldUpdate = true;
        }
      }

      if (shouldUpdate) {
        await _refreshServerList();
      }

      checkUpdate();
    } on TimeoutException catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message!),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('error_domain')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _refreshServerList() async {
    try {
      String userKey = await storage.read(key: 'user') ?? '';

      if (userKey == '') {
        final response = await Dio().get(
          "https://$domainName/api/firebase/init/android",
          options: Options(
            headers: {'X-Content-Type-Options': 'nosniff'},
          ),
        ).timeout(Duration(seconds: 8));

        userKey = response.data['key'];
        await storage.write(key: 'user', value: userKey);
      }

      final response = await Dio().get(
        "https://$domainName/api/firebase/init/data/$userKey",
        options: Options(
          headers: {'X-Content-Type-Options': 'nosniff'},
        ),
      ).timeout(Duration(seconds: 8));

      if (response.data['status'] == true) {
        List<dynamic> serversJson = response.data['servers'];
        List<Map<String, String>> servers = [];

        for (var server in serversJson) {
          servers.add({'name': server['name'], 'config': server['config']});
        }

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('servers_list', jsonEncode(servers));
        await prefs.setString('last_server_update', DateTime.now().toIso8601String());
      }
    } catch (e) {
      // Silent error handling
    }
  }

  void checkUpdate() async {
    try {
      String userKey = await storage.read(key: 'user') ?? '';
      if (userKey == '') {
        final response = await Dio()
            .get(
          "https://$domainName/api/firebase/init/android",
          options: Options(
            headers: {
              'X-Content-Type-Options': 'nosniff',
            },
          ),
        )
            .timeout(
          Duration(seconds: 8),
          onTimeout: () {
            throw TimeoutException(context.tr('error_timeout'));
          },
        );
        final dataJson = response.data;
        final key = dataJson['key'];
        userKey = key;
        await storage.write(key: 'user', value: key);
      }

      final response = await Dio()
          .get(
        "https://$domainName/api/firebase/init/data/$userKey",
        options: Options(
          headers: {
            'X-Content-Type-Options': 'nosniff',
          },
        ),
      )
          .timeout(
        Duration(seconds: 8),
        onTimeout: () {
          throw TimeoutException(context.tr('error_timeout'));
        },
      );

      if (response.data['status'] == true) {
        final dataJson = response.data;
        final version = dataJson['version'];
        final updateUrl = dataJson['updated_url'];

        // Handle notification from server
        if (dataJson['notification'] != null) {
          final notification = dataJson['notification'];
          SharedPreferences prefs = await SharedPreferences.getInstance();
          bool shownOnce = prefs.getBool('notification_shown') ?? false;

          if (!shownOnce || notification['show_once'] == false) {
            IOSDialog.show(
              context: context,
              title: notification['title'] ?? 'Notification',
              message: notification['message'] ?? '',
              type: _getDialogType(notification['type']),
              primaryButtonText: 'OK',
              onPrimaryPressed: () async {
                await prefs.setBool('notification_shown', true);
              },
            );
          }
        }

        // Handle force update from server
        if (dataJson['force_update'] != null) {
          final forceUpdate = dataJson['force_update'];
          if (forceUpdate['required'] == true) {
            String minVersion = forceUpdate['min_version'] ?? '0.0.0';
            if (_compareVersions(versionName!, minVersion) < 0) {
              IOSDialog.show(
                context: context,
                title: forceUpdate['title'] ?? 'Update Required',
                message: forceUpdate['message'] ?? 'Please update to continue',
                type: IOSDialogType.warning,
                primaryButtonText: 'Update',
                secondaryButtonText: 'Later',
                dismissible: false,
                onPrimaryPressed: () async {
                  String downloadUrl = forceUpdate['download_url'] ?? '';
                  if (downloadUrl.isNotEmpty) {
                    await launchUrl(
                      Uri.parse(utf8.decode(base64Decode(downloadUrl))),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
              );
              return; // Don't connect if force update required
            }
          }
        }

        List<dynamic> serversJson = dataJson['servers'];
        List<Map<String, String>> servers = [];

        for (var server in serversJson) {
          servers.add({'name': server['name'], 'config': server['config']});
        }

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('servers_list', jsonEncode(servers));

        if (version == versionName) {
          await connect(servers);
        } else {
          if (updateUrl.isNotEmpty) {
            AwesomeDialog(
              context: context,
              dialogType: DialogType.warning,
              title: context.tr('update_title'),
              desc: context.tr('update_description'),
              dialogBackgroundColor: Colors.white,
              btnCancelOnPress: () {},
              btnOkOnPress: () async {
                await launchUrl(
                    Uri.parse(utf8.decode(base64Decode(updateUrl))),
                    mode: LaunchMode.externalApplication);
              },
              btnOkText: context.tr('download'),
              btnCancelText: context.tr('close'),
              buttonsTextStyle: TextStyle(
                  fontFamily: 'sm', color: Colors.white, fontSize: 14),
              titleTextStyle: TextStyle(
                  fontFamily: 'sb', color: Colors.black, fontSize: 16),
              descTextStyle: TextStyle(
                  fontFamily: 'sm', color: Colors.black, fontSize: 14),
            )..show();
          }
        }
      } else {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr('request_limit'),
                style: TextStyle(
                  fontFamily: 'GM',
                ),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } on TimeoutException catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.message!,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('error_get_version'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> connect(List<Map<String, String>> serverList) async {
    if (serverList.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('error_no_server_connected')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() {
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    List<Map<String, String>> filteredServers = [];

    if (selectedServer == 'Automatic') {
      filteredServers = serverList;
    } else {
      var found = serverList.where((s) => s['name'] == selectedServer).toList();
      if (found.isNotEmpty) {
        filteredServers.add(found[0]);
      }
    }

    if (filteredServers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Server "$selectedServer" not available'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() {
        isLoading = false;
      });
      return;
    }

    List<String> configList = [];

    for (var server in filteredServers) {
      try {
        // Decrypt server config before parsing
        String config = server['config']!;
        String decryptedConfig = EncryptionHelper.decryptServer(config);

        final V2RayURL v2rayURL = FlutterV2ray.parseFromURL(decryptedConfig);
        String fullConfig = v2rayURL.getFullConfiguration();
        configList.add(fullConfig);
      } catch (e) {
        // Silent error handling - config might not be encrypted or invalid
      }
    }

    if (configList.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing server configs'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (configList.length == 1) {
      String bestConfig = configList[0];

      if (await flutterV2ray.requestPermission()) {
        try {
          flutterV2ray.startV2Ray(
            remark: context.tr('app_title'),
            config: bestConfig,
            proxyOnly: false,
            bypassSubnets: null,
            notificationDisconnectButtonName: context.tr('disconnect_btn'),
            blockedApps: blockedApps,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Connection error: $e'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.tr('error_permission')),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      try {
        Map<String, dynamic> getAllDelay =
            jsonDecode(await flutterV2ray.getAllServerDelay(configs: configList));

        int minPing = 99999999;
        String bestConfig = '';

        getAllDelay.forEach((key, value) {
          if (value < minPing && value != -1) {
            bestConfig = key;
            minPing = value;
          }
        });

        if (bestConfig.isNotEmpty) {
          if (await flutterV2ray.requestPermission()) {
            flutterV2ray.startV2Ray(
              remark: context.tr('app_title'),
              config: bestConfig,
              proxyOnly: false,
              bypassSubnets: null,
              notificationDisconnectButtonName: context.tr('disconnect_btn'),
              blockedApps: blockedApps,
            );
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(context.tr('error_permission')),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('No active servers found. All servers timed out.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Server test error: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    Future.delayed(Duration(seconds: 1), () {
      delay();
    });

    setState(() {
      isLoading = false;
    });
  }

  void delay() async {
    if (v2rayStatus.value.state == 'CONNECTED') {
      setState(() {
        isFetchingPing = true;
        connectedServerDelay = null;
      });

      connectedServerDelay = await flutterV2ray.getConnectedServerDelay();

      if (mounted) {
        setState(() {
          isFetchingPing = false;
        });
      }
    }
  }

  // Helper: Get dialog type from string
  IOSDialogType _getDialogType(String? type) {
    switch (type) {
      case 'success':
        return IOSDialogType.success;
      case 'error':
        return IOSDialogType.error;
      case 'warning':
        return IOSDialogType.warning;
      case 'notification':
        return IOSDialogType.notification;
      default:
        return IOSDialogType.info;
    }
  }

  // Helper: Compare versions (e.g., "5.5.0" vs "6.0.0")
  int _compareVersions(String v1, String v2) {
    List<int> parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      int part1 = i < parts1.length ? parts1[i] : 0;
      int part2 = i < parts2.length ? parts2[i] : 0;
      if (part1 < part2) return -1;
      if (part1 > part2) return 1;
    }
    return 0;
  }
}
