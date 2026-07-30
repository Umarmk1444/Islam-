import 'dart:async';
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
      begin: const Offset(0.2, 0), // Slide in from the right
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));

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
      // Added a 2 second timeout because database initialization in background isolates often hangs infinitely.
      var zekr = await service
          .getRandomShortZekr()
          .timeout(const Duration(seconds: 2));

      // Fallback if the database query returns empty
      if (zekr == null || zekr.isEmpty) {
        zekr = "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ";
      }

      if (mounted) {
        setState(() {
          _zekr = zekr;
          _isLoading = false;
        });
        _animController.forward();
        _autoDismissTimer = Timer(const Duration(seconds: 15), _close);
      }
    } catch (e) {
      debugPrint('Error fetching Zekr for overlay: $e');
      // If the database fails (common in background isolates), use a fallback Zekr
      if (mounted) {
        setState(() {
          _zekr = "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ";
          _isLoading = false;
        });
        _animController.forward();
        _autoDismissTimer = Timer(const Duration(seconds: 15), _close);
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
    if (_isLoading) return const SizedBox(width: 420, height: 150);

    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= 0) {
      screenWidth =
          390; // Default phone screen width to prevent negative bounds
    }

    // Gap of 30px from upper, 16px from right edge
    final double cardWidth = screenWidth < 432 ? screenWidth - 32 : 400;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned(
            top: 30, // 30px gap from upper edge
            right: 16, // 16px gap from right edge
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Dismissible(
                  key: const Key('system_overlay_zekr'),
                  direction: DismissDirection.horizontal,
                  onDismissed: (_) => FlutterOverlayWindow.closeOverlay(),
                  child: _OverlayCard(
                    zekr: _zekr!,
                    cardWidth: cardWidth,
                    onClose: _close,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayCard extends StatelessWidget {
  final String zekr;
  final double cardWidth;
  final VoidCallback onClose;

  const _OverlayCard({
    required this.zekr,
    required this.cardWidth,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      height: 50,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF042B2B).withValues(alpha: 0.95), // Deep emerald
                const Color(0xFF021717)
                    .withValues(alpha: 0.95), // Darker emerald
              ],
            ),
            border: Border.all(
              color:
                  const Color(0xFFD4AF37).withValues(alpha: 0.5), // Gold border
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // ── Decorative glowing orb – top right ──────────────────────
              Positioned(
                top: -25,
                right: -25,
                child: Container(
                  width: 80,
                  height: 80,
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
                bottom: -20,
                left: -20,
                child: Container(
                  width: 60,
                  height: 60,
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

              // ── Main content ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // ✨ Icon
                      const Text('✨', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),

                      // Arabic Zekr text (takes remaining space)
                      Expanded(
                        child: Text(
                          zekr,
                          style: const TextStyle(
                            color: Color(0xFFF0F4F0),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Amiri',
                          ),
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Close button
                      GestureDetector(
                        onTap: onClose,
                        child: Container(
                          width: 28,
                          height: 28,
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
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
