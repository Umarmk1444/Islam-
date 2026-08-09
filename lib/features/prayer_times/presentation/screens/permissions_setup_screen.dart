import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../theme_notifier.dart';
import '../../../../l10n/app_localizations.dart';

class PermissionsSetupScreen extends StatefulWidget {
  const PermissionsSetupScreen({super.key});

  @override
  State<PermissionsSetupScreen> createState() => _PermissionsSetupScreenState();
}

class _PermissionsSetupScreenState extends State<PermissionsSetupScreen> {
  bool _hasNotification = false;
  bool _hasExactAlarm = false;
  bool _hasBatteryIgnore = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final notif = await Permission.notification.isGranted;
    final exact = await Permission.scheduleExactAlarm.isGranted;
    final battery = await Permission.ignoreBatteryOptimizations.isGranted;

    if (mounted) {
      setState(() {
        _hasNotification = notif;
        _hasExactAlarm = exact;
        _hasBatteryIgnore = battery;
      });
    }
  }

  Future<void> _requestNotification() async {
    final status = await Permission.notification.request();
    setState(() => _hasNotification = status.isGranted);
  }

  Future<void> _requestExactAlarm() async {
    final status = await Permission.scheduleExactAlarm.request();
    setState(() => _hasExactAlarm = status.isGranted);
  }

  Future<void> _requestBattery() async {
    final status = await Permission.ignoreBatteryOptimizations.request();
    setState(() => _hasBatteryIgnore = status.isGranted);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final l10n = AppLocalizations.of(context)!;
        final isDark = theme == QuranTheme.dark;
        final bg = AppTheme.getScreenBgColor(theme);
        final textColor = AppTheme.getMainTextColor(theme);
        final primary = AppTheme.getPrimaryColor(theme);

        final allGranted =
            _hasNotification && _hasExactAlarm && _hasBatteryIgnore;

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            title: Text(l10n.setupGuide),
            backgroundColor: AppTheme.getAppBarBgColor(theme),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                Icon(
                  Icons.mosque_rounded,
                  size: 80,
                  color: primary.withValues(alpha: 0.8),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.neverMissPrayer,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.headlineMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.setupGuideDescription,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textColor.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),

                // 1. Notification
                _PermissionCard(
                  title: l10n.notificationsTitle,
                  subtitle: l10n.notificationsSubtitle,
                  icon: Icons.notifications_active_rounded,
                  isGranted: _hasNotification,
                  onRequest: _requestNotification,
                  theme: theme,
                ),
                const SizedBox(height: 16),

                // 2. Exact Alarms
                _PermissionCard(
                  title: l10n.exactAlarmsTitle,
                  subtitle: l10n.notificationAlarmRequired,
                  icon: Icons.alarm_on_rounded,
                  isGranted: _hasExactAlarm,
                  onRequest: _requestExactAlarm,
                  theme: theme,
                ),
                const SizedBox(height: 16),

                // 3. Battery Optimization
                _PermissionCard(
                  title: l10n.backgroundExecution,
                  subtitle:
                      l10n.batteryOptimizationSubtitle,
                  icon: Icons.battery_charging_full_rounded,
                  isGranted: _hasBatteryIgnore,
                  onRequest: _requestBattery,
                  theme: theme,
                ),

                const SizedBox(height: 40),

                ElevatedButton(
                  onPressed: allGranted ? () => Navigator.pop(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    disabledBackgroundColor:
                        isDark ? Colors.white12 : Colors.black12,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    allGranted ? l10n.done : l10n.completeSetupAbove,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: allGranted
                          ? Colors.white
                          : textColor.withValues(alpha: 0.5),
                      fontWeight: FontWeight.bold,
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

class _PermissionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isGranted;
  final VoidCallback onRequest;
  final QuranTheme theme;

  const _PermissionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isGranted,
    required this.onRequest,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = theme == QuranTheme.dark;
    final cardBg = AppTheme.getCardBgColor(theme);
    final textColor = AppTheme.getMainTextColor(theme);
    final primary = AppTheme.getPrimaryColor(theme);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? AppColors.emeraldLight
              : (isDark ? Colors.white12 : Colors.black12),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isGranted
                  ? AppColors.emeraldLight.withValues(alpha: 0.1)
                  : primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGranted ? Icons.check_circle_rounded : icon,
              color: isGranted ? AppColors.emeraldLight : primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (!isGranted)
            TextButton(
              onPressed: onRequest,
              style: TextButton.styleFrom(
                foregroundColor: primary,
                backgroundColor: primary.withValues(alpha: 0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(l10n.allow),
            ),
        ],
      ),
    );
  }
}
