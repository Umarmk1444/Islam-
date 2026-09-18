import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CIRCULAR THEME REVEAL CONTROLLER
// ─────────────────────────────────────────────────────────────────────────────

class CircularThemeRevealController {
  _CircularThemeRevealState? _state;

  void _attach(_CircularThemeRevealState state) {
    _state = state;
  }

  void _detach() {
    _state = null;
  }

  bool get isRevealing => _state?._isRevealing ?? false;

  Future<void> triggerReveal({
    required Offset origin,
    required Color ringColor,
    Color? targetBgColor,
    required VoidCallback onThemeChange,
  }) async {
    await _state?.reveal(
      origin: origin,
      ringColor: ringColor,
      targetBgColor: targetBgColor,
      onThemeChange: onThemeChange,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CIRCULAR THEME REVEAL WIDGET (1-Pixel Radial Inception & Guaranteed Animation)
// ─────────────────────────────────────────────────────────────────────────────

class CircularThemeReveal extends StatefulWidget {
  final CircularThemeRevealController controller;
  final Widget child;

  const CircularThemeReveal({
    super.key,
    required this.controller,
    required this.child,
  });

  @override
  State<CircularThemeReveal> createState() => _CircularThemeRevealState();
}

class _CircularThemeRevealState extends State<CircularThemeReveal>
    with SingleTickerProviderStateMixin {
  final GlobalKey _repaintKey = GlobalKey();
  late final AnimationController _animCtrl;
  late final Animation<double> _revealAnim;

  ui.Image? _snapshot;
  bool _isRevealing = false;
  Offset _origin = Offset.zero;
  Color _ringColor = const Color(0xFFC9A84C);
  Color? _targetBgColor;
  double _maxRadius = 1000.0;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _revealAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOutCubic);
  }

  @override
  void didUpdateWidget(CircularThemeReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller._detach();
      widget.controller._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller._detach();
    _animCtrl.dispose();
    _snapshot?.dispose();
    super.dispose();
  }

  Future<void> reveal({
    required Offset origin,
    required Color ringColor,
    Color? targetBgColor,
    required VoidCallback onThemeChange,
  }) async {
    if (_isRevealing || !mounted) return;

    final RenderRepaintBoundary? boundary =
        _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;

    final RenderBox? revealBox = context.findRenderObject() as RenderBox?;
    final Offset localOrigin = (revealBox != null && revealBox.hasSize)
        ? revealBox.globalToLocal(origin)
        : origin;

    final Size boxSize = (revealBox != null && revealBox.hasSize)
        ? revealBox.size
        : MediaQuery.of(context).size;

    final double dx = math.max(localOrigin.dx, boxSize.width - localOrigin.dx);
    final double dy = math.max(localOrigin.dy, boxSize.height - localOrigin.dy);
    _maxRadius = math.sqrt(dx * dx + dy * dy) + 80.0;
    _origin = localOrigin;
    _ringColor = ringColor;
    _targetBgColor = targetBgColor;

    // Safely snapshot the current screen prior to mutating theme
    ui.Image? image;
    if (boundary != null && boundary.hasSize) {
      try {
        if (boundary.debugNeedsPaint) {
          final completer = Completer<void>();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            completer.complete();
          });
          await completer.future;
        }

        if (mounted && boundary.hasSize) {
          final mediaQuery = MediaQuery.of(context);
          final pixelRatio = mediaQuery.devicePixelRatio.clamp(1.0, 2.0);
          image = await boundary.toImage(pixelRatio: pixelRatio);
        }
      } catch (e) {
        debugPrint('CircularThemeReveal snapshot note: $e');
        image = null;
      }
    }

    if (!mounted) {
      image?.dispose();
      onThemeChange();
      return;
    }

    _snapshot?.dispose();
    _snapshot = image;

    setState(() {
      _isRevealing = true;
    });

    // Apply the theme mutation so widget.child rebuilds with the new theme
    onThemeChange();

    // Run the animation smoothly from 1px to max radius
    await _animCtrl.forward(from: 0.0);

    if (mounted) {
      setState(() {
        _isRevealing = false;
        _snapshot?.dispose();
        _snapshot = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _revealAnim,
      builder: (context, _) {
        // Starts strictly from 1.0 pixel to max screen radius
        final double radius = 1.0 + (_revealAnim.value * (_maxRadius - 1.0));

        return Stack(
          fit: StackFit.passthrough,
          children: [
            // 1. Frozen Snapshot of Old Theme (Bottom Layer when snapshot succeeded)
            if (_isRevealing && _snapshot != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: RawImage(
                    image: _snapshot,
                    fit: BoxFit.fill,
                  ),
                ),
              ),

            // 2. Active Screen with New Theme (Revealed outwards from 1px)
            ClipPath(
              clipper: (_isRevealing && _snapshot != null)
                  ? CircularRevealClipper(center: _origin, radius: radius)
                  : null,
              child: RepaintBoundary(
                key: _repaintKey,
                child: widget.child,
              ),
            ),

            // 3. Fallback expanding theme color wash if snapshot was not captured
            if (_isRevealing && _snapshot == null)
              Positioned.fill(
                child: IgnorePointer(
                  child: ClipPath(
                    clipper: CircularRevealClipper(center: _origin, radius: radius),
                    child: Container(
                      color: _targetBgColor ?? _ringColor.withValues(alpha: 0.18),
                    ),
                  ),
                ),
              ),

            // 4. Glowing Wavefront Ring starting strictly from 1px
            if (_isRevealing)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: CircularRippleRingPainter(
                      center: _origin,
                      radius: radius,
                      color: _ringColor,
                      progress: _revealAnim.value,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CIRCULAR REVEAL CLIPPER
// ─────────────────────────────────────────────────────────────────────────────

class CircularRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  const CircularRevealClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) {
    return oldClipper.radius != radius || oldClipper.center != center;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CIRCULAR RIPPLE RING PAINTER (Telegram Wavefront Glow)
// ─────────────────────────────────────────────────────────────────────────────

class CircularRippleRingPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color color;
  final double progress;

  CircularRippleRingPainter({
    required this.center,
    required this.radius,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (radius < 1.0) return;
    final double alpha = (1.0 - progress * 0.65).clamp(0.0, 1.0);
    final double ringScale = (radius / 25.0).clamp(0.0, 1.0);

    // Glowing outer aura (grows softly from 1px without an awkward blob)
    if (radius > 2.0) {
      final aura = Paint()
        ..color = color.withValues(alpha: alpha * 0.35 * ringScale)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (6.0 * ringScale).clamp(1.0, 6.0)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, (3.0 * ringScale).clamp(0.5, 3.0));
      canvas.drawCircle(center, radius, aura);
    }

    // Sharp wavefront ring starting right from 1px
    final core = Paint()
      ..color = color.withValues(alpha: alpha * 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (2.5 * ringScale).clamp(0.8, 2.5);
    canvas.drawCircle(center, radius, core);
  }

  @override
  bool shouldRepaint(CircularRippleRingPainter old) =>
      old.radius != radius || old.progress != progress || old.color != color;
}
