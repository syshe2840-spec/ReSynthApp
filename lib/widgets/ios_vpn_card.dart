import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

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
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with server info
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Color(0xFF007AFF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Lottie.asset(
                          widget.selectedServerLogo,
                          width: 28,
                          height: 28,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.selectedServer,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.41,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Connected',
                            style: TextStyle(
                              fontSize: 13,
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
                
                SizedBox(height: 20),
                
                // Duration Badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.clock,
                        size: 16,
                        color: Color(0xFF007AFF),
                      ),
                      SizedBox(width: 6),
                      Text(
                        widget.duration,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.24,
                          color: Colors.black,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 20),
                
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
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      minSize: 0,
      borderRadius: BorderRadius.circular(8),
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
            CupertinoActivityIndicator(radius: 8)
          else ...[
            if (ipflag != null) ...[
              Text(
                ipflag!,
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(width: 6),
            ],
            Text(
              ipText ?? context.tr('show_ip'),
              style: TextStyle(
                fontSize: 13,
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
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
                size: 20,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
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
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                CupertinoIcons.arrow_down,
                size: 14,
                color: Colors.black.withOpacity(0.4),
              ),
              SizedBox(width: 4),
              Text(
                download,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.24,
                  color: Colors.black,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Icon(
                CupertinoIcons.arrow_up,
                size: 14,
                color: Colors.black.withOpacity(0.4),
              ),
              SizedBox(width: 4),
              Text(
                upload,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.24,
                  color: Colors.black,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Format for real-time speed - always shows MB/s
  String formatBytes(int bytes) {
    if (bytes <= 0) return '0.00 MB/s';
    const int mb = 1024 * 1024;
    double megabytes = bytes / mb;
    return '${megabytes.toStringAsFixed(2)} MB/s';
  }

  // Format for total usage - auto-scales without /s
  String formatSpeedBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const int kb = 1024;
    const int mb = kb * 1024;
    const int gb = mb * 1024;
    if (bytes < kb) return '${bytes} B';
    if (bytes < mb) return '${(bytes / kb).toStringAsFixed(1)} KB';
    if (bytes < gb) return '${(bytes / mb).toStringAsFixed(1)} MB';
    return '${(bytes / gb).toStringAsFixed(2)} GB';
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
