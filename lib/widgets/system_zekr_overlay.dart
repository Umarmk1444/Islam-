import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../services/azkar_service.dart';

class SystemZekrOverlay extends StatefulWidget {
  const SystemZekrOverlay({Key? key}) : super(key: key);

  @override
  State<SystemZekrOverlay> createState() => _SystemZekrOverlayState();
}

class _SystemZekrOverlayState extends State<SystemZekrOverlay>
    with SingleTickerProviderStateMixin {
  String? _zekr;
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

    _fetchZekr();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchZekr() async {
    final service = AzkarService();
    final zekr = await service.getRandomShortZekr();
    if (mounted) {
      setState(() {
        _zekr = zekr;
        _isLoading = false;
      });
      if (zekr != null && zekr.isNotEmpty) {
        _animController.forward();
      }
    }
  }

  void _close() {
    _animController.reverse().then((_) {
      FlutterOverlayWindow.closeOverlay();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();
    if (_zekr == null || _zekr!.isEmpty) {
      FlutterOverlayWindow.closeOverlay();
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: _close,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          // Semi-transparent dimmed backdrop
          color: Colors.black.withValues(alpha: 0.45),
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () {}, // Prevent tap-through on the card
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Dismissible(
                  key: const Key('system_overlay_zekr'),
                  direction: DismissDirection.vertical,
                  onDismissed: (_) => FlutterOverlayWindow.closeOverlay(),
                  child: _OverlayCard(zekr: _zekr!, onClose: _close),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OverlayCard extends StatelessWidget {
  final String zekr;
  final VoidCallback onClose;

  const _OverlayCard({required this.zekr, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.88,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
              // Deep emerald glassmorphism gradient
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xEE0D4F3C), // deep emerald, mostly opaque
                  Color(0xDD0A3A2C),
                  Color(0xEE071E16),
                ],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0x55D4A017), // gold tint border
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 40,
                  spreadRadius: 4,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: const Color(0xFF1A7A5E).withValues(alpha: 0.3),
                  blurRadius: 30,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Stack(
              children: [
                // ── Decorative radial glow top-right ──
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFD4A017).withValues(alpha: 0.25),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // ── Main content ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFB8860B),
                                  Color(0xFFFFD966),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('✨',
                                    style: TextStyle(fontSize: 13)),
                                SizedBox(width: 5),
                                Text(
                                  'ذكر الله',
                                  style: TextStyle(
                                    color: Color(0xFF1A1200),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          // Close button
                          GestureDetector(
                            onTap: onClose,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Color(0xCCFFFFFF),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 22),

                      // ── Arabic Zekr text ──
                      Text(
                        zekr,
                        style: const TextStyle(
                          color: Color(0xFFF0F4F0),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.65,
                          fontFamily: 'Amiri',
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                      ),

                      const SizedBox(height: 24),

                      // ── Divider ──
                      Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              const Color(0xFFD4A017).withValues(alpha: 0.5),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Swipe hint ──
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.swipe_down_rounded,
                            size: 14,
                            color: Color(0x669BAAAA),
                          ),
                          SizedBox(width: 6),
                          Text(
                            'اسحب للإغلاق',
                            style: TextStyle(
                              color: Color(0x779BAAAA),
                              fontSize: 11,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ],
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
