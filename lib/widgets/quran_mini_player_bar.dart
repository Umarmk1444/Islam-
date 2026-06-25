import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/quran_audio_controller.dart';
import '../theme_notifier.dart';

/// A premium, compact mini-player bar that sits at the bottom of the
/// Quran screen while audio is active.
class QuranMiniPlayerBar extends StatelessWidget {
  const QuranMiniPlayerBar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: QuranAudioController.instance,
      builder: (context, _) {
        final ctrl   = QuranAudioController.instance;
        final theme  = AppTheme.notifier.value;
        final bg     = AppTheme.getPageBgColor(theme);
        final border = AppTheme.getBorderColor(theme);
        final gold   = AppTheme.getGoldTextColor(theme);
        final text   = AppTheme.getMainTextColor(theme);
        final isDark = theme == QuranTheme.dark;

        if (!ctrl.isActive) return const SizedBox.shrink();

        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: border.withOpacity(0.5), 
                  width: 1.2
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
          child: SafeArea(
            top: false,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Main column ─────────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Layer: [Surah Name] | [Reciter Name]
                      _ReciterSelectionHeader(ctrl: ctrl, textColor: text, gold: gold, bg: bg, border: border),
                      const SizedBox(height: 8),
                      // Controller Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _IconBtn(
                            icon: Icons.skip_previous_rounded,
                            color: text,
                            size: 26,
                            onTap: ctrl.currentAbsoluteIdx > 1 ? ctrl.previousAyah : null,
                          ),
                          const SizedBox(width: 16),
                          _PlayPauseButton(ctrl: ctrl, gold: gold),
                          const SizedBox(width: 16),
                          _IconBtn(
                            icon: Icons.skip_next_rounded,
                            color: text,
                            size: 26,
                            onTap: ctrl.currentAbsoluteIdx < 6236 ? ctrl.nextAyah : null,
                          ),
                          const SizedBox(width: 24),
                          _ControlsPopup(ctrl: ctrl, textColor: text, gold: gold, bg: bg, border: border),
                          const SizedBox(width: 8),
                          _IconBtn(
                            icon: Icons.close_rounded,
                            color: text.withOpacity(0.6),
                            size: 22,
                            onTap: ctrl.stopAndDismiss,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // ── Progress Bar across the top edge ──────────────────────────
                Positioned(
                  top: -10, // pull up exactly half the track height or thumb radius
                  left: 0,
                  right: 0,
                  child: StreamBuilder<Duration?>(
                    key: ValueKey(ctrl.streamKey),
                    stream: ctrl.durationStream,
                    builder: (context, durationSnapshot) {
                      final duration = durationSnapshot.data ?? Duration.zero;
                      return StreamBuilder<Duration>(
                        stream: ctrl.positionStream,
                        builder: (context, positionSnapshot) {
                          var position = positionSnapshot.data ?? Duration.zero;
                          if (position > duration) position = duration;
                          return SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2.0,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                              activeTrackColor: gold,
                              inactiveTrackColor: border.withValues(alpha: 0.3),
                              thumbColor: gold,
                              overlayColor: gold.withValues(alpha: 0.2),
                              trackShape: const RectangularSliderTrackShape(), // full width
                            ),
                            child: Slider(
                              min: 0.0,
                              max: duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0,
                              value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble() > 0 ? duration.inMilliseconds.toDouble() : 1.0),
                              onChanged: (value) {
                                ctrl.seek(Duration(milliseconds: value.round()));
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onTap != null) {
          HapticFeedback.lightImpact();
          onTap!();
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.transparent : color.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: size, color: onTap == null ? color.withValues(alpha: 0.3) : color),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.ctrl, required this.gold});
  final QuranAudioController ctrl;
  final Color gold;

  @override
  Widget build(BuildContext context) {
    if (ctrl.isLoading) {
      return Container(
        width: 44,
        height: 44,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gold.withValues(alpha: 0.1),
        ),
        child: CircularProgressIndicator(color: gold, strokeWidth: 2.5),
      );
    }
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ctrl.isPlaying ? ctrl.pause() : ctrl.play();
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gold,
          boxShadow: [
            BoxShadow(color: gold.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Icon(
            ctrl.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
            key: ValueKey<bool>(ctrl.isPlaying),
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _ReciterSelectionHeader extends StatelessWidget {
  const _ReciterSelectionHeader({
    required this.ctrl,
    required this.textColor,
    required this.gold,
    required this.bg,
    required this.border,
  });
  final QuranAudioController ctrl;
  final Color textColor;
  final Color gold;
  final Color bg;
  final Color border;

  void _showRecitersSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          padding: const EdgeInsets.only(top: 16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: border.withValues(alpha: 0.4)),
          ),
          child: Column(
            children: [
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: border.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text('اختر القارئ', style: TextStyle(fontFamily: 'Amiri', fontSize: 18, fontWeight: FontWeight.bold, color: gold)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: kAllReciters.length,
                  itemBuilder: (context, index) {
                    final reciter = kAllReciters[index];
                    final isSelected = ctrl.selectedReciter.identifier == reciter.identifier;
                    return ListTile(
                      title: Text(reciter.name, style: TextStyle(fontFamily: 'Amiri', fontSize: 16, color: isSelected ? gold : textColor)),
                      trailing: isSelected ? Icon(Icons.check_circle, color: gold) : null,
                      onTap: () {
                        ctrl.changeReciter(reciter);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showRecitersSheet(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'سورة ${ctrl.currentSurahName} · آية ${ctrl.currentAyah}',
              style: TextStyle(fontFamily: 'Amiri', fontSize: 13, fontWeight: FontWeight.bold, color: gold),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(width: 8),
            Container(width: 1.5, height: 14, color: border.withValues(alpha: 0.5)),
            const SizedBox(width: 8),
            Icon(Icons.person, size: 14, color: textColor.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Text(
              ctrl.selectedReciter.name,
              style: TextStyle(fontFamily: 'Amiri', fontSize: 13, color: textColor.withValues(alpha: 0.85)),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: gold),
          ],
        ),
      ),
    );
  }
}

class _ControlsPopup extends StatelessWidget {
  const _ControlsPopup({
    required this.ctrl,
    required this.textColor,
    required this.gold,
    required this.bg,
    required this.border,
  });
  final QuranAudioController ctrl;
  final Color textColor;
  final Color gold;
  final Color bg;
  final Color border;

  @override
  Widget build(BuildContext context) {
    final repVal   = ctrl.repetitionOptions[ctrl.repetitionIndex];
    final delayVal = ctrl.delayOptions[ctrl.delayIndex];
    final repLabel   = repVal  == -1 ? '∞' : '$repVal×';
    final delayLabel = delayVal == 0  ? '—' : delayVal == -1 ? 'آية' : '${delayVal}s';

    return GestureDetector(
      onTap: () => _showControlsSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🔁 $repLabel', style: TextStyle(fontSize: 10, color: gold)),
            Text('⏱ $delayLabel', style: TextStyle(fontSize: 10, color: textColor.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }

  void _showControlsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _AudioControlsSheet(ctrl: ctrl, bg: bg, gold: gold, textColor: textColor, border: border),
    );
  }
}

class _AudioControlsSheet extends StatelessWidget {
  const _AudioControlsSheet({
    required this.ctrl,
    required this.bg,
    required this.gold,
    required this.textColor,
    required this.border,
  });
  final QuranAudioController ctrl;
  final Color bg;
  final Color gold;
  final Color textColor;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(color: border.withValues(alpha: 0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: border.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text('إعدادات الاستماع', style: TextStyle(fontFamily: 'Amiri', fontSize: 18, fontWeight: FontWeight.bold, color: gold)),
              const SizedBox(height: 20),
              _buildDropdown(
                context,
                icon: Icons.repeat_rounded,
                label: 'التكرار',
                value: ctrl.repetitionOptions[ctrl.repetitionIndex],
                options: ctrl.repetitionOptions,
                formatValue: (v) => v == -1 ? 'لا نهائي' : '${v}x',
                onChanged: (v) { if (v != null) ctrl.setRepetition(v); },
              ),
              const SizedBox(height: 16),
              _buildDropdown(
                context,
                icon: Icons.timer_outlined,
                label: 'الفاصل الزمني',
                value: ctrl.delayOptions[ctrl.delayIndex],
                options: ctrl.delayOptions,
                formatValue: (v) {
                  if (v == 0) return 'بدون';
                  if (v == -1) return 'طول الآية';
                  return '$v ث';
                },
                onChanged: (v) { if (v != null) ctrl.setDelay(v); },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDropdown(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int value,
    required List<int> options,
    required String Function(int) formatValue,
    required void Function(int?) onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: gold),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontFamily: 'Amiri', fontSize: 16, color: textColor)),
          ],
        ),
        DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: value,
            dropdownColor: bg,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontFamily: 'Amiri', fontSize: 15),
            icon: Icon(Icons.arrow_drop_down, color: gold),
            onChanged: onChanged,
            items: options.map((v) => DropdownMenuItem<int>(
              value: v,
              child: Text(formatValue(v)),
            )).toList(),
          ),
        ),
      ],
    );
  }
}
