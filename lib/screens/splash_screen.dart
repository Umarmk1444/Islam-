import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'main_navigation_screen.dart';
import '../core/database/database_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SplashScreen
//
// Performance contract:
//   • The branded UI renders on the very first frame — zero blocking I/O.
//   • DB init and a minimum display timer run in PARALLEL via Future.wait().
//   • Navigation fires as soon as BOTH are ready (whichever takes longer wins).
//   • On subsequent cold boots (DB already on device), the wait is dominated
//     by the 800ms min-display timer, giving a polished branded moment.
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Animation controllers ──────────────────────────────────────────────────
  late final AnimationController _logoController;
  late final AnimationController _shimmerController;
  late final AnimationController _textController;
  late final AnimationController _pulseController;

  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _shimmer;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimations();
    _runInitSequence();
  }

  void _setupAnimations() {
    // Logo: scale up from 0.6 + fade in
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    // Text: slide up + fade in (starts after logo)
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
    );

    // Gold shimmer sweep
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Soft pulse on the logo glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _startAnimations() {
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 450), () {
      if (mounted) _textController.forward();
    });
  }

  Future<void> _runInitSequence() async {
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

  @override
  void dispose() {
    _logoController.dispose();
    _shimmerController.dispose();
    _textController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050E08), // Near-black deep green
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background radial gradients ─────────────────────────────────
          _BackgroundGradients(pulse: _pulse),

          // ── Geometric Islamic pattern (subtle) ──────────────────────────
          const _GeometricPattern(),

          // ── Main content ────────────────────────────────────────────────
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Logo
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (_, __) => Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: _LogoWidget(pulse: _pulse),
                    ),
                  ),
                ),

                const SizedBox(height: 36),

                // App name + Arabic tagline
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: _AppNameWidget(shimmer: _shimmer),
                  ),
                ),

                const Spacer(flex: 2),

                // Loading indicator at the bottom
                FadeTransition(
                  opacity: _textOpacity,
                  child: const _LoadingDots(),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _BackgroundGradients extends StatelessWidget {
  final Animation<double> pulse;
  const _BackgroundGradients({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) => Stack(
        fit: StackFit.expand,
        children: [
          // Center emerald glow
          Center(
            child: Container(
              width: 360 * pulse.value,
              height: 360 * pulse.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF0D4F3C).withValues(alpha: 0.55 * pulse.value),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Top-right gold accent
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFFD4A017).withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Bottom-left teal accent
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2ECC9A).withValues(alpha: 0.10),
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

class _GeometricPattern extends StatelessWidget {
  const _GeometricPattern();

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.035,
      child: CustomPaint(
        painter: _IslamicPatternPainter(),
      ),
    );
  }
}

class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4A017)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const step = 80.0;
    for (double x = 0; x < size.width + step; x += step) {
      for (double y = 0; y < size.height + step; y += step) {
        final center = Offset(x, y);
        canvas.drawCircle(center, 28, paint);
        // Draw 8-pointed star lines
        for (int i = 0; i < 8; i++) {
          final angle = (i * math.pi) / 4;
          final dx = math.cos(angle) * 28;
          final dy = math.sin(angle) * 28;
          canvas.drawLine(
            center + Offset(dx * 0.5, dy * 0.5),
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

class _LogoWidget extends StatelessWidget {
  final Animation<double> pulse;
  const _LogoWidget({required this.pulse});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (_, __) => Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow ring
          Container(
            width: 140 + (8 * pulse.value),
            height: 140 + (8 * pulse.value),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1A7A5E).withValues(alpha: 0.4 * pulse.value),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Gold ring border
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFD4A017),
                  Color(0xFFFFD966),
                  Color(0xFFB8860B),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFD4A017)
                      .withValues(alpha: 0.5 * pulse.value),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          // Inner dark circle
          Container(
            width: 108,
            height: 108,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0D4F3C),
                  Color(0xFF071E16),
                ],
              ),
            ),
            child: const Center(
              child: Text(
                'ﷻ',
                style: TextStyle(
                  fontSize: 52,
                  color: Color(0xFFFFD966),
                  fontFamily: 'Amiri',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppNameWidget extends StatelessWidget {
  final Animation<double> shimmer;
  const _AppNameWidget({required this.shimmer});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // English app name with gold shimmer
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
                Color(0xFFE8DCC8),
                Color(0xFFFFFFFF),
                Color(0xFFE8DCC8),
              ],
            ).createShader(bounds),
            child: child!,
          ),
          child: const Text(
            'Muslim Hub',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Gold divider
        Container(
          width: 60,
          height: 1.5,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                Color(0xFFD4A017),
                Color(0xFFFFD966),
                Color(0xFFD4A017),
                Colors.transparent,
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Arabic tagline
        const Text(
          'القرآن والذكر',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD4A017),
            fontFamily: 'Amiri',
            letterSpacing: 0.5,
          ),
          textDirection: TextDirection.rtl,
        ),

        const SizedBox(height: 6),

        // Subtitle
        const Text(
          'Your Complete Islamic Companion',
          style: TextStyle(
            fontSize: 13,
            color: Color(0x889BAAAA),
            letterSpacing: 0.8,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

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
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD4A017).withValues(alpha: opacity),
              ),
            );
          }),
        );
      },
    );
  }
}
