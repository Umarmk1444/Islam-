// lib/services/notification_service.dart
// ─────────────────────────────────────────────────────────────────────────────
// NotificationService — singleton managing all local notifications.
//
// Channels:
//   • 'daily_reminder_channel' — existing daily Quran verses
//   • 'adhan_channel'          — high-priority prayer-time alerts (NEW)
//
// Notification ID allocation:
//   0          — daily reminder (existing)
//   100–105    — Adhan alerts: Fajr=100, Sunrise=101, Dhuhr=102,
//                              Asr=103, Maghrib=104, Isha=105
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../main.dart';
import '../features/prayer_times/data/models/prayer_config.dart';
import '../features/prayer_times/data/models/prayer_time_model.dart';
import '../features/prayer_times/presentation/screens/prayer_times_screen.dart';
import '../features/prayer_times/presentation/controllers/prayer_controller.dart';
import '../screens/azkar_screen.dart';
import '../screens/quran_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<void> init() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;

    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final actionId = response.actionId;
        final payload = response.payload;
        final target = (actionId != null && actionId.isNotEmpty) ? actionId : payload;
        if (target != null) {
          if (target == 'app_update') {
            final url = Uri.parse('https://play.google.com/store/apps/details?id=com.umer.quranzone');
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          } else {
            _navigatePayload(target);
          }
        }
      },
    );

    // If app was launched from terminated state by tapping a notification
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
      final res = launchDetails.notificationResponse;
      final target = (res?.actionId != null && res!.actionId!.isNotEmpty) ? res.actionId : res?.payload;
      if (target != null && target.isNotEmpty) {
        _navigatePayload(target);
      }
    }

    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      // Create the Adhan notification channel on Android 8+.
      await androidImplementation
          .createNotificationChannel(const AndroidNotificationChannel(
        'adhan_channel',
        'Adhan Prayer Alerts',
        description: 'High-priority alerts for each of the 5 daily prayers',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ));

      // Create the App Updates notification channel on Android 8+.
      await androidImplementation
          .createNotificationChannel(const AndroidNotificationChannel(
        'app_updates_channel',
        'App Updates',
        description: 'Notifications for new Quran Zone releases and features',
        importance: Importance.high,
      ));
    }

    // Schedule static Islamic reminders
    try {
      await scheduleIslamicReminders();
    } catch (_) {}
  }

  /// Explicitly request notification permissions when called in staged sequence
  Future<bool> requestPermission() async {
    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  // ── Reminders (Islamic & Daily) ──────────────────────────────────────────

  Future<void> scheduleIslamicReminders() async {
    // Cancel prior Sunnah reminder IDs
    await _plugin.cancel(1); // Morning Adhkar
    await _plugin.cancel(2); // Duha Prayer
    await _plugin.cancel(3); // Evening Adhkar
    await _plugin.cancel(4); // Sleep Adhkar
    await _plugin.cancel(10); // Friday Kahf
    await _plugin.cancel(11); // Monday Fasting
    await _plugin.cancel(12); // Thursday Fasting

    final now = tz.TZDateTime.now(tz.local);

    // Helper to find next occurrence of a daily time
    tz.TZDateTime nextDailyTime(int hour, int minute) {
      tz.TZDateTime scheduled =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      return scheduled;
    }

    // Helper to find next occurrence of a weekday
    tz.TZDateTime nextWeekday(int weekday, int hour, int minute) {
      tz.TZDateTime scheduled =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      while (scheduled.weekday != weekday || scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      return scheduled;
    }

    const androidDetails = AndroidNotificationDetails(
      'islamic_reminders_channel',
      'Islamic Reminders',
      channelDescription: 'Morning, Evening, Duha, Sleep, and Sunnah reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
    );
    const details = NotificationDetails(android: androidDetails);

    // 1. أذكار الصباح (7:00 AM daily)
    await _plugin.zonedSchedule(
      1,
      '🌅 أذكار الصباح',
      'أصبحنا وأصبح الملك لله والحمد لله.. حان وقت أذكار الصباح لحفظك وبركة يومك',
      nextDailyTime(7, 0),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'morning_azkar',
    );

    // 2. صلاة الضحى (9:30 AM daily)
    await _plugin.zonedSchedule(
      2,
      '☀️ صلاة الضحى (صلاة الأوابين)',
      'ركعتا الضحى صدقة عن كل مفصل في جسدك، لا تفوت أجرها العظيم',
      nextDailyTime(9, 30),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'duha_prayer',
    );

    // 3. أذكار المساء (5:00 PM daily)
    await _plugin.zonedSchedule(
      3,
      '🌇 أذكار المساء',
      'أمسينا وأمسى الملك لله والحمد لله.. حصّن نفسك وأهلك بأذكار المساء',
      nextDailyTime(17, 0),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'evening_azkar',
    );

    // 4. أذكار النوم وسورة الملك (10:00 PM daily)
    await _plugin.zonedSchedule(
      4,
      '🌙 أذكار النوم وسورة الملك',
      'باسمك ربي وضعت جنبي وبك أرفعه.. اختم يومك بذكر الله وتلاوة سورة الملك المنجية',
      nextDailyTime(22, 0),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'sleep_azkar',
    );

    // 5. Friday Kahf (Friday 10:00 AM)
    await _plugin.zonedSchedule(
      10,
      '🕌 جمعة مباركة: سورة الكهف والصلاة على النبي ﷺ',
      'نور ما بين الجمعتين.. أكثروا من الصلاة على الحبيب المصطفى ﷺ واقرؤوا سورة الكهف',
      nextWeekday(DateTime.friday, 10, 0),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      payload: 'friday_kahf',
    );

    // 6. Monday Fasting (Sunday 8:00 PM)
    await _plugin.zonedSchedule(
      11,
      '🌿 صيام الاثنين المبارك',
      'غداً الاثنين يُستحب صيامه، تُعرض فيه الأعمال على الله عز وجل',
      nextWeekday(DateTime.sunday, 20, 0),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );

    // 7. Thursday Fasting (Wednesday 8:00 PM)
    await _plugin.zonedSchedule(
      12,
      '🌿 صيام الخميس المبارك',
      'غداً الخميس يُستحب صيامه، لا تفوت أجر الصيام وعظيم الثواب',
      nextWeekday(DateTime.wednesday, 20, 0),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancelNotifications() async {
    await _plugin.cancelAll();
  }

  // ── Adhan Alert Scheduling ─────────────────────────────────────────────────

  /// Schedules up to 6 exact-time Adhan alerts for the upcoming prayer schedule.
  /// Only schedules prayers that:
  ///   1. Have notifications enabled in [config].
  ///   2. Are still in the future.
  ///
  /// Existing Adhan notifications (IDs 100–105) are cancelled first to avoid
  /// duplicates across recomputes.
  Future<void> scheduleAdhanNotifications(
    List<PrayerTimeEntry> entries,
    PrayerConfig config,
  ) async {
    // Single source of truth: delegate to BackgroundEngine to avoid dual scheduling
    await cancelAdhanNotifications();
  }

  /// Cancels only the Adhan and Pre-Adhan notification IDs (100–105, 200-205)
  Future<void> cancelAdhanNotifications() async {
    try {
      for (int id = 100; id <= 105; id++) {
        try {
          await _plugin.cancel(id);
        } catch (_) {}
        try {
          await _plugin.cancel(id + 100);
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[NotificationService] cancelAdhanNotifications error: $e');
    }
  }

  /// Shows a rich notification informing the user of a new app update on Google Play.
  Future<void> showUpdateNotification({
    required String version,
    required String releaseNotes,
    String? title,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'app_updates_channel',
      'App Updates',
      channelDescription: 'Notifications for new Quran Zone releases and features',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        releaseNotes.isNotEmpty
            ? releaseNotes
            : 'A new version of Quran Zone ($version) is available with the latest features and improvements.',
      ),
    );
    final details = NotificationDetails(android: androidDetails);

    final notifTitle = title ?? '🎉 New Update Available (v$version)';
    final body = releaseNotes.isNotEmpty
        ? releaseNotes
        : 'A new version of Quran Zone is available on Google Play!';

    await _plugin.show(
      9999,
      notifTitle,
      body,
      details,
      payload: 'app_update',
    );
  }

  void _navigatePayload(String target, [int attempts = 0]) {
    final navigator = rootNavigatorKey.currentState;
    if (navigator != null && navigator.mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (target == 'morning_azkar' || target == 'open_morning') {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => const AzkarScreen(initialCategory: 'الصباح'),
            ),
          );
        } else if (target == 'evening_azkar' || target == 'open_evening') {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => const AzkarScreen(initialCategory: 'المساء'),
            ),
          );
        } else if (target == 'sleep_azkar' || target == 'open_sleep') {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => const AzkarScreen(initialCategory: 'النوم'),
            ),
          );
        } else if (target == 'friday_kahf') {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => const QuranScreen(initialPage: 293),
            ),
          );
        } else if (target == 'duha_prayer' || target == 'prayer_times') {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => PrayerTimesScreen(controller: PrayerController()),
            ),
          );
        } else if (target == 'periodic_dhikr' || target == 'azkar_general') {
          navigator.push(
            MaterialPageRoute(
              builder: (_) => const AzkarScreen(),
            ),
          );
        }
      });
    } else if (attempts < 25) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _navigatePayload(target, attempts + 1);
      });
    }
  }
}

// ── Internal value holder ─────────────────────────────────────────────────────
