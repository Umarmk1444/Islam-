import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import '../services/azkar_service.dart';

class SystemZekrOverlay extends StatefulWidget {
  const SystemZekrOverlay({Key? key}) : super(key: key);

  @override
  State<SystemZekrOverlay> createState() => _SystemZekrOverlayState();
}

class _SystemZekrOverlayState extends State<SystemZekrOverlay> {
  String? _zekr;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchZekr();
  }

  Future<void> _fetchZekr() async {
    final service = AzkarService();
    final zekr = await service.getRandomShortZekr();
    if (mounted) {
      setState(() {
        _zekr = zekr;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink(); // Hide while loading
    }
    if (_zekr == null || _zekr!.isEmpty) {
      FlutterOverlayWindow.closeOverlay();
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.transparent,
      elevation: 0,
      child: GestureDetector(
        onTap: () {
          // Could open app or do nothing
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          alignment: Alignment.topRight,
          child: Dismissible(
            key: const Key('overlay_zekr'),
            direction: DismissDirection.endToStart, // Swipe left to dismiss
            onDismissed: (_) {
              FlutterOverlayWindow.closeOverlay();
            },
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4), // Soft pastel green
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(-2, 4),
                  ),
                ],
                border: Border.all(
                  color: const Color(0xFFC8E6C9),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      _zekr!,
                      style: const TextStyle(
                        color: Color(0xFF1B5E20), // Dark green text
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
                    onTap: () => FlutterOverlayWindow.closeOverlay(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 14,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
