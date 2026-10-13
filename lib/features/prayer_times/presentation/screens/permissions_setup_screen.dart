import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../theme_notifier.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../services/permission_health_service.dart';
import '../../../../core/services/background_engine.dart';
import '../controllers/prayer_controller.dart';

class PermissionsSetupScreen extends StatefulWidget {
  final bool isModal;
  const PermissionsSetupScreen({super.key, this.isModal = false});

  /// Displays the unified permissions onboarding sheet as a luxury modal bottom sheet.
  static Future<void> showAsModal(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (_) => const FractionallySizedBox(
        heightFactor: 0.90,
        child: PermissionsSetupScreen(isModal: true),
      ),
    );
  }

  @override
  State<PermissionsSetupScreen> createState() => _PermissionsSetupScreenState();
}

class _PermissionsSetupScreenState extends State<PermissionsSetupScreen> {
  bool _hasLocation = false;
  bool _hasNotification = false;
  bool _hasExactAlarm = false;
  bool _hasBatteryIgnore = false;
  bool _hasDndAccess = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final notif = await Permission.notification.isGranted;
      final battery = await Permission.ignoreBatteryOptimizations.isGranted;
      final dnd = await Permission.accessNotificationPolicy.isGranted;

      bool exact = true;
      if (!kIsWeb && Platform.isAndroid) {
        exact = await Permission.scheduleExactAlarm.isGranted;
      }

      final loc = await Geolocator.checkPermission();
      final hasLoc = (loc == LocationPermission.always || loc == LocationPermission.whileInUse);

      if (mounted) {
        setState(() {
          _hasLocation = hasLoc;
          _hasNotification = notif;
          _hasExactAlarm = exact;
          _hasBatteryIgnore = battery;
          _hasDndAccess = dnd;
        });
      }
      PermissionHealthService.checkHealth();
    } catch (e) {
      debugPrint('[PermissionsSetupScreen] Error checking permissions: $e');
    }
  }

  Future<void> _requestLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      } else if (permission == LocationPermission.deniedForever) {
        await openAppSettings();
      }
      
      final granted = (permission == LocationPermission.always || permission == LocationPermission.whileInUse);
      if (mounted) {
        setState(() => _hasLocation = granted);
      }
      if (granted) {
        // Trigger silent background location resolution
        PrayerController().analyzeLocationInBackground();
      }
      PermissionHealthService.checkHealth();
    } catch (e) {
      debugPrint('[PermissionsSetupScreen] Location permission error: $e');
    }
  }

  Future<void> _requestNotification() async {
    try {
      final status = await Permission.notification.request();
      if (mounted) {
        setState(() => _hasNotification = status.isGranted);
      }
      PermissionHealthService.checkHealth();
    } catch (e) {
      debugPrint('[PermissionsSetupScreen] Notification permission error: $e');
    }
  }

  Future<void> _requestExactAlarm() async {
    try {
      final status = await Permission.scheduleExactAlarm.request();
      if (mounted) {
        setState(() => _hasExactAlarm = status.isGranted);
      }
      PermissionHealthService.checkHealth();
      if (status.isGranted) {
        await BackgroundEngine().scheduleIslamicReminders();
        final prefs = await SharedPreferences.getInstance();
        final int interval = prefs.getInt('notification_interval') ?? 60;
        await BackgroundEngine().scheduleZekrNotification(interval);
      }
    } catch (e) {
      debugPrint('[PermissionsSetupScreen] Exact alarm permission error: $e');
    }
  }

  Future<void> _requestBattery() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      if (mounted) {
        setState(() => _hasBatteryIgnore = status.isGranted);
      }
      PermissionHealthService.checkHealth();
    } catch (e) {
      debugPrint('[PermissionsSetupScreen] Battery optimization permission error: $e');
    }
  }

  Future<void> _requestDnd() async {
    try {
      final status = await Permission.accessNotificationPolicy.request();
      if (mounted) {
        setState(() => _hasDndAccess = status.isGranted);
      }
      if (status.isGranted) {
        await PrayerController().toggleAutoSilent(true);
      }
      PermissionHealthService.checkHealth();
    } catch (e) {
      debugPrint('[PermissionsSetupScreen] DND permission error: $e');
    }
  }

  Future<void> _onFinish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permissions_onboarding_completed', true);
    await PermissionHealthService.checkHealth();
    if (mounted) {
      Navigator.pop(context);
    }
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
        final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';

        final allGranted = _hasLocation &&
            _hasNotification &&
            _hasBatteryIgnore &&
            _hasExactAlarm &&
            _hasDndAccess;

        final content = SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              if (widget.isModal)
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                ),
              Icon(
                Icons.mosque_rounded,
                size: 64,
                color: primary.withValues(alpha: 0.85),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.neverMissPrayer,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.setupGuideDescription,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: textColor.withValues(alpha: 0.72),
                  height: 1.45,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 28),

              // 1. Location Permission
              _PermissionCard(
                title: locale == 'ar'
                    ? 'الموقع الجغرافي'
                    : (locale == 'am'
                        ? 'የአካባቢ ፈቃድ'
                        : (locale == 'om' ? 'Bakka' : 'Location')),
                subtitle: locale == 'ar'
                    ? 'لحساب مواقيت الصلاة والقبلة تلقائياً (تتوفر إمكانية الاختيار اليدوي)'
                    : (locale == 'am'
                        ? 'የሶላት ጊዜያትን እና የቂብላ አቅጣጫን በራስ-ሰር ለማስላት'
                        : (locale == 'om'
                            ? 'Yeroo salaataafi Qiblaa ofumaan herreguuf'
                            : 'Calculate accurate prayer times and Qibla direction')),
                icon: Icons.my_location_rounded,
                isGranted: _hasLocation,
                onRequest: _requestLocation,
                theme: theme,
              ),
              const SizedBox(height: 14),

              // 2. Notification Permission
              _PermissionCard(
                title: l10n.notificationsTitle,
                subtitle: l10n.notificationsSubtitle,
                icon: Icons.notifications_active_rounded,
                isGranted: _hasNotification,
                onRequest: _requestNotification,
                theme: theme,
              ),
              const SizedBox(height: 14),

              // 3. Background Battery Optimization (Crucial for Adhan!)
              _PermissionCard(
                title: l10n.backgroundExecution,
                subtitle: l10n.batteryOptimizationSubtitle,
                icon: Icons.battery_charging_full_rounded,
                isGranted: _hasBatteryIgnore,
                onRequest: _requestBattery,
                theme: theme,
              ),
              const SizedBox(height: 14),

              // 4. Exact Alarms (Android only)
              if (!kIsWeb && Platform.isAndroid) ...[
                _PermissionCard(
                  title: l10n.exactAlarmsTitle,
                  subtitle: l10n.notificationAlarmRequired,
                  icon: Icons.alarm_on_rounded,
                  isGranted: _hasExactAlarm,
                  onRequest: _requestExactAlarm,
                  theme: theme,
                ),
                const SizedBox(height: 14),
              ],

              // 5. Do Not Disturb Access (Auto-Silent mode)
              if (!kIsWeb && Platform.isAndroid) ...[
                _PermissionCard(
                  title: locale == 'ar'
                      ? 'وضع الصامت في المسجد'
                      : (locale == 'am'
                          ? 'በመስጂድ ውስጥ ድምፅ አልባ ሁነታ'
                          : (locale == 'om'
                              ? 'Moosqii Keessatti Sagalee Dhabamsiisuu'
                              : 'Auto-Silent (DND)')),
                  subtitle: locale == 'ar'
                      ? 'كتم صوت الهاتف تلقائياً أثناء أوقات الصلاة في المسجد'
                      : (locale == 'am'
                          ? 'በሶላት ወቅት ስልክዎን በራስ-ሰር ድምፅ አልባ ለማድረግ'
                          : (locale == 'om'
                              ? 'Yeroo salaataatti bilbila sagalee dhabamsiisuuf'
                              : 'Automatically silence phone during prayers in the mosque')),
                  icon: Icons.do_not_disturb_on_rounded,
                  isGranted: _hasDndAccess,
                  onRequest: _requestDnd,
                  theme: theme,
                ),
                const SizedBox(height: 24),
              ],

              // Main Completion Button (Always accessible)
              ElevatedButton(
                onPressed: _onFinish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  allGranted
                      ? l10n.done
                      : (locale == 'ar'
                          ? 'متابعة وحفظ'
                          : (locale == 'am'
                              ? 'ቀጥል'
                              : (locale == 'om' ? 'Itti fufi' : 'Continue'))),
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );

        if (widget.isModal) {
          return Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: content,
          );
        }

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
          body: content,
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? AppColors.emeraldLight.withValues(alpha: 0.8)
              : (isDark ? Colors.white12 : Colors.black12),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isGranted
                  ? AppColors.emeraldLight.withValues(alpha: 0.15)
                  : primary.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isGranted ? Icons.check_circle_rounded : icon,
              color: isGranted ? AppColors.emeraldLight : primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: textColor.withValues(alpha: 0.65),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (!isGranted)
            TextButton(
              onPressed: onRequest,
              style: TextButton.styleFrom(
                foregroundColor: primary,
                backgroundColor: primary.withValues(alpha: 0.12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                l10n.allow,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }
}
