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

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

import '../main.dart';
import '../features/prayer_times/data/models/prayer_config.dart';
import '../features/prayer_times/data/models/prayer_time_model.dart';
import '../features/prayer_times/presentation/screens/prayer_times_screen.dart';
import '../features/prayer_times/presentation/controllers/prayer_controller.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // ── Initialization ─────────────────────────────────────────────────────────

  Future<void> init() async {
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload == 'prayer_times') {
          rootNavigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => PrayerTimesScreen(controller: PrayerController()),
            ),
          );
        }
      },
    );

    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();

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
    }

    // Schedule static Islamic reminders
    try {
      await scheduleIslamicReminders();
    } catch (_) {}
  }

  // ── Reminders (Islamic & Daily) ──────────────────────────────────────────

  Future<void> scheduleIslamicReminders() async {
    // 0: Daily Reminder
    // 10: Friday Kahf
    // 11: Monday Fasting
    // 12: Thursday Fasting
    await _plugin.cancel(0);
    await _plugin.cancel(10);
    await _plugin.cancel(11);
    await _plugin.cancel(12);

    final now = tz.TZDateTime.now(tz.local);

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
      channelDescription: 'Kahf, Fasting, and daily quotes',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(android: androidDetails);

    // 1. Daily Random Quote / Reminder (9:00 AM)
    tz.TZDateTime nextDaily =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0);
    if (nextDaily.isBefore(now)) {
      nextDaily = nextDaily.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(0, 'Daily Reminder',
        "Start your day with remembrance of Allah.", nextDaily, details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time);

    // 2. Friday Kahf (Friday 10:00 AM)
    await _plugin.zonedSchedule(
        10,
        'Jumuah Mubarak',
        "Don't forget to read Surah Al-Kahf today.",
        nextWeekday(DateTime.friday, 10, 0),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime);

    // 3. Monday Fasting (Sunday 8:00 PM to remind for tomorrow)
    await _plugin.zonedSchedule(
        11,
        'Sunnah Fasting',
        "Tomorrow is Monday. A great day to observe a Sunnah fast.",
        nextWeekday(DateTime.sunday, 20, 0),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime);

    // 4. Thursday Fasting (Wednesday 8:00 PM to remind for tomorrow)
    await _plugin.zonedSchedule(
        12,
        'Sunnah Fasting',
        "Tomorrow is Thursday. Don't forget the Sunnah fast if you are able.",
        nextWeekday(DateTime.wednesday, 20, 0),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime);
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
    for (int id = 100; id <= 105; id++) {
      await _plugin.cancel(id);
      await _plugin.cancel(id + 100);
    }
  }
}

// ── Internal value holder ─────────────────────────────────────────────────────
