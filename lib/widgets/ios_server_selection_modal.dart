import 'dart:convert';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  List<String> serverNames = [];
  bool isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _loadServers();
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadServers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? serversJson = prefs.getString('servers_list');
    
    if (serversJson != null) {
      List<dynamic> servers = jsonDecode(serversJson);
      setState(() {
        serverNames = servers.map((s) => s['name'].toString()).toList();
      });
    }
  }

  Future<void> _refreshServers() async {
    setState(() {
      isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userKey = prefs.getString('user_key');
      
      if (userKey == null || userKey.isEmpty) {
        final keyResponse = await Dio().get(
          "https://begzar-api.lastofanarchy.workers.dev/api/firebase/init/android",
          options: Options(
            headers: {'X-Content-Type-Options': 'nosniff'},
          ),
        ).timeout(Duration(seconds: 8));
        
        userKey = keyResponse.data['key'] as String;
        await prefs.setString('user_key', userKey);
      }

      final response = await Dio().get(
        "https://begzar-api.lastofanarchy.workers.dev/api/firebase/init/data/$userKey",
        options: Options(
          headers: {'X-Content-Type-Options': 'nosniff'},
        ),
      ).timeout(Duration(seconds: 8));

      if (response.data['status'] == true) {
        List<dynamic> serversJson = response.data['servers'];
        List<Map<String, String>> servers = [];
        
        for (var server in serversJson) {
          servers.add({
            'name': server['name'].toString(),
            'config': server['config'].toString()
          });
        }
        
        await prefs.setString('servers_list', jsonEncode(servers));
        
        setState(() {
          serverNames = servers.map((s) => s['name']!).toList();
        });

        if (mounted) {
          _showIOSSnackBar(context, '✓ Servers updated', isSuccess: true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showIOSSnackBar(context, '✗ Failed to update', isSuccess: false);
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showIOSSnackBar(BuildContext context, String message, {required bool isSuccess}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSuccess ? Color(0xFF34C759) : Color(0xFFFF3B30),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.24,
              ),
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
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFFF2F2F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: 8),
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              
              // Header
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('select_server'),
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.41,
                        color: Colors.black,
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      minSize: 32,
                      onPressed: isLoading ? null : _refreshServers,
                      child: isLoading
                          ? CupertinoActivityIndicator(radius: 10)
                          : Icon(
                              CupertinoIcons.refresh,
                              color: Color(0xFF007AFF),
                              size: 22,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListView(
                    shrinkWrap: true,
                    physics: ClampingScrollPhysics(),
                    padding: EdgeInsets.zero,
                    children: [
                      // Automatic
                      _buildServerTile(
                        icon: 'assets/lottie/auto.json',
                        title: 'Automatic',
                        isSelected: widget.selectedServer == 'Automatic',
                        onTap: () => widget.onServerSelected('Automatic'),
                        isFirst: true,
                      ),
                      
                      // Dynamic Servers
                      if (serverNames.isEmpty && !isLoading)
                        Container(
                          padding: EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(
                                CupertinoIcons.exclamationmark_triangle,
                                color: Colors.black.withOpacity(0.3),
                                size: 32,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'No servers found',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      ...serverNames.asMap().entries.map((entry) {
                        int index = entry.key;
                        String serverName = entry.value;
                        return _buildServerTile(
                          icon: 'assets/lottie/server.json',
                          title: serverName,
                          isSelected: widget.selectedServer == serverName,
                          onTap: () => widget.onServerSelected(serverName),
                          isLast: index == serverNames.length - 1,
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
      ),
    );
  }

  Widget _buildServerTile({
    required String icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Column(
      children: [
        if (!isFirst)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: 56,
            color: Colors.black.withOpacity(0.1),
          ),
        CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 32,
                  height: 32,
                  child: Lottie.asset(icon, width: 32, height: 32),
                ),
                
                SizedBox(width: 12),
                
                // Title
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.41,
                      color: Colors.black,
                    ),
                  ),
                ),
                
                // Checkmark
                if (isSelected)
                  Icon(
                    CupertinoIcons.checkmark_alt,
                    color: Color(0xFF007AFF),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
