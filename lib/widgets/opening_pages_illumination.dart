import 'package:flutter/material.dart';
import 'dart:math' as math;

class OpeningPagesIllumination extends StatelessWidget {
  final Widget child;
  final bool isPageOne;
  final Color? primaryColor;
  final Color? accentColor;
  final Color? backgroundColor;

  const OpeningPagesIllumination({
    Key? key,
    required this.child,
    required this.isPageOne,
    this.primaryColor,
    this.accentColor,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _IntricateIslamicPatternPainter(
        isPageOne: isPageOne,
        primaryColor: primaryColor ?? const Color(0xFF1B365D),
        accentColor: accentColor ?? const Color(0xFFCFB53B),
        backgroundColor: backgroundColor ?? const Color(0xFFFFFDF3),
      ),
      child: child,
    );
  }
}

class _IntricateIslamicPatternPainter extends CustomPainter {
  final bool isPageOne;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;

  _IntricateIslamicPatternPainter({
    required this.isPageOne,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = backgroundColor);

    // Define color palette inspired by the image
    final Color navyBlue = primaryColor;
    final Color deepRed = Color.lerp(primaryColor, const Color(0xFF8B1C24), 0.5) ?? primaryColor;
    final Color gold = accentColor;
    final Color creamBg = backgroundColor;

    // 1. OUTER BORDER FRAME
    _paintOuterBorderFrame(canvas, w, h, navyBlue, gold);

    // 2. DECORATIVE TESSELLATING PATTERN FILLS
    _paintGeometricPatternBorders(canvas, w, h, navyBlue, deepRed, gold);

    // 3. TOP SMOOTH DOME/ARCH (Very smooth circular decoration)
    _paintTopSmoothDome(canvas, w, h, navyBlue, gold, deepRed);

    // 4. BOTTOM CORNER ORNAMENTS
    _paintBottomCornerOrnaments(canvas, w, h, gold, navyBlue);

    // 5. INNER GOLDEN OUTLINE
    _paintInnerGoldenOutline(canvas, w, h, gold);
  }

  void _paintTopSmoothDome(Canvas canvas, double w, double h, Color navy, Color gold, Color red) {
    const double domeTop = 30;
    const double domeHeight = 120;
    const double domeLeft = 80;
    const double domeRight = 80;

    // Main smooth dome arch - very circular at the top
    final Path domePath = Path()
      ..moveTo(domeLeft, domeTop + domeHeight)
      // Left curved side
      ..cubicTo(
        domeLeft - 20,
        domeTop + domeHeight * 0.6,
        domeLeft - 25,
        domeTop + domeHeight * 0.2,
        w * 0.5,
        domeTop,
      )
      // Right curved side
      ..cubicTo(
        w - domeLeft + 25,
        domeTop + domeHeight * 0.2,
        w - domeLeft + 20,
        domeTop + domeHeight * 0.6,
        w - domeLeft,
        domeTop + domeHeight,
      )
      ..lineTo(w - domeLeft, domeTop + domeHeight + 10)
      ..lineTo(domeLeft, domeTop + domeHeight + 10)
      ..close();

    // Fill dome with gradient effect (navy to lighter)
    canvas.drawPath(domePath, Paint()..color = navy..style = PaintingStyle.fill);
    canvas.drawPath(domePath, Paint()..color = gold..style = PaintingStyle.stroke..strokeWidth = 2.5);

    // Inner lighter dome layer
    final Path innerDomePath = Path()
      ..moveTo(domeLeft + 15, domeTop + domeHeight)
      ..cubicTo(
        domeLeft - 5,
        domeTop + domeHeight * 0.5,
        domeLeft - 10,
        domeTop + domeHeight * 0.15,
        w * 0.5,
        domeTop + 15,
      )
      ..cubicTo(
        w - domeLeft + 10,
        domeTop + domeHeight * 0.15,
        w - domeLeft + 5,
        domeTop + domeHeight * 0.5,
        w - domeLeft - 15,
        domeTop + domeHeight,
      );

    canvas.drawPath(
      innerDomePath,
      Paint()
        ..color = gold.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Decorative circles inside dome
    for (double x = domeLeft + 20; x < w - domeLeft; x += 40) {
      canvas.drawCircle(Offset(x, domeTop + 40), 3, Paint()..color = gold);
      canvas.drawCircle(Offset(x, domeTop + 40), 1.5, Paint()..color = red);
    }
  }

  void _paintOuterBorderFrame(Canvas canvas, double w, double h, Color navy, Color gold) {
    const double cornerRadius = 20; // 45-60 degree smooth corner

    // Create outer thick navy border with smooth corners
    final Path outerPath = Path()
      ..moveTo(cornerRadius, 8)
      ..lineTo(w - cornerRadius, 8)
      ..arcToPoint(
        Offset(w - 8, cornerRadius),
        radius: const Radius.circular(cornerRadius),
        clockwise: true,
      )
      ..lineTo(w - 8, h - cornerRadius)
      ..arcToPoint(
        Offset(w - cornerRadius, h - 8),
        radius: const Radius.circular(cornerRadius),
        clockwise: true,
      )
      ..lineTo(cornerRadius, h - 8)
      ..arcToPoint(
        Offset(8, h - cornerRadius),
        radius: const Radius.circular(cornerRadius),
        clockwise: true,
      )
      ..lineTo(8, cornerRadius)
      ..arcToPoint(
        Offset(cornerRadius, 8),
        radius: const Radius.circular(cornerRadius),
        clockwise: true,
      )
      ..close();

    canvas.drawPath(outerPath, Paint()..color = navy..style = PaintingStyle.stroke..strokeWidth = 6.0);

    // Double gold line accent with smooth corners
    const double goldRadius = 18;
    final Path goldPath = Path()
      ..moveTo(goldRadius + 6, 14)
      ..lineTo(w - goldRadius - 6, 14)
      ..arcToPoint(
        Offset(w - 14, goldRadius + 6),
        radius: const Radius.circular(goldRadius),
        clockwise: true,
      )
      ..lineTo(w - 14, h - goldRadius - 6)
      ..arcToPoint(
        Offset(w - goldRadius - 6, h - 14),
        radius: const Radius.circular(goldRadius),
        clockwise: true,
      )
      ..lineTo(goldRadius + 6, h - 14)
      ..arcToPoint(
        Offset(14, h - goldRadius - 6),
        radius: const Radius.circular(goldRadius),
        clockwise: true,
      )
      ..lineTo(14, goldRadius + 6)
      ..arcToPoint(
        Offset(goldRadius + 6, 14),
        radius: const Radius.circular(goldRadius),
        clockwise: true,
      )
      ..close();

    canvas.drawPath(goldPath, Paint()..color = gold..style = PaintingStyle.stroke..strokeWidth = 3.0);

    // Inner navy accent with smooth corners
    const double innerRadius = 16;
    final Path innerPath = Path()
      ..moveTo(innerRadius + 12, 20)
      ..lineTo(w - innerRadius - 12, 20)
      ..arcToPoint(
        Offset(w - 20, innerRadius + 12),
        radius: const Radius.circular(innerRadius),
        clockwise: true,
      )
      ..lineTo(w - 20, h - innerRadius - 12)
      ..arcToPoint(
        Offset(w - innerRadius - 12, h - 20),
        radius: const Radius.circular(innerRadius),
        clockwise: true,
      )
      ..lineTo(innerRadius + 12, h - 20)
      ..arcToPoint(
        Offset(20, h - innerRadius - 12),
        radius: const Radius.circular(innerRadius),
        clockwise: true,
      )
      ..lineTo(20, innerRadius + 12)
      ..arcToPoint(
        Offset(innerRadius + 12, 20),
        radius: const Radius.circular(innerRadius),
        clockwise: true,
      )
      ..close();

    canvas.drawPath(innerPath, Paint()..color = navy..style = PaintingStyle.stroke..strokeWidth = 1.5);
  }

  void _paintGeometricPatternBorders(
    Canvas canvas,
    double w,
    double h,
    Color navy,
    Color red,
    Color gold,
  ) {
    const double borderWidth = 60;
    const double patternSpacing = 15;

    // Fill ENTIRE border areas with geometric tessellations (full coverage)
    _paintTessellatingPatternArea(canvas, 25, 25, w - 50, 50, navy, red, gold);
    _paintTessellatingPatternArea(canvas, 25, h - 75, w - 50, 50, navy, red, gold);
    _paintTessellatingPatternArea(canvas, 25, 60, 50, h - 120, navy, red, gold);
    _paintTessellatingPatternArea(canvas, w - 75, 60, 50, h - 120, navy, red, gold);

    // Top border pattern (8-pointed stars evenly spaced)
    for (double x = 30; x < w - 30; x += patternSpacing) {
      _paintGeometricFlowerStar(canvas, x, 35, 6, navy, gold);
      _paintGeometricFlowerStar(canvas, x, 42, 4, gold, navy); // Double pattern for depth
    }

    // Bottom border pattern
    for (double x = 30; x < w - 30; x += patternSpacing) {
      _paintGeometricFlowerStar(canvas, x, h - 35, 6, navy, gold);
      _paintGeometricFlowerStar(canvas, x, h - 42, 4, gold, navy);
    }

    // Left border pattern
    for (double y = 40; y < h - 40; y += patternSpacing) {
      _paintGeometricFlowerStar(canvas, 35, y, 5, navy, gold);
      _paintGeometricFlowerStar(canvas, 42, y, 3, gold, navy);
    }

    // Right border pattern
    for (double y = 40; y < h - 40; y += patternSpacing) {
      _paintGeometricFlowerStar(canvas, w - 35, y, 5, navy, gold);
      _paintGeometricFlowerStar(canvas, w - 42, y, 3, gold, navy);
    }
  }

  void _paintGeometricFlowerStar(
    Canvas canvas,
    double cx,
    double cy,
    double radius,
    Color navy,
    Color gold,
  ) {
    // 8-pointed star pattern
    final Path starPath = Path();
    const int points = 8;

    for (int i = 0; i < points; i++) {
      final double angle = (2 * math.pi / points) * i;
      final double x = cx + radius * math.cos(angle);
      final double y = cy + radius * math.sin(angle);

      if (i == 0) {
        starPath.moveTo(x, y);
      } else {
        starPath.lineTo(x, y);
      }
    }
    starPath.close();

    // Fill star
    canvas.drawPath(starPath, Paint()..color = gold..style = PaintingStyle.fill);

    // Stroke star
    canvas.drawPath(starPath, Paint()..color = navy..style = PaintingStyle.stroke..strokeWidth = 0.8);

    // Center dot
    canvas.drawCircle(Offset(cx, cy), 1.5, Paint()..color = navy);
  }

  void _paintTessellatingPatternArea(
    Canvas canvas,
    double x,
    double y,
    double w,
    double h,
    Color navy,
    Color red,
    Color gold,
  ) {
    const double tileSize = 7;
    final Paint navyPaint = Paint()..color = navy;
    final Paint redPaint = Paint()..color = red;
    final Paint goldPaint = Paint()..color = gold;

    // Create a COMPLEX tessellating pattern with proper symmetry
    for (double dx = x; dx < x + w; dx += tileSize) {
      for (double dy = y; dy < y + h; dy += tileSize) {
        final double cx = dx + tileSize / 2;
        final double cy = dy + tileSize / 2;

        // Determine pattern based on position for symmetry
        final int patternType = ((dx.toInt() + dy.toInt()) ~/ tileSize.toInt()) % 5;

        switch (patternType) {
          case 0:
            // 6-pointed star
            final Path hexStar = Path();
            for (int i = 0; i < 6; i++) {
              final double angle = (math.pi / 3) * i;
              final double px = cx + (tileSize * 0.35) * math.cos(angle);
              final double py = cy + (tileSize * 0.35) * math.sin(angle);
              if (i == 0) hexStar.moveTo(px, py);
              else hexStar.lineTo(px, py);
            }
            hexStar.close();
            canvas.drawPath(hexStar, Paint()..color = gold..style = PaintingStyle.fill);
            canvas.drawPath(hexStar, Paint()..color = navy..style = PaintingStyle.stroke..strokeWidth = 0.4);
            break;

          case 1:
            // Small diamond grid
            final Path diamond = Path()
              ..moveTo(cx, dy)
              ..lineTo(dx + tileSize, cy)
              ..lineTo(cx, dy + tileSize)
              ..lineTo(dx, cy)
              ..close();
            canvas.drawPath(diamond, Paint()..color = red.withOpacity(0.6)..style = PaintingStyle.fill);
            canvas.drawPath(diamond, Paint()..color = gold..style = PaintingStyle.stroke..strokeWidth = 0.3);
            break;

          case 2:
            // Geometric flower (8-petal)
            for (int i = 0; i < 8; i++) {
              final double angle = (math.pi / 4) * i;
              final double px = cx + (tileSize * 0.3) * math.cos(angle);
              final double py = cy + (tileSize * 0.3) * math.sin(angle);
              canvas.drawCircle(Offset(px, py), 0.8, goldPaint);
            }
            canvas.drawCircle(Offset(cx, cy), 0.5, Paint()..color = navy);
            break;

          case 3:
            // Interlocking squares
            canvas.drawRect(
              Rect.fromCenter(center: Offset(cx, cy), width: tileSize * 0.4, height: tileSize * 0.4),
              Paint()..color = gold.withOpacity(0.5)..style = PaintingStyle.fill,
            );
            canvas.drawRect(
              Rect.fromCenter(center: Offset(cx, cy), width: tileSize * 0.6, height: tileSize * 0.2),
              Paint()..color = red.withOpacity(0.4)..style = PaintingStyle.fill,
            );
            break;

          case 4:
            // Cross with dot
            canvas.drawLine(
              Offset(cx - tileSize * 0.25, cy),
              Offset(cx + tileSize * 0.25, cy),
              Paint()..color = navy..strokeWidth = 0.5,
            );
            canvas.drawLine(
              Offset(cx, cy - tileSize * 0.25),
              Offset(cx, cy + tileSize * 0.25),
              Paint()..color = gold..strokeWidth = 0.5,
            );
            canvas.drawCircle(Offset(cx, cy), 1, Paint()..color = red);
            break;
        }
      }
    }
  }

  void _paintTopMihrAbArch(Canvas canvas, double w, double h, Color navy, Color gold, Color red) {
    const double archTop = 30;
    const double archHeight = 90;
    const double archLeft = 40;
    const double archRight = 40;

    // Outer arch curve
    final Path archPath = Path()
      ..moveTo(archLeft, archTop + archHeight)
      // Left side curve
      ..quadraticBezierTo(
        archLeft - 15,
        archTop + archHeight * 0.3,
        archLeft + 20,
        archTop,
      )
      // Top curve (dome)
      ..quadraticBezierTo(
        w * 0.5,
        archTop - 20,
        w - archLeft - 20,
        archTop,
      )
      // Right side curve
      ..quadraticBezierTo(
        w - archLeft + 15,
        archTop + archHeight * 0.3,
        w - archLeft,
        archTop + archHeight,
      )
      ..lineTo(w - archLeft, archTop + archHeight + 15)
      ..lineTo(archLeft, archTop + archHeight + 15)
      ..close();

    // Fill arch with navy blue
    canvas.drawPath(archPath, Paint()..color = navy..style = PaintingStyle.fill);

    // Stroke arch with gold
    canvas.drawPath(archPath, Paint()..color = gold..style = PaintingStyle.stroke..strokeWidth = 2.5);

    // Decorative arch interior pattern
    for (double x = 60; x < w - 60; x += 12) {
      canvas.drawCircle(
        Offset(x, archTop + 25),
        3,
        Paint()..color = gold,
      );
      canvas.drawCircle(
        Offset(x, archTop + 25),
        1.5,
        Paint()..color = red,
      );
    }
  }

  void _paintBottomCornerOrnaments(Canvas canvas, double w, double h, Color gold, Color navy) {
    const double ornamentSize = 35;
    const double ornamentY = 40;

    // Bottom-left ornament
    _paintCornerOrnament(canvas, ornamentSize, h - ornamentY, ornamentSize, gold, navy);

    // Bottom-right ornament
    _paintCornerOrnament(canvas, w - ornamentSize, h - ornamentY, ornamentSize, gold, navy);
  }

  void _paintCornerOrnament(Canvas canvas, double cx, double cy, double size, Color gold, Color navy) {
    // Outer gold shape
    final Path outerShape = Path()
      ..moveTo(cx, cy - size * 0.5)
      ..quadraticBezierTo(cx - size * 0.3, cy - size * 0.3, cx - size * 0.5, cy)
      ..quadraticBezierTo(cx - size * 0.3, cy + size * 0.3, cx, cy + size * 0.5)
      ..quadraticBezierTo(cx + size * 0.3, cy + size * 0.3, cx + size * 0.5, cy)
      ..quadraticBezierTo(cx + size * 0.3, cy - size * 0.3, cx, cy - size * 0.5)
      ..close();

    canvas.drawPath(outerShape, Paint()..color = gold..style = PaintingStyle.fill);
    canvas.drawPath(outerShape, Paint()..color = navy..style = PaintingStyle.stroke..strokeWidth = 1.5);

    // Inner decorative pattern
    for (int i = 0; i < 4; i++) {
      final double angle = (math.pi * 2 / 4) * i;
      final double x = cx + (size * 0.25) * math.cos(angle);
      final double y = cy + (size * 0.25) * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = navy);
    }
  }

  void _paintInnerGoldenOutline(Canvas canvas, double w, double h, Color gold) {
    // Inner decorative golden outline for content area
    const double insetX = 80;
    const double insetY = 120;

    // Top-left corner curve
    final Path cornerCurve = Path()
      ..moveTo(insetX + 15, insetY)
      ..quadraticBezierTo(insetX, insetY, insetX, insetY + 15);

    // Simplified inner frame outline
    canvas.drawRect(
      Rect.fromLTRB(insetX, insetY, w - insetX, h - insetY),
      Paint()
        ..color = gold.withOpacity(0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(_IntricateIslamicPatternPainter oldDelegate) =>
      oldDelegate.isPageOne != isPageOne ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.accentColor != accentColor ||
      oldDelegate.backgroundColor != backgroundColor;
}
