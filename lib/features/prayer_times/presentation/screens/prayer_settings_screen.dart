import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../theme_notifier.dart';
import '../../data/models/prayer_config.dart';
import '../controllers/prayer_controller.dart';
import 'permissions_setup_screen.dart';

class PrayerSettingsScreen extends StatefulWidget {
  const PrayerSettingsScreen({super.key, required this.controller});
  final PrayerController controller;

  @override
  State<PrayerSettingsScreen> createState() => _PrayerSettingsScreenState();
}

class _PrayerSettingsScreenState extends State<PrayerSettingsScreen> {
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
            title: Text(l10n.prayerSettingsTitle),
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

              Widget sectionHeader(String label, IconData icon) => Padding(
                    padding: const EdgeInsets.only(
                        top: 24, bottom: 12, left: 16, right: 16),
                    child: Row(
                      children: [
                        Icon(icon, color: primary, size: 20),
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

              Widget settingsCard({required Widget child}) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12),
                  ),
                  child: child,
                );
              }

              return ListView(
                padding: const EdgeInsets.only(bottom: 40),
                children: [
                  // ── Display ───────────────────────────────────────────────
                  sectionHeader('Display', Icons.tune_rounded),
                  settingsCard(
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('24-Hour Clock',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: textColor)),
                          activeThumbColor: primary,
                          value: cfg.is24HourFormat,
                          onChanged: (val) {
                            ctrl.updateConfig(
                                cfg.copyWith(is24HourFormat: val));
                          },
                        ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hijri Date Offset',
                                  style: AppTextStyles.bodyMedium
                                      .copyWith(color: textColor)),
                              const SizedBox(height: 4),
                              Text('Adjust to match your local moon sighting',
                                  style: AppTextStyles.labelSmall.copyWith(
                                      color: textColor.withValues(alpha: 0.6))),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (i) {
                                  final val = i - 2;
                                  final isSelected = cfg.hijriOffset == val;
                                  return GestureDetector(
                                    onTap: () => ctrl.updateConfig(
                                        cfg.copyWith(hijriOffset: val)),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 180),
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 4),
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
                                                    : Colors.black12)),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        val == 0
                                            ? '0'
                                            : (val > 0 ? '+$val' : '$val'),
                                        style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : textColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13),
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

                  // ── Calculation ───────────────────────────────────────────
                  sectionHeader(l10n.calcMethod, Icons.calculate_rounded),
                  settingsCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('Auto-detect Location (GPS)',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: textColor)),
                          activeThumbColor: primary,
                          value: cfg.useGps,
                          onChanged: (val) {
                            ctrl.updateConfig(cfg.copyWith(useGps: val));
                            if (val) ctrl.syncLocation();
                          },
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text('Calculation Method',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: textColor)),
                        DropdownButton<CalculationMethodEnum>(
                          value: cfg.method,
                          dropdownColor: cardBg,
                          isExpanded: true,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: textColor),
                          onChanged: (val) {
                            if (val != null) ctrl.changeMethod(val);
                          },
                          items: CalculationMethodEnum.values.map((method) {
                            final label =
                                Localizations.localeOf(context).languageCode ==
                                        'ar'
                                    ? method.labelAr
                                    : method.labelEn;
                            return DropdownMenuItem(
                                value: method, child: Text(label));
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        Text(l10n.madhab,
                            style: AppTextStyles.labelLarge
                                .copyWith(color: textColor)),
                        DropdownButton<MadhabEnum>(
                          value: cfg.madhab,
                          dropdownColor: cardBg,
                          isExpanded: true,
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: textColor),
                          onChanged: (val) {
                            if (val != null) ctrl.changeMadhab(val);
                          },
                          items: MadhabEnum.values.map((m) {
                            final label =
                                Localizations.localeOf(context).languageCode ==
                                        'ar'
                                    ? m.labelAr
                                    : m.labelEn;
                            return DropdownMenuItem(
                                value: m, child: Text(label));
                          }).toList(),
                        ),
                      ],
                    ),
                  ),

                  // ── Prayer Adjustments ────────────────────────────────────
                  sectionHeader('Prayer Adjustments', Icons.schedule_rounded),
                  settingsCard(
                    child: Column(
                      children: [
                        'fajr',
                        'sunrise',
                        'dhuhr',
                        'asr',
                        'maghrib',
                        'isha'
                      ].map((key) {
                        final offsetVal = cfg.prayerOffsets[key] ?? 0;
                        final prayerLabel =
                            key[0].toUpperCase() + key.substring(1);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              SizedBox(
                                  width: 72,
                                  child: Text(prayerLabel,
                                      style: AppTextStyles.bodyMedium
                                          .copyWith(color: textColor))),
                              Expanded(
                                child: Slider(
                                  value: offsetVal.toDouble(),
                                  min: -30,
                                  max: 30,
                                  divisions: 60,
                                  activeColor: primary,
                                  inactiveColor: primary.withValues(alpha: 0.2),
                                  onChanged: (val) {
                                    final newOffsets =
                                        Map<String, int>.from(cfg.prayerOffsets)
                                          ..[key] = val.round();
                                    ctrl.updateConfig(cfg.copyWith(
                                        prayerOffsets: newOffsets));
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
                                      color:
                                          offsetVal != 0 ? primary : textColor,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.right,
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
                          leading: Icon(Icons.security_rounded, color: primary),
                          title: Text('Permissions Setup Guide',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: textColor)),
                          subtitle: Text('Ensure Athan plays in background',
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: textColor.withValues(alpha: 0.6))),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 16),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const PermissionsSetupScreen()));
                          },
                        ),
                        const Divider(),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.sync_rounded, color: primary),
                          title: Text('Force Sync Time & Location',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: textColor)),
                          subtitle: Text('Recalculate all prayer times now',
                              style: AppTextStyles.labelSmall.copyWith(
                                  color: textColor.withValues(alpha: 0.6))),
                          onTap: () {
                            ctrl.syncLocation();
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Syncing location...')));
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
