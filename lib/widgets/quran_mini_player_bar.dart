import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/quran_audio_controller.dart';
import '../theme_notifier.dart';
import '../l10n/app_localizations.dart';

/// A premium, compact mini-player bar that sits at the bottom of the
/// Quran screen while audio is active.
class QuranMiniPlayerBar extends StatelessWidget {
  final VoidCallback? onTimerTap;
  const QuranMiniPlayerBar({Key? key, this.onTimerTap}) : super(key: key);

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

        return Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 3, bottom: 13),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 6, top: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: border.withValues(alpha: 0.5), 
                      width: 1.2
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 28,
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
                                      trackHeight: 6.0,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
                                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 24.0),
                                      activeTrackColor: gold,
                                      inactiveTrackColor: border.withValues(alpha: 0.3),
                                      thumbColor: gold,
                                      overlayColor: gold.withValues(alpha: 0.2),
                                      trackShape: const RectangularSliderTrackShape(),
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
                        // ── Compact Single Row Layout ─────────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(left: 4, right: 4, top: 0, bottom: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Reciter selection on left
                              Expanded(
                                child: _ReciterSelectionHeader(ctrl: ctrl, textColor: text, gold: gold, bg: bg, border: border),
                              ),
                              // Media controls in center
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _IconBtn(
                                    icon: Icons.skip_previous_rounded,
                                    color: text,
                                    size: 18,
                                    onTap: ctrl.currentAbsoluteIdx > 1 ? ctrl.previousAyah : null,
                                  ),
                                  const SizedBox(width: 4),
                                  _PlayPauseButton(ctrl: ctrl, gold: gold),
                                  const SizedBox(width: 4),
                                  _IconBtn(
                                    icon: Icons.skip_next_rounded,
                                    color: text,
                                    size: 18,
                                    onTap: ctrl.currentAbsoluteIdx < 6236 ? ctrl.nextAyah : null,
                                  ),
                                  if (onTimerTap != null) ...[
                                    const SizedBox(width: 4),
                                    _IconBtn(
                                      icon: Icons.timer_outlined,
                                      color: text,
                                      size: 18,
                                      onTap: onTimerTap,
                                    ),
                                  ],
                                ],
                              ),
                              // Settings & close on right
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _ControlsPopup(ctrl: ctrl, textColor: text, gold: gold, bg: bg, border: border),
                                  const SizedBox(width: 4),
                                  _IconBtn(
                                    icon: Icons.close_rounded,
                                    color: text.withValues(alpha: 0.6),
                                    size: 16,
                                    onTap: ctrl.stopAndDismiss,
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
        width: 32,
        height: 32,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gold.withValues(alpha: 0.1),
        ),
        child: CircularProgressIndicator(color: gold, strokeWidth: 2.0),
      );
    }
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        ctrl.isPlaying ? ctrl.pause() : ctrl.play();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: gold,
          boxShadow: [
            BoxShadow(color: gold.withValues(alpha: 0.35), blurRadius: 4, offset: const Offset(0, 1.5)),
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
            size: 20,
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
    final isDark = AppTheme.notifier.value == QuranTheme.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (_) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final lowerQuery = searchQuery.trim().toLowerCase();
            final filteredReciters = [...sortedReciters]
              ..retainWhere((r) => r.searchText.contains(lowerQuery));
            final visibleReciters = lowerQuery.isEmpty
                ? sortedReciters
                : filteredReciters;

            return Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.30,
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.55)
                              : Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: border.withValues(alpha: 0.35), width: 1.0),
                        ),
                        child: Column(
                          children: [
                            // ── Handle ─────────────────────────────────────────
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Container(
                                width: 32, height: 3,
                                decoration: BoxDecoration(
                                  color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            // ── Header ─────────────────────────────────────────
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.person_outline_rounded, size: 16, color: gold),
                                  const SizedBox(width: 6),
                                  Text('اختر القارئ',
                                    style: TextStyle(fontFamily: 'Amiri', fontSize: 15,
                                      fontWeight: FontWeight.bold, color: gold)),
                                  const Spacer(),
                                  // Search field inline
                                  SizedBox(
                                    width: 160,
                                    height: 30,
                                    child: TextField(
                                      textAlignVertical: TextAlignVertical.center,
                                      decoration: InputDecoration(
                                        hintText: 'بحث...',
                                        hintStyle: TextStyle(fontFamily: 'Amiri', fontSize: 12,
                                          color: textColor.withValues(alpha: 0.45)),
                                        filled: true,
                                        fillColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                        isDense: true,
                                        prefixIcon: Icon(Icons.search, size: 14, color: textColor.withValues(alpha: 0.4)),
                                      ),
                                      style: TextStyle(color: textColor, fontFamily: 'Amiri', fontSize: 13),
                                      onChanged: (q) => setState(() => searchQuery = q),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Divider(height: 1, color: border.withValues(alpha: 0.2)),
                            // ── List ───────────────────────────────────────────
                            Expanded(
                              child: visibleReciters.isEmpty
                                  ? Center(child: Text('لا يوجد نتائج',
                                      style: TextStyle(fontFamily: 'Amiri', color: textColor.withValues(alpha: 0.5))))
                                  : ListView.separated(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      itemCount: visibleReciters.length,
                                      separatorBuilder: (_, __) => Divider(
                                        height: 1, indent: 16, endIndent: 16,
                                        color: border.withValues(alpha: 0.12),
                                      ),
                                      itemBuilder: (context, i) {
                                        final r = visibleReciters[i];
                                        final isSelected = ctrl.selectedReciter.identifier == r.identifier;
                                        return InkWell(
                                          onTap: () {
                                            ctrl.changeReciter(r);
                                            Navigator.pop(context);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            child: Row(
                                              children: [
                                                if (isSelected)
                                                  Icon(Icons.radio_button_checked, size: 14, color: gold)
                                                else
                                                  Icon(Icons.radio_button_off, size: 14,
                                                    color: textColor.withValues(alpha: 0.3)),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(r.name,
                                                    style: TextStyle(fontFamily: 'Amiri', fontSize: 14,
                                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                      color: isSelected ? gold : textColor)),
                                                ),
                                                Text(r.englishName,
                                                  style: TextStyle(fontFamily: 'Amiri', fontSize: 11,
                                                    color: textColor.withValues(alpha: 0.45))),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, size: 12, color: textColor.withValues(alpha: 0.7)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                ctrl.selectedReciter.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'Amiri', fontSize: 12, color: textColor.withValues(alpha: 0.85)),
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.arrow_drop_down, size: 14, color: gold),
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
    return InkWell(
      onTap: () => _showControlsSheet(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: textColor.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.settings_rounded,
          size: 18,
          color: textColor.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  void _showControlsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
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
    final l10n = AppLocalizations.of(context)!;
    final isDark = AppTheme.notifier.value == QuranTheme.dark;
    return ListenableBuilder(
      listenable: ctrl,
      builder: (context, _) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.55)
                          : Colors.white.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: border.withValues(alpha: 0.35), width: 1.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Handle ───────────────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 4),
                          child: Container(
                            width: 32, height: 3,
                            decoration: BoxDecoration(
                              color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        // ── Title ────────────────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Row(
                            children: [
                              Icon(Icons.tune_rounded, size: 15, color: gold),
                              const SizedBox(width: 6),
                              Text(l10n.playbackSettings,
                                style: TextStyle(fontFamily: 'Amiri', fontSize: 15,
                                  fontWeight: FontWeight.bold, color: gold)),
                            ],
                          ),
                        ),
                        Divider(height: 1, color: border.withValues(alpha: 0.2)),
                        // ── Controls ─────────────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                          child: Column(
                            children: [
                              _buildPillRow(
                                context: context,
                                isDark: isDark,
                                icon: Icons.repeat_rounded,
                                label: l10n.repetition,
                                options: ctrl.repetitionOptions,
                                selectedIndex: ctrl.repetitionIndex,
                                formatValue: (v) => v == -1 ? '∞' : '${v}x',
                                onSelect: (v) => ctrl.setRepetition(v),
                              ),
                              const SizedBox(height: 10),
                              _buildPillRow(
                                context: context,
                                isDark: isDark,
                                icon: Icons.timer_outlined,
                                label: l10n.intervalGap,
                                options: ctrl.delayOptions,
                                selectedIndex: ctrl.delayIndex,
                                formatValue: (v) {
                                  if (v == 0) return l10n.noneOffLabel;
                                  if (v == -1) return l10n.ayahLabel;
                                  return '$v${l10n.secLabel}';
                                },
                                onSelect: (v) => ctrl.setDelay(v),
                              ),
                              const SizedBox(height: 10),
                              _buildSpeedPillRow(context, isDark, l10n),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPillRow({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    required List<int> options,
    required int selectedIndex,
    required String Function(int) formatValue,
    required void Function(int) onSelect,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: gold),
        const SizedBox(width: 6),
        SizedBox(
          width: 52,
          child: Text(label,
            style: TextStyle(fontFamily: 'Amiri', fontSize: 13, color: textColor.withValues(alpha: 0.8))),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(options.length, (i) {
                final isSelected = i == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => onSelect(options[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? gold : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? gold : border.withValues(alpha: 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        formatValue(options[i]),
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 12,
                          color: isSelected ? Colors.white : textColor.withValues(alpha: 0.75),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedPillRow(BuildContext context, bool isDark, AppLocalizations l10n) {
    return Row(
      children: [
        Icon(Icons.speed_rounded, size: 14, color: gold),
        const SizedBox(width: 6),
        SizedBox(
          width: 52,
          child: Text(l10n.playbackSpeed,
            style: TextStyle(fontFamily: 'Amiri', fontSize: 13, color: textColor.withValues(alpha: 0.8))),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(ctrl.speedOptions.length, (i) {
                final isSelected = i == ctrl.speedIndex;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => ctrl.setSpeed(ctrl.speedOptions[i]),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? gold : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? gold : border.withValues(alpha: 0.25),
                          width: 1.0,
                        ),
                      ),
                      child: Text(
                        '${ctrl.speedOptions[i].toStringAsFixed(2)}x',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 12,
                          color: isSelected ? Colors.white : textColor.withValues(alpha: 0.75),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}
