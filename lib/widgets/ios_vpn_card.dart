import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:begzar/common/ios_theme.dart';

class IOSVpnCard extends StatefulWidget {
  final String downloadSpeed;
  final String uploadSpeed;
  final String selectedServer;
  final String selectedServerLogo;
  final String duration;
  final String download;
  final String upload;

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

class _IOSVpnCardState extends State<IOSVpnCard> with TickerProviderStateMixin {
  String? ipText;
  String? ipflag;
  bool isLoading = false;
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            IOSColors.secondarySystemGroupedBackground,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: IOSColors.systemBlue.withOpacity(0.1),
            blurRadius: 30,
            offset: Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Animated gradient overlay
            AnimatedBuilder(
              animation: _shimmerController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(-1.0 + (_shimmerController.value * 2), -1.0),
                      end: Alignment(1.0 + (_shimmerController.value * 2), 1.0),
                      colors: [
                        Colors.transparent,
                        IOSColors.systemBlue.withOpacity(0.02),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
            
            // Content
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              IOSColors.systemBlue.withOpacity(0.2),
                              IOSColors.systemBlue.withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: IOSColors.systemBlue.withOpacity(0.2),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Lottie.asset(
                            widget.selectedServerLogo,
                            width: 32,
                            height: 32,
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
                              style: IOSTypography.headline.copyWith(
                                color: IOSColors.label,
                              ),
                            ),
                            SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: IOSColors.systemGreen,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: IOSColors.systemGreen.withOpacity(0.5),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Connected',
                                  style: IOSTypography.footnote.copyWith(
                                    color: IOSColors.systemGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _buildIPButton(),
                    ],
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Duration
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: IOSColors.tertiarySystemFill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.clock_fill,
                          size: 16,
                          color: IOSColors.systemBlue,
                        ),
                        SizedBox(width: 6),
                        Text(
                          widget.duration,
                          style: IOSTypography.subheadline.copyWith(
                            color: IOSColors.label,
                            fontWeight: FontWeight.w600,
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
                          icon: CupertinoIcons.speedometer,
                          title: context.tr('realtime_usage'),
                          download: widget.downloadSpeed,
                          upload: widget.uploadSpeed,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              IOSColors.systemBlue.withOpacity(0.1),
                              IOSColors.systemBlue.withOpacity(0.05),
                            ],
                          ),
                          borderColor: IOSColors.systemBlue.withOpacity(0.2),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          icon: CupertinoIcons.chart_bar_fill,
                          title: context.tr('total_usage'),
                          download: widget.download,
                          upload: widget.upload,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              IOSColors.systemGreen.withOpacity(0.1),
                              IOSColors.systemGreen.withOpacity(0.05),
                            ],
                          ),
                          borderColor: IOSColors.systemGreen.withOpacity(0.2),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIPButton() {
    return CupertinoButton(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      minSize: 0,
      borderRadius: BorderRadius.circular(10),
      color: IOSColors.tertiarySystemFill,
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
            Icon(
              CupertinoIcons.location_fill,
              size: 14,
              color: IOSColors.systemBlue,
            ),
            if (ipflag != null || ipText != null) ...[
              SizedBox(width: 6),
              if (ipflag != null)
                Text(
                  ipflag!,
                  style: TextStyle(fontSize: 14),
                ),
              if (ipText != null) ...[
                if (ipflag != null) SizedBox(width: 4),
                Text(
                  ipText!,
                  style: IOSTypography.footnote.copyWith(
                    color: IOSColors.label,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
            if (ipflag == null && ipText == null) ...[
              SizedBox(width: 4),
              Text(
                'IP',
                style: IOSTypography.footnote.copyWith(
                  color: IOSColors.label,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
    required Gradient gradient,
    required Color borderColor,
  }) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: IOSColors.systemBlue,
                  size: 18,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: IOSTypography.caption1.copyWith(
                    color: IOSColors.secondaryLabel,
                    fontWeight: FontWeight.w600,
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
                color: IOSColors.tertiaryLabel,
              ),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  download,
                  style: IOSTypography.subheadline.copyWith(
                    color: IOSColors.label,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(
                CupertinoIcons.arrow_up,
                size: 14,
                color: IOSColors.tertiaryLabel,
              ),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  upload,
                  style: IOSTypography.subheadline.copyWith(
                    color: IOSColors.label,
                    fontWeight: FontWeight.w600,
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
    ).timeout(Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = response.data;
      if (data != null && data is Map) {
        String ip = data['ipAddress'] ?? 'Unknown';
        if (ip.contains('.')) {
          final parts = ip.split('.');
          if (parts.length == 4) {
            ip = '${parts[0]}.${parts[1]}.*.${parts[3]}';
          }
        } else if (ip.contains(':')) {
          final parts = ip.split(':');
          if (parts.length > 4) {
            ip = '${parts[0]}:${parts[1]}::${parts.last}';
          }
        }
        return {
          'countryCode': data['countryCode'] ?? 'XX',
          'ip': ip,
        };
      }
    }
    return {'countryCode': 'XX', 'ip': 'Unknown'};
  } catch (e) {
    return {'countryCode': 'XX', 'ip': 'Error'};
  }
}
