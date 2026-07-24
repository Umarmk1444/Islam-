import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/azkar_service.dart';
import '../theme_notifier.dart';

class ZekrOverlayManager {
  static final ZekrOverlayManager _instance = ZekrOverlayManager._internal();
  factory ZekrOverlayManager() => _instance;
  ZekrOverlayManager._internal();

  OverlayEntry? _overlayEntry;
  final AzkarService _azkarService = AzkarService();
  Timer? _autoDismissTimer;
  Timer? _periodicTimer;

  void startTimer(BuildContext context, int intervalMinutes) {
    stopTimer();
    _periodicTimer = Timer.periodic(Duration(minutes: intervalMinutes), (_) {
      showOverlay(context);
    });
  }

  void stopTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  void showOverlay(BuildContext context) async {
    if (_overlayEntry != null) {
      _removeOverlay();
    }

    final zekr = await _azkarService.getRandomShortZekr();
    if (zekr == null || zekr.isEmpty) return;

    if (!context.mounted) return;
    final overlayState = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (ctx) {
        final isDark = AppTheme.notifier.value == QuranTheme.dark;
        final screenWidth = MediaQuery.of(ctx).size.width;
        final topPad = MediaQuery.of(ctx).padding.top;

        return Positioned.fill(
          child: GestureDetector(
            onTap: _removeOverlay,
            behavior: HitTestBehavior.opaque,
            child: Container(
              color: Colors.transparent,
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: () {}, // consume taps on card
                child: Padding(
                  padding: EdgeInsets.only(
                    top: topPad + 12,
                    left: 16,
                    right: 16,
                  ),
                  child: MediaQuery(
                    data: MediaQuery.of(ctx).copyWith(textScaler: TextScaler.noScaling),
                    child: _InAppZekrCard(
                      zekr: zekr,
                      isDark: isDark,
                      screenWidth: screenWidth,
                      onDismiss: _removeOverlay,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 450.ms, curve: Curves.easeOut)
                      .slideY(
                        begin: 0.08,
                        end: 0,
                        duration: 500.ms,
                        curve: Curves.easeOutCubic,
                      )
                      .scale(
                        begin: const Offset(0.96, 0.96),
                        end: const Offset(1, 1),
                        duration: 500.ms,
                        curve: Curves.easeOutCubic,
                      ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(_overlayEntry!);

    // Auto-dismiss after 15 seconds
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(seconds: 15), _removeOverlay);
  }

  void _removeOverlay() {
    _autoDismissTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Standalone card widget — clean, reusable
// ─────────────────────────────────────────────────────────────────────────────
class _InAppZekrCard extends StatelessWidget {
  final String zekr;
  final bool isDark;
  final double screenWidth;
  final VoidCallback onDismiss;

  const _InAppZekrCard({
    required this.zekr,
    required this.isDark,
    required this.screenWidth,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => onDismiss(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: double.infinity,
            height: 190,
            decoration: BoxDecoration(
              gradient: isDark
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.0, 0.55, 1.0],
                      colors: [
                        Color(0xF20D4F3C), // deep emerald
                        Color(0xF2091E16), // darker core
                        Color(0xF20A1A14), // near black emerald
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      stops: [0.0, 0.6, 1.0],
                      colors: [
                        Color(0xFF0D4F3C),
                        Color(0xFF0A3A2C),
                        Color(0xFF071E16),
                      ],
                    ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0x44D4A017),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 50,
                  spreadRadius: 6,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: const Color(0xFF1A7A5E).withValues(alpha: 0.35),
                  blurRadius: 40,
                  spreadRadius: -8,
                ),
                BoxShadow(
                  color: const Color(0xFFD4A017).withValues(alpha: 0.12),
                  blurRadius: 60,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                // ── Decorative glowing orb – top right ──────────────────────
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFD4A017).withValues(alpha: 0.22),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Decorative glowing orb – bottom left ────────────────────
                Positioned(
                  bottom: -40,
                  left: -40,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF2ECC9A).withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Content ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Force Header Row to LTR to keep Close Button on Upper Right
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Row(
                            children: [
                              // Gold badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFB8860B),
                                      Color(0xFFFFD966),
                                      Color(0xFFD4A017),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('✨', style: TextStyle(fontSize: 11)),
                                    SizedBox(width: 4),
                                    Text(
                                      'تذكير بذكر الله',
                                      style: TextStyle(
                                        color: Color(0xFF1A1200),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              // Close button (enlarged and forced right)
                              GestureDetector(
                                onTap: onDismiss,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ── Arabic Zekr ─────────────────────────────────────────
                        Text(
                          zekr,
                          style: const TextStyle(
                            color: Color(0xFFF0F4F0),
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                            fontFamily: 'Amiri',
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 12),

                        // ── Gold shimmer divider ────────────────────────────────
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                const Color(0xFFD4A017).withValues(alpha: 0.6),
                                const Color(0xFFFFD966).withValues(alpha: 0.4),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ── Swipe-to-dismiss hint (Horizontal) ───────────────────────────────
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.swipe_rounded,
                              size: 14,
                              color: Color(0x889BAAAA),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'اسحب أفقياً للإغلاق',
                              style: TextStyle(
                                color: Color(0xAA9BAAAA),
                                fontSize: 11,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
