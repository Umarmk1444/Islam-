import 'package:flutter/material.dart';
import '../controllers/quran_audio_controller.dart';
import '../theme_notifier.dart';

/// A compact, persistent mini-player bar that sits at the bottom of the
/// Quran screen while audio is active. Height ~68px — non-intrusive.
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

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0D1F17) : bg,
            border: Border(
              top: BorderSide(color: border.withValues(alpha: 0.6), width: 1.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Main row ─────────────────────────────────────────────────
                SizedBox(
                  height: 52,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: [
                        // Previous
                        _IconBtn(
                          icon: Icons.skip_previous_rounded,
                          color: text,
                          size: 22,
                          onTap: ctrl.currentAbsoluteIdx > 1
                              ? ctrl.previousAyah
                              : null,
                        ),

                        // Play / Pause / Loading
                        _PlayPauseButton(ctrl: ctrl, gold: gold),

                        // Next
                        _IconBtn(
                          icon: Icons.skip_next_rounded,
                          color: text,
                          size: 22,
                          onTap: ctrl.currentAbsoluteIdx < 6236
                              ? ctrl.nextAyah
                              : null,
                        ),

                        const SizedBox(width: 6),

                        // Verse info (expands to fill remaining space)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'سورة ${ctrl.currentSurahName} · آية ${ctrl.currentAyah}',
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: gold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textDirection: TextDirection.rtl,
                              ),
                              const SizedBox(height: 2),
                              // Reciter dropdown — compact
                              _ReciterDropdown(ctrl: ctrl, textColor: text, gold: gold, bg: bg),
                            ],
                          ),
                        ),

                        // Controls row: Repetition + Delay
                        _ControlsPopup(ctrl: ctrl, textColor: text, gold: gold, bg: bg, border: border),

                        // Dismiss
                        _IconBtn(
                          icon: Icons.close_rounded,
                          color: text.withValues(alpha: 0.6),
                          size: 20,
                          onTap: ctrl.stopAndDismiss,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets (kept in same file for locality)
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
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
      return Padding(
        padding: const EdgeInsets.all(6),
        child: SizedBox(
          width: 24, height: 24,
          child: CircularProgressIndicator(color: gold, strokeWidth: 2.5),
        ),
      );
    }
    return InkWell(
      onTap: ctrl.isPlaying ? ctrl.pause : ctrl.play,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gold,
          boxShadow: [
            BoxShadow(color: gold.withValues(alpha: 0.35), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(
          ctrl.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _ReciterDropdown extends StatelessWidget {
  const _ReciterDropdown({
    required this.ctrl,
    required this.textColor,
    required this.gold,
    required this.bg,
  });
  final QuranAudioController ctrl;
  final Color textColor;
  final Color gold;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<QuranReciter>(
        value: ctrl.selectedReciter,
        isDense: true,
        icon: Icon(Icons.arrow_drop_down, size: 14, color: gold),
        dropdownColor: bg,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 11,
          color: textColor.withValues(alpha: 0.75),
        ),
        onChanged: (val) {
          if (val != null) ctrl.changeReciter(val);
        },
        items: kAllReciters.map((r) {
          return DropdownMenuItem<QuranReciter>(
            value: r,
            child: Text(r.name, style: TextStyle(fontSize: 11, color: textColor)),
          );
        }).toList(),
      ),
    );
  }
}

/// Small popup button showing repetition + delay pickers.
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        margin: const EdgeInsets.only(right: 4),
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
              // Drag handle
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(color: border.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Text('إعدادات الاستماع', style: TextStyle(fontFamily: 'Amiri', fontSize: 18, fontWeight: FontWeight.bold, color: gold)),
              const SizedBox(height: 20),

              // Repetition
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

              // Delay
              _buildDropdown(
                context,
                icon: Icons.timer_outlined,
                label: 'الفاصل الزمني',
                value: ctrl.delayOptions[ctrl.delayIndex],
                options: ctrl.delayOptions,
                formatValue: (v) {
                  if (v == 0) return 'بدون';
                  if (v == -1) return 'طول الآية';
                  final s = v.toString();
                  return '$s ث';
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
