// =============================================================================
// FILE PATH : lib/features/qibla/presentation/screens/qibla_screen.dart
//
// Minimalist, high-performance Qibla compass.
//
// • Uses geolocator for GPS + flutter_compass for magnetometer heading.
// • Calculates bearing to Kaaba (21.4225°N, 39.8262°E) via spherical math.
// • FAST LOADING: Uses getLastKnownPosition for instant UI, then updates.
// • Dynamic Guidance: Tells user to turn right/left based on device heading.
// • Renders a premium CustomPainter compass with smooth animated needle.
// • Full AppTheme integration — adapts to Cream / Dark / White.
// =============================================================================

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme_notifier.dart';
import '../../../../language_notifier.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

const double _kMakkahLat = 21.4225;
const double _kMakkahLng = 39.8262;

// ─────────────────────────────────────────────────────────────────────────────
// Localized Strings Helper
// ─────────────────────────────────────────────────────────────────────────────

class _QiblaL10n {
  static String aligned(String lang) {
    const m = {'ar': 'أنت متجه للقبلة ✓', 'en': 'You are facing Qibla ✓', 'am': 'ወደ ቂብላ ዞረዋል ✓', 'om': 'Gara Qiblaa garagalteetta ✓'};
    return m[lang] ?? m['en']!;
  }
  static String turnRight(String lang) {
    const m = {'ar': 'أدر لليمين قليلاً →', 'en': 'Turn right slightly →', 'am': 'ወደ ቀኝ ትንሽ አዙር →', 'om': 'Gara mirgaatiif xiqqoo garagali →'};
    return m[lang] ?? m['en']!;
  }
  static String turnLeft(String lang) {
    const m = {'ar': '← أدر لليسار قليلاً', 'en': '← Turn left slightly', 'am': '← ወደ ግራ ትንሽ አዙር', 'om': '← Gara bitaatiif xiqqoo garagali'};
    return m[lang] ?? m['en']!;
  }
  static String calculating(String lang) {
    const m = {'ar': 'جاري الحساب...', 'en': 'Calculating...', 'am': 'በማስላት ላይ...', 'om': 'Herregaa jira...'};
    return m[lang] ?? m['en']!;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// QiblaScreen
// ─────────────────────────────────────────────────────────────────────────────

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  // ── State ──────────────────────────────────────────────────────────────────
  _QiblaStatus _status = _QiblaStatus.loading;
  String _errorKey = '';
  String _rawError = '';

  double _qiblaBearing = 0;     // Bearing from user → Kaaba (true north)
  double _distanceKm = 0;

  StreamSubscription<CompassEvent>? _compassSub;

  // Smooth animation
  late AnimationController _animCtrl;
  double _animatedNeedleAngle = 0;
  double _targetNeedleAngle = 0;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        if (mounted) setState(() {});
      });
    _initialize();
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  // ── Initialization pipeline ────────────────────────────────────────────────

  Future<void> _initialize() async {
    setState(() => _status = _QiblaStatus.loading);

    try {
      // 1. Check location service
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setError('qiblaLocationDisabled');
        return;
      }

      // 2. Check / request permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setError('qiblaPermissionDenied');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _setError('qiblaPermissionPermanentlyDenied');
        return;
      }

      // 3. Try to get LAST KNOWN POSITION for instant loading!
      final lastPosition = await Geolocator.getLastKnownPosition();
      if (lastPosition != null) {
        _updateLocationData(lastPosition.latitude, lastPosition.longitude);
        _startCompassStream();
        if (mounted) setState(() => _status = _QiblaStatus.ready);
      }

      // 4. Fetch CURRENT POSITION in the background to update accuracy
      Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      ).then((position) {
        if (!mounted) return;
        _updateLocationData(position.latitude, position.longitude);
        if (_status == _QiblaStatus.loading) {
          _startCompassStream();
          setState(() => _status = _QiblaStatus.ready);
        }
      }).catchError((e) {
        if (_status == _QiblaStatus.loading) {
          _setError('qiblaFailedInit', e.toString());
        }
      });

    } catch (e) {
      _setError('qiblaFailedInit', e.toString());
    }
  }

  void _updateLocationData(double lat, double lng) {
    _qiblaBearing = _bearingTo(lat, lng, _kMakkahLat, _kMakkahLng);
    _distanceKm = _haversineKm(lat, lng, _kMakkahLat, _kMakkahLng);
  }

  void _startCompassStream() {
    if (_compassSub != null) return;
    _compassSub = FlutterCompass.events?.listen(
      (event) {
        if (!mounted) return;
        final heading = event.heading ?? 0;

        // The needle angle: how much to rotate the qibla indicator
        // relative to device orientation.
        _targetNeedleAngle = (_qiblaBearing - heading);

        // Animate smoothly
        setState(() {
          _animatedNeedleAngle = _lerpAngle(
            _animatedNeedleAngle,
            _targetNeedleAngle,
            0.15,
          );
        });
      },
      onError: (e) {
        debugPrint('Compass error: $e');
      },
    );
  }

  void _setError(String key, [String raw = '']) {
    if (mounted) {
      setState(() {
        _status = _QiblaStatus.error;
        _errorKey = key;
        _rawError = raw;
      });
    }
  }

  // ── Math helpers ───────────────────────────────────────────────────────────

  static double _bearingTo(double lat1, double lon1, double lat2, double lon2) {
    final phi1 = lat1 * math.pi / 180;
    final phi2 = lat2 * math.pi / 180;
    final dLambda = (lon2 - lon1) * math.pi / 180;

    final y = math.sin(dLambda) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(dLambda);

    return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
  }

  static double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dPhi = (lat2 - lat1) * math.pi / 180;
    final dLam = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dPhi / 2) * math.sin(dPhi / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLam / 2) *
            math.sin(dLam / 2);
    return r * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// Lerp between two angles (in degrees) along the shortest arc.
  static double _lerpAngle(double from, double to, double t) {
    var diff = (to - from) % 360;
    if (diff > 180) diff -= 360;
    if (diff < -180) diff += 360;
    return from + diff * t;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final screenBg   = AppTheme.getScreenBgColor(theme);
        final pageBg     = AppTheme.getPageBgColor(theme);
        final appBarBg   = AppTheme.getAppBarBgColor(theme);
        final appBarText = AppTheme.getAppBarTextColor(theme);
        final borderClr  = AppTheme.getBorderColor(theme);
        final goldText   = AppTheme.getGoldTextColor(theme);
        final mainText   = AppTheme.getMainTextColor(theme);
        final isDark     = theme == QuranTheme.dark;
        final l10n       = AppLocalizations.of(context);
        final lang       = AppLanguage.notifier.value.languageCode;

        return Scaffold(
          backgroundColor: screenBg,
          appBar: AppBar(
            backgroundColor: appBarBg,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: appBarText, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              l10n?.qiblaTitle ?? 'Qibla',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: appBarText,
              ),
            ),
          ),
          body: _buildBody(
            theme: theme,
            screenBg: screenBg,
            pageBg: pageBg,
            borderClr: borderClr,
            goldText: goldText,
            mainText: mainText,
            isDark: isDark,
            l10n: l10n,
            lang: lang,
          ),
        );
      },
    );
  }

  Widget _buildBody({
    required QuranTheme theme,
    required Color screenBg,
    required Color pageBg,
    required Color borderClr,
    required Color goldText,
    required Color mainText,
    required bool isDark,
    required AppLocalizations? l10n,
    required String lang,
  }) {
    switch (_status) {
      case _QiblaStatus.loading:
        return _LoadingView(borderClr: borderClr, mainText: mainText, lang: lang);
      case _QiblaStatus.error:
        return _ErrorView(
          errorKey: _errorKey,
          rawError: _rawError,
          l10n: l10n,
          borderClr: borderClr,
          goldText: goldText,
          mainText: mainText,
          isDark: isDark,
          onRetry: _initialize,
        );
      case _QiblaStatus.ready:
        return _CompassView(
          needleAngle: _animatedNeedleAngle,
          qiblaBearing: _qiblaBearing,
          distanceKm: _distanceKm,
          borderClr: borderClr,
          goldText: goldText,
          mainText: mainText,
          pageBg: pageBg,
          isDark: isDark,
          l10n: l10n,
          lang: lang,
        );
    }
  }
}

enum _QiblaStatus { loading, error, ready }

// ═════════════════════════════════════════════════════════════════════════════
//  LOADING VIEW
// ═════════════════════════════════════════════════════════════════════════════

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.borderClr, required this.mainText, required this.lang});
  final Color borderClr;
  final Color mainText;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: borderClr,
              strokeWidth: 2.5,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _QiblaL10n.calculating(lang),
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16,
              color: mainText.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  ERROR VIEW — graceful permission / service error prompt
// ═════════════════════════════════════════════════════════════════════════════

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.errorKey,
    required this.rawError,
    required this.l10n,
    required this.borderClr,
    required this.goldText,
    required this.mainText,
    required this.isDark,
    required this.onRetry,
  });

  final String errorKey;
  final String rawError;
  final AppLocalizations? l10n;
  final Color borderClr;
  final Color goldText;
  final Color mainText;
  final bool isDark;
  final VoidCallback onRetry;

  String _resolveMessage() {
    if (l10n == null) return errorKey;
    switch (errorKey) {
      case 'qiblaLocationDisabled':
        return l10n!.qiblaLocationDisabled;
      case 'qiblaPermissionDenied':
        return l10n!.qiblaPermissionDenied;
      case 'qiblaPermissionPermanentlyDenied':
        return l10n!.qiblaPermissionPermanentlyDenied;
      case 'qiblaFailedInit':
        return l10n!.qiblaFailedInit(rawError);
      default:
        return errorKey;
    }
  }

  bool get _isPermissionError =>
      errorKey == 'qiblaPermissionDenied' ||
      errorKey == 'qiblaPermissionPermanentlyDenied' ||
      errorKey == 'qiblaLocationDisabled';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: borderClr.withValues(alpha: 0.1),
                border: Border.all(
                  color: borderClr.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(
                _isPermissionError
                    ? Icons.location_off_rounded
                    : Icons.error_outline_rounded,
                color: borderClr,
                size: 40,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              _resolveMessage(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 16,
                color: mainText.withValues(alpha: 0.8),
                height: 1.6,
              ),
            ),
            const SizedBox(height: 28),
            if (_isPermissionError)
              _GoldButton(
                label: l10n?.qiblaEnableLocation ?? 'Enable Location',
                icon: Icons.location_on_rounded,
                borderClr: borderClr,
                goldText: goldText,
                isDark: isDark,
                onTap: () async {
                  if (errorKey == 'qiblaLocationDisabled') {
                    await Geolocator.openLocationSettings();
                  } else {
                    await Geolocator.openAppSettings();
                  }
                },
              ),
            if (_isPermissionError) const SizedBox(height: 12),
            _GoldButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              borderClr: borderClr,
              goldText: goldText,
              isDark: isDark,
              onTap: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoldButton extends StatelessWidget {
  const _GoldButton({
    required this.label,
    required this.icon,
    required this.borderClr,
    required this.goldText,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color borderClr;
  final Color goldText;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          color: borderClr.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderClr.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: goldText, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: goldText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  COMPASS VIEW — the main attraction
// ═════════════════════════════════════════════════════════════════════════════

class _CompassView extends StatelessWidget {
  const _CompassView({
    required this.needleAngle,
    required this.qiblaBearing,
    required this.distanceKm,
    required this.borderClr,
    required this.goldText,
    required this.mainText,
    required this.pageBg,
    required this.isDark,
    required this.l10n,
    required this.lang,
  });

  final double needleAngle;
  final double qiblaBearing;
  final double distanceKm;
  final Color borderClr;
  final Color goldText;
  final Color mainText;
  final Color pageBg;
  final bool isDark;
  final AppLocalizations? l10n;
  final String lang;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final compassSize = math.min(size.width, size.height * 0.6);

    // Is the needle roughly aligned to Qibla? (within ±5°)
    final normalizedAngle = (needleAngle % 360 + 360) % 360;
    final isAligned = normalizedAngle < 5 || normalizedAngle > 355;
    
    // Determine the dynamic guidance text based on angle
    String guidanceText = '';
    Color guidanceColor = mainText;
    FontWeight guidanceWeight = FontWeight.w600;

    if (isAligned) {
      guidanceText = _QiblaL10n.aligned(lang);
      guidanceColor = AppColors.emeraldLight;
      guidanceWeight = FontWeight.w700;
    } else if (normalizedAngle > 5 && normalizedAngle <= 180) {
      // Qibla is to the LEFT
      guidanceText = _QiblaL10n.turnLeft(lang);
      guidanceColor = goldText;
    } else {
      // Qibla is to the RIGHT
      guidanceText = _QiblaL10n.turnRight(lang);
      guidanceColor = goldText;
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Subtle background glow when aligned
        if (isAligned)
          Positioned(
            top: size.height * 0.2,
            child: Container(
              width: compassSize * 1.2,
              height: compassSize * 1.2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emeraldLight.withValues(alpha: 0.15),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

        Column(
          children: [
            const Spacer(flex: 3),

            // ── Dynamic Guidance Text ──────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                guidanceText,
                key: ValueKey<String>(guidanceText),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 20,
                  color: guidanceColor,
                  fontWeight: guidanceWeight,
                  shadows: isAligned ? [
                    Shadow(
                      color: AppColors.emeraldLight.withValues(alpha: 0.4),
                      blurRadius: 8,
                    )
                  ] : [],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Compass ────────────────────────────────────────────────────────
            SizedBox(
              width: compassSize,
              height: compassSize,
              child: CustomPaint(
                painter: _QiblaCompassPainter(
                  needleAngleDeg: needleAngle,
                  borderClr: borderClr,
                  goldText: goldText,
                  mainText: mainText,
                  pageBg: pageBg,
                  isDark: isDark,
                  isAligned: isAligned,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ── Distance pill ──────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: borderClr.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: borderClr.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mosque_rounded, color: goldText, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${distanceKm.toStringAsFixed(0)} ${l10n?.qiblaKm ?? 'KM'}',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: goldText,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 4),
          ],
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  CUSTOM PAINTER — premium Qibla compass
// ═════════════════════════════════════════════════════════════════════════════

class _QiblaCompassPainter extends CustomPainter {
  _QiblaCompassPainter({
    required this.needleAngleDeg,
    required this.borderClr,
    required this.goldText,
    required this.mainText,
    required this.pageBg,
    required this.isDark,
    required this.isAligned,
  });

  final double needleAngleDeg;
  final Color borderClr;
  final Color goldText;
  final Color mainText;
  final Color pageBg;
  final bool isDark;
  final bool isAligned;

  static const double _deg2rad = math.pi / 180;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    _drawOuterRing(canvas, center, radius);
    _drawTickMarks(canvas, center, radius);
    _drawQiblaNeedle(canvas, center, radius);
    _drawCenterDot(canvas, center, radius);
  }

  void _drawOuterRing(Canvas canvas, Offset center, double radius) {
    // Elegant glow shadow on the compass body
    final shadowPaint = Paint()
      ..color = isDark ? Colors.black.withValues(alpha: 0.4) : borderClr.withValues(alpha: 0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(center, radius - 4, shadowPaint);

    // Outer decorative ring
    final outerRingPaint = Paint()
      ..color = isAligned ? AppColors.emeraldLight.withValues(alpha: 0.5) : borderClr.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 4, outerRingPaint);

    // Inner circle (compass face)
    final facePaint = Paint()
      ..color = pageBg.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 12, facePaint);

    // Inner border
    final innerBorderPaint = Paint()
      ..color = borderClr.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 12, innerBorderPaint);
    
    // Very subtle inner grid circles
    final gridPaint = Paint()
      ..color = borderClr.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius * 0.5, gridPaint);
    canvas.drawCircle(center, radius * 0.25, gridPaint);
  }

  void _drawTickMarks(Canvas canvas, Offset center, double radius) {
    final tickPaint = Paint()
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 360; i += 6) {
      final isMajor = i % 30 == 0;
      final isCardinal = i % 90 == 0;

      final tickLength = isCardinal ? 18.0 : isMajor ? 12.0 : 5.0;
      final tickWidth = isCardinal ? 2.5 : isMajor ? 1.5 : 0.8;

      tickPaint
        ..color = isCardinal
            ? borderClr.withValues(alpha: 0.8)
            : isMajor
                ? borderClr.withValues(alpha: 0.4)
                : borderClr.withValues(alpha: 0.15)
        ..strokeWidth = tickWidth;

      final angle = i * _deg2rad;
      final outerR = radius - 14;
      final innerR = outerR - tickLength;

      canvas.drawLine(
        Offset(
          center.dx + outerR * math.sin(angle),
          center.dy - outerR * math.cos(angle),
        ),
        Offset(
          center.dx + innerR * math.sin(angle),
          center.dy - innerR * math.cos(angle),
        ),
        tickPaint,
      );
    }
  }

  void _drawQiblaNeedle(Canvas canvas, Offset center, double radius) {
    final angleRad = needleAngleDeg * _deg2rad;
    final needleLength = radius * 0.65;
    final tailLength = radius * 0.2;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angleRad);

    // ── Glow when aligned ───────────────────────────────────────────────
    if (isAligned) {
      final glowPath = Path();
      glowPath.moveTo(0, -needleLength - 10);
      glowPath.lineTo(-12, 0);
      glowPath.lineTo(0, tailLength + 5);
      glowPath.lineTo(12, 0);
      glowPath.close();

      final glowPaint = Paint()
        ..color = AppColors.emeraldLight.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawPath(glowPath, glowPaint);
    }

    // ── Qibla direction needle (golden/emerald, elegant) ────────────────
    final needlePath = Path();
    needlePath.moveTo(0, -needleLength);          // tip
    needlePath.lineTo(-6, -needleLength + 30);    // left shoulder
    needlePath.lineTo(-2.5, 0);                   // left body
    needlePath.lineTo(-4, tailLength);             // left tail
    needlePath.lineTo(0, tailLength - 6);          // tail center
    needlePath.lineTo(4, tailLength);              // right tail
    needlePath.lineTo(2.5, 0);                    // right body
    needlePath.lineTo(6, -needleLength + 30);     // right shoulder
    needlePath.close();

    // Needle fill — gradient
    final needlePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: isAligned
            ? [AppColors.emeraldLight, AppColors.emeraldMid]
            : [goldText, goldText.withValues(alpha: 0.6)],
      ).createShader(Rect.fromCenter(
        center: Offset.zero,
        width: 20,
        height: needleLength + tailLength,
      ))
      ..style = PaintingStyle.fill;
    canvas.drawPath(needlePath, needlePaint);

    // Needle outline
    final outlinePaint = Paint()
      ..color = isAligned
          ? AppColors.emeraldLight.withValues(alpha: 0.8)
          : borderClr.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(needlePath, outlinePaint);

    // ── Kaaba indicator at tip ──────────────────────────────────────────
    final tipY = -needleLength - 8;
    
    // Draw the Kaaba cube
    final kaabaPaint = Paint()
      ..color = isAligned ? AppColors.emeraldLight : goldText;
    
    final kaabaRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, tipY), width: 16, height: 16),
      const Radius.circular(3),
    );
    canvas.drawRRect(kaabaRect, kaabaPaint);

    // Kaaba details (golden door / band)
    final kaabaDetailPaint = Paint()
      ..color = isDark ? Colors.black87 : Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    
    // Golden band around Kaaba
    canvas.drawLine(
      Offset(-8, tipY - 2),
      Offset(8, tipY - 2),
      kaabaDetailPaint,
    );

    // Small crescent on top
    canvas.drawArc(
      Rect.fromCenter(center: Offset(0, tipY - 12), width: 8, height: 8),
      0.3,
      math.pi * 1.4,
      false,
      kaabaDetailPaint,
    );

    canvas.restore();
  }

  void _drawCenterDot(Canvas canvas, Offset center, double radius) {
    // Outer ring
    final ringPaint = Paint()
      ..color = isAligned ? AppColors.emeraldLight.withValues(alpha: 0.4) : borderClr.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, 8, ringPaint);

    // Inner dot
    final dotPaint = Paint()
      ..color = isAligned ? AppColors.emeraldLight : borderClr
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _QiblaCompassPainter old) {
    return old.needleAngleDeg != needleAngleDeg ||
        old.isAligned != isAligned ||
        old.isDark != isDark;
  }
}
