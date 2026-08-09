// lib/features/prayer_times/presentation/screens/prayer_times_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// PrayerTimesScreen — Full-featured responsive prayer times control panel.
//
// Features:
//  • Top Hero Card with dynamic segment gradient and pulsing live countdown.
//  • Dynamic icons based on the time of day segment.
//  • 6 prayer time cards showing localized names, exact times, and notif toggles.
//  • ModalBottomSheet for calculations, juristic madhab, and GPS sync.
//  • Fully supports the app's 3-theme palette (Cream, Dark, White).
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme_notifier.dart';
import '../../data/models/prayer_time_model.dart';
import '../controllers/prayer_controller.dart';
import 'prayer_settings_screen.dart';
import 'muezzin_selection_screen.dart';
import 'location_selection_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key, required this.controller});

  final PrayerController controller;

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  @override
  void initState() {
    super.initState();
    // The controller purely drives state from RAM/Storage. No GPS fetching here.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRequestPermissions();
    });
  }

  Future<void> _checkAndRequestPermissions() async {
    // 1. POST_NOTIFICATIONS
    if (!await Permission.notification.isGranted) {
      await Permission.notification.request();
    }
    // 2. SCHEDULE_EXACT_ALARM
    if (!await Permission.scheduleExactAlarm.isGranted) {
      await Permission.scheduleExactAlarm.request();
    }
    // 3. ignoreBatteryOptimizations
    if (!await Permission.ignoreBatteryOptimizations.isGranted) {
      final prefs = await SharedPreferences.getInstance();
      final promptCount = prefs.getInt('background_prompt_count') ?? 0;

      final notifs = widget.controller.config.notifications;
      final anyEnabled = notifs.fajrEnabled ||
          notifs.sunriseEnabled ||
          notifs.dhuhrEnabled ||
          notifs.asrEnabled ||
          notifs.maghribEnabled ||
          notifs.ishaEnabled;

      // Strike System (Max 2 prompts) and respect Settings choice
      if (promptCount >= 2 || !anyEnabled) {
        return;
      }

      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('Background Protection'),
            content: const Text(
              'To ensure Adhan triggers exactly on time in the background, please disable battery optimization for this app on the next screen.',
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await prefs.setInt(
                      'background_prompt_count', promptCount + 1);
                  // ignore: use_build_context_synchronously
                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  if (mounted) Navigator.pop(ctx);
                  await Permission.ignoreBatteryOptimizations.request();
                },
                child: const Text('Proceed'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final l10n = AppLocalizations.of(context)!;

        final Color scaffoldBg = AppTheme.getScreenBgColor(theme);
        final Color cardBg = AppTheme.getCardBgColor(theme);
        final Color textColor = AppTheme.getMainTextColor(theme);
        final Color primaryColor = AppTheme.getPrimaryColor(theme);

        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final ctrl = widget.controller;
            final model = ctrl.model;

            return Scaffold(
              backgroundColor: scaffoldBg,
              appBar: AppBar(
                title: Text(l10n.prayerTimes),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: l10n.prayerSettingsTitle,
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  PrayerSettingsScreen(controller: ctrl)));
                    },
                  ),
                ],
              ),
              body: ctrl.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (model == null && !ctrl.isLocationMissing)
                      ? Center(
                          child: Text(
                            ctrl.errorMessage ?? l10n.loading,
                            style: AppTextStyles.bodyLarge
                                .copyWith(color: textColor),
                          ),
                        )
                      : Builder(builder: (context) {
                          final isEmpty =
                              ctrl.isLocationMissing && model == null;
                          final displayModel = model ??
                              PrayerTimeModel(
                                date: DateTime.now(),
                                hijriDate: const HijriDate(
                                    year: 1445,
                                    month: 1,
                                    day: 1,
                                    monthNameAr: '',
                                    monthNameEn: ''),
                                locationLabel: '',
                                latitude: 0,
                                longitude: 0,
                                entries: [
                                  PrayerTimeEntry(
                                      prayer: PrayerName.fajr,
                                      time: DateTime.now(),
                                      alertMode: PrayerAlertMode.silent),
                                  PrayerTimeEntry(
                                      prayer: PrayerName.sunrise,
                                      time: DateTime.now(),
                                      alertMode: PrayerAlertMode.silent),
                                  PrayerTimeEntry(
                                      prayer: PrayerName.dhuhr,
                                      time: DateTime.now(),
                                      alertMode: PrayerAlertMode.silent),
                                  PrayerTimeEntry(
                                      prayer: PrayerName.asr,
                                      time: DateTime.now(),
                                      alertMode: PrayerAlertMode.silent),
                                  PrayerTimeEntry(
                                      prayer: PrayerName.maghrib,
                                      time: DateTime.now(),
                                      alertMode: PrayerAlertMode.silent),
                                  PrayerTimeEntry(
                                      prayer: PrayerName.isha,
                                      time: DateTime.now(),
                                      alertMode: PrayerAlertMode.silent),
                                ],
                                daySegment: DaySegment.morning,
                                nextPrayer: PrayerTimeEntry(
                                    prayer: PrayerName.fajr,
                                    time: DateTime.now(),
                                    alertMode: PrayerAlertMode.silent),
                                calculationMethod: '',
                              );

                          return SafeArea(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // ── 1. Top Hero Countdown Panel ────────────────
                                ValueListenableBuilder<String>(
                                  valueListenable: ctrl.countdownNotifier,
                                  builder: (context, countdownStr, _) {
                                    return _HeroCountdownPanel(
                                      model: displayModel,
                                      countdown: countdownStr,
                                      l10n: l10n,
                                    );
                                  },
                                ),

                                // ── 2. Current Location & Hijri Date Info ─────────
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 16, 20, 8),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  LocationSelectionScreen(
                                                      controller: ctrl),
                                            ),
                                          );
                                        },
                                        child: ctrl.isLocationMissing
                                            ? Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.shade700
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                      color: Colors
                                                          .orange.shade400,
                                                      width: 1.5),
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                        Icons
                                                            .warning_amber_rounded,
                                                        size: 16,
                                                        color: Colors.orange),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      l10n.tapToSetLocation,
                                                      style: AppTextStyles
                                                          .bodyMedium
                                                          .copyWith(
                                                        color: theme ==
                                                                QuranTheme.dark
                                                            ? Colors
                                                                .orange.shade300
                                                            : Colors.orange
                                                                .shade800,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                                .animate(
                                                  onPlay: (controller) =>
                                                      controller.repeat(
                                                          reverse: true),
                                                )
                                                .scaleXY(
                                                    end: 1.05, duration: 800.ms)
                                            : Row(
                                                children: [
                                                  Icon(Icons.location_on,
                                                      size: 16,
                                                      color: primaryColor),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    displayModel.locationLabel,
                                                    style: AppTextStyles
                                                        .bodyMedium
                                                        .copyWith(
                                                      color: textColor,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                      Text(
                                        isEmpty
                                            ? '--/--/----'
                                            : (Localizations.localeOf(context)
                                                        .languageCode ==
                                                    'ar'
                                                ? displayModel
                                                    .hijriDate.formattedAr
                                                : displayModel
                                                    .hijriDate.formattedEn),
                                        style:
                                            AppTextStyles.bodyMedium.copyWith(
                                          color:
                                              AppTheme.getGoldTextColor(theme),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // ── 3. Vertical List of 6 Prayers ───────────────
                                Expanded(
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    itemCount: displayModel.entries.length,
                                    itemBuilder: (context, index) {
                                      final entry = displayModel.entries[index];
                                      final isNext = !isEmpty &&
                                          entry.prayer ==
                                              displayModel.nextPrayer.prayer;
                                      return _PrayerRowCard(
                                        entry: entry,
                                        isNext: isNext,
                                        cardBg: cardBg,
                                        textColor: textColor,
                                        primaryColor: primaryColor,
                                        theme: theme,
                                        l10n: l10n,
                                        isEmptyState: isEmpty,
                                        onToggleNotif: () async {
                                          if (isEmpty) return;
                                          final isEnabled =
                                              ctrl.isNotifEnabled(entry.prayer);
                                          if (!isEnabled) {
                                            await _checkAndRequestPermissions();
                                          }
                                          ctrl.toggleNotification(entry.prayer);
                                        },
                                        notifEnabled:
                                            ctrl.isNotifEnabled(entry.prayer),
                                        is24HourFormat:
                                            ctrl.config.is24HourFormat,
                                        onTap: () {
                                          if (!isEmpty) {
                                            _showPrayerOptionsSheet(
                                                context, entry, ctrl, theme);
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
            );
          },
        );
      },
    );
  }

  // ── Prayer Options Bottom Sheet ────────────────────────────────────────────

  void _showPrayerOptionsSheet(BuildContext context, PrayerTimeEntry entry,
      PrayerController ctrl, QuranTheme theme) {
    final l10n = AppLocalizations.of(context)!;
    final cardBg = AppTheme.getCardBgColor(theme);
    final textColor = AppTheme.getMainTextColor(theme);
    final primary = AppTheme.getPrimaryColor(theme);
    final prayerNameStr = _localizePrayerName(entry.prayer, l10n);
    final formattedTime = _formatTime(entry.time, ctrl.config.is24HourFormat);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return AnimatedBuilder(
          animation: ctrl,
          builder: (context, _) {
            final currentOffset =
                ctrl.config.prayerOffsets[entry.prayer.name] ?? 0;
            final currentMuezzinId =
                ctrl.config.prayerMuezzins[entry.prayer.name] ??
                    'adhan_abdulbasit';
            final muezzinNames = {
              'adhan_abdulbasit': l10n.muezzinAbdulbasit,
              'adhan_mecca_ali_mulla': l10n.muezzinMecca,
              'adhan_mishary_alafasy': l10n.muezzinAlafasy,
              'adhan_nasser_al_qatami': l10n.muezzinNasser,
              'adhan_yasser_al_dosari': l10n.muezzinDosari,
            };

            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Hero Header for Prayer
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        _buildPrayerIcon(entry.prayer),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prayerNameStr,
                                style: AppTextStyles.headlineMedium.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedTime,
                                style: AppTextStyles.bodyLarge.copyWith(
                                    color: primary,
                                    fontWeight: FontWeight.bold,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Athan Toggle
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.notifEnabled,
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: textColor, fontWeight: FontWeight.bold)),
                    subtitle: Text(l10n.athanNotifDesc,
                        style: AppTextStyles.labelSmall
                            .copyWith(color: textColor.withValues(alpha: 0.6))),
                    value: ctrl.isNotifEnabled(entry.prayer),
                    activeThumbColor: primary,
                    onChanged: (val) async {
                      if (val) {
                        await _checkAndRequestPermissions();
                      }
                      ctrl.toggleNotification(entry.prayer);
                    },
                  ),

                  const Divider(height: 24),

                  // Pre-Athan Warning
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.preAthanWarning,
                          style: AppTextStyles.bodyMedium.copyWith(
                              color: textColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildPreAthanChip(0, l10n.off, ctrl,
                              entry.prayer.name, primary, textColor, cardBg),
                          _buildPreAthanChip(5, '5 ${l10n.minLabel}', ctrl,
                              entry.prayer.name, primary, textColor, cardBg),
                          _buildPreAthanChip(10, '10 ${l10n.minLabel}', ctrl,
                              entry.prayer.name, primary, textColor, cardBg),
                          _buildCustomPreAthanChip(ctrl, entry.prayer.name,
                              primary, textColor, cardBg, context, l10n),
                        ],
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // Time Adjustment (Offset)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.timeAdjustment,
                                style: AppTextStyles.bodyMedium.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(l10n.adjustAthan,
                                style: AppTextStyles.labelSmall.copyWith(
                                    color: textColor.withValues(alpha: 0.6))),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline,
                                color: primary),
                            onPressed: () {
                              final newOffsets = Map<String, int>.from(
                                  ctrl.config.prayerOffsets);
                              newOffsets[entry.prayer.name] = currentOffset - 1;
                              ctrl.updateConfig(ctrl.config
                                  .copyWith(prayerOffsets: newOffsets));
                            },
                          ),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '${currentOffset > 0 ? '+' : ''}$currentOffset',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyLarge.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon:
                                Icon(Icons.add_circle_outline, color: primary),
                            onPressed: () {
                              final newOffsets = Map<String, int>.from(
                                  ctrl.config.prayerOffsets);
                              newOffsets[entry.prayer.name] = currentOffset + 1;
                              ctrl.updateConfig(ctrl.config
                                  .copyWith(prayerOffsets: newOffsets));
                            },
                          ),
                        ],
                      )
                    ],
                  ),

                  const Divider(height: 24),

                  // Change Athan Sound
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.muezzinVoice,
                        style: AppTextStyles.bodyMedium.copyWith(
                            color: textColor, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        muezzinNames[currentMuezzinId] ??
                            l10n.muezzinAbdulbasit,
                        style:
                            AppTextStyles.labelSmall.copyWith(color: primary)),
                    trailing:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onTap: () {
                      Navigator.pop(context); // Close bottom sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MuezzinSelectionScreen(
                            controller: ctrl,
                            prayerName: entry.prayer.name,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPreAthanChip(int minutes, String label, PrayerController ctrl,
      String prayerName, Color primary, Color textColor, Color cardBg) {
    final currentPreAthan = ctrl.config.preAthanMinutes[prayerName] ?? 0;
    final isSelected = currentPreAthan == minutes;
    return InkWell(
      onTap: () {
        final newPreAthan = Map<String, int>.from(ctrl.config.preAthanMinutes);
        newPreAthan[prayerName] = minutes;
        ctrl.updateConfig(ctrl.config.copyWith(preAthanMinutes: newPreAthan));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? primary : primary.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isSelected ? Colors.white : textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCustomPreAthanChip(
      PrayerController ctrl,
      String prayerName,
      Color primary,
      Color textColor,
      Color cardBg,
      BuildContext context,
      AppLocalizations l10n) {
    final currentPreAthan = ctrl.config.preAthanMinutes[prayerName] ?? 0;
    final isCustom = currentPreAthan != 0 &&
        currentPreAthan != 5 &&
        currentPreAthan != 10 &&
        currentPreAthan != 15;
    final label = isCustom ? '$currentPreAthan ${l10n.minLabel}' : l10n.custom;

    return InkWell(
      onTap: () {
        _showCustomPreAthanDialog(context, ctrl, prayerName, currentPreAthan,
            primary, textColor, cardBg, l10n);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isCustom ? primary : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isCustom ? primary : primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isCustom ? Colors.white : textColor,
                fontWeight: isCustom ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.edit,
                size: 14, color: isCustom ? Colors.white : primary),
          ],
        ),
      ),
    );
  }

  void _showCustomPreAthanDialog(
      BuildContext context,
      PrayerController ctrl,
      String prayerName,
      int currentVal,
      Color primary,
      Color textColor,
      Color cardBg,
      AppLocalizations l10n) {
    final textController = TextEditingController(
        text: currentVal > 0 ? currentVal.toString() : '');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.customTimeMin,
              style: AppTextStyles.headlineMedium
                  .copyWith(color: textColor, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            style: AppTextStyles.bodyLarge.copyWith(color: textColor),
            decoration: InputDecoration(
              hintText: l10n.example30,
              hintStyle: AppTextStyles.bodyMedium
                  .copyWith(color: textColor.withValues(alpha: 0.5)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: primary.withValues(alpha: 0.5))),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primary)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: textColor.withValues(alpha: 0.6))),
            ),
            ElevatedButton(
              onPressed: () {
                final val = int.tryParse(textController.text);
                if (val != null && val >= 0) {
                  final newPreAthan =
                      Map<String, int>.from(ctrl.config.preAthanMinutes);
                  newPreAthan[prayerName] = val;
                  ctrl.updateConfig(
                      ctrl.config.copyWith(preAthanMinutes: newPreAthan));
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: Text(l10n.save,
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// _HeroCountdownPanel — Displays the next prayer name and countdown ticker
// ─────────────────────────────────────────────────────────────────────────────

class _HeroCountdownPanel extends StatelessWidget {
  const _HeroCountdownPanel({
    required this.model,
    required this.countdown,
    required this.l10n,
  });

  final PrayerTimeModel model;
  final String countdown;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final nextPrayer = model.nextPrayer;
    final gradient = model.miqatGradientColors;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.95, end: 1.0),
      duration: const Duration(seconds: 2),
      curve: Curves.easeInOutSine,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: -2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  l10n.nextPrayer.toUpperCase(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white70,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _localizePrayerName(nextPrayer.prayer, l10n),
                  style: AppTextStyles.displayMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  countdown,
                  style: AppTextStyles.prayerTimeLarge.copyWith(
                    color: AppColors.goldLight,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: AppColors.goldLight.withValues(alpha: 0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 0),
                      ),
                      const Shadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.countdown,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white60,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      onEnd: () {
        // We can't trivially loop TweenAnimationBuilder without state,
        // but the layout itself is already heavily upgraded.
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PrayerRowCard — Individual card for Fajr, Dhuhr, etc.
// ─────────────────────────────────────────────────────────────────────────────

class _PrayerRowCard extends StatelessWidget {
  const _PrayerRowCard({
    required this.entry,
    required this.isNext,
    required this.cardBg,
    required this.textColor,
    required this.primaryColor,
    required this.theme,
    required this.l10n,
    required this.onToggleNotif,
    required this.notifEnabled,
    required this.is24HourFormat,
    required this.onTap,
    this.isEmptyState = false,
  });

  final PrayerTimeEntry entry;
  final bool isNext;
  final Color cardBg;
  final Color textColor;
  final Color primaryColor;
  final QuranTheme theme;
  final AppLocalizations l10n;
  final VoidCallback onToggleNotif;
  final bool notifEnabled;
  final bool is24HourFormat;
  final VoidCallback onTap;
  final bool isEmptyState;

  @override
  Widget build(BuildContext context) {
    final name = _localizePrayerName(entry.prayer, l10n);
    final isDark = theme == QuranTheme.dark;
    final formattedTime =
        isEmptyState ? '--:--' : _formatTime(entry.time, is24HourFormat);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isNext
            ? primaryColor.withValues(alpha: isDark ? 0.15 : 0.08)
            : cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              isNext ? primaryColor.withValues(alpha: 0.3) : Colors.transparent,
          width: 0.5,
        ),
        boxShadow: isNext
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.2),
                  blurRadius: 24,
                  spreadRadius: -2,
                  offset: const Offset(0, 8),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          highlightColor: primaryColor.withValues(alpha: 0.05),
          splashColor: primaryColor.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Prayer Icon indicator
                _buildPrayerIcon(entry.prayer),
                const SizedBox(width: 16),

                // Prayer Name
                Expanded(
                  child: Text(
                    name,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: textColor,
                      fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ),

                // Prayer Time
                Text(
                  formattedTime,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: textColor,
                    fontWeight: isNext ? FontWeight.bold : FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 12),

                // Notification Bell Toggle
                IconButton(
                  icon: Icon(
                    notifEnabled
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_off_rounded,
                    color: notifEnabled
                        ? (isNext ? primaryColor : AppColors.goldMid)
                        : Colors.grey.shade400,
                  ),
                  tooltip:
                      notifEnabled ? l10n.notifEnabled : l10n.notifDisabled,
                  onPressed: onToggleNotif,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildPrayerIcon(PrayerName prayer) {
  IconData icon;
  Color color;
  switch (prayer) {
    case PrayerName.fajr:
      icon = Icons.wb_twilight_rounded;
      color = AppColors.prayerFajr;
      break;
    case PrayerName.sunrise:
      icon = Icons.light_mode_rounded;
      color = AppColors.prayerSunrise;
      break;
    case PrayerName.dhuhr:
      icon = Icons.wb_sunny_rounded;
      color = AppColors.prayerDhuhr;
      break;
    case PrayerName.asr:
      icon = Icons.filter_drama_rounded;
      color = AppColors.prayerAsr;
      break;
    case PrayerName.maghrib:
      icon = Icons.nights_stay_rounded;
      color = AppColors.prayerMaghrib;
      break;
    case PrayerName.isha:
      icon = Icons.bedtime_rounded;
      color = AppColors.prayerIsha;
      break;
    default:
      icon = Icons.access_time_filled_rounded;
      color = Colors.grey;
  }

  return Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, color: color, size: 20),
  );
}

String _formatTime(DateTime time, bool is24h) {
  if (is24h) return DateFormat.Hm().format(time);
  return DateFormat.jm().format(time);
}

// Helper to translate prayer names
String _localizePrayerName(PrayerName prayer, AppLocalizations l10n) {
  switch (prayer) {
    case PrayerName.fajr:
      return l10n.fajr;
    case PrayerName.sunrise:
      return l10n.sunrise;
    case PrayerName.dhuhr:
      return l10n.dhuhr;
    case PrayerName.asr:
      return l10n.asr;
    case PrayerName.maghrib:
      return l10n.maghrib;
    case PrayerName.isha:
      return l10n.isha;
    default:
      return prayer.name;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PermissionRow — Shows status of a device permission with a mock toggle
// ─────────────────────────────────────────────────────────────────────────────

class _PermissionRow extends StatefulWidget {
  const _PermissionRow({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.isDark,
    required this.textColor,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final bool isDark;
  final Color textColor;

  @override
  State<_PermissionRow> createState() => _PermissionRowState();
}

class _PermissionRowState extends State<_PermissionRow> {
  bool _granted = true; // Mock: assume granted

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color:
            widget.isDark ? AppColors.surfaceElevated : const Color(0xFFF5F7F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _granted
              ? widget.iconColor.withValues(alpha: 0.35)
              : Colors.red.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: widget.iconColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: widget.iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    color: widget.isDark ? Colors.white38 : Colors.black38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _granted,
            activeThumbColor: widget.iconColor,
            onChanged: (v) => setState(() => _granted = v),
          ),
        ],
      ),
    );
  }
}
