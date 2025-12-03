import 'package:begzar/common/ios_theme.dart';
import 'package:begzar/widgets/settings/blocked_apps_widget.dart';
import 'package:begzar/widgets/settings/language_widget.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsWidget extends StatefulWidget {
  SettingsWidget({super.key});

  @override
  _SettingsWidgetState createState() => _SettingsWidgetState();
}

class _SettingsWidgetState extends State<SettingsWidget> {
  String? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _loadSelectedLanguage();
  }

  void _loadSelectedLanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('selectedLanguage') ?? 'English';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('setting'),
          style: TextStyle(
            color: IOSColors.label,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Icon(
            CupertinoIcons.back,
            color: IOSColors.systemBlue,
          ),
        ),
        backgroundColor: IOSColors.systemBackground,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: IOSColors.systemGroupedBackground,
      body: ListView(
        physics: BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 32),
          
          // Blocking Settings Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              context.tr('blocking_settings').toUpperCase(),
              style: IOSTypography.caption1.copyWith(
                color: IOSColors.secondaryLabel,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: IOSColors.secondarySystemGroupedBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: _buildIOSSettingsTile(
              icon: CupertinoIcons.slash_circle,
              iconColor: IOSColors.systemRed,
              title: context.tr('block_application'),
              subtitle: context.tr('block_detail'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => BlockedAppsWidgets(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
          
          // Language Settings Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              context.tr('language_settings').toUpperCase(),
              style: IOSTypography.caption1.copyWith(
                color: IOSColors.secondaryLabel,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: IOSColors.secondarySystemGroupedBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: _buildIOSSettingsTile(
              icon: CupertinoIcons.globe,
              iconColor: IOSColors.systemBlue,
              title: context.tr('language'),
              subtitle: _selectedLanguage,
              onTap: () {
                Navigator.of(context)
                    .push(
                  MaterialPageRoute(
                    builder: (context) => LanguageWidget(
                      selectedLanguage: _selectedLanguage!,
                    ),
                  ),
                )
                    .then((value) {
                  _loadSelectedLanguage();
                });
              },
            ),
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildIOSSettingsTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: IOSTypography.body.copyWith(
                        color: IOSColors.label,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
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
              Icon(
                CupertinoIcons.forward,
                size: 20,
                color: IOSColors.tertiaryLabel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
