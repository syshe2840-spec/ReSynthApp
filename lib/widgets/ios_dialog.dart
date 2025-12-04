import 'package:resynth/common/ios_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

enum IOSDialogType {
  info,
  warning,
  error,
  success,
  notification,
}

class IOSDialog {
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    IOSDialogType type = IOSDialogType.info,
    String? lottieAsset,
    String? primaryButtonText,
    String? secondaryButtonText,
    VoidCallback? onPrimaryPressed,
    VoidCallback? onSecondaryPressed,
    bool dismissible = true,
  }) {
    showGeneralDialog(
      context: context,
      barrierDismissible: dismissible,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Container();
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: FadeTransition(
            opacity: animation,
            child: _IOSDialogContent(
              title: title,
              message: message,
              type: type,
              lottieAsset: lottieAsset,
              primaryButtonText: primaryButtonText,
              secondaryButtonText: secondaryButtonText,
              onPrimaryPressed: onPrimaryPressed,
              onSecondaryPressed: onSecondaryPressed,
            ),
          ),
        );
      },
    );
  }
}

class _IOSDialogContent extends StatelessWidget {
  final String title;
  final String message;
  final IOSDialogType type;
  final String? lottieAsset;
  final String? primaryButtonText;
  final String? secondaryButtonText;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;

  const _IOSDialogContent({
    required this.title,
    required this.message,
    required this.type,
    this.lottieAsset,
    this.primaryButtonText,
    this.secondaryButtonText,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
  });

  String _getDefaultLottie() {
    switch (type) {
      case IOSDialogType.success:
        return 'assets/lottie/success.json';
      case IOSDialogType.error:
        return 'assets/lottie/error.json';
      case IOSDialogType.warning:
        return 'assets/lottie/warning.json';
      case IOSDialogType.notification:
        return 'assets/lottie/notification.json';
      default:
        return 'assets/lottie/info.json';
    }
  }

  Color _getTypeColor() {
    switch (type) {
      case IOSDialogType.success:
        return IOSColors.systemGreen;
      case IOSDialogType.error:
        return IOSColors.systemRed;
      case IOSDialogType.warning:
        return IOSColors.systemOrange;
      case IOSDialogType.notification:
        return IOSColors.systemBlue;
      default:
        return IOSColors.systemBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 40),
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animation
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _getTypeColor().withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Lottie.asset(
                    lottieAsset ?? _getDefaultLottie(),
                    width: 80,
                    height: 80,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        CupertinoIcons.info_circle_fill,
                        size: 60,
                        color: _getTypeColor(),
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: 20),

              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: IOSColors.label,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 12),

              // Message
              Text(
                message,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: IOSColors.secondaryLabel,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  if (secondaryButtonText != null) ...[
                    Expanded(
                      child: _buildButton(
                        text: secondaryButtonText!,
                        onPressed: () {
                          Navigator.of(context).pop();
                          onSecondaryPressed?.call();
                        },
                        isPrimary: false,
                      ),
                    ),
                    SizedBox(width: 12),
                  ],
                  Expanded(
                    child: _buildButton(
                      text: primaryButtonText ?? 'OK',
                      onPressed: () {
                        Navigator.of(context).pop();
                        onPrimaryPressed?.call();
                      },
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({
    required String text,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.symmetric(vertical: 12),
      color: isPrimary ? IOSColors.systemBlue : IOSColors.secondarySystemBackground,
      borderRadius: BorderRadius.circular(12),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: isPrimary ? Colors.white : IOSColors.label,
        ),
      ),
    );
  }
}
