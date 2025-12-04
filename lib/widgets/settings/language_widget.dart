import 'package:begzar/common/ios_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageWidget extends StatefulWidget {
  final String selectedLanguage;

  LanguageWidget({required this.selectedLanguage});

  @override
  _LanguageWidgetState createState() => _LanguageWidgetState();
}

class _LanguageWidgetState extends State<LanguageWidget> {
  late String _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.selectedLanguage;
  }

  void _saveSelectedLanguage(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language);
  }

  void _changeLocale(BuildContext context, String language) {
    if (language == 'English') {
      context.setLocale(Locale('en', 'US'));
    } else if (language == 'فارسی') {
      context.setLocale(Locale('fa', 'IR'));
    } else if (language == '中文') {
      context.setLocale(Locale('zh', 'CN'));
    } else if (language == 'русский') {
      context.setLocale(Locale('ru', 'RU'));
    }
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
        title: Text(
          context.tr('select_language'),
          style: IOSTypography.headline.copyWith(
            color: IOSColors.label,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: 20),
        children: [
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: IOSColors.secondarySystemGroupedBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildLanguageTile(context, 'English', isFirst: true),
                _buildDivider(),
                _buildLanguageTile(context, 'فارسی'),
                _buildDivider(),
                _buildLanguageTile(context, '中文'),
                _buildDivider(),
                _buildLanguageTile(context, 'русский', isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.only(left: 56),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: IOSColors.separator,
      ),
    );
  }

  Widget _buildLanguageTile(
    BuildContext context,
    String language, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    bool isSelected = _selectedLanguage == language;
    
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        setState(() {
          _selectedLanguage = language;
          _saveSelectedLanguage(language);
          _changeLocale(context, language);
        });
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected 
                      ? IOSColors.systemBlue 
                      : IOSColors.tertiaryLabel,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: IOSColors.systemBlue,
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                language,
                style: IOSTypography.body.copyWith(
                  color: IOSColors.label,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
