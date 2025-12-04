import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:begzar/common/ios_theme.dart';

class AboutScreen extends StatefulWidget {
  AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String? version;

  @override
  void initState() {
    super.initState();
    _getVersion();
  }

  Future<void> _getVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      version = packageInfo.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSColors.systemGroupedBackground,
      appBar: AppBar(
        backgroundColor: IOSColors.systemBackground,
        elevation: 0,
        automaticallyImplyLeading: false, // ✅ حذف دکمه Back
        title: Text(
          context.tr('about'),
          style: TextStyle(
            color: IOSColors.label,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.41,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: 40),
            
            // Logo Container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: IOSColors.secondarySystemGroupedBackground,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 80,
                    height: 80,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // App Name
            Text(
              context.tr('app_title'),
              style: IOSTypography.title1.copyWith(
                color: IOSColors.label,
              ),
            ),
            const SizedBox(height: 4),
            
            // Version
            if (version != null)
              Text(
                '${context.tr('version_title')} : $version',
                style: IOSTypography.subheadline.copyWith(
                  color: IOSColors.secondaryLabel,
                ),
              ),
            
            const SizedBox(height: 32),

            // Links Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: IOSColors.secondarySystemGroupedBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildIOSListTile(
                    icon: CupertinoIcons.creditcard,
                    iconColor: IOSColors.systemPurple,
                    title: 'TON Wallet',
                    showDivider: true,
                    onTap: () {
                      Clipboard.setData(
                        const ClipboardData(
                          text: "UQDrQ59AyNvwH96R7wHl8-VqVFhWqoliujMpelbs2aR-LWr1",
                        ),
                      ).then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.tr('wallet_address_copied'),
                              style: IOSTypography.body,
                            ),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      });
                    },
                  ),
                  _buildIOSListTile(
                    icon: CupertinoIcons.mail,
                    iconColor: IOSColors.systemBlue,
                    title: 'info@begzar.xyz',
                    showDivider: true,
                    onTap: () async {
                      final Uri emailLaunchUri = Uri(
                        scheme: 'mailto',
                        path: 'info@begzar.xyz',
                      );
                      await launchUrl(emailLaunchUri);
                    },
                  ),
                  _buildIOSListTile(
                    icon: CupertinoIcons.square_on_square,
                    iconColor: IOSColors.label,
                    title: 'Github',
                    showDivider: true,
                    onTap: () async {
                      await launchUrl(
                        Uri.parse('https://github.com/Begzar/BegzarApp'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                  _buildIOSListTile(
                    icon: CupertinoIcons.chat_bubble,
                    iconColor: IOSColors.systemBlue,
                    title: context.tr('telegram_channel'),
                    showDivider: false,
                    onTap: () async {
                      await launchUrl(
                        Uri.parse('https://t.me/BegzarVPN'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Description
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: IOSColors.secondarySystemGroupedBackground,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                context.tr('about_description'),
                style: IOSTypography.footnote.copyWith(
                  color: IOSColors.secondaryLabel,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),
            
            // Copyright
            Text(
              context.tr('copyright'),
              style: IOSTypography.caption1.copyWith(
                color: IOSColors.tertiaryLabel,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildIOSListTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool showDivider,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: iconColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: IOSTypography.body.copyWith(
                        color: IOSColors.label,
                      ),
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
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: Divider(
              height: 1,
              thickness: 0.5,
              color: IOSColors.separator,
            ),
          ),
      ],
    );
  }
}
