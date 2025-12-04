import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServerSelectionModal extends StatefulWidget {
  final String selectedServer;
  final Function(String) onServerSelected;
  
  ServerSelectionModal({
    required this.selectedServer, 
    required this.onServerSelected
  });

  @override
  State<ServerSelectionModal> createState() => _ServerSelectionModalState();
}

class _ServerSelectionModalState extends State<ServerSelectionModal> {
  List<String> serverNames = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadServers();
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

  // 🔄 رفرش لیست سرورها از API
  Future<void> _refreshServers() async {
    setState(() {
      isLoading = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userKey = prefs.getString('user_key');
      
      if (userKey == null || userKey.isEmpty) {
        // دریافت User Key
        final keyResponse = await Dio().get(
          "https://resynth-api.syshe2840.workers.dev/api/firebase/init/android",
          options: Options(
            headers: {'X-Content-Type-Options': 'nosniff'},
          ),
        ).timeout(Duration(seconds: 8));
        
        userKey = keyResponse.data['key'] as String;
        await prefs.setString('user_key', userKey);
      }

      // دریافت لیست سرورها
      final response = await Dio().get(
        "https://resynth-api.syshe2840.workers.dev/api/firebase/init/data/$userKey",
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
        
        // ذخیره لیست جدید
        await prefs.setString('servers_list', jsonEncode(servers));
        
        // آپدیت UI
        setState(() {
          serverNames = servers.map((s) => s['name']!).toList();
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ لیست سرورها بروزرسانی شد'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطا در بروزرسانی سرورها'),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.tr('select_server'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // 🔄 دکمه Refresh
                IconButton(
                  onPressed: isLoading ? null : _refreshServers,
                  icon: isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        )
                      : Icon(Icons.refresh, color: Colors.blue),
                  tooltip: 'بروزرسانی سرورها',
                ),
              ],
            ),
            SizedBox(height: 20),
            
            // Automatic
            ListTile(
              leading: Lottie.asset('assets/lottie/auto.json', width: 30),
              title: Text('Automatic'),
              trailing: widget.selectedServer == 'Automatic'
                  ? Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () => widget.onServerSelected('Automatic'),
            ),
            Divider(),
            
            // سرورهای داینامیک
            if (serverNames.isEmpty && !isLoading)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'هیچ سروری یافت نشد',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            
            ...serverNames.map((serverName) {
              return ListTile(
                leading: Lottie.asset('assets/lottie/server.json', width: 32),
                title: Text(
                  serverName,
                  style: TextStyle(fontFamily: 'GM'),
                ),
                trailing: widget.selectedServer == serverName
                    ? Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () => widget.onServerSelected(serverName),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
