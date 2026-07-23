import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/azkar_service.dart';
import '../theme_notifier.dart';
import '../core/constants/app_colors.dart';
// Reusing some theme constants if needed, but AppColors is better.

class ZekrOverlayManager {
  static final ZekrOverlayManager _instance = ZekrOverlayManager._internal();
  factory ZekrOverlayManager() => _instance;
  ZekrOverlayManager._internal();

  OverlayEntry? _overlayEntry;
  final AzkarService _azkarService = AzkarService();
  Timer? _autoDismissTimer;
  Timer? _periodicTimer;

  void startTimer(BuildContext context, int intervalMinutes) {
    stopTimer(); // Ensure no duplicates
    _periodicTimer = Timer.periodic(Duration(minutes: intervalMinutes), (_) {
      showOverlay(context);
    });
  }

  void stopTimer() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  void showOverlay(BuildContext context) async {
    // Prevent overlapping
    if (_overlayEntry != null) {
      _removeOverlay();
    }

    final zekr = await _azkarService.getRandomShortZekr();
    if (zekr == null || zekr.isEmpty) return;

    if (!context.mounted) return;
    final overlayState = Overlay.of(context);

    _overlayEntry = OverlayEntry(
      builder: (context) {
        final isDark = AppTheme.notifier.value == QuranTheme.dark;

        return Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: Dismissible(
              key: UniqueKey(),
              direction: DismissDirection.horizontal,
              onDismissed: (_) => _removeOverlay(),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.75,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceCard
                      : AppColors.surfaceCardLight,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(-2, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isDark ? AppColors.divider : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        zekr,
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.emeraldDeep,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _removeOverlay,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.grey.shade800
                              : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 14,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().slideX(
                  begin: 1.0,
                  end: 0,
                  duration: 600.ms,
                  curve: Curves.easeOutQuart),
            ),
          ),
        );
      },
    );

    overlayState.insert(_overlayEntry!);

    // Auto dismiss after 8 seconds
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(const Duration(seconds: 8), () {
      _removeOverlay();
    });
  }

  void _removeOverlay() {
    _autoDismissTimer?.cancel();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
