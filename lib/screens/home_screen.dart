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
import 'package:flutter_v2ray_client/flutter_v2ray_client.dart';
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
  // V2Ray Client
  late final V2RayClient v2rayClient;
  String connectionState = 'DISCONNECTED'; // DISCONNECTED, CONNECTING, CONNECTED, ERROR
  Timer? _statsTimer;
  
  // Stats
  int uploadSpeed = 0;
  int downloadSpeed = 0;
  int upload = 0;
  int download = 0;
  String duration = '00:00:00';

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
    v2rayClient = V2RayClient();
    getVersionName();
    _loadServerSelection();
    _checkConnectionState();
    coreVersion = 'V2Ray Core';
    setState(() {});
  }

  // چک کردن وضعیت اتصال هر 1 ثانیه
  void _checkConnectionState() {
    Timer.periodic(Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      try {
        final state = await v2rayClient.getState();
        
        if (state != connectionState) {
          setState(() {
            connectionState = state;
          });
          
          // اگر متصل شد، شروع مانیتورینگ
          if (state == 'connected') {
            _startStatsMonitoring();
            Future.delayed(Duration(seconds: 2), () {
              delay();
            });
          } else if (state == 'disconnected') {
            _stopStatsMonitoring();
            setState(() {
              connectedServerDelay = null;
            });
          }
        }
      } catch (e) {
        print('Error checking state: $e');
      }
    });
  }

  // مانیتورینگ آمار
  void _startStatsMonitoring() {
    _statsTimer?.cancel();
    
    _statsTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      try {
        final stats = await v2rayClient.getStats();
        
        setState(() {
          upload = stats.upload;
          download = stats.download;
          uploadSpeed = stats.upload;
          downloadSpeed = stats.download;
          
          // محاسبه Duration
          int seconds = stats.duration;
          int hours = seconds ~/ 3600;
          int minutes = (seconds % 3600) ~/ 60;
          int secs = seconds % 60;
          duration = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
        });
        
      } catch (e) {
        print('Error getting stats: $e');
      }
    });
  }

  void _stopStatsMonitoring() {
    _statsTimer?.cancel();
    _statsTimer = null;
    setState(() {
      upload = 0;
      download = 0;
      uploadSpeed = 0;
      downloadSpeed = 0;
      duration = '00:00:00';
    });
  }

  // ساخت V2RayStatus شبیه‌ساز برای سازگاری با Widget های قدیمی
  V2RayStatus _createMockStatus() {
    return V2RayStatus(
      state: connectionState.toUpperCase(),
      upload: upload.toString(),
      download: download.toString(),
      uploadSpeed: uploadSpeed.toString(),
      downloadSpeed: downloadSpeed.toString(),
      duration: duration,
    );
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
                child: Builder(
                  builder: (context) {
                    final value = _createMockStatus();
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
    } else {
      // قطع اتصال
      setState(() {
        isLoading = true;
      });
      
      try {
        await v2rayClient.disconnect();
        _stopStatsMonitoring();
        print('✅ اتصال قطع شد');
      } catch (e) {
        print('❌ خطا در قطع اتصال: $e');
      }
      
      setState(() {
        isLoading = false;
      });
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
            if (connectionState == "DISCONNECTED") {
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
          servers.add({'name': server['name'], 'config': server['config']});
        }

        // ذخیره لیست جدید
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('servers_list', jsonEncode(servers));
      }
    } catch (e) {
      print('Error refreshing server list: $e');
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
          servers.add({'name': server['name'], 'config': server['config']});
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

    // 🎯 فیلتر کردن سرورها
    if (selectedServer == 'Automatic') {
      if (serverList.isNotEmpty) {
        filteredServers.add(serverList[0]);
        print('🔄 Automatic mode - انتخاب اولین سرور: ${serverList[0]['name']}');
      }
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

    print('📡 شروع Parse کانفیگ...');

    try {
      var server = filteredServers[0];
      print('🔧 Parse: ${server['name']}');
      print('📄 کانفیگ کامل:');
      print('   ${server['config']}');
      
      // Parse با API جدید
      final v2rayUrl = V2RayURL.parse(server['config']!);
      final config = v2rayUrl.config;
      
      print('✅ Parse موفق: ${server['name']}');
      print('📊 جزئیات Parse شده:');
      print('   - Protocol: ${config['outbounds'][0]['protocol']}');
      
      // درخواست دسترسی
      print('🚀 شروع اتصال...');
      final permissionGranted = await v2rayClient.requestPermission();
      
      if (!permissionGranted) {
        throw Exception('VPN permission denied');
      }
      
      print('✅ دسترسی VPN داده شد');
      print('🔌 در حال اتصال به V2Ray...');
      
      // اتصال
      await v2rayClient.connect(
        config: config,
        proxyOnly: false,
      );
      
      print('✅ V2Ray service شروع شد');
      print('⏳ منتظر اتصال...');
      
      // صبر برای اتصال
      await Future.delayed(Duration(seconds: 2));
      
      final state = await v2rayClient.getState();
      print('🔍 وضعیت اتصال: $state');
      
      if (state == 'connected') {
        print('🎉 اتصال برقرار شد!');
        
        // تست Ping
        Future.delayed(Duration(seconds: 2), () {
          delay();
        });
      }
      
    } catch (e, stackTrace) {
      print('❌ خطا در اتصال: $e');
      print('📚 StackTrace:');
      print(stackTrace.toString());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در اتصال: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      
      try {
        await v2rayClient.disconnect();
      } catch (_) {}
    }

    setState(() {
      isLoading = false;
    });
  }

  void delay() async {
    if (connectionState == 'connected') {
      try {
        // دریافت کانفیگ فعلی
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? serverListJson = prefs.getString('servers_list');
        
        if (serverListJson != null) {
          List<dynamic> serverList = jsonDecode(serverListJson);
          
          var server = serverList.firstWhere(
            (s) => s['name'] == selectedServer,
            orElse: () => serverList[0],
          );
          
          final v2rayUrl = V2RayURL.parse(server['config']);
          final config = v2rayUrl.config;
          
          int ping = await v2rayClient.delay(config);
          
          setState(() {
            connectedServerDelay = ping;
            isFetchingPing = true;
          });
          
          print('📶 Ping: $ping ms');
        }
      } catch (e) {
        print('⚠️ Ping failed: $e');
        setState(() {
          connectedServerDelay = null;
        });
      }
    }
    if (!mounted) return;
  }

  @override
  void dispose() {
    _stopStatsMonitoring();
    v2rayClient.dispose();
    super.dispose();
  }
}

// کلاس V2RayStatus برای سازگاری با Widget های قدیمی
class V2RayStatus {
  final String state;
  final String upload;
  final String download;
  final String uploadSpeed;
  final String downloadSpeed;
  final String duration;

  V2RayStatus({
    this.state = 'DISCONNECTED',
    this.upload = '0',
    this.download = '0',
    this.uploadSpeed = '0',
    this.downloadSpeed = '0',
    this.duration = '00:00:00',
  });
}
