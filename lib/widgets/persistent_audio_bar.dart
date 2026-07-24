import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../models/minbar_models.dart';
import '../services/minbar_player.dart';
import '../theme_notifier.dart';

class PersistentAudioBar extends StatelessWidget {
  const PersistentAudioBar({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final isDark = theme == QuranTheme.dark;
        final bg = AppTheme.getCardBgColor(theme);
        final textColor = AppTheme.getMainTextColor(theme);
        final primaryColor = AppTheme.getPrimaryColor(theme);
        final subtitleColor = textColor.withValues(alpha: 0.7);
        final borderColor = theme == QuranTheme.cream
            ? const Color(0xFFC9A84C).withValues(alpha: 0.3)
            : (isDark ? AppColors.divider : Colors.grey.shade200);

        return ValueListenableBuilder<MinbarAudioItem?>(
          valueListenable: MinbarPlayer.currentItemNotifier,
          builder: (context, currentItem, _) {
            if (currentItem == null) {
              return const SizedBox.shrink();
            }

            return Container(
              decoration: BoxDecoration(
                color: bg,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.08),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: Border(top: BorderSide(color: borderColor, width: 1.0)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Row 1: Art, Title, Close
                      Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          // Graphic EQ animation art
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.graphic_eq_rounded,
                                color: primaryColor, size: 22),
                          ),
                          const SizedBox(width: 12),

                          // Track details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              textDirection: TextDirection.rtl,
                              children: [
                                Text(
                                  currentItem.title,
                                  style: AppTextStyles.arabicSmall.copyWith(
                                    fontSize: 14,
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                ValueListenableBuilder<String?>(
                                  valueListenable:
                                      MinbarPlayer.currentAuthorNotifier,
                                  builder: (context, authorName, _) {
                                    return Text(
                                      authorName ?? '',
                                      style:
                                          AppTextStyles.audioSubtitle.copyWith(
                                        color: subtitleColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),

                          // Close Button
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            color: textColor.withValues(alpha: 0.6),
                            iconSize: 22,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: MinbarPlayer.stop,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Row 2: Seek Bar and Timestamps
                      _AudioProgressBar(
                          primaryColor: primaryColor, textColor: textColor),

                      const SizedBox(height: 4),

                      // Row 3: Player Controls (Loop, Prev, Play, Next, Sleep Timer)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        textDirection:
                            TextDirection.ltr, // Player controls usually LTR
                        children: [
                          // Loop Mode
                          StreamBuilder<LoopMode>(
                            stream: MinbarPlayer.player.loopModeStream,
                            builder: (context, loopSnap) {
                              final mode = loopSnap.data ?? LoopMode.off;
                              IconData icon;
                              Color color;
                              if (mode == LoopMode.all) {
                                icon = Icons.repeat_rounded;
                                color = primaryColor;
                              } else if (mode == LoopMode.one) {
                                icon = Icons.repeat_one_rounded;
                                color = primaryColor;
                              } else {
                                icon = Icons.repeat_rounded;
                                color = textColor.withValues(alpha: 0.3);
                              }

                              return IconButton(
                                icon: Icon(icon),
                                color: color,
                                iconSize: 22,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  if (mode == LoopMode.off) {
                                    MinbarPlayer.setLoopMode(LoopMode.all);
                                  } else if (mode == LoopMode.all) {
                                    MinbarPlayer.setLoopMode(LoopMode.one);
                                  } else {
                                    MinbarPlayer.setLoopMode(LoopMode.off);
                                  }
                                },
                              );
                            },
                          ),

                          // Main Controls (Prev, Play, Next)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Previous
                              StreamBuilder<SequenceState?>(
                                stream: MinbarPlayer.player.sequenceStateStream,
                                builder: (context, seqSnap) {
                                  final hasPrev =
                                      MinbarPlayer.player.hasPrevious;
                                  return IconButton(
                                    icon:
                                        const Icon(Icons.skip_previous_rounded),
                                    color: hasPrev
                                        ? textColor
                                        : textColor.withValues(alpha: 0.2),
                                    iconSize: 30,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: hasPrev
                                        ? MinbarPlayer.playPrevious
                                        : null,
                                  );
                                },
                              ),
                              const SizedBox(width: 24),

                              // Play / Pause
                              StreamBuilder<PlayerState>(
                                stream: MinbarPlayer.player.playerStateStream,
                                builder: (context, stateSnap) {
                                  final playing =
                                      stateSnap.data?.playing ?? false;
                                  final processingState =
                                      stateSnap.data?.processingState;

                                  if (processingState ==
                                          ProcessingState.buffering ||
                                      processingState ==
                                          ProcessingState.loading) {
                                    return SizedBox(
                                      width: 48,
                                      height: 48,
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  primaryColor),
                                        ),
                                      ),
                                    );
                                  }

                                  return GestureDetector(
                                    onTap: MinbarPlayer.togglePlay,
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: primaryColor.withValues(
                                                alpha: 0.3),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        playing
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: theme == QuranTheme.dark
                                            ? Colors.black87
                                            : Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 24),

                              // Next
                              StreamBuilder<SequenceState?>(
                                stream: MinbarPlayer.player.sequenceStateStream,
                                builder: (context, seqSnap) {
                                  final hasNext = MinbarPlayer.player.hasNext;
                                  return IconButton(
                                    icon: const Icon(Icons.skip_next_rounded),
                                    color: hasNext
                                        ? textColor
                                        : textColor.withValues(alpha: 0.2),
                                    iconSize: 30,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed:
                                        hasNext ? MinbarPlayer.playNext : null,
                                  );
                                },
                              ),
                            ],
                          ),

                          // Sleep Timer
                          ValueListenableBuilder<Duration?>(
                            valueListenable: MinbarPlayer.sleepTimerNotifier,
                            builder: (context, sleepTimer, _) {
                              return IconButton(
                                icon: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(Icons.timer_rounded,
                                        color: sleepTimer != null
                                            ? primaryColor
                                            : textColor.withValues(alpha: 0.3)),
                                    if (sleepTimer != null)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle),
                                          child: Text(
                                            '${sleepTimer.inMinutes}',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                iconSize: 22,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _showSleepTimerDialog(context,
                                    theme, primaryColor, textColor, bg),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSleepTimerDialog(BuildContext context, QuranTheme theme,
      Color primaryColor, Color textColor, Color bg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('مؤقت النوم',
                      style: AppTextStyles.headlineMedium
                          .copyWith(fontSize: 20, color: textColor)),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildTimerOption(
                          ctx, null, 'إيقاف', primaryColor, textColor),
                      _buildTimerOption(ctx, const Duration(minutes: 15),
                          '15 دقيقة', primaryColor, textColor),
                      _buildTimerOption(ctx, const Duration(minutes: 30),
                          '30 دقيقة', primaryColor, textColor),
                      _buildTimerOption(ctx, const Duration(minutes: 60),
                          '60 دقيقة', primaryColor, textColor),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'وقت مخصص (بالدقائق)',
                      labelStyle:
                          TextStyle(color: textColor.withValues(alpha: 0.6)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: primaryColor.withValues(alpha: 0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor),
                      ),
                    ),
                    onSubmitted: (value) {
                      final minutes = int.tryParse(value);
                      if (minutes != null && minutes > 0) {
                        MinbarPlayer.setCustomSleepTimer(
                            Duration(minutes: minutes));
                        Navigator.pop(ctx);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimerOption(BuildContext context, Duration? duration,
      String label, Color primaryColor, Color textColor) {
    return ActionChip(
      label: Text(label, style: TextStyle(color: textColor)),
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
      onPressed: () {
        MinbarPlayer.setCustomSleepTimer(duration);
        Navigator.pop(context);
      },
    );
  }
}

// ---------------------------------------------------------
// Custom Seek Bar Widget
// ---------------------------------------------------------

class _AudioProgressBar extends StatefulWidget {
  final Color primaryColor;
  final Color textColor;

  const _AudioProgressBar(
      {required this.primaryColor, required this.textColor});

  @override
  State<_AudioProgressBar> createState() => _AudioProgressBarState();
}

class _AudioProgressBarState extends State<_AudioProgressBar> {
  double? _dragValue;

  String _formatDuration(Duration? duration) {
    if (duration == null) return "00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: MinbarPlayer.player.positionStream,
      builder: (context, positionSnap) {
        final position = positionSnap.data ?? Duration.zero;
        final duration = MinbarPlayer.player.duration ?? Duration.zero;

        double currentProgress = duration.inMilliseconds > 0
            ? (position.inMilliseconds / duration.inMilliseconds)
            : 0.0;

        double displayValue = _dragValue ?? currentProgress;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: widget.primaryColor,
                inactiveTrackColor: widget.primaryColor.withValues(alpha: 0.2),
                thumbColor: widget.primaryColor,
                overlayColor: widget.primaryColor.withValues(alpha: 0.1),
              ),
              child: Slider(
                value: displayValue.clamp(0.0, 1.0),
                onChanged: (val) {
                  setState(() {
                    _dragValue = val;
                  });
                },
                onChangeEnd: (val) {
                  if (duration.inMilliseconds > 0) {
                    final newPosition = Duration(
                        milliseconds: (duration.inMilliseconds * val).round());
                    MinbarPlayer.seek(newPosition);
                  }
                  setState(() {
                    _dragValue = null;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                textDirection: TextDirection.ltr, // LTR for timestamps
                children: [
                  Text(
                      _formatDuration(Duration(
                          milliseconds: (duration.inMilliseconds * displayValue)
                              .round())),
                      style: TextStyle(
                          color: widget.textColor.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                  Text(_formatDuration(duration),
                      style: TextStyle(
                          color: widget.textColor.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
