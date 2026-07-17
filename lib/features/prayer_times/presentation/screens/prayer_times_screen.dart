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
import '../../data/models/prayer_config.dart';
import '../../data/models/prayer_time_model.dart';
import '../controllers/prayer_controller.dart';

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
    // Re-resolve location and times when opening the screen to ensure accuracy.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.controller.syncLocation();
    });
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
                    onPressed: () => _showSettingsSheet(context, ctrl, theme),
                  ),
                ],
              ),
              body: ctrl.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : model == null
                      ? Center(
                          child: Text(
                            ctrl.errorMessage ?? l10n.loading,
                            style: AppTextStyles.bodyLarge.copyWith(color: textColor),
                          ),
                        )
                      : SafeArea(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // ── 1. Top Hero Countdown Panel ────────────────
                              _HeroCountdownPanel(
                                model: model,
                                countdown: ctrl.countdown,
                                l10n: l10n,
                              ),

                              // ── 2. Current Location & Hijri Date Info ─────────
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.location_on, size: 16, color: primaryColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          model.locationLabel,
                                          style: AppTextStyles.bodyMedium.copyWith(
                                            color: textColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      Localizations.localeOf(context).languageCode == 'ar'
                                          ? model.hijriDate.formattedAr
                                          : model.hijriDate.formattedEn,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppTheme.getGoldTextColor(theme),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // ── 3. Vertical List of 6 Prayers ───────────────
                              Expanded(
                                child: ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  itemCount: model.entries.length,
                                  itemBuilder: (context, index) {
                                    final entry = model.entries[index];
                                    final isNext = entry.prayer == model.nextPrayer.prayer;
                                    return _PrayerRowCard(
                                      entry: entry,
                                      isNext: isNext,
                                      cardBg: cardBg,
                                      textColor: textColor,
                                      primaryColor: primaryColor,
                                      theme: theme,
                                      l10n: l10n,
                                      onToggleNotif: () => ctrl.toggleNotification(entry.prayer),
                                      notifEnabled: ctrl.isNotifEnabled(entry.prayer),
                                      is24HourFormat: ctrl.config.is24HourFormat,
                                      onTap: () => _showPrayerOptionsSheet(context, entry, ctrl, theme),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
            );
          },
        );
      },
    );
  }

  // ── Prayer Options Bottom Sheet ────────────────────────────────────────────

  void _showPrayerOptionsSheet(BuildContext context, PrayerTimeEntry entry, PrayerController ctrl, QuranTheme theme) {
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
            final currentOffset = ctrl.config.prayerOffsets[entry.prayer.name] ?? 0;
            final currentMuezzinId = ctrl.config.prayerMuezzins[entry.prayer.name] ?? 'adhan_abdulbasit';
            final muezzinNames = {
              'adhan_abdulbasit': l10n.muezzinAbdulbasit,
              'adhan_mecca_ali_mulla': l10n.muezzinMecca,
              'adhan_mishary_alafasy': l10n.muezzinAlafasy,
              'adhan_mansour_al_zahrani': l10n.muezzinZahrani,
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
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10)),
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
                                style: AppTextStyles.headlineMedium.copyWith(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formattedTime,
                                style: AppTextStyles.bodyLarge.copyWith(color: primary, fontWeight: FontWeight.bold, fontFeatures: const [FontFeature.tabularFigures()]),
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
                    title: Text(l10n.notifEnabled, style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                    subtitle: Text(l10n.athanNotifDesc, style: AppTextStyles.labelSmall.copyWith(color: textColor.withValues(alpha: 0.6))),
                    value: ctrl.isNotifEnabled(entry.prayer),
                    activeColor: primary,
                    onChanged: (val) {
                      ctrl.toggleNotification(entry.prayer);
                    },
                  ),
                  
                  const Divider(height: 24),

                  // Pre-Athan Warning
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.preAthanWarning, style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          _buildPreAthanChip(0, l10n.off, ctrl, entry.prayer.name, primary, textColor, cardBg),
                          _buildPreAthanChip(5, '5 ${l10n.minLabel}', ctrl, entry.prayer.name, primary, textColor, cardBg),
                          _buildPreAthanChip(10, '10 ${l10n.minLabel}', ctrl, entry.prayer.name, primary, textColor, cardBg),
                          _buildCustomPreAthanChip(ctrl, entry.prayer.name, primary, textColor, cardBg, context, l10n),
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
                            Text(l10n.timeAdjustment, style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(l10n.adjustAthan, style: AppTextStyles.labelSmall.copyWith(color: textColor.withValues(alpha: 0.6))),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: primary),
                            onPressed: () {
                              final newOffsets = Map<String, int>.from(ctrl.config.prayerOffsets);
                              newOffsets[entry.prayer.name] = currentOffset - 1;
                              ctrl.updateConfig(ctrl.config.copyWith(prayerOffsets: newOffsets));
                            },
                          ),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '${currentOffset > 0 ? '+' : ''}$currentOffset',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodyLarge.copyWith(color: textColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline, color: primary),
                            onPressed: () {
                              final newOffsets = Map<String, int>.from(ctrl.config.prayerOffsets);
                              newOffsets[entry.prayer.name] = currentOffset + 1;
                              ctrl.updateConfig(ctrl.config.copyWith(prayerOffsets: newOffsets));
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
                    title: Text(l10n.muezzinVoice, style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                    subtitle: Text(muezzinNames[currentMuezzinId] ?? l10n.muezzinAbdulbasit, style: AppTextStyles.labelSmall.copyWith(color: primary)),
                    trailing: Icon(Icons.keyboard_arrow_down_rounded, color: primary),
                    onTap: () {
                      _showMuezzinSelector(context, entry, ctrl, theme, muezzinNames, currentMuezzinId, l10n);
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

  Widget _buildPreAthanChip(int minutes, String label, PrayerController ctrl, String prayerName, Color primary, Color textColor, Color cardBg) {
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
          border: Border.all(color: isSelected ? primary : primary.withValues(alpha: 0.3)),
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

  Widget _buildCustomPreAthanChip(PrayerController ctrl, String prayerName, Color primary, Color textColor, Color cardBg, BuildContext context, AppLocalizations l10n) {
    final currentPreAthan = ctrl.config.preAthanMinutes[prayerName] ?? 0;
    final isCustom = currentPreAthan != 0 && currentPreAthan != 5 && currentPreAthan != 10 && currentPreAthan != 15;
    final label = isCustom ? '$currentPreAthan ${l10n.minLabel}' : l10n.custom;
    
    return InkWell(
      onTap: () {
        _showCustomPreAthanDialog(context, ctrl, prayerName, currentPreAthan, primary, textColor, cardBg, l10n);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isCustom ? primary : cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isCustom ? primary : primary.withValues(alpha: 0.3)),
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
            Icon(Icons.edit, size: 14, color: isCustom ? Colors.white : primary),
          ],
        ),
      ),
    );
  }

  void _showCustomPreAthanDialog(BuildContext context, PrayerController ctrl, String prayerName, int currentVal, Color primary, Color textColor, Color cardBg, AppLocalizations l10n) {
    final textController = TextEditingController(text: currentVal > 0 ? currentVal.toString() : '');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(l10n.customTimeMin, style: AppTextStyles.headlineMedium.copyWith(color: textColor, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            style: AppTextStyles.bodyLarge.copyWith(color: textColor),
            decoration: InputDecoration(
              hintText: l10n.example30,
              hintStyle: AppTextStyles.bodyMedium.copyWith(color: textColor.withValues(alpha: 0.5)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primary.withValues(alpha: 0.5))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primary)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel, style: AppTextStyles.bodyMedium.copyWith(color: textColor.withValues(alpha: 0.6))),
            ),
            ElevatedButton(
              onPressed: () {
                final val = int.tryParse(textController.text);
                if (val != null && val >= 0) {
                  final newPreAthan = Map<String, int>.from(ctrl.config.preAthanMinutes);
                  newPreAthan[prayerName] = val;
                  ctrl.updateConfig(ctrl.config.copyWith(preAthanMinutes: newPreAthan));
                }
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(l10n.save, style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showMuezzinSelector(BuildContext context, PrayerTimeEntry entry, PrayerController ctrl, QuranTheme theme, Map<String, String> muezzinNames, String currentId, AppLocalizations l10n) {
    final cardBg = AppTheme.getCardBgColor(theme);
    final textColor = AppTheme.getMainTextColor(theme);
    final primary = AppTheme.getPrimaryColor(theme);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(l10n.chooseMuezzin, style: AppTextStyles.headlineMedium.copyWith(color: textColor, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...muezzinNames.entries.map((m) {
                final isSelected = m.key == currentId;
                return ListTile(
                  title: Text(m.value, style: AppTextStyles.bodyMedium.copyWith(color: isSelected ? primary : textColor, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSelected ? Icon(Icons.check_circle_rounded, color: primary) : null,
                  onTap: () {
                    final newMuezzins = Map<String, String>.from(ctrl.config.prayerMuezzins);
                    newMuezzins[entry.prayer.name] = m.key;
                    ctrl.updateConfig(ctrl.config.copyWith(prayerMuezzins: newMuezzins));
                    Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ── Settings Bottom Sheet ──────────────────────────────────────────────────

  void _showSettingsSheet(BuildContext context, PrayerController ctrl, QuranTheme theme) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme == QuranTheme.dark;
    final cardBg = AppTheme.getCardBgColor(theme);
    final textColor = AppTheme.getMainTextColor(theme);
    final primary = AppTheme.getPrimaryColor(theme);

    // Prayer keys order
    const prayerKeys = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
    const prayerIcons = [
      Icons.wb_twilight_rounded,
      Icons.light_mode_rounded,
      Icons.wb_sunny_rounded,
      Icons.filter_drama_rounded,
      Icons.nights_stay_rounded,
      Icons.bedtime_rounded,
    ];
    final prayerColors = [
      AppColors.prayerFajr,
      AppColors.prayerSunrise,
      AppColors.prayerDhuhr,
      AppColors.prayerAsr,
      AppColors.prayerMaghrib,
      AppColors.prayerIsha,
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final cfg = ctrl.config;

            // ── Section header helper ────────────────────────────────────
            Widget sectionHeader(String label, IconData icon) => Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: Row(
                children: [
                  Icon(icon, color: primary, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            );

            // ── Settings row (label + widget) ──────────────────────────
            Widget settingsRow(String label, Widget trailing) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMedium.copyWith(color: textColor),
                  ),
                ),
                trailing,
              ],
            );

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (ctx, scrollCtrl) => SafeArea(
                child: ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white24
                              : Colors.black26,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // Title
                    Text(
                      l10n.prayerSettingsTitle,
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    // ─────────────────────────────────────────
                    // 1. Display
                    // ─────────────────────────────────────────
                    sectionHeader('Display', Icons.tune_rounded),

                    settingsRow(
                      '24-Hour Clock',
                      Switch(
                        value: cfg.is24HourFormat,
                        activeThumbColor: primary,
                        onChanged: (val) {
                          ctrl.updateConfig(cfg.copyWith(is24HourFormat: val));
                          setModalState(() {});
                        },
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Hijri offset picker (−2 .. +2 days)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hijri Date Offset',
                          style: AppTextStyles.bodyMedium.copyWith(color: textColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Adjust to match your local moon sighting',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (i) {
                            final val = i - 2; // -2 to +2
                            final isSelected = cfg.hijriOffset == val;
                            return GestureDetector(
                              onTap: () {
                                ctrl.updateConfig(cfg.copyWith(hijriOffset: val));
                                setModalState(() {});
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 44,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? primary
                                      : (isDark
                                          ? AppColors.surfaceElevated
                                          : const Color(0xFFF0F4F2)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? primary
                                        : (isDark
                                            ? Colors.white12
                                            : Colors.black12),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  val == 0 ? '0' : (val > 0 ? '+$val' : '$val'),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : textColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),

                    // ─────────────────────────────────────────
                    // 2. Calculation
                    // ─────────────────────────────────────────
                    sectionHeader(l10n.calcMethod, Icons.calculate_rounded),

                    DropdownButton<CalculationMethodEnum>(
                      value: cfg.method,
                      dropdownColor: cardBg,
                      isExpanded: true,
                      style: AppTextStyles.bodyLarge.copyWith(color: textColor),
                      onChanged: (val) {
                        if (val != null) {
                          ctrl.changeMethod(val);
                          setModalState(() {});
                        }
                      },
                      items: CalculationMethodEnum.values.map((method) {
                        final label =
                            Localizations.localeOf(context).languageCode == 'ar'
                                ? method.labelAr
                                : method.labelEn;
                        return DropdownMenuItem(
                          value: method,
                          child: Text(label),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      l10n.madhab,
                      style: AppTextStyles.labelLarge.copyWith(color: textColor),
                    ),
                    DropdownButton<MadhabEnum>(
                      value: cfg.madhab,
                      dropdownColor: cardBg,
                      isExpanded: true,
                      style: AppTextStyles.bodyLarge.copyWith(color: textColor),
                      onChanged: (val) {
                        if (val != null) {
                          ctrl.changeMadhab(val);
                          setModalState(() {});
                        }
                      },
                      items: MadhabEnum.values.map((m) {
                        final label =
                            Localizations.localeOf(context).languageCode == 'ar'
                                ? m.labelAr
                                : m.labelEn;
                        return DropdownMenuItem(
                          value: m,
                          child: Text(label),
                        );
                      }).toList(),
                    ),

                    // ─────────────────────────────────────────
                    // 3. Prayer Time Offsets
                    // ─────────────────────────────────────────
                    sectionHeader('Prayer Time Adjustments', Icons.schedule_rounded),

                    Text(
                      'Fine-tune each prayer time (minutes)',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                    const SizedBox(height: 8),

                    ...List.generate(prayerKeys.length, (i) {
                      final key = prayerKeys[i];
                      final offsetVal = cfg.prayerOffsets[key] ?? 0;
                      final prayerLabel = key[0].toUpperCase() + key.substring(1);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: prayerColors[i].withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(prayerIcons[i],
                                  color: prayerColors[i], size: 16),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 72,
                              child: Text(
                                prayerLabel,
                                style: AppTextStyles.bodyMedium
                                    .copyWith(color: textColor),
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: offsetVal.toDouble(),
                                min: -30,
                                max: 30,
                                divisions: 60,
                                activeColor: prayerColors[i],
                                inactiveColor:
                                    prayerColors[i].withValues(alpha: 0.2),
                                onChanged: (val) {
                                  final newOffsets =
                                      Map<String, int>.from(cfg.prayerOffsets)
                                        ..[key] = val.round();
                                  ctrl.updateConfig(
                                      cfg.copyWith(prayerOffsets: newOffsets));
                                  setModalState(() {});
                                },
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              child: Text(
                                offsetVal == 0
                                    ? '0'
                                    : (offsetVal > 0
                                        ? '+$offsetVal'
                                        : '$offsetVal'),
                                style: TextStyle(
                                  color: prayerColors[i],
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),

                    // ─────────────────────────────────────────
                    // 4. Location
                    // ─────────────────────────────────────────
                    sectionHeader('Location', Icons.location_on_rounded),

                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.gps_fixed),
                      label: Text(l10n.locationSync),
                      onPressed: () async {
                        Navigator.pop(context);
                        await ctrl.syncLocation();
                      },
                    ),

                    // ─────────────────────────────────────────
                    // 5. Permissions Status
                    // ─────────────────────────────────────────
                    sectionHeader('Permissions', Icons.security_rounded),

                    _PermissionRow(
                      label: 'Exact Alarms',
                      subtitle: 'Required for precise adhan notifications',
                      icon: Icons.alarm_rounded,
                      iconColor: AppColors.prayerFajr,
                      isDark: isDark,
                      textColor: textColor,
                    ),
                    const SizedBox(height: 8),
                    _PermissionRow(
                      label: 'Battery Optimization',
                      subtitle: 'Ignored — keeps adhan reliable in background',
                      icon: Icons.battery_charging_full_rounded,
                      iconColor: AppColors.emeraldLight,
                      isDark: isDark,
                      textColor: textColor,
                    ),
                  ],
                ),
              ),
            );
          },
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
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.5),
                  blurRadius: 24,
                  spreadRadius: 2,
                  offset: const Offset(0, 12),
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
                const SizedBox(height: 8),
                Text(
                  _localizePrayerName(nextPrayer.prayer, l10n),
                  style: AppTextStyles.displayMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  countdown,
                  style: AppTextStyles.prayerTimeLarge.copyWith(
                    color: AppColors.goldLight,
                    fontSize: 48,
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
                const SizedBox(height: 8),
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

  @override
  Widget build(BuildContext context) {
    final name = _localizePrayerName(entry.prayer, l10n);
    final isDark = theme == QuranTheme.dark;
    final formattedTime = _formatTime(entry.time, is24HourFormat);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isNext
            ? primaryColor.withValues(alpha: isDark ? 0.15 : 0.08)
            : cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isNext
              ? primaryColor.withValues(alpha: 0.5)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: isNext ? [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          highlightColor: primaryColor.withValues(alpha: 0.1),
          splashColor: primaryColor.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                    notifEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                    color: notifEnabled
                        ? (isNext ? primaryColor : AppColors.goldMid)
                        : Colors.grey.shade400,
                  ),
                  tooltip: notifEnabled ? l10n.notifEnabled : l10n.notifDisabled,
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
    case PrayerName.fajr:    return l10n.prayerFajr;
    case PrayerName.sunrise: return l10n.prayerSunrise;
    case PrayerName.dhuhr:   return l10n.prayerDhuhr;
    case PrayerName.asr:     return l10n.prayerAsr;
    case PrayerName.maghrib: return l10n.prayerMaghrib;
    case PrayerName.isha:    return l10n.prayerIsha;
    default:                 return prayer.name;
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

  final String    label;
  final String    subtitle;
  final IconData  icon;
  final Color     iconColor;
  final bool      isDark;
  final Color     textColor;

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
        color: widget.isDark
            ? AppColors.surfaceElevated
            : const Color(0xFFF5F7F5),
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
                    color:      widget.textColor,
                    fontWeight: FontWeight.w600,
                    fontSize:   13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    color:    widget.isDark ? Colors.white38 : Colors.black38,
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
