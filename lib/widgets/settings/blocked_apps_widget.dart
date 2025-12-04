import 'package:resynth/common/ios_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BlockedAppsWidgets extends StatefulWidget {
  BlockedAppsWidgets({super.key});

  @override
  State<BlockedAppsWidgets> createState() => _BlockedAppsWidgetsState();
}

class _BlockedAppsWidgetsState extends State<BlockedAppsWidgets>
    with SingleTickerProviderStateMixin {
  List<AppInfo>? apps;
  List<AppInfo>? filteredApps;
  List<String> blockedApps = [];
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  bool isSearchReady = false;
  bool isLoadSystemApps = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    searchController.addListener(_filterApps);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedBlockedApps = prefs.getStringList('blockedApps') ?? [];
    bool? savedIsLoadSystemApps = prefs.getBool('isLoadSystemApps');

    setState(() {
      blockedApps = savedBlockedApps;
      isLoadSystemApps = savedIsLoadSystemApps ?? false;
    });

    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() {
      isLoading = true;
    });

    List<AppInfo> installedApps =
        await InstalledApps.getInstalledApps(!isLoadSystemApps, true);

    setState(() {
      apps = installedApps;

      apps!.sort((a, b) {
        bool aIsBlocked = blockedApps.contains(a.packageName);
        bool bIsBlocked = blockedApps.contains(b.packageName);
        return (bIsBlocked ? 1 : 0).compareTo(aIsBlocked ? 1 : 0);
      });

      filteredApps = apps;
      isLoading = false;

      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            isSearchReady = true;
          });
        }
      });
    });
  }

  void _filterApps() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredApps = apps?.where((app) {
        return app.name.toLowerCase().contains(query) ||
            app.packageName.toLowerCase().contains(query);
      }).toList();

      filteredApps!.sort((a, b) {
        bool aIsBlocked = blockedApps.contains(a.packageName);
        bool bIsBlocked = blockedApps.contains(b.packageName);
        return (bIsBlocked ? 1 : 0).compareTo(aIsBlocked ? 1 : 0);
      });
    });
  }

  Future<void> _saveBlockedApps() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('blockedApps', blockedApps);
    await prefs.setBool('isLoadSystemApps', isLoadSystemApps);
  }

  void _toggleBlockedApp(String packageName) {
    setState(() {
      if (blockedApps.contains(packageName)) {
        blockedApps.remove(packageName);
      } else {
        blockedApps.add(packageName);
      }
    });
    _saveBlockedApps();
  }

  void _toggleSystemApps() {
    setState(() {
      isLoading = true;
      isLoadSystemApps = !isLoadSystemApps;
    });
    _saveBlockedApps();
    _loadApps();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSColors.systemGroupedBackground,
      appBar: AppBar(
        backgroundColor: IOSColors.systemBackground,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Icon(
            CupertinoIcons.back,
            color: IOSColors.systemBlue,
          ),
        ),
        title: AnimatedOpacity(
          opacity: isSearchReady ? 1.0 : 0.0,
          duration: Duration(milliseconds: 500),
          child: CupertinoSearchTextField(
            controller: searchController,
            placeholder: context.tr('search_application'),
            enabled: isSearchReady,
            style: IOSTypography.body.copyWith(
              color: IOSColors.label,
            ),
          ),
        ),
        actions: [
          CupertinoButton(
            padding: EdgeInsets.symmetric(horizontal: 16),
            onPressed: () {
              showCupertinoModalPopup(
                context: context,
                builder: (context) => CupertinoActionSheet(
                  actions: [
                    CupertinoActionSheetAction(
                      onPressed: () {
                        Navigator.pop(context);
                        _toggleSystemApps();
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.tr('show_system_apps'),
                            style: IOSTypography.body,
                          ),
                          if (isLoadSystemApps)
                            Icon(
                              CupertinoIcons.checkmark_alt,
                              color: IOSColors.systemBlue,
                            ),
                        ],
                      ),
                    ),
                  ],
                  cancelButton: CupertinoActionSheetAction(
                    onPressed: () => Navigator.pop(context),
                    isDefaultAction: true,
                    child: Text('Cancel'),
                  ),
                ),
              );
            },
            child: Icon(
              CupertinoIcons.ellipsis_circle,
              color: IOSColors.systemBlue,
              size: 28,
            ),
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CupertinoActivityIndicator(radius: 14),
            )
          : ListView.separated(
              physics: BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(vertical: 8),
              itemCount: filteredApps?.length ?? 0,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 0.5,
                color: IOSColors.separator,
                indent: 72,
              ),
              itemBuilder: (context, index) {
                AppInfo app = filteredApps![index];
                bool isBlocked = blockedApps.contains(app.packageName);
                
                return Container(
                  color: IOSColors.secondarySystemGroupedBackground,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _toggleBlockedApp(app.packageName),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // App Icon
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: IOSColors.tertiarySystemFill,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: app.icon != null && app.icon!.isNotEmpty
                                  ? Image.memory(
                                      app.icon!,
                                      fit: BoxFit.cover,
                                    )
                                  : Icon(
                                      CupertinoIcons.app,
                                      color: IOSColors.secondaryLabel,
                                    ),
                            ),
                          ),
                          SizedBox(width: 12),
                          
                          // App Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app.name,
                                  style: IOSTypography.body.copyWith(
                                    color: IOSColors.label,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 2),
                                Text(
                                  app.packageName,
                                  style: IOSTypography.footnote.copyWith(
                                    color: IOSColors.secondaryLabel,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          
                          // Checkbox
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isBlocked 
                                    ? IOSColors.systemBlue 
                                    : IOSColors.tertiaryLabel,
                                width: 2,
                              ),
                              color: isBlocked 
                                  ? IOSColors.systemBlue 
                                  : Colors.transparent,
                            ),
                            child: isBlocked
                                ? Icon(
                                    CupertinoIcons.check_mark,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
