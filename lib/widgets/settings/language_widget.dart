import 'package:begzar/common/ios_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LanguageWidget extends StatefulWidget {
  const LanguageWidget({super.key});

  @override
  State<LanguageWidget> createState() => _LanguageWidgetState();
}

class _LanguageWidgetState extends State<LanguageWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSColors.systemGroupedBackground,
      appBar: AppBar(
        title: Text(
          context.tr('language'),
          style: IOSTypography.headline,
        ),
        centerTitle: true,
        backgroundColor: IOSColors.systemBackground,
        elevation: 0,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: IOSColors.systemBlue,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            _buildLanguageOption(
              title: 'English',
              locale: Locale('en', 'US'),
              isSelected: context.locale == Locale('en', 'US'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String title,
    required Locale locale,
    required bool isSelected,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? IOSColors.systemBlue : Colors.transparent,
          width: 2,
        ),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onPressed: () async {
          await context.setLocale(locale);
          setState(() {});
        },
        child: Row(
          children: [
            Icon(
              isSelected ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.circle,
              color: isSelected ? IOSColors.systemBlue : IOSColors.tertiaryLabel,
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? IOSColors.systemBlue : IOSColors.label,
                  fontSize: 17,
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
