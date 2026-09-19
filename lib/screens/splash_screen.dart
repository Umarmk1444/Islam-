import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'main_navigation_screen.dart';
import '../core/database/database_helper.dart';
import '../services/app_update_service.dart';
import 'setup_screen.dart';
import '../widgets/custom_banner_ad.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SplashScreen
//
// Modern Luxury Islamic Splash Experience:
//   • Authentic uncropped application logo (golden Q + Holy Quran + crescent)
//   • Staged cinematic multi-phase entrance: Logo -> Brand -> Holy Quran Ayah
//   • Sacred Verse (Surat Al-Qamar 54:17):
//     ﴿ وَلَقَدْ يَسَّرْنَا الْقُرْآنَ لِلذِّكْرِ فَهَلْ مِن مُّدَّكِرٍ ﴾
//   • Extended 4.8s display timing (+1.6s) for complete cinematic immersion
//   • Liquid gold gliding progress capsule
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ──────────────────────────────────────────────────
  late final AnimationController _entranceController;
  late final AnimationController _ayahController;
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;
  late final AnimationController _sheenController;
  late final AnimationController _progressController;

  // ── Animations ─────────────────────────────────────────────────────────────
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _ayahOpacity;
  late final Animation<double> _ayahScale;
  late final Animation<Offset> _ayahSlide;
  late final Animation<double> _pulse;
  late final Animation<double> _shimmer;
  late final Animation<double> _sheen;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    // Hide persistent banner ads while the splash screen is visible
    kQuranScreenActive.value = true;

    _setupAnimations();
    _startAnimations();
    _checkForUpdates();
    _runInitSequence();
  }

  void _setupAnimations() {
    // 1. Logo & Title entrance timeline
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
      ),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // 2. Dedicated Ayah Reveal Animation Controller
    _ayahController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _ayahOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ayahController, curve: Curves.easeOut),
    );

    _ayahScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _ayahController, curve: Curves.easeOutBack),
    );

    _ayahSlide = Tween<Offset>(
      begin: const Offset(0, 0.22),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _ayahController, curve: Curves.easeOutCubic),
    );

    // 3. Organic breathing pulse on ambient halos (continuous)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 4. Gold shimmer across the typography
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // 5. Metallic light gleam sweep across the logo
    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    _sheen = Tween<double>(begin: -1.8, end: 2.2).animate(
      CurvedAnimation(parent: _sheenController, curve: Curves.easeInOutSine),
    );

    // 6. Sleek modern progress indicator
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _progress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOutCubic),
    );
  }

  void _startAnimations() {
    _entranceController.forward();
    // Staged Ayah reveal: starts right after title settles
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) _ayahController.forward();
    });
  }

  Future<void> _runInitSequence() async {
    final isDbPresent = await DatabaseHelper.instance.isDatabaseOnDevice;

    if (!isDbPresent) {
      await Future.delayed(const Duration(milliseconds: 4800));
      if (mounted) {
        kQuranScreenActive.value = false;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const SetupScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 450),
          ),
        );
      }
      return;
    }

    // Extended 4.8s timing (+1.6s) to comfortably enjoy the full animation & Ayah
    await Future.wait([
      _initDatabase(),
      Future.delayed(const Duration(milliseconds: 4800)),
    ]);

    if (mounted) {
      kQuranScreenActive.value = false;
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainNavigationScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 450),
        ),
      );
    }
  }

  Future<void> _initDatabase() async {
    try {
      await DatabaseHelper.instance.init();
    } catch (e) {
      debugPrint('[Splash] Database initialization error: $e');
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      if (mounted) {
        await AppUpdateService.instance.checkForUpdate(context, isManual: false);
      }
    } catch (e) {
      debugPrint('[Splash] Update check error: $e');
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ayahController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    _sheenController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF06090E), // Deep luxury midnight obsidian
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── 1. Ambient Volumetric Atmospheric Glows ──────────────────────────
          _AtmosphericGlows(pulse: _pulse),

          // ── 2. Subtle Islamic Geometric Star Rosette Pattern ────────────────
          const _GeometricStarLattice(),

          // ── 3. Foreground Content ───────────────────────────────────────────
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // Real Uncropped Application Logo with Ambient Halo & Metallic Sheen
                AnimatedBuilder(
                  animation: Listenable.merge([_entranceController, _pulseController, _sheenController]),
                  builder: (context, _) {
                    return Opacity(
                      opacity: _logoOpacity.value,
                      child: Transform.scale(
                        scale: _logoScale.value * (1.0 + (0.02 * _pulse.value)),
                        child: _RealAppLogo(
                          pulse: _pulse.value,
                          sheen: _sheen.value,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 34),

                // Luxury Typography ("Quran Zone" + Astral Star + Sacred Ayah + Motto)
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: _BrandTypography(
                      shimmer: _shimmer,
                      ayahOpacity: _ayahOpacity,
                      ayahScale: _ayahScale,
                      ayahSlide: _ayahSlide,
                      pulse: _pulse,
                    ),
                  ),
                ),

                const Spacer(flex: 3),

                // Modern Liquid Gold Progress Capsule Indicator
                FadeTransition(
                  opacity: _textOpacity,
                  child: _ModernProgressCapsule(
                    progress: _progress,
                    pulse: _pulse,
                  ),
                ),

                const SizedBox(height: 52),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Real App Logo Component (100% Uncropped, High-Resolution, Luxury Halo)
// ─────────────────────────────────────────────────────────────────────────────
class _RealAppLogo extends StatelessWidget {
  final double pulse;
  final double sheen;

  const _RealAppLogo({
    required this.pulse,
    required this.sheen,
  });

  @override
  Widget build(BuildContext context) {
    const double size = 146.0;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Outer Luminous Pulsing Halo
          Container(
            width: size + 70 + (20 * pulse),
            height: size + 70 + (20 * pulse),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFD4AF37).withValues(alpha: 0.22 * pulse),
                  const Color(0xFF1B8A6B).withValues(alpha: 0.12 * pulse),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // Secondary Soft Emerald Outer Ring
          Container(
            width: size + 28,
            height: size + 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1B8A6B).withValues(alpha: 0.28 * pulse),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Main Logo Emblem Container with Shadow & Glow
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34), // Matches the exact squircle geometry of app_icon.png
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.30 * pulse),
                  blurRadius: 36,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.70),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Full Authentic Clean App Icon (100% Uncropped)
                  Image.asset(
                    'assets/images/app_logo_clean.png',
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),

                  // Metallic Light Sheen Glint across the gold surface
                  Positioned.fill(
                    child: ShaderMask(
                      blendMode: BlendMode.srcATop,
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          stops: [
                            (sheen - 0.35).clamp(0.0, 1.0),
                            sheen.clamp(0.0, 1.0),
                            (sheen + 0.35).clamp(0.0, 1.0),
                          ],
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.28),
                            Colors.transparent,
                          ],
                        ).createShader(bounds);
                      },
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),

                  // Ultra-fine subtle gold rim border
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.22),
                        width: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Brand Typography Component ("Quran Zone" + Shimmer + Sacred Ayah Reveal)
// ─────────────────────────────────────────────────────────────────────────────
class _BrandTypography extends StatelessWidget {
  final Animation<double> shimmer;
  final Animation<double> ayahOpacity;
  final Animation<double> ayahScale;
  final Animation<Offset> ayahSlide;
  final Animation<double> pulse;

  const _BrandTypography({
    required this.shimmer,
    required this.ayahOpacity,
    required this.ayahScale,
    required this.ayahSlide,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // App Title with Metallic Gold Shimmer Sweep
        AnimatedBuilder(
          animation: shimmer,
          builder: (_, child) => ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                (shimmer.value - 0.4).clamp(0.0, 1.0),
                shimmer.value.clamp(0.0, 1.0),
                (shimmer.value + 0.4).clamp(0.0, 1.0),
              ],
              colors: const [
                Color(0xFFE8D5B5),
                Color(0xFFFFFFFF),
                Color(0xFFD4AF37),
              ],
            ).createShader(bounds),
            child: child!,
          ),
          child: const Text(
            'Quran Zone',
            style: TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 2.2,
              fontFamily: 'Roboto',
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Central Astral Divider with Diamond Motif
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 1.2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xFFD4AF37)],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.star_rounded,
                size: 13,
                color: Color(0xFFE5B33C),
              ),
            ),
            Container(
              width: 48,
              height: 1.2,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFD4AF37), Colors.transparent],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // ── Sacred Holy Quran Ayah Reveal with Illuminated Gilded Glow ───────
        SlideTransition(
          position: ayahSlide,
          child: ScaleTransition(
            scale: ayahScale,
            child: FadeTransition(
              opacity: ayahOpacity,
              child: AnimatedBuilder(
                animation: pulse,
                builder: (context, child) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.04 * pulse.value),
                        border: Border.all(
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.18 * pulse.value),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.12 * pulse.value),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: child,
                    ),
                  );
                },
                child: const Text(
                  '﴿ وَلَقَدْ يَسَّرْنَا الْقُرْآنَ لِلذِّكْرِ فَهَلْ مِن مُّدَّكِرٍ ﴾',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 19.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD54F),
                    fontFamily: 'Amiri',
                    height: 1.45,
                    letterSpacing: 0.4,
                    shadows: [
                      Shadow(
                        color: Color(0xFFD4AF37),
                        blurRadius: 16,
                      ),
                      Shadow(
                        color: Colors.black87,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Official App Motto (from splash_screen.png)
        const Text(
          'READ • LEARN • REMEMBER • LIVE',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0x99A8BCB4),
            letterSpacing: 3.5,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modern Liquid Gold Progress Capsule (Replaces basic dots with luxury bar)
// ─────────────────────────────────────────────────────────────────────────────
class _ModernProgressCapsule extends StatelessWidget {
  final Animation<double> progress;
  final Animation<double> pulse;

  const _ModernProgressCapsule({
    required this.progress,
    required this.pulse,
  });

  @override
  Widget build(BuildContext context) {
    const double barWidth = 140.0;
    const double barHeight = 4.0;

    return AnimatedBuilder(
      animation: Listenable.merge([progress, pulse]),
      builder: (context, _) {
        final val = progress.value;
        return Container(
          width: barWidth,
          height: barHeight,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(barHeight / 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.15 * pulse.value),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(barHeight / 2),
            child: Stack(
              children: [
                // Gliding liquid gold beam
                Positioned(
                  left: (val * (barWidth + 50)) - 50,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFFD4AF37).withValues(alpha: 0.9),
                          const Color(0xFFFFE082),
                          const Color(0xFFD4AF37).withValues(alpha: 0.9),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Atmospheric Volumetric Corner & Center Glows
// ─────────────────────────────────────────────────────────────────────────────
class _AtmosphericGlows extends StatelessWidget {
  final Animation<double> pulse;
  const _AtmosphericGlows({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) => Stack(
        fit: StackFit.expand,
        children: [
          // Center Radiant Emerald & Amber Core
          Center(
            child: Container(
              width: 380 * pulse.value,
              height: 380 * pulse.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0B2D21).withValues(alpha: 0.45 * pulse.value),
                    const Color(0xFF061812).withValues(alpha: 0.20 * pulse.value),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // Top-Right Gold Aurora
          Positioned(
            top: -90,
            right: -90,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFE5B33C).withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Top-Left Deep Teal Aurora
          Positioned(
            top: -70,
            left: -70,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1B8A6B).withValues(alpha: 0.14),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom-Left Vivid Teal Aurora
          Positioned(
            bottom: -70,
            left: -70,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2ECC9A).withValues(alpha: 0.13),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Bottom-Right Warm Gold Aurora
          Positioned(
            bottom: -80,
            right: -80,
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFD4AF37).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Geometric Star Lattice Pattern (Subtle 8-Pointed Star Islamic Tessellation)
// ─────────────────────────────────────────────────────────────────────────────
class _GeometricStarLattice extends StatelessWidget {
  const _GeometricStarLattice();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.04,
      child: CustomPaint(
        painter: _StarLatticePainter(),
      ),
    );
  }
}

class _StarLatticePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4AF37)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const step = 84.0;
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        final center = Offset(x, y);
        canvas.drawCircle(center, 30, paint);
        // Draw 8-pointed star lines radiating symmetrically
        for (int i = 0; i < 8; i++) {
          final angle = (i * math.pi) / 4;
          final dx = math.cos(angle) * 30;
          final dy = math.sin(angle) * 30;
          canvas.drawLine(
            center + Offset(dx * 0.45, dy * 0.45),
            center + Offset(dx, dy),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
