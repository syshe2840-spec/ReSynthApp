import 'dart:async';
import 'dart:convert';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:begzar/common/cha.dart';
import 'package:begzar/common/http_client.dart';
import 'package:begzar/common/secure_storage.dart';
import 'package:begzar/widgets/connection_widget.dart';
import 'package:begzar/widgets/server_selection_modal_widget.dart';
import 'package:begzar/widgets/vpn_status.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_v2ray/flutter_v2ray.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../common/theme.dart';

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
      backgroundColor: const Color(0xff192028),
      body: SafeArea(
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _showServerSelectionModal(context),
              child: Container(
                margin: const EdgeInsets.all(16),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Lottie.asset(
                      selectedServerLogo ?? 'assets/lottie/auto.json',
                      width: 24,
                      height: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      selectedServer,
                      style: TextStyle(
                        color: Colors.grey[300],
                        fontSize: 16,
                        fontFamily: 'GM',
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.keyboard_arrow_down, color: Colors.grey[400]),
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
                                        ConnectionWidget(
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
                                      child: VpnCard(
                                        download: value.download,
                                        upload: value.upload,
                                        downloadSpeed: value.downloadSpeed,
                                        uploadSpeed: value.uploadSpeed,
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
                              ConnectionWidget(
                                onTap: () => _handleConnectionTap(value),
                                isLoading: isLoading,
                                status: value.state,
                              ),
                              if (value.state == 'CONNECTED') ...[
                                const SizedBox(height: 16),
                                _buildDelayIndicator(),
                                const SizedBox(height: 60),
                                VpnCard(
                                  download: value.download,
                                  upload: value.upload,
                                  downloadSpeed: value.downloadSpeed,
                                  uploadSpeed: value.uploadSpeed,
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
          color: ThemeColor.foregroundColor,
          fontSize: isWideScreen ? 22 : 18,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/images/logo_transparent.png',
            color: ThemeColor.foregroundColor,
            height: 50,
          ),
        ),
      ],
      automaticallyImplyLeading: !isWideScreen,
      centerTitle: true,
      backgroundColor: ThemeColor.backgroundColor,
      elevation: 0,
    );
  }

  Widget _buildDelayIndicator() {
    return Container(
      margin: const EdgeInsets.only(top: 0),
      width: connectedServerDelay == null ? 50 : 90,
      height: 30,
      child: Center(
        child: connectedServerDelay == null
            ? LoadingAnimationWidget.fallingDot(
                color: const Color.fromARGB(255, 214, 182, 0),
                size: 35,
              )
            : _buildDelayDisplay(),
      ),
    );
  }

  Widget _buildDelayDisplay() {
    return SizedBox(
      height: 50,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: delay,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.wifi, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              connectedServerDelay.toString(),
              style: TextStyle(fontFamily: 'GM'),
            ),
            const SizedBox(width: 4),
            const Text('ms'),
          ],
        ),
      ),
    );
  }

  void _handleConnectionTap(V2RayStatus value) async {
    if (value.state == "DISCONNECTED") {
      getDomain();
      // initKey();
    } else {
      flutterV2ray.stopV2Ray();
    }
  }


  void _showServerSelectionModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
    ),
    builder: (BuildContext context) {
      return ServerSelectionModal(
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
  } else if (selectedServer == 'Server 3') {  // اضافه شد
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
    
    // 🔥 مستقیم به Cloudflare Worker وصل میشیم
    domainName = 'begzar-api.lastofanarchy.workers.dev';
    
    // 🔄 رفرش لیست سرورها قبل از اتصال
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

// 🔄 تابع رفرش لیست سرورها
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

    // دریافت لیست سرورها
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
        servers.add({
          'name': server['name'],
          'config': server['config']
        });
      }
      
      // ذخیره لیست جدید
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('servers_list', jsonEncode(servers));
    }
  } catch (e) {
    print('Error refreshing server list: $e');
  }
}

  String decrypt(String secureData, String x1, String x2, String key) {
    final encryptedData = {
      'ciphertext': secureData, // secure
      'nonce': x1, // x1
      'tag': x2 // x2
    };
    final savedKey = key;
    try {
      final decrypted = Decryptor.decryptChaCha20(encryptedData, savedKey);
      return decrypted.toString();
    } catch (e) {
      return 'Error during decryption: $e';
    }
  }

 void checkUpdate() async {
  try {
    // 🔑 دریافت یا ساخت User Key
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

    // 📡 دریافت لیست سرورها
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
      
      // 🔥 دریافت سرورها با نام
      List<dynamic> serversJson = dataJson['servers'];
      List<Map<String, String>> servers = [];
      
      for (var server in serversJson) {
        servers.add({
          'name': server['name'],
          'config': server['config']
        });
      }
      
      // ذخیره لیست سرورها
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('servers_list', jsonEncode(servers));

      // ✅ چک ورژن
      if (version == versionName) {
        await connect(servers);
      } else {
        // 🔄 نمایش دیالوگ آپدیت
        if (updateUrl.isNotEmpty) {
          AwesomeDialog(
            context: context,
            dialogType: DialogType.warning,
            title: context.tr('update_title'),
            desc: context.tr('update_description'),
            dialogBackgroundColor: Colors.white,
            btnCancelOnPress: () {},
            btnOkOnPress: () async {
              await launchUrl(Uri.parse(utf8.decode(base64Decode(updateUrl))),
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
          content: Text(
            context.tr('error_no_server_connected'),
          ),
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

  // 🎯 فیلتر کردن سرورها بر اساس انتخاب کاربر
  if (selectedServer == 'Automatic') {
    // همه سرورها
    filteredServers = serverList;
  } else {
    // سرور خاص بر اساس نام
    var found = serverList.where((s) => s['name'] == selectedServer).toList();
    if (found.isNotEmpty) {
      filteredServers.add(found[0]);
    }
  }

  if (filteredServers.isEmpty) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('error_no_server_connected'),
          ),
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

  // تبدیل URL به کانفیگ
  filteredServers.forEach((server) {
    final V2RayURL v2rayURL = FlutterV2ray.parseFromURL(server['config']!);
    configList.add(v2rayURL.getFullConfiguration());
  });

  // 🚀 اگر فقط یک سرور انتخاب شده، مستقیم وصل میشیم
  if (configList.length == 1) {
    String bestConfig = configList[0];
    
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
    // 🎯 Automatic mode - تست همه و انتخاب بهترین
    Map<String, dynamic> getAllDelay =
        jsonDecode(await flutterV2ray.getAllServerDelay(configs: configList));

    int minPing = 99999999;
    String bestConfig = '';

    getAllDelay.forEach(
      (key, value) {
        if (value < minPing && value != -1) {
          setState(() {
            bestConfig = key;
            minPing = value;
          });
        }
      },
    );

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
            content: Text(
              context.tr('error_no_server_connected'),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future.delayed(
    Duration(seconds: 1),
    () {
      delay();
    },
  );
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
