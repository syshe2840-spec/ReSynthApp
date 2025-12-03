import 'dart:async';
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:begzar/common/cha.dart';
import 'package:begzar/common/http_client.dart';
import 'package:begzar/common/secure_storage.dart';
import 'package:begzar/common/ios_theme.dart';
import 'package:begzar/widgets/ios_connection_widget.dart';
import 'package:begzar/widgets/ios_server_selection_modal.dart';
import 'package:begzar/widgets/ios_vpn_card.dart';
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

class _HomePageState extends State<HomePage> {
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

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bool isWideScreen = size.width > 600;

    return Scaffold(
      appBar: isWideScreen ? null : _buildAppBar(isWideScreen),
      backgroundColor: IOSColors.systemGroupedBackground,
      body: SafeArea(
        child: Column(
          children: [
            // iOS-style Server Selector
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
              child: Center(
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
                                        download: int.parse(value.download),
                                        upload: int.parse(value.upload),
                                        downloadSpeed: int.parse(value.downloadSpeed),
                                        uploadSpeed: int.parse(value.uploadSpeed),
                                        selectedServer: selectedServer,
                                        selectedServerLogo:
                                            selectedServerLogo ??
                                                'assets/lottie/auto.json',
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
                                const SizedBox(height: 32),
                                IOSVpnCard(
                                  download: int.parse(value.download),
                                  upload: int.parse(value.upload),
                                  downloadSpeed: int.parse(value.downloadSpeed),
                                  uploadSpeed: int.parse(value.uploadSpeed),
                                  selectedServer: selectedServer,
                                  selectedServerLogo: selectedServerLogo ??
                                      'assets/lottie/auto.json',
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
          child: Image.asset(
            'assets/images/logo_transparent.png',
            color: IOSColors.systemBlue,
            height: 32,
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
    return Container(
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
          if (connectedServerDelay == null)
            CupertinoActivityIndicator(radius: 10)
          else ...[
            Icon(
              CupertinoIcons.wifi,
              color: IOSColors.systemGreen,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              '${connectedServerDelay}ms',
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

      domainName = 'begzar-api.lastofanarchy.workers.dev';
      await _refreshServerList();
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
      }
    } catch (e) {
      print('Error refreshing server list: $e');
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
      print('🔄 Automatic mode - تست ${serverList.length} سرور');
    } else {
      var found = serverList.where((s) => s['name'] == selectedServer).toList();
      if (found.isNotEmpty) {
        filteredServers.add(found[0]);
        print('✅ سرور انتخاب شده: ${found[0]['name']}');
      } else {
        print('❌ سرور "$selectedServer" پیدا نشد!');
      }
    }

    if (filteredServers.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('سرور "$selectedServer" موجود نیست'),
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

    print('📡 شروع Parse کانفیگ‌ها...');

    for (var server in filteredServers) {
      try {
        print('🔧 Parse: ${server['name']}');
        print('   URL: ${server['config']!.substring(0, 50)}...');

        final V2RayURL v2rayURL = FlutterV2ray.parseFromURL(server['config']!);
        String fullConfig = v2rayURL.getFullConfiguration();

        configList.add(fullConfig);
        print('✅ Parse موفق: ${server['name']}');
      } catch (e) {
        print('❌ خطا در Parse ${server['name']}: $e');
      }
    }

    if (configList.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در پردازش کانفیگ سرورها'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      setState(() {
        isLoading = false;
      });
      return;
    }

    print('📊 تعداد کانفیگ‌های آماده: ${configList.length}');

    if (configList.length == 1) {
      print('🚀 اتصال مستقیم به سرور...');
      String bestConfig = configList[0];

      if (await flutterV2ray.requestPermission()) {
        print('✅ دسترسی VPN داده شد');
        try {
          flutterV2ray.startV2Ray(
            remark: context.tr('app_title'),
            config: bestConfig,
            proxyOnly: false,
            bypassSubnets: null,
            notificationDisconnectButtonName: context.tr('disconnect_btn'),
            blockedApps: blockedApps,
          );
          print('✅ V2Ray شروع شد');
        } catch (e) {
          print('❌ خطا در شروع V2Ray: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('خطا در اتصال: $e'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        print('❌ دسترسی VPN رد شد');
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
      print('🎯 Automatic mode - شروع تست ping...');

      try {
        Map<String, dynamic> getAllDelay =
            jsonDecode(await flutterV2ray.getAllServerDelay(configs: configList));

        print('📊 نتایج Ping:');
        getAllDelay.forEach((key, value) {
          print(
              '   Config ${getAllDelay.keys.toList().indexOf(key) + 1}: ${value}ms');
        });

        int minPing = 99999999;
        String bestConfig = '';

        getAllDelay.forEach((key, value) {
          if (value < minPing && value != -1) {
            bestConfig = key;
            minPing = value;
          }
        });

        if (bestConfig.isNotEmpty) {
          print('🎯 بهترین سرور: Ping = ${minPing}ms');

          if (await flutterV2ray.requestPermission()) {
            flutterV2ray.startV2Ray(
              remark: context.tr('app_title'),
              config: bestConfig,
              proxyOnly: false,
              bypassSubnets: null,
              notificationDisconnectButtonName: context.tr('disconnect_btn'),
              blockedApps: blockedApps,
            );
            print('✅ اتصال به بهترین سرور');
          } else {
            print('❌ دسترسی VPN رد شد');
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
          print('❌ هیچ سرور فعالی یافت نشد');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('هیچ سرور فعالی یافت نشد. همه سرورها Timeout شدند.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        print('❌ خطا در تست ping: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطا در تست سرورها: $e'),
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
      connectedServerDelay = await flutterV2ray.getConnectedServerDelay();
      setState(() {
        isFetchingPing = true;
      });
    }
    if (!mounted) return;
  }
}
