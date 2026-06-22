import 'dart:math' as math;
import 'package:flutter/material.dart';

class QuranPageBorder extends StatelessWidget {
  final Widget child;
  /// سمك الإطار (يحدد المسافة المتروكة من حافة الشاشة)
  final double borderThickness;
  /// ألوان قابلة للتخصيص حسب المظهر
  final Color? primaryColor;
  final Color? accentColor;
  final Color? tertiaryColor;

  const QuranPageBorder({
    Key? key,
    required this.child,
    this.borderThickness = 45.0,
    this.primaryColor,
    this.accentColor,
    this.tertiaryColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: TezhibBorderPainter(
        thickness: borderThickness,
        primaryColor: primaryColor ?? const Color(0xFF14305E),
        accentColor: accentColor ?? const Color(0xFFC5A059),
        tertiaryColor: tertiaryColor ?? const Color(0xFF8B1C24),
      ),
      child: Padding(
        // تأمين مساحة داخلية آمنة للنص القرآني حتى لا يتداخل مع الزخرفة
        padding: EdgeInsets.fromLTRB(
          borderThickness + 15.0,
          borderThickness + 20.0, // Increased top padding to avoid border overlap
          borderThickness + 15.0,
          borderThickness + 15.0,
        ),
        child: child,
      ),
    );
  }
}

class TezhibBorderPainter extends CustomPainter {
  final double thickness;
  final Color primaryColor;
  final Color accentColor;
  final Color tertiaryColor;

  TezhibBorderPainter({
    required this.thickness,
    required this.primaryColor,
    required this.accentColor,
    required this.tertiaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // استخراج الألوان المتكيفة مع المظهر
    final Color darkBlue = primaryColor;
    final Color gold = accentColor;
    final Color darkRed = tertiaryColor;
    final Color lightTeal = primaryColor.withOpacity(0.3);
    final Color greyAccent = gold.withOpacity(0.5);

    // 1. رسم الخطوط الداخلية الصلبة التي تحيط بالنص (كما في الصورة)
    final Rect innerRect = Rect.fromLTRB(thickness, thickness, w - thickness, h - thickness);

    // خط أحمر داخلي
    canvas.drawRect(
      innerRect,
      Paint()..color = darkRed..style = PaintingStyle.stroke..strokeWidth = 1.5,
    );
    // خط ذهبي سميك
    canvas.drawRect(
      innerRect.inflate(3),
      Paint()..color = gold..style = PaintingStyle.stroke..strokeWidth = 3,
    );
    // خط أزرق خارجي
    canvas.drawRect(
      innerRect.inflate(6),
      Paint()..color = darkBlue..style = PaintingStyle.stroke..strokeWidth = 1,
    );

    // 2. Add decorative geometric corner details
    _paintGeometricCornerDetails(canvas, w, h, darkBlue, gold, darkRed);

    // 3. دالة لرسم وحدة الزخرفة (القبة الإسلامية) المستوحاة من أطراف الصورة
    void drawSingleMotif(Canvas canvas, double width, double height) {
      // الخلفية المائية الفاتحة (Teal)
      Path baseShape = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(width * 0.2, -height * 0.5, width * 0.5, -height)
        ..quadraticBezierTo(width * 0.8, -height * 0.5, width, 0);
      canvas.drawPath(baseShape, Paint()..color = lightTeal..style = PaintingStyle.fill);
      canvas.drawPath(baseShape, Paint()..color = gold..style = PaintingStyle.stroke..strokeWidth = 1.5);

      // الطبقة الزرقاء الداكنة (قلب القبة)
      Path innerShape = Path()
        ..moveTo(width * 0.15, 0)
        ..quadraticBezierTo(width * 0.3, -height * 0.4, width * 0.5, -height * 0.8)
        ..quadraticBezierTo(width * 0.7, -height * 0.4, width * 0.85, 0);
      canvas.drawPath(innerShape, Paint()..color = darkBlue..style = PaintingStyle.fill);
      canvas.drawPath(innerShape, Paint()..color = Colors.white.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 0.5);

      // اللمسة الحمراء في المنتصف
      Path redAccent = Path()
        ..moveTo(width * 0.35, 0)
        ..quadraticBezierTo(width * 0.45, -height * 0.2, width * 0.5, -height * 0.4)
        ..quadraticBezierTo(width * 0.55, -height * 0.2, width * 0.65, 0);
      canvas.drawPath(redAccent, Paint()..color = darkRed..style = PaintingStyle.fill);

      // الزخارف الخارجية الدقيقة (التيجان/الرؤوس الرمادية والذهبية الممتدة للخارج)
      Paint finialPaint = Paint()..color = greyAccent..style = PaintingStyle.stroke..strokeWidth = 0.8;
      canvas.drawLine(Offset(width * 0.5, -height), Offset(width * 0.5, -height - 8), finialPaint);
      canvas.drawCircle(Offset(width * 0.5, -height - 10), 1.5, Paint()..color = gold);

      // Add small geometric stars in motif
      _paintSmallGeometricStar(canvas, width * 0.5, -height * 0.5, 2, gold, darkBlue);
    }

    // 3. دالة لحساب وتكرار الزخارف على طول ضلع معين بدون تمطيط
    void drawEdgeMotifs(Canvas canvas, double length, double motifHeight) {
      double targetWidth = 35.0; // العرض التقريبي لكل زخرفة
      int count = (length / targetWidth).floor();
      if (count <= 0) return;
      double actualWidth = length / count; // ضبط العرض الدقيق ليملأ الضلع تماماً

      for (int i = 0; i < count; i++) {
        canvas.save();
        canvas.translate(i * actualWidth, 0);
        drawSingleMotif(canvas, actualWidth, motifHeight);
        canvas.restore();
      }
    }

    double motifExtrusion = thickness - 12.0;

    // --- رسم الضلع العلوي ---
    canvas.save();
    canvas.translate(thickness, thickness + 6);
    drawEdgeMotifs(canvas, w - (thickness * 2), motifExtrusion);
    canvas.restore();

    // --- رسم الضلع السفلي ---
    canvas.save();
    // ننتقل للزاوية السفلية اليمنى ونعكس الاتجاه 180 درجة
    canvas.translate(w - thickness, h - thickness - 6);
    canvas.rotate(math.pi);
    drawEdgeMotifs(canvas, w - (thickness * 2), motifExtrusion);
    canvas.restore();

    // --- رسم الضلع الأيسر ---
    canvas.save();
    // ننتقل للزاوية السفلية اليسرى ونعكس 90 درجة للأعلى
    canvas.translate(thickness + 6, h - thickness);
    canvas.rotate(-math.pi / 2);
    drawEdgeMotifs(canvas, h - (thickness * 2), motifExtrusion);
    canvas.restore();

    // --- رسم الضلع الأيمن ---
    canvas.save();
    // ننتقل للزاوية العلوية اليمنى ونعكس 90 درجة للأسفل
    canvas.translate(w - thickness - 6, thickness);
    canvas.rotate(math.pi / 2);
    drawEdgeMotifs(canvas, h - (thickness * 2), motifExtrusion);
    canvas.restore();

    // 4. رسم زوايا الإطار (الزخارف الرابطة في الزوايا الأربع)
    List<Offset> corners = [
      Offset(thickness + 6, thickness + 6),           // أعلى اليسار
      Offset(w - thickness - 6, thickness + 6),       // أعلى اليمين
      Offset(thickness + 6, h - thickness - 6),       // أسفل اليسار
      Offset(w - thickness - 6, h - thickness - 6),   // أسفل اليمين
    ];

    for (var corner in corners) {
      double cornerSize = thickness * 0.45;

      canvas.save();
      canvas.translate(corner.dx, corner.dy);

      Path cornerShape = Path()
        ..moveTo(0, -cornerSize)
        ..quadraticBezierTo(cornerSize * 0.4, -cornerSize * 0.4, cornerSize, 0)
        ..quadraticBezierTo(cornerSize * 0.4, cornerSize * 0.4, 0, cornerSize)
        ..quadraticBezierTo(-cornerSize * 0.4, cornerSize * 0.4, -cornerSize, 0)
        ..quadraticBezierTo(-cornerSize * 0.4, -cornerSize * 0.4, 0, -cornerSize);

      canvas.drawPath(cornerShape, Paint()..color = darkBlue..style = PaintingStyle.fill);
      canvas.drawPath(cornerShape, Paint()..color = gold..style = PaintingStyle.stroke..strokeWidth = 2);

      canvas.drawCircle(Offset.zero, cornerSize * 0.35, Paint()..color = darkRed);
      canvas.drawCircle(Offset.zero, cornerSize * 0.15, Paint()..color = gold);

      canvas.restore();
    }
  }

  void _paintGeometricCornerDetails(Canvas canvas, double w, double h, Color navy, Color gold, Color red) {
    // Add geometric details to break up the frame
    // Top corners
    _paintSmallGeometricStar(canvas, 30, 30, 3, gold, navy);
    _paintSmallGeometricStar(canvas, w - 30, 30, 3, gold, navy);
    // Bottom corners
    _paintSmallGeometricStar(canvas, 30, h - 30, 3, gold, navy);
    _paintSmallGeometricStar(canvas, w - 30, h - 30, 3, gold, navy);

    // Fill border areas with complex tessellating patterns
    _paintComplexTessellationPattern(canvas, 25, 25, w - 50, 45, navy, red, gold);
    _paintComplexTessellationPattern(canvas, 25, h - 70, w - 50, 45, navy, red, gold);
    _paintComplexTessellationPattern(canvas, 25, 70, 45, h - 140, navy, red, gold);
    _paintComplexTessellationPattern(canvas, w - 70, 70, 45, h - 140, navy, red, gold);
  }

  void _paintComplexTessellationPattern(
    Canvas canvas,
    double x,
    double y,
    double w,
    double h,
    Color navy,
    Color red,
    Color gold,
  ) {
    const double tileSize = 5.5;

    // Create FULLY DENSE symmetrical tessellating pattern with multiple geometric elements
    for (double dx = x; dx < x + w; dx += tileSize) {
      for (double dy = y; dy < y + h; dy += tileSize) {
        // Center point
        final double cx = dx + tileSize / 2;
        final double cy = dy + tileSize / 2;

        // Determine pattern based on position - creates symmetrical effect
        final int patternX = (dx.toInt() ~/ tileSize.toInt()) % 4;
        final int patternY = (dy.toInt() ~/ tileSize.toInt()) % 4;
        final int combined = (patternX + patternY) % 6;

        switch (combined) {
          case 0:
            // 6-pointed star pattern
            final Path hexStar = Path();
            for (int i = 0; i < 6; i++) {
              final double angle = (math.pi / 3) * i;
              final double px = cx + (tileSize * 0.35) * math.cos(angle);
              final double py = cy + (tileSize * 0.35) * math.sin(angle);
              if (i == 0) hexStar.moveTo(px, py);
              else hexStar.lineTo(px, py);
            }
            hexStar.close();
            canvas.drawPath(hexStar, Paint()..color = gold.withOpacity(0.5)..style = PaintingStyle.fill);
            canvas.drawPath(hexStar, Paint()..color = navy..style = PaintingStyle.stroke..strokeWidth = 0.3);
            break;

          case 1:
            // Diamond grid pattern
            final Path diamond = Path()
              ..moveTo(cx, dy)
              ..lineTo(dx + tileSize, cy)
              ..lineTo(cx, dy + tileSize)
              ..lineTo(dx, cy)
              ..close();
            canvas.drawPath(diamond, Paint()..color = red.withOpacity(0.5)..style = PaintingStyle.fill);
            canvas.drawPath(diamond, Paint()..color = gold..style = PaintingStyle.stroke..strokeWidth = 0.2);
            break;

          case 2:
            // 8-petal flower
            for (int i = 0; i < 8; i++) {
              final double angle = (math.pi / 4) * i;
              final double px = cx + (tileSize * 0.28) * math.cos(angle);
              final double py = cy + (tileSize * 0.28) * math.sin(angle);
              canvas.drawCircle(Offset(px, py), 0.6, Paint()..color = gold);
            }
            canvas.drawCircle(Offset(cx, cy), 0.4, Paint()..color = navy);
            break;

          case 3:
            // Concentric squares
            for (int i = 0; i < 2; i++) {
              final double size = tileSize * 0.4 * (1 - i * 0.4);
              canvas.drawRect(
                Rect.fromCenter(center: Offset(cx, cy), width: size, height: size),
                Paint()
                  ..color = i == 0 ? gold.withOpacity(0.4) : red.withOpacity(0.3)
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = 0.2,
              );
            }
            break;

          case 4:
            // Cross grid
            canvas.drawLine(
              Offset(cx - tileSize * 0.3, cy),
              Offset(cx + tileSize * 0.3, cy),
              Paint()..color = navy..strokeWidth = 0.4,
            );
            canvas.drawLine(
              Offset(cx, cy - tileSize * 0.3),
              Offset(cx, cy + tileSize * 0.3),
              Paint()..color = gold..strokeWidth = 0.4,
            );
            canvas.drawCircle(Offset(cx, cy), 0.5, Paint()..color = red);
            break;

          case 5:
            // Triangle pattern (creates intricate look)
            final Path triangle = Path()
              ..moveTo(cx, dy + tileSize * 0.2)
              ..lineTo(dx + tileSize * 0.7, cy + tileSize * 0.3)
              ..lineTo(dx + tileSize * 0.3, cy + tileSize * 0.6)
              ..close();
            canvas.drawPath(triangle, Paint()..color = gold.withOpacity(0.3)..style = PaintingStyle.fill);
            canvas.drawPath(triangle, Paint()..color = navy..style = PaintingStyle.stroke..strokeWidth = 0.2);
            break;
        }
      }
    }
  }

  void _paintSmallGeometricStar(Canvas canvas, double cx, double cy, double radius, Color gold, Color navy) {
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

    canvas.drawPath(starPath, Paint()..color = gold..style = PaintingStyle.fill);
    canvas.drawPath(starPath, Paint()..color = navy..style = PaintingStyle.stroke..strokeWidth = 0.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
