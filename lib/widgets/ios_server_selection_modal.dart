import 'dart:convert';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:resynth/common/ios_theme.dart';

class IOSServerSelectionModal extends StatefulWidget {
  final String selectedServer;
  final Function(String) onServerSelected;
  
  const IOSServerSelectionModal({
    super.key,
    required this.selectedServer,
    required this.onServerSelected,
  });

  @override
  State<IOSServerSelectionModal> createState() => _IOSServerSelectionModalState();
}

class _IOSServerSelectionModalState extends State<IOSServerSelectionModal>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> servers = [];
  bool isLoading = false;
  bool isRefreshing = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadServers();
    
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadServers() async {
    setState(() => isLoading = true);
    
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? serversJson = prefs.getString('servers_list');
      
      if (serversJson != null) {
        List<dynamic> serversList = jsonDecode(serversJson);
        setState(() {
          servers = serversList.map((s) {
            return {
              'name': s['name'].toString(),
              'config': s['config'].toString(),
              'ping': null,
            };
          }).toList();
        });
      }
    } catch (e) {
      // Silent error handling
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _refreshServers() async {
    setState(() => isRefreshing = true);

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userKey = prefs.getString('user');
      
      if (userKey == null || userKey.isEmpty) {
        final keyResponse = await Dio().get(
          "https://resynth-api.syshe2840.workers.dev/api/firebase/init/android",
          options: Options(
            headers: {'X-Content-Type-Options': 'nosniff'},
          ),
        ).timeout(Duration(seconds: 8));
        
        userKey = keyResponse.data['key'] as String;
        await prefs.setString('user', userKey);
      }

      final response = await Dio().get(
        "https://resynth-api.syshe2840.workers.dev/api/firebase/init/data/$userKey",
        options: Options(
          headers: {'X-Content-Type-Options': 'nosniff'},
        ),
      ).timeout(Duration(seconds: 8));

      if (response.data['status'] == true) {
        List<dynamic> serversJson = response.data['servers'];
        List<Map<String, String>> serversList = [];
        
        for (var server in serversJson) {
          serversList.add({
            'name': server['name'].toString(),
            'config': server['config'].toString(),
          });
        }
        
        await prefs.setString('servers_list', jsonEncode(serversList));
        await prefs.setString('last_server_update', DateTime.now().toIso8601String());
        
        await _loadServers();

        if (mounted) {
          _showSuccessToast('Servers updated successfully');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorToast('Failed to update servers');
      }
    } finally {
      setState(() => isRefreshing = false);
    }
  }

  void _showSuccessToast(String message) {
    _showToast(message, IOSColors.systemGreen);
  }

  void _showErrorToast(String message) {
    _showToast(message, IOSColors.systemRed);
  }

  void _showToast(String message, Color color) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  color == IOSColors.systemGreen
                      ? CupertinoIcons.checkmark_alt_circle_fill
                      : CupertinoIcons.xmark_circle_fill,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: IOSTypography.subheadline.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _animationController.value) * 400),
          child: Opacity(
            opacity: _animationController.value,
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: IOSColors.systemGroupedBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: EdgeInsets.only(top: 10),
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: IOSColors.tertiaryLabel,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            
            // Header
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    context.tr('select_server'),
                    style: IOSTypography.title3.copyWith(
                      color: IOSColors.label,
                    ),
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 0,
                    onPressed: isRefreshing ? null : _refreshServers,
                    child: isRefreshing
                        ? CupertinoActivityIndicator(radius: 10)
                        : Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: IOSColors.systemBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              CupertinoIcons.arrow_clockwise,
                              color: IOSColors.systemBlue,
                              size: 20,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            
            // Server List
            Flexible(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: IOSColors.secondarySystemGroupedBackground,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: isLoading
                    ? Container(
                        height: 200,
                        child: Center(
                          child: CupertinoActivityIndicator(),
                        ),
                      )
                    : ListView(
                        shrinkWrap: true,
                        physics: BouncingScrollPhysics(),
                        padding: EdgeInsets.zero,
                        children: [
                          _buildServerTile(
                            icon: 'assets/lottie/auto.json',
                            title: 'Automatic',
                            subtitle: 'Best server selected automatically',
                            isSelected: widget.selectedServer == 'Automatic',
                            onTap: () => widget.onServerSelected('Automatic'),
                            isFirst: true,
                          ),
                          
                          ...servers.asMap().entries.map((entry) {
                            int index = entry.key;
                            var server = entry.value;
                            return _buildServerTile(
                              icon: 'assets/lottie/server.json',
                              title: server['name'],
                              subtitle: _getServerLocation(server['config']),
                              ping: server['ping'],
                              isSelected: widget.selectedServer == server['name'],
                              onTap: () => widget.onServerSelected(server['name']),
                              isLast: index == servers.length - 1,
                            );
                          }).toList(),
                        ],
                      ),
              ),
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  String _getServerLocation(String config) {
    try {
      if (config.contains('@')) {
        final parts = config.split('@');
        if (parts.length > 1) {
          final hostPart = parts[1].split(':')[0];
          if (hostPart.contains('.')) {
            return hostPart.split('.')[0];
          }
        }
      }
    } catch (e) {
      // ignore
    }
    return 'Server';
  }

  Widget _buildServerTile({
    required String icon,
    required String title,
    String? subtitle,
    int? ping,
    required bool isSelected,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        if (!isFirst)
          Padding(
            padding: EdgeInsets.only(left: 64),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: IOSColors.separator,
            ),
          ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? IOSColors.systemBlue.withOpacity(0.1)
                        : IOSColors.tertiarySystemFill,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Lottie.asset(
                      icon,
                      width: 24,
                      height: 24,
                    ),
                  ),
                ),
                
                SizedBox(width: 12),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: IOSTypography.body.copyWith(
                          color: IOSColors.label,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: IOSTypography.footnote.copyWith(
                            color: IOSColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                if (ping != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    margin: EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _getPingColor(ping).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${ping}ms',
                      style: IOSTypography.caption2.copyWith(
                        color: _getPingColor(ping),
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                
                if (isSelected)
                  Icon(
                    CupertinoIcons.checkmark_alt,
                    color: IOSColors.systemBlue,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getPingColor(int ping) {
    if (ping < 100) return IOSColors.systemGreen;
    if (ping < 200) return IOSColors.systemOrange;
    return IOSColors.systemRed;
  }
}
