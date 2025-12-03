import 'package:begzar/screens/home_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:math';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

class NavigationRailWidget extends StatefulWidget {
  final int selectedIndex;
  final ValueNotifier<V2RayStatus>? singStatus;
  final Function(int) onDestinationSelected;

  NavigationRailWidget({
    Key? key,
    required this.selectedIndex,
    required this.singStatus,
    required this.onDestinationSelected,
  }) : super(key: key);

  @override
  State<NavigationRailWidget> createState() => _NavigationRailWidgetState();
}

class _NavigationRailWidgetState extends State<NavigationRailWidget> {
  String? ip;
  String? countryCode;

  Future<Map<String, String>> getIpApi() async {
    try {
      final dio = Dio();
      dio.httpClientAdapter = IOHttpClientAdapter()
        ..createHttpClient = () {
          final client = HttpClient();
          client.findProxy = (uri) {
            return 'PROXY 127.0.0.1:8569';
          };
          return client;
        };

      final response = await dio.get(
        'https://freeipapi.com/api/json',
        options: Options(
          followRedirects: true,
          validateStatus: (status) => true,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data is Map) {
          String ip = data['ipAddress'] ?? 'نامشخص';

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
      return {'countryCode': 'IR', 'ip': 'Unknown'};
    } catch (e) {
      return {'countryCode': 'IR', 'ip': 'Error'};
    }
  }

  String countryCodeToFlagEmoji(String countryCode) {
    countryCode = countryCode.toUpperCase();
    return countryCode.codeUnits
        .map((codeUnit) => String.fromCharCode(0x1F1E6 + codeUnit - 0x41))
        .join();
  }

  String formatBytes(int bytes) {
    if (bytes <= 0) return '0B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)}${suffixes[i]}';
  }

  String formatSpeedBytes(int bytes) {
    if (bytes <= 0) return '0B/s';
    const suffixes = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(2)}${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isExtraWideScreen = size.width > 12000;

    return Container(
      width: isExtraWideScreen ? 180 : 88,
      child: Column(
        children: [
          const SizedBox(height: 50),
          Text(
            context.tr('app_title'),
            style: TextStyle(fontFamily: 'sb', fontSize: 20),
          ),
          const Spacer(),
          _buildNavItems(isExtraWideScreen),
        ],
      ),
    );
  }

  Widget _buildNavItems(bool isExtraWideScreen) {
    return Column(
      children: [
        _buildNavItem(
          Iconsax.setting,
          '',
          0,
          isExtraWideScreen,
        ),
        _buildNavItem(
          Iconsax.home,
          '',
          1,
          isExtraWideScreen,
        ),
        _buildNavItem(
          Iconsax.info_circle,
          '',
          2,
          isExtraWideScreen,
        ),
      ],
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    bool showLabel,
  ) {
    final isSelected = widget.selectedIndex == index;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onDestinationSelected(index),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: showLabel ? 150 : 60,
            padding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
            decoration: BoxDecoration(
              color: isSelected ? Colors.grey[800] : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.grey[600],
                  size: 24,
                ),
                if (showLabel) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[600],
                      fontSize: 14,
                      fontFamily: 'sm',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
