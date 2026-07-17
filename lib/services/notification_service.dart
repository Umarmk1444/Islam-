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

    final androidImplementation = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();

      // Create the Adhan notification channel on Android 8+.
      await androidImplementation.createNotificationChannel(const AndroidNotificationChannel(
        'adhan_channel',
        'Adhan Prayer Alerts',
        description: 'High-priority alerts for each of the 5 daily prayers',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      ));
    }
  }

  // ── Daily Quran Reminder (existing) ───────────────────────────────────────

  Future<void> scheduleDailyNotification(int hour, int minute) async {
    await _plugin.cancel(0);

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Daily Quranic verses and reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    await _plugin.zonedSchedule(
      0,
      'Daily Reminder',
      "Don't forget to read your daily portion of the Quran.",
      scheduledDate,
      const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
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
      final muezzinId = config.prayerMuezzins[entry.prayer.name] ?? 'adhan_abdulbasit';
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
            final preAndroidDetails = const AndroidNotificationDetails(
              'pre_adhan_channel',
              'Pre-Adhan Warning',
              channelDescription: 'Notification before Adhan time',
              importance: Importance.high,
              priority: Priority.high,
              sound: RawResourceAndroidNotificationSound('salah'),
              playSound: true,
            );
            // ignore: deprecated_member_use
            await _plugin.zonedSchedule(
              slotId + 100, // 200-205 for pre-athan
              '⏳ اقتربت الصلاة',
              'باقي $preAthanMinutes دقائق على أذان ${_prayerNameDisplay(entry.prayer)}',
              preTzTime,
              NotificationDetails(android: preAndroidDetails),
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
      case PrayerName.fajr: return notif.fajrEnabled;
      case PrayerName.sunrise: return notif.sunriseEnabled;
      case PrayerName.dhuhr: return notif.dhuhrEnabled;
      case PrayerName.asr: return notif.asrEnabled;
      case PrayerName.maghrib: return notif.maghribEnabled;
      case PrayerName.isha: return notif.ishaEnabled;
      default: return false;
    }
  }

  /// Cancels only the Adhan and Pre-Adhan notification IDs (100–105, 200-205)
  Future<void> cancelAdhanNotifications() async {
    for (int id = 100; id <= 105; id++) {
      await _plugin.cancel(id);
      await _plugin.cancel(id + 100);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _prayerNameDisplay(PrayerName prayer) {
    switch (prayer) {
      case PrayerName.fajr:    return 'Fajr';
      case PrayerName.sunrise: return 'Sunrise';
      case PrayerName.dhuhr:   return 'Dhuhr';
      case PrayerName.asr:     return 'Asr';
      case PrayerName.maghrib: return 'Maghrib';
      case PrayerName.isha:    return 'Isha';
      default:                 return prayer.name;
    }
  }
}

// ── Internal value holder ─────────────────────────────────────────────────────

