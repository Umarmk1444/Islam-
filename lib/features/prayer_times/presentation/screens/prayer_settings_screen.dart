import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../../../../core/services/background_engine.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme_notifier.dart';
import '../../data/models/prayer_config.dart';
import '../controllers/prayer_controller.dart';
import 'permissions_setup_screen.dart';
import 'diagnostic_screen.dart';

class PrayerSettingsScreen extends StatefulWidget {
  const PrayerSettingsScreen({super.key, required this.controller});
  final PrayerController controller;

  @override
  State<PrayerSettingsScreen> createState() => _PrayerSettingsScreenState();
}

class _PrayerSettingsScreenState extends State<PrayerSettingsScreen> {
  int _diagnosticTapCount = 0;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final l10n = AppLocalizations.of(context)!;
        final isDark = theme == QuranTheme.dark;
        final bg = AppTheme.getScreenBgColor(theme);
        final cardBg = AppTheme.getCardBgColor(theme);
        final textColor = AppTheme.getMainTextColor(theme);
        final primary = AppTheme.getPrimaryColor(theme);

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            title: GestureDetector(
              onTap: () {
                _diagnosticTapCount++;
                if (_diagnosticTapCount >= 5) {
                  _diagnosticTapCount = 0;
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosticScreen()));
                }
              },
              child: Text(l10n.prayerSettingsTitle),
            ),
            backgroundColor: AppTheme.getAppBarBgColor(theme),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: AnimatedBuilder(
            animation: widget.controller,
            builder: (context, _) {
              final ctrl = widget.controller;
              final cfg = ctrl.config;
              final currentMuezzinId = cfg.prayerMuezzins['fajr'] ?? 'adhan_abdulbasit';

              Widget sectionHeader(String label, IconData icon) => Padding(
                padding: const EdgeInsets.only(top: 32, bottom: 16, left: 24, right: 24),
                child: Row(
                  children: [
                    Icon(icon, color: primary, size: 22),
                    const SizedBox(width: 12),
                    Text(
                      label.toUpperCase(),
                      style: AppTextStyles.labelLarge.copyWith(
                        color: primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              );

              Widget settingsCard({required Widget child}) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: child,
                );
              }

              return ListView(
                padding: const EdgeInsets.only(bottom: 60),
                children: [
                  // ── Premium Muezzin Selection ──────────────────────────────
                  sectionHeader('Muezzin Voice', Icons.record_voice_over_rounded),
                  settingsCard(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: Icon(Icons.person_search_rounded, color: primary),
                      ),
                      title: Text('Select Muezzin', style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                      subtitle: Text('Premium voices & downloads', style: AppTextStyles.labelSmall.copyWith(color: textColor.withValues(alpha: 0.6))),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MuezzinSelectionScreen(controller: widget.controller)),
                        );
                      },
                    ),
                  ),

                  // ── Calculation ───────────────────────────────────────────
                  sectionHeader(l10n.calcMethod, Icons.calculate_rounded),
                  settingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Auto-detect Location (GPS)',
                              style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                          activeThumbColor: Colors.white,
                          activeTrackColor: primary,
                          value: cfg.useGps,
                          onChanged: (val) {
                            ctrl.updateConfig(cfg.copyWith(useGps: val));
                            if (val) ctrl.syncLocation();
                          },
                        ),
                        const Divider(),
                        const SizedBox(height: 12),
                        Text('Calculation Method', style: AppTextStyles.labelLarge.copyWith(color: textColor.withValues(alpha: 0.6))),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black12 : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<CalculationMethodEnum>(
                              value: cfg.method,
                              dropdownColor: cardBg,
                              isExpanded: true,
                              style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.w600),
                              icon: Icon(Icons.expand_more_rounded, color: primary),
                              onChanged: (val) {
                                if (val != null) ctrl.changeMethod(val);
                              },
                              items: CalculationMethodEnum.values.map((method) {
                                final label = Localizations.localeOf(context).languageCode == 'ar' ? method.labelAr : method.labelEn;
                                return DropdownMenuItem(value: method, child: Text(label));
                              }).toList(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(l10n.madhab, style: AppTextStyles.labelLarge.copyWith(color: textColor.withValues(alpha: 0.6))),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black12 : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<MadhabEnum>(
                              value: cfg.madhab,
                              dropdownColor: cardBg,
                              isExpanded: true,
                              style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.w600),
                              icon: Icon(Icons.expand_more_rounded, color: primary),
                              onChanged: (val) {
                                if (val != null) ctrl.changeMadhab(val);
                              },
                              items: MadhabEnum.values.map((m) {
                                final label = Localizations.localeOf(context).languageCode == 'ar' ? m.labelAr : m.labelEn;
                                return DropdownMenuItem(value: m, child: Text(label));
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Display & General ───────────────────────────────────────────────
                  sectionHeader('General', Icons.tune_rounded),
                  settingsCard(
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('24-Hour Clock', style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                          activeThumbColor: Colors.white,
                          activeTrackColor: primary,
                          value: cfg.is24HourFormat,
                          onChanged: (val) {
                            ctrl.updateConfig(cfg.copyWith(is24HourFormat: val));
                          },
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hijri Date Offset', style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('Adjust to match your local moon sighting', style: AppTextStyles.labelSmall.copyWith(color: textColor.withValues(alpha: 0.6))),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(5, (i) {
                                  final val = i - 2;
                                  final isSelected = cfg.hijriOffset == val;
                                  return GestureDetector(
                                    onTap: () => ctrl.updateConfig(cfg.copyWith(hijriOffset: val)),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: isSelected ? primary : (isDark ? Colors.black12 : Colors.grey[50]),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isSelected ? primary : (isDark ? Colors.white12 : Colors.black12),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        val == 0 ? '0' : (val > 0 ? '+$val' : '$val'),
                                        style: TextStyle(
                                          color: isSelected ? Colors.white : textColor,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Prayer Adjustments ────────────────────────────────────
                  sectionHeader('Time Adjustments', Icons.schedule_rounded),
                  settingsCard(
                    child: Column(
                      children: ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'].map((key) {
                        final offsetVal = cfg.prayerOffsets[key] ?? 0;
                        final prayerLabel = key[0].toUpperCase() + key.substring(1);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text(prayerLabel, style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.w600))
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 4,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                                  ),
                                  child: Slider(
                                    value: offsetVal.toDouble(),
                                    min: -30,
                                    max: 30,
                                    divisions: 60,
                                    activeColor: primary,
                                    inactiveColor: primary.withValues(alpha: 0.15),
                                    onChanged: (val) {
                                      final newOffsets = Map<String, int>.from(cfg.prayerOffsets)..['key'] = val.round();
                                      ctrl.updateConfig(cfg.copyWith(prayerOffsets: newOffsets));
                                    },
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 40,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: offsetVal != 0 ? primary.withValues(alpha: 0.1) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    offsetVal == 0 ? '0' : (offsetVal > 0 ? '+$offsetVal' : '$offsetVal'),
                                    style: TextStyle(
                                      color: offsetVal != 0 ? primary : textColor.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.bold
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // ── Advanced ──────────────────────────────────────────────
                  sectionHeader('Advanced', Icons.admin_panel_settings_rounded),
                  settingsCard(
                    child: Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: Icon(Icons.play_circle_fill_rounded, color: primary, size: 20),
                          ),
                          title: Text('Test Full Adhan', style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                          subtitle: Text('Simulate exactly how the alarm plays', style: AppTextStyles.labelSmall.copyWith(color: textColor.withValues(alpha: 0.6))),
                          onTap: () async {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test Adhan will play in 2 seconds...')));
                            await Future.delayed(const Duration(seconds: 2));
                            // Trigger background callback immediately with ID 199
                            // We import android_alarm_manager_plus to call oneShot, or just call athanAlarmCallback directly
                            // Since we want to test background isolate, we'll schedule a 1-second alarm
                            await AndroidAlarmManager.oneShot(
                              const Duration(seconds: 1),
                              199,
                              athanAlarmCallback,
                              exact: true,
                              wakeup: true,
                              allowWhileIdle: true,
                            );
                          },
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.emeraldLight.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: const Icon(Icons.security_rounded, color: AppColors.emeraldLight, size: 20),
                          ),
                          title: Text('Permissions Setup Guide', style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                          subtitle: Text('Ensure Athan plays in background', style: AppTextStyles.labelSmall.copyWith(color: textColor.withValues(alpha: 0.6))),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const PermissionsSetupScreen()));
                          },
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                            child: Icon(Icons.sync_rounded, color: primary, size: 20),
                          ),
                          title: Text('Force Sync Time & Location', style: AppTextStyles.bodyMedium.copyWith(color: textColor, fontWeight: FontWeight.bold)),
                          subtitle: Text('Recalculate all prayer times now', style: AppTextStyles.labelSmall.copyWith(color: textColor.withValues(alpha: 0.6))),
                          onTap: () {
                            ctrl.syncLocation();
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Syncing location...')));
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

