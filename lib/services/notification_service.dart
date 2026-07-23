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

import '../features/prayer_times/data/models/prayer_config.dart';
import '../features/prayer_times/data/models/prayer_time_model.dart';

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
        debugPrint('Notification clicked: ${response.payload}');
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
    // Cancel existing Adhan alerts before rescheduling.
    await cancelAdhanNotifications();

    final notif = config.notifications;
    final now = DateTime.now();

    final Map<PrayerName, int> baseIds = {
      PrayerName.fajr: 100,
      PrayerName.sunrise: 101,
      PrayerName.dhuhr: 102,
      PrayerName.asr: 103,
      PrayerName.maghrib: 104,
      PrayerName.isha: 105,
    };

    for (final entry in entries) {
      if (!baseIds.containsKey(entry.prayer)) continue;

      final isEnabled = _isNotifEnabledForPrayer(entry.prayer, notif);
      if (!isEnabled || entry.time.isBefore(now)) continue;

      final slotId = baseIds[entry.prayer]!;
      final tzTime = tz.TZDateTime.from(entry.time, tz.local);
      final muezzinId =
          config.prayerMuezzins[entry.prayer.name] ?? 'adhan_abdulbasit';
      final soundName = muezzinId;

      final androidDetails = AndroidNotificationDetails(
        'adhan_channel_$muezzinId',
        'Adhan - ${_prayerNameDisplay(entry.prayer)}',
        channelDescription: 'High-priority Athan alert',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(soundName),
        playSound: true,
        ticker: 'Prayer time',
        styleInformation: const BigTextStyleInformation(''),
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
      );

      try {
        // ignore: deprecated_member_use
        await _plugin.zonedSchedule(
          slotId,
          '🕌 ${_prayerNameDisplay(entry.prayer)}',
          'حان الآن موعد أذان ${_prayerNameDisplay(entry.prayer)}',
          tzTime,
          NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: entry.prayer.name,
        );

        // Schedule Pre-Athan Alert if enabled for this specific prayer
        final preAthanMinutes = config.preAthanMinutes[entry.prayer.name] ?? 0;
        if (preAthanMinutes > 0) {
          final preTzTime = tzTime.subtract(Duration(minutes: preAthanMinutes));
          if (preTzTime.isAfter(now)) {
            const preAndroidDetails = AndroidNotificationDetails(
              'pre_adhan_channel_v2',
              'Pre-Adhan Warning',
              channelDescription: 'Notification before Adhan time',
              importance: Importance.high,
              priority: Priority.high,
              sound: RawResourceAndroidNotificationSound('salah'),
              playSound: true,
              category: AndroidNotificationCategory.alarm,
              audioAttributesUsage: AudioAttributesUsage.alarm,
              visibility: NotificationVisibility.public,
            );
            // ignore: deprecated_member_use
            await _plugin.zonedSchedule(
              slotId + 100, // 200-205 for pre-athan
              '⏳ اقتربت الصلاة',
              'باقي $preAthanMinutes دقائق على أذان ${_prayerNameDisplay(entry.prayer)}',
              preTzTime,
              const NotificationDetails(android: preAndroidDetails),
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              payload: 'pre_${entry.prayer.name}',
            );
          }
        }
      } catch (_) {
        // Exact alarm permission may not be granted; skip silently.
      }
    }
  }

  bool _isNotifEnabledForPrayer(PrayerName prayer, PrayerNotifConfig notif) {
    switch (prayer) {
      case PrayerName.fajr:
        return notif.fajrEnabled;
      case PrayerName.sunrise:
        return notif.sunriseEnabled;
      case PrayerName.dhuhr:
        return notif.dhuhrEnabled;
      case PrayerName.asr:
        return notif.asrEnabled;
      case PrayerName.maghrib:
        return notif.maghribEnabled;
      case PrayerName.isha:
        return notif.ishaEnabled;
      default:
        return false;
    }
  }

  /// Cancels only the Adhan and Pre-Adhan notification IDs (100–105, 200-205)
  Future<void> cancelAdhanNotifications() async {
    for (int id = 100; id <= 105; id++) {
      await _plugin.cancel(id);
      await _plugin.cancel(id + 100);
    }
  }

  // ── Testing Tools ─────────────────────────────────────────────────────────

  Future<void> testAdhanNotification(String muezzinId) async {
    final now = DateTime.now();
    final tzTime = tz.TZDateTime.from(now.add(const Duration(seconds: 5)), tz.local);
    final soundName = muezzinId;

    final androidDetails = AndroidNotificationDetails(
      'adhan_channel_test_$muezzinId',
      'Test Adhan',
      channelDescription: 'High-priority Athan alert test',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(soundName),
      playSound: true,
      ticker: 'Prayer time test',
      styleInformation: const BigTextStyleInformation(''),
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
    );

    // ignore: deprecated_member_use
    await _plugin.zonedSchedule(
      999, // Debug ID
      '🕌 Test Adhan',
      'This is a test adhan exactly 5s from tap.',
      tzTime,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'test_adhan',
    );
  }

  Future<void> testPreAdhanNotification() async {
    final now = DateTime.now();
    final preTzTime = tz.TZDateTime.from(now.add(const Duration(seconds: 5)), tz.local);

    const preAndroidDetails = AndroidNotificationDetails(
      'pre_adhan_channel_test',
      'Test Pre-Adhan Warning',
      channelDescription: 'Notification before Adhan time test',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('salah'),
      playSound: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      visibility: NotificationVisibility.public,
    );

    // ignore: deprecated_member_use
    await _plugin.zonedSchedule(
      998, // Debug ID
      '⏳ Test Pre-Adhan',
      'This is a test pre-adhan warning 5s from tap.',
      preTzTime,
      const NotificationDetails(android: preAndroidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'test_pre_adhan',
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _prayerNameDisplay(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:
        return 'Fajr';
      case PrayerName.sunrise:
        return 'Sunrise';
      case PrayerName.dhuhr:
        return 'Dhuhr';
      case PrayerName.asr:
        return 'Asr';
      case PrayerName.maghrib:
        return 'Maghrib';
      case PrayerName.isha:
        return 'Isha';
      default:
        return prayer.name;
    }
  }
}

// ── Internal value holder ─────────────────────────────────────────────────────
