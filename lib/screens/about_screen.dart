import 'package:begzar/common/ios_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> with SingleTickerProviderStateMixin {
  String? version;
  late AnimationController _logoAnimationController;
  late Animation<double> _logoRotation;
  late Animation<double> _logoScale;

  @override
  void initState() {
    super.initState();
    _getVersion();

    _logoAnimationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _logoRotation = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _logoAnimationController, curve: Curves.elasticOut),
    );

    _logoScale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _logoAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    super.dispose();
  }

  void _animateLogo() {
    _logoAnimationController.forward(from: 0);
  }

  String _toEnglishDigits(String input) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persian = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

    String result = input;
    for (int i = 0; i < 10; i++) {
      result = result.replaceAll(persian[i], english[i]);
      result = result.replaceAll(arabic[i], english[i]);
    }
    return result;
  }

  Future<void> _getVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        version = packageInfo.version;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSColors.systemGroupedBackground,
      appBar: AppBar(
        backgroundColor: IOSColors.systemBackground,
        elevation: 0,
        title: Text(
          context.tr('about'),
          style: IOSTypography.headline,
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const SizedBox(height: 20),

                GestureDetector(
                  onTap: _animateLogo,
                  child: AnimatedBuilder(
                    animation: _logoAnimationController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: Transform.rotate(
                          angle: _logoRotation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: IOSColors.systemBlue.withOpacity(0.1),
                                  blurRadius: 30,
                                  offset: Offset(0, 10),
                                ),
                              ],
                            ),
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
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  context.tr('app_title'),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: IOSColors.label,
                  ),
                ),

                const SizedBox(height: 10),

                if (version != null)
                  Text(
                    _toEnglishDigits('Version : $version'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: IOSColors.secondaryLabel,
                    ),
                  ),

                const SizedBox(height: 30),

                _buildContactCard(
                  icon: CupertinoIcons.creditcard,
                  title: 'TON Wallet',
                  onTap: () {
                    Clipboard.setData(const ClipboardData(
                      text: "UQDrQ59AyNvwH96R7wHl8-VqVFhWqoliujMpelbs2aR-LWr1"
                    )).then((_) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.tr('wallet_address_copied')),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    });
                  },
                ),

                _buildContactCard(
                  icon: CupertinoIcons.mail,
                  title: 'info@begzar.xyz',
                  onTap: () async {
                    final Uri emailLaunchUri = Uri(
                      scheme: 'mailto',
                      path: 'info@begzar.xyz',
                    );
                    await launchUrl(emailLaunchUri);
                  },
                ),

                _buildContactCard(
                  icon: CupertinoIcons.square_stack_3d_up,
                  title: 'Github',
                  onTap: () async {
                    await launchUrl(
                      Uri.parse('https://github.com/Begzar/BegzarApp'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),

                _buildContactCard(
                  icon: CupertinoIcons.chat_bubble,
                  title: context.tr('telegram_channel'),
                  onTap: () async {
                    await launchUrl(
                      Uri.parse('https://t.me/BegzarVPN'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),

                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    context.tr('about_description'),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: IOSColors.secondaryLabel,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  _toEnglishDigits(context.tr('copyright')),
                  style: TextStyle(
                    fontSize: 12,
                    color: IOSColors.tertiaryLabel,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: IOSColors.systemBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: IOSColors.systemBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: IOSColors.label,
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.forward,
                color: IOSColors.tertiaryLabel,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
