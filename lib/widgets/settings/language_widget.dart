import 'package:resynth/common/ios_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

class LanguageWidget extends StatefulWidget {
  const LanguageWidget({super.key});

  @override
  _LanguageWidgetState createState() => _LanguageWidgetState();
}

class _LanguageWidgetState extends State<LanguageWidget> {
  String _selectedLanguage = 'English';

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

  void _saveSelectedLanguage(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedLanguage', language);
  }

  void _changeLocale(BuildContext context, String language) {
    if (language == 'English') {
      context.setLocale(Locale('en', 'US'));
    } else if (language == '中文') {
      context.setLocale(Locale('zh', 'CN'));
    } else if (language == 'русский') {
      context.setLocale(Locale('ru', 'RU'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          context.tr('select_language'),
          style: TextStyle(
            color: IOSColors.label,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
        backgroundColor: IOSColors.systemBackground,
        elevation: 0,
        centerTitle: true,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: IOSColors.systemBlue,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: IOSColors.systemGroupedBackground,
      body: ListView(
        physics: BouncingScrollPhysics(),
        children: [
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: IOSColors.secondarySystemGroupedBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildLanguageTile(context, 'English', isFirst: true),
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
      padding: const EdgeInsets.only(left: 56),
      child: Divider(
        height: 1,
        thickness: 0.5,
        color: IOSColors.separator,
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, String language, {bool isFirst = false, bool isLast = false}) {
    final bool isSelected = _selectedLanguage == language;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedLanguage = language;
            _saveSelectedLanguage(language);
            _changeLocale(context, language);
          });
        },
        borderRadius: BorderRadius.vertical(
          top: isFirst ? Radius.circular(10) : Radius.zero,
          bottom: isLast ? Radius.circular(10) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? IOSColors.systemBlue : IOSColors.tertiaryLabel,
                    width: isSelected ? 7 : 2,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  language,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.41,
                    color: IOSColors.label,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  CupertinoIcons.checkmark_alt,
                  color: IOSColors.systemBlue,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
