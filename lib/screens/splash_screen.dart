import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'main_navigation_screen.dart';
import 'dart:io' show Platform;
import 'package:in_app_update/in_app_update.dart';
import '../core/database/database_helper.dart';
import 'setup_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SplashScreen
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkForUpdates(); // Check for updates in the background without blocking
    _runInitSequence();
  }

  Future<void> _runInitSequence() async {
    final isDbPresent = await DatabaseHelper.instance.isDatabaseOnDevice;

    if (!isDbPresent) {
      await Future.delayed(const Duration(milliseconds: 3200));
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const SetupScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOut,
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      }
      return;
    }

    // Run DB init and minimum splash display in parallel.
    // Navigation fires only when BOTH complete.
    await Future.wait([
      _initDatabase(),
      Future.delayed(const Duration(milliseconds: 3200)),
    ]);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainNavigationScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  Future<void> _initDatabase() async {
    try {
      await DatabaseHelper.instance.init();
    } catch (e) {
      debugPrint('[Splash] Database initialization failed: $e');
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      if (!Platform.isAndroid) return;
      
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.flexibleUpdateAllowed) {
          // Triggers the download silently in the background
          await InAppUpdate.startFlexibleUpdate();
          // Prompts the user to install and restart once the download is finished
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      debugPrint('[Splash] In-App Update failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          Image.asset(
            'assets/images/splash_screen.png',
            fit: BoxFit.cover,
          ),
          // Loading Dots at bottom
          const Positioned(
            bottom: 48,
            left: 0,
            right: 0,
            child: _LoadingDots(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            // Each dot pulses with a 0.33 phase offset
            final phase = ((_ctrl.value - (i * 0.33)) % 1.0);
            final opacity = (math.sin(phase * math.pi * 2) * 0.5 + 0.5)
                .clamp(0.2, 1.0);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4A017).withValues(alpha: opacity),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD4A017).withValues(alpha: opacity * 0.5),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
