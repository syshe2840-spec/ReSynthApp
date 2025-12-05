import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart' ;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

class IOSVpnCard extends StatefulWidget {
  final int downloadSpeed;
  final int uploadSpeed;
  final String selectedServer;
  final String selectedServerLogo;
  final String duration;
  final int download;
  final int upload;

  const IOSVpnCard({
    super.key,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.download,
    required this.upload,
    required this.selectedServer,
    required this.selectedServerLogo,
    required this.duration,
  });

  @override
  State<IOSVpnCard> createState() => _IOSVpnCardState();
}

class _IOSVpnCardState extends State<IOSVpnCard> {
  String? ipText;
  String? ipflag;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with server info
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(0xFF007AFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Lottie.asset(
                          widget.selectedServerLogo,
                          width: 22,
                          height: 22,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.selectedServer,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.41,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Connected',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              letterSpacing: -0.08,
                              color: Color(0xFF34C759),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildIPButton(),
                  ],
                ),

                SizedBox(height: 14),

                // Duration Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.clock,
                        size: 14,
                        color: Color(0xFF007AFF),
                      ),
                      SizedBox(width: 5),
                      Text(
                        toEnglishDigits(widget.duration),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.24,
                          color: Colors.black,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 14),
                
                // Stats
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: CupertinoIcons.arrow_down_circle_fill,
                        title: context.tr('realtime_usage'),
                        download: formatBytes(widget.downloadSpeed),
                        upload: formatBytes(widget.uploadSpeed),
                        color: Color(0xFF007AFF),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        icon: CupertinoIcons.arrow_up_arrow_down_circle_fill,
                        title: context.tr('total_usage'),
                        download: formatSpeedBytes(widget.download),
                        upload: formatSpeedBytes(widget.upload),
                        color: Color(0xFF34C759),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIPButton() {
    return CupertinoButton(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      minSize: 0,
      borderRadius: BorderRadius.circular(6),
      color: Color(0xFFF2F2F7),
      onPressed: isLoading ? null : () async {
        setState(() => isLoading = true);
        try {
          final ipInfo = await getIpApi();
          if (mounted) {
            setState(() {
              ipflag = countryCodeToFlagEmoji(ipInfo['countryCode']!);
              ipText = ipInfo['ip'];
              isLoading = false;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() => isLoading = false);
          }
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            CupertinoActivityIndicator(radius: 6)
          else ...[
            if (ipflag != null) ...[
              Text(
                ipflag!,
                style: TextStyle(fontSize: 12),
              ),
              SizedBox(width: 4),
            ],
            Text(
              ipText ?? context.tr('show_ip'),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.08,
                color: Colors.black.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String download,
    required String upload,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.07,
                    color: Colors.black.withOpacity(0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(
                CupertinoIcons.arrow_down,
                size: 12,
                color: Colors.black.withOpacity(0.4),
              ),
              SizedBox(width: 3),
              Flexible(
                child: Text(
                  download,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.24,
                    color: Colors.black,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 3),
          Row(
            children: [
              Icon(
                CupertinoIcons.arrow_up,
                size: 12,
                color: Colors.black.withOpacity(0.4),
              ),
              SizedBox(width: 3),
              Flexible(
                child: Text(
                  upload,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.24,
                    color: Colors.black,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Convert Persian/Arabic digits to English
  String toEnglishDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    String result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(persian[i], english[i]);
      result = result.replaceAll(arabic[i], english[i]);
    }
    return result;
  }

  // Format for real-time speed - always shows MB/s with English numbers
  String formatBytes(int bytes) {
    if (bytes <= 0) return '0.00 MB/s';
    const int mb = 1024 * 1024;
    double megabytes = bytes / mb;
    final formatter = NumberFormat('0.00', 'en_US');
    String result = formatter.format(megabytes);
    return '${toEnglishDigits(result)} MB/s';
  }

  // Format for total usage - auto-scales without /s with English numbers
  String formatSpeedBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;
    final formatter1 = NumberFormat('0.0', 'en_US');
    final formatter2 = NumberFormat('0.00', 'en_US');
    if (bytes < kb) {
      return '${toEnglishDigits('$bytes')} B';
    }
    if (bytes < mb) {
      String result = formatter1.format(bytes / kb);
      return '${toEnglishDigits(result)} KB';
    }
    if (bytes < gb) {
      String result = formatter1.format(bytes / mb);
      return '${toEnglishDigits(result)} MB';
    }
    String result = formatter2.format(bytes / gb);
    return '${toEnglishDigits(result)} GB';
  }
}

String countryCodeToFlagEmoji(String countryCode) {
  countryCode = countryCode.toUpperCase();
  return countryCode.codeUnits
      .map((codeUnit) => String.fromCharCode(0x1F1E6 + codeUnit - 0x41))
      .join();
}

Future<Map<String, String>> getIpApi() async {
  try {
    final dio = Dio();
    final response = await dio.get(
      'https://freeipapi.com/api/json',
      options: Options(
        headers: {'X-Content-Type-Options': 'nosniff'},
      ),
    );

    if (response.statusCode == 200) {
      final data = response.data;
      if (data != null && data is Map) {
        String ip = data['ipAddress'] ?? 'Unknown IP';
        if (ip.contains('.')) {
          final parts = ip.split('.');
          if (parts.length == 4) {
            ip = '${parts[0]}.*.*.${parts[3]}';
          }
        } else if (ip.contains(':')) {
          final parts = ip.split(':');
          if (parts.length > 4) {
            ip = '${parts[0]}:${parts[1]}:****:${parts.last}';
          }
        }
        return {'countryCode': data['countryCode'] ?? 'Unknown', 'ip': ip};
      }
    }
    return {'countryCode': 'Unknown', 'ip': 'Unknown IP'};
  } catch (e) {
    return {'countryCode': 'Error', 'ip': 'Error'};
  }
}
