import os

with open('lib/screens/library_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

start_marker = "// Rich Domain Gradients for the 8 Islamic Faculties"
end_marker = "// Monumental Islamic Faculty Card (Authentic Rich Jewel-Toned Gradients & Art)"

idx1 = content.find(start_marker)
idx2 = content.find(end_marker)

if idx1 == -1 or idx2 == -1:
    print(f"Error finding markers: idx1={idx1}, idx2={idx2}")
    exit(1)

new_code = """// Rich Domain Gradients for the 8 Islamic Faculties (Vibrant Saturated Jewel Tones)
// ─────────────────────────────────────────────────────────────────────────────
List<Color> _getFacultyCardGradient(String facultyId) {
  switch (facultyId) {
    case 'quran_sciences':
      // Vibrant Royal Quranic Blue & Lapis Lazuli
      return const [Color(0xFF0F2E68), Color(0xFF1B499E), Color(0xFF2865C8)];
    case 'seerah':
      // Noble Warm Medina Amber, Desert Bronze & Copper
      return const [Color(0xFF5A2707), Color(0xFF8B3F0D), Color(0xFFBA5A16)];
    case 'companions':
      // Sacred Medina Oasis Emerald & Rich Forest Jade
      return const [Color(0xFF0A4E31), Color(0xFF127A4E), Color(0xFF1AA46C)];
    case 'prophets':
      // Persian Turquoise & Mount Sinai Teal
      return const [Color(0xFF0C465E), Color(0xFF166E94), Color(0xFF2193C2)];
    case 'fiqh_and_fatawa':
      // Imperial Velvet Plum & Byzantine Amethyst
      return const [Color(0xFF480F57), Color(0xFF751C8C), Color(0xFFA129BF)];
    case 'aqeedah':
      // Celestial Dawn Azure & Deep Cosmic Cobalt
      return const [Color(0xFF0D3E5D), Color(0xFF16618F), Color(0xFF2082BE)];
    case 'tibb':
      // Sacred Pomegranate Ruby & Damascus Rose
      return const [Color(0xFF550E2D), Color(0xFF8B184C), Color(0xFFBD2568)];
    case 'quizzes':
    default:
      // Moroccan Saffron & Andalusian Royal Gold
      return const [Color(0xFF5A3105), Color(0xFF91510B), Color(0xFFC47313)];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Meaningful, High-Visibility Islamic Artwork Painter for Each Faculty
// ─────────────────────────────────────────────────────────────────────────────
class _FacultyIllustrationPainter extends CustomPainter {
  final String facultyId;
  final Color accentColor;

  const _FacultyIllustrationPainter({
    required this.facultyId,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Ambient Luminous Spotlight Aura behind artwork so it stands out prominently
    final cx = size.width * 0.74;
    final cy = size.height * 0.68;
    final r = size.width * 0.38;

    final auraPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          accentColor.withValues(alpha: 0.32),
          const Color(0xFFFFD54F).withValues(alpha: 0.14),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r * 1.2));
    canvas.drawCircle(Offset(cx, cy), r * 1.2, auraPaint);

    final strokePaint = Paint()
      ..color = accentColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.32)
      ..style = PaintingStyle.fill;

    final goldGlow = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    final goldFill = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;

    final whiteGlow = Paint()
      ..color = Colors.white.withValues(alpha: 0.80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    switch (facultyId) {
      case 'quran_sciences':
        // ── 1. The Holy Quran resting open upon an ornate wooden Rihal stand ──
        // Radiant background Rub el Hizb 8-pointed star
        final starPath = Path();
        for (int i = 0; i < 8; i++) {
          final rad = i * (math.pi / 4);
          final p = Offset(cx + (r * 0.85) * math.cos(rad), cy + (r * 0.85) * math.sin(rad));
          if (i == 0) {
            starPath.moveTo(p.dx, p.dy);
          } else {
            starPath.lineTo(p.dx, p.dy);
          }
        }
        starPath.close();
        canvas.drawPath(starPath, goldGlow);

        // Open Holy Quran pages (curved open codex)
        final leftPage = Path()
          ..moveTo(cx, cy + 4)
          ..quadraticBezierTo(cx - r * 0.45, cy - r * 0.38, cx - r * 0.90, cy - r * 0.15)
          ..lineTo(cx - r * 0.90, cy + r * 0.38)
          ..quadraticBezierTo(cx - r * 0.45, cy + r * 0.15, cx, cy + r * 0.48)
          ..close();
        canvas.drawPath(leftPage, fillPaint);
        canvas.drawPath(leftPage, strokePaint);

        final rightPage = Path()
          ..moveTo(cx, cy + 4)
          ..quadraticBezierTo(cx + r * 0.45, cy - r * 0.38, cx + r * 0.90, cy - r * 0.15)
          ..lineTo(cx + r * 0.90, cy + r * 0.38)
          ..quadraticBezierTo(cx + r * 0.45, cy + r * 0.15, cx, cy + r * 0.48)
          ..close();
        canvas.drawPath(rightPage, fillPaint);
        canvas.drawPath(rightPage, strokePaint);

        // Scripture lines on the open pages
        for (double dy = -0.15; dy <= 0.25; dy += 0.12) {
          canvas.drawLine(
            Offset(cx - r * 0.78, cy + r * dy),
            Offset(cx - r * 0.20, cy + r * (dy - 0.05)),
            whiteGlow,
          );
          canvas.drawLine(
            Offset(cx + r * 0.20, cy + r * (dy - 0.05)),
            Offset(cx + r * 0.78, cy + r * dy),
            whiteGlow,
          );
        }

        // Crossing legs of the Wooden Rihal stand
        canvas.drawLine(Offset(cx - r * 0.60, cy + r * 0.75), Offset(cx + r * 0.40, cy + r * 0.25), strokePaint);
        canvas.drawLine(Offset(cx + r * 0.60, cy + r * 0.75), Offset(cx - r * 0.40, cy + r * 0.25), strokePaint);

        // Celestial light rays rising from the Quran
        for (double a = -0.6; a <= 0.6; a += 0.3) {
          canvas.drawLine(
            Offset(cx + math.sin(a) * 8, cy - r * 0.2),
            Offset(cx + math.sin(a) * (r * 1.0), cy - r * 1.05),
            goldGlow,
          );
        }
        break;

      case 'seerah':
        // ── 2. The Prophet's Green Mosque Dome (القبة الخضراء) & Tall Minaret ──
        // Desert sand dune base
        final dune = Path()
          ..moveTo(cx - r * 1.15, cy + r * 0.85)
          ..quadraticBezierTo(cx, cy + r * 0.45, cx + r * 1.15, cy + r * 0.85);
        canvas.drawPath(dune, strokePaint);

        // The Sacred Green Dome (القبة الخضراء)
        final dome = Path()
          ..moveTo(cx - r * 0.60, cy + r * 0.45)
          ..quadraticBezierTo(cx, cy - r * 0.60, cx + r * 0.60, cy + r * 0.45)
          ..close();
        canvas.drawPath(dome, fillPaint);
        canvas.drawPath(dome, strokePaint);
        // Dome spire with Golden Crescent
        canvas.drawLine(Offset(cx, cy - r * 0.60), Offset(cx, cy - r * 0.88), goldGlow);
        canvas.drawCircle(Offset(cx, cy - r * 0.88), 3.0, goldFill);
        canvas.drawCircle(Offset(cx, cy - r * 0.88), 3.0, goldGlow);

        // Tall Minaret beside the dome
        final minaretX = cx + r * 0.75;
        canvas.drawRect(Rect.fromLTWH(minaretX - 7, cy - r * 0.80, 14, r * 1.25), fillPaint);
        canvas.drawRect(Rect.fromLTWH(minaretX - 7, cy - r * 0.80, 14, r * 1.25), strokePaint);
        // Minaret Balcony
        canvas.drawRect(Rect.fromLTWH(minaretX - 10, cy - r * 0.52, 20, 5), goldGlow);
        // Minaret Spire & Crescent
        final minCap = Path()
          ..moveTo(minaretX - 7, cy - r * 0.80)
          ..lineTo(minaretX, cy - r * 1.20)
          ..lineTo(minaretX + 7, cy - r * 0.80)
          ..close();
        canvas.drawPath(minCap, fillPaint);
        canvas.drawPath(minCap, strokePaint);
        canvas.drawCircle(Offset(minaretX, cy - r * 1.20), 2.5, goldGlow);

        // Prophetic Crescent Moon in the sky
        final moonCenter = Offset(cx - r * 0.65, cy - r * 0.88);
        canvas.drawCircle(moonCenter, 11, goldFill);
        canvas.drawCircle(moonCenter, 11, goldGlow);
        break;

      case 'companions':
        // ── 3. Illuminated Ancient Parchment Scroll, Ink Quill & Stars ──
        // Rolled Parchment Scroll
        final scroll = Path()
          ..moveTo(cx - r * 0.70, cy - r * 0.50)
          ..lineTo(cx + r * 0.50, cy - r * 0.50)
          ..quadraticBezierTo(cx + r * 0.75, cy - r * 0.28, cx + r * 0.50, cy - r * 0.05)
          ..lineTo(cx - r * 0.70, cy - r * 0.05)
          ..lineTo(cx - r * 0.70, cy + r * 0.60)
          ..lineTo(cx + r * 0.50, cy + r * 0.60)
          ..quadraticBezierTo(cx + r * 0.75, cy + r * 0.80, cx + r * 0.50, cy + r * 0.90)
          ..lineTo(cx - r * 0.80, cy + r * 0.90)
          ..close();
        canvas.drawPath(scroll, fillPaint);
        canvas.drawPath(scroll, strokePaint);

        // Quill Pen angled across the scroll
        final quill = Path()
          ..moveTo(cx - r * 0.25, cy + r * 0.65)
          ..quadraticBezierTo(cx + r * 0.35, cy + r * 0.1, cx + r * 0.90, cy - r * 0.70)
          ..quadraticBezierTo(cx + r * 0.70, cy - r * 0.35, cx - r * 0.25, cy + r * 0.65);
        canvas.drawPath(quill, goldFill);
        canvas.drawPath(quill, goldGlow);

        // Radiant Companion Stars ("أصحابي كالنجوم")
        final starOffsets = [
          Offset(cx - r * 0.80, cy - r * 0.75),
          Offset(cx, cy - r * 0.95),
          Offset(cx + r * 0.80, cy - r * 0.40),
          Offset(cx - r * 0.90, cy + r * 0.20),
          Offset(cx + r * 0.35, cy + r * 0.85),
        ];
        for (final so in starOffsets) {
          canvas.drawCircle(so, 4.0, goldFill);
          canvas.drawCircle(so, 4.0, goldGlow);
          canvas.drawCircle(so, 1.8, whiteGlow);
        }
        break;

      case 'prophets':
        // ── 4. The Sacred Ark of Noah & Peak of Mount Sinai ──
        // Water Waves
        final waves = Path()
          ..moveTo(cx - r * 1.15, cy + r * 0.65)
          ..quadraticBezierTo(cx - r * 0.6, cy + r * 0.48, cx - r * 0.2, cy + r * 0.65)
          ..quadraticBezierTo(cx + r * 0.3, cy + r * 0.82, cx + r * 0.7, cy + r * 0.65)
          ..quadraticBezierTo(cx + r * 0.9, cy + r * 0.52, cx + r * 1.15, cy + r * 0.65);
        canvas.drawPath(waves, strokePaint);

        // The Sacred Ark (سفينة نوح)
        final ark = Path()
          ..moveTo(cx - r * 0.80, cy + r * 0.40)
          ..quadraticBezierTo(cx, cy + r * 0.72, cx + r * 0.80, cy + r * 0.40)
          ..lineTo(cx + r * 0.65, cy + r * 0.22)
          ..lineTo(cx - r * 0.65, cy + r * 0.22)
          ..close();
        canvas.drawPath(ark, fillPaint);
        canvas.drawPath(ark, strokePaint);
        // Cabin on Ark
        canvas.drawRect(Rect.fromLTWH(cx - r * 0.38, cy + r * 0.02, r * 0.76, r * 0.22), fillPaint);
        canvas.drawRect(Rect.fromLTWH(cx - r * 0.38, cy + r * 0.02, r * 0.76, r * 0.22), strokePaint);

        // Mount Sinai (طور سيناء) mountain peak in background
        final mt = Path()
          ..moveTo(cx - r * 0.95, cy + r * 0.25)
          ..lineTo(cx - r * 0.1, cy - r * 0.80)
          ..lineTo(cx + r * 0.70, cy + r * 0.25);
        canvas.drawPath(mt, goldGlow);
        // Divine sun halo over Sinai
        canvas.drawCircle(Offset(cx - r * 0.1, cy - r * 0.80), 12, goldFill);
        canvas.drawCircle(Offset(cx - r * 0.1, cy - r * 0.80), 12, goldGlow);
        break;

      case 'fiqh_and_fatawa':
        // ── 5. Classical Scales of Sacred Justice (ميزان العدل والشرع) ──
        // Central upright Pillar
        canvas.drawLine(Offset(cx, cy - r * 1.0), Offset(cx, cy + r * 0.90), strokePaint);
        // Pillar Base
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + r * 0.90), width: r * 0.65, height: 12), fillPaint);
        canvas.drawOval(Rect.fromCenter(center: Offset(cx, cy + r * 0.90), width: r * 0.65, height: 12), strokePaint);
        // Fulcrum Ring
        canvas.drawCircle(Offset(cx, cy - r * 0.58), 5, goldFill);
        canvas.drawCircle(Offset(cx, cy - r * 0.58), 5, goldGlow);

        // Horizontal Balance Beam
        final beamY = cy - r * 0.58;
        final beamLeft = cx - r * 0.80;
        final beamRight = cx + r * 0.80;
        canvas.drawLine(Offset(beamLeft, beamY), Offset(beamRight, beamY), strokePaint);

        // Left Pan & Suspension Chains
        canvas.drawLine(Offset(beamLeft, beamY), Offset(beamLeft - 12, cy + 6), goldGlow);
        canvas.drawLine(Offset(beamLeft, beamY), Offset(beamLeft + 12, cy + 6), goldGlow);
        final leftPan = Path()
          ..moveTo(beamLeft - 18, cy + 6)
          ..quadraticBezierTo(beamLeft, cy + 22, beamLeft + 18, cy + 6)
          ..close();
        canvas.drawPath(leftPan, fillPaint);
        canvas.drawPath(leftPan, strokePaint);

        // Right Pan & Suspension Chains
        canvas.drawLine(Offset(beamRight, beamY), Offset(beamRight - 12, cy + 6), goldGlow);
        canvas.drawLine(Offset(beamRight, beamY), Offset(beamRight + 12, cy + 6), goldGlow);
        final rightPan = Path()
          ..moveTo(beamRight - 18, cy + 6)
          ..quadraticBezierTo(beamRight, cy + 22, beamRight + 18, cy + 6)
          ..close();
        canvas.drawPath(rightPan, fillPaint);
        canvas.drawPath(rightPan, strokePaint);
        break;

      case 'aqeedah':
        // ── 6. Radiant Divine Sunburst of Tawhid & Celestial Minarets ──
        final sunCenter = Offset(cx, cy - r * 0.12);
        canvas.drawCircle(sunCenter, r * 0.38, fillPaint);
        canvas.drawCircle(sunCenter, r * 0.38, strokePaint);

        // 16 Emanating Divine Light Rays
        for (int i = 0; i < 16; i++) {
          final rad = i * (math.pi / 8);
          final inner = (i % 2 == 0) ? r * 0.44 : r * 0.55;
          final outer = (i % 2 == 0) ? r * 1.15 : r * 0.90;
          canvas.drawLine(
            Offset(sunCenter.dx + inner * math.cos(rad), sunCenter.dy + inner * math.sin(rad)),
            Offset(sunCenter.dx + outer * math.cos(rad), sunCenter.dy + outer * math.sin(rad)),
            (i % 2 == 0) ? strokePaint : goldGlow,
          );
        }

        // Two Sacred Minarets rising into the light
        for (final mx in [cx - r * 0.70, cx + r * 0.70]) {
          canvas.drawRect(Rect.fromLTWH(mx - 5, cy + r * 0.08, 10, r * 0.80), fillPaint);
          canvas.drawRect(Rect.fromLTWH(mx - 5, cy + r * 0.08, 10, r * 0.80), strokePaint);
          final spire = Path()
            ..moveTo(mx - 6, cy + r * 0.08)
            ..lineTo(mx, cy - r * 0.28)
            ..lineTo(mx + 6, cy + r * 0.08)
            ..close();
          canvas.drawPath(spire, goldGlow);
        }
        break;

      case 'tibb':
        // ── 7. Sacred Healing Olive Branch & Honeycomb Lattice ──
        // Hexagonal Honeycomb grid (العسل والشفاء)
        for (int i = 0; i < 5; i++) {
          final hexCenter = Offset(
            cx + (i % 2 == 0 ? 0 : 18) - 10,
            cy - r * 0.55 + (i * 20),
          );
          final hex = Path();
          for (int j = 0; j < 6; j++) {
            final a = j * (math.pi / 3);
            final pt = Offset(hexCenter.dx + 13 * math.cos(a), hexCenter.dy + 13 * math.sin(a));
            if (j == 0) {
              hex.moveTo(pt.dx, pt.dy);
            } else {
              hex.lineTo(pt.dx, pt.dy);
            }
          }
          hex.close();
          canvas.drawPath(hex, fillPaint);
          canvas.drawPath(hex, strokePaint);
        }

        // Branch of the Sacred Olive Tree with Leaves
        final branch = Path()
          ..moveTo(cx - r * 0.85, cy + r * 0.85)
          ..quadraticBezierTo(cx - r * 0.3, cy + r * 0.3, cx + r * 0.75, cy + r * 0.18);
        canvas.drawPath(branch, goldGlow);

        // Olive leaves and golden olives
        for (final leafCenter in [
          Offset(cx - r * 0.55, cy + r * 0.52),
          Offset(cx - r * 0.12, cy + r * 0.35),
          Offset(cx + r * 0.38, cy + r * 0.24),
        ]) {
          final leaf = Path()
            ..moveTo(leafCenter.dx - 12, leafCenter.dy)
            ..quadraticBezierTo(leafCenter.dx, leafCenter.dy - 10, leafCenter.dx + 12, leafCenter.dy)
            ..quadraticBezierTo(leafCenter.dx, leafCenter.dy + 10, leafCenter.dx - 12, leafCenter.dy);
          canvas.drawPath(leaf, fillPaint);
          canvas.drawPath(leaf, strokePaint);
          // Golden Olive fruit
          canvas.drawCircle(Offset(leafCenter.dx + 6, leafCenter.dy + 8), 3.5, goldFill);
          canvas.drawCircle(Offset(leafCenter.dx + 6, leafCenter.dy + 8), 3.5, goldGlow);
        }
        break;

      case 'quizzes':
      default:
        // ── 8. Ancient Astrolabe Rings & Triumph Star ──
        // Astrolabe concentric graduated brass rings
        canvas.drawCircle(Offset(cx, cy), r * 0.38, goldGlow);
        canvas.drawCircle(Offset(cx, cy), r * 0.68, strokePaint);
        canvas.drawCircle(Offset(cx, cy), r * 0.98, goldGlow);

        // Throne ring (عروة الأسطرلاب)
        canvas.drawCircle(Offset(cx, cy - r * 0.98), 9, goldGlow);

        // Radiant 8-pointed star in the center
        final star = Path();
        for (int i = 0; i < 8; i++) {
          final rad = i * (math.pi / 4);
          final rad2 = rad + (math.pi / 8);
          final p1 = Offset(cx + (r * 0.38) * math.cos(rad), cy + (r * 0.38) * math.sin(rad));
          final p2 = Offset(cx + (r * 0.18) * math.cos(rad2), cy + (r * 0.18) * math.sin(rad2));
          if (i == 0) {
            star.moveTo(p1.dx, p1.dy);
          } else {
            star.lineTo(p1.dx, p1.dy);
          }
          star.lineTo(p2.dx, p2.dy);
        }
        star.close();
        canvas.drawPath(star, goldFill);
        canvas.drawPath(star, goldGlow);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _FacultyIllustrationPainter oldDelegate) {
    return oldDelegate.facultyId != facultyId || oldDelegate.accentColor != accentColor;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
"""

content = content[:idx1] + new_code + content[idx2:]

with open('lib/screens/library_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print("Successfully upgraded faculty gradients and artwork painter!")
