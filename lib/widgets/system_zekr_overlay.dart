import 'dart:async';
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
  Timer? _autoDismissTimer;

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
    _autoDismissTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _fetchZekr() async {
    try {
      final service = AzkarService();
      final zekr = await service.getRandomShortZekr();
      if (mounted) {
        setState(() {
          _zekr = zekr;
          _isLoading = false;
        });
        if (zekr != null && zekr.isNotEmpty) {
          _animController.forward();
          _autoDismissTimer = Timer(const Duration(seconds: 15), _close);
        } else {
          FlutterOverlayWindow.closeOverlay();
        }
      }
    } catch (e) {
      debugPrint('Error fetching Zekr for overlay: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        FlutterOverlayWindow.closeOverlay();
      }
    }
  }

  void _close() {
    _autoDismissTimer?.cancel();
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
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () {}, // Prevent tap-through on the card
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Dismissible(
                key: const Key('system_overlay_zekr'),
                direction: DismissDirection.horizontal,
                onDismissed: (_) => FlutterOverlayWindow.closeOverlay(),
                child: _OverlayCard(zekr: _zekr!, onClose: _close),
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
    return Container(
      width: double.infinity,
      height: 240,
      margin: const EdgeInsets.fromLTRB(12, 35, 12, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              // Deep emerald glassmorphism gradient
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFA0D4F3C), // deep emerald
                  Color(0xFA0A3A2C),
                  Color(0xFA071E16),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0x55D4A017), // gold tint border
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // ── Main content ──
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFB8860B),
                                      Color(0xFFFFD966),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('✨',
                                        style: TextStyle(fontSize: 11)),
                                    SizedBox(width: 4),
                                    Text(
                                      'ذكر الله',
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
                                onTap: onClose,
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2),
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

                        const SizedBox(height: 10),

                        // ── Arabic Zekr text ──
                        Text(
                          zekr,
                          style: const TextStyle(
                            color: Color(0xFFF0F4F0),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.4,
                            fontFamily: 'Amiri',
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 10),

                        // ── Swipe hint (Horizontal) ──
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.swipe_rounded,
                              size: 14,
                              color: Color(0x889BAAAA),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'اسحب أفقياً للإغلاق',
                              style: TextStyle(
                                color: Color(0xAA9BAAAA),
                                fontSize: 11,
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
