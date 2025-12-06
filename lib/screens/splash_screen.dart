import 'package:flutter/material.dart';
import 'package:resynth/common/ios_theme.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: IOSColors.systemBackground,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: IOSColors.systemBlue.withOpacity(0.2),
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

            const SizedBox(height: 40),

            // App Name
            Text(
              'ReSynth',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: IOSColors.label,
              ),
            ),

            const SizedBox(height: 50),

            // Loading Animation
            LoadingAnimationWidget.staggeredDotsWave(
              color: IOSColors.systemBlue,
              size: 50,
            ),

            const SizedBox(height: 20),

            // Loading Text
            Text(
              'Initializing...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: IOSColors.secondaryLabel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
