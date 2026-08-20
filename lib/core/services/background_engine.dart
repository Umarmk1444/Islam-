import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:path_provider/path_provider.dart';

import 'package:adhan/adhan.dart' as adhan;

import '../../features/prayer_times/data/models/prayer_config.dart';
import '../../features/prayer_times/data/models/prayer_time_model.dart';
import '../../features/prayer_times/data/services/muezzin_manager.dart';
import '../../services/azkar_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MethodChannel for native AlarmManager scheduling (main isolate only)
// ─────────────────────────────────────────────────────────────────────────────

const _kAthanAlarmChannel = MethodChannel('com.umer.quranzone/athan_alarm');

// ── Alarm Manager Callback (Runs in Background Isolate) ──────────────────────
//
// IMPORTANT: This callback is now NOTIFICATION-ONLY.
//
// The actual audio playback is handled by the native AthanForegroundService
// (Kotlin), which is started directly by AthanAlarmReceiver when the native
// AlarmManager fires. This Dart callback is kept as a BACKUP mechanism only
// — it shows the notification and reschedules tomorrow's alarm, but it does
// NOT attempt to play audio. Audio played here would be killed by the OS
// within ~10 seconds regardless.
//
// The native alarm (via MethodChannel → AlarmManager) fires AthanAlarmReceiver
// → AthanForegroundService for the actual Athan audio.
// ─────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
void athanAlarmCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  debugPrint(
      '[athanAlarmCallback] Backup isolate callback triggered for id=$id');

  try {
    final prefs = await SharedPreferences.getInstance();
    final rawConfig = prefs.getString(PrayerConfig.prefKey);
    final config = rawConfig != null
        ? PrayerConfig.fromJsonString(rawConfig)
        : const PrayerConfig();

    final bool isPreAdhan = id >= 200 && id <= 205;
    final int baseId = isPreAdhan ? id - 100 : id;

    String prayerNameStr;
    switch (baseId) {
      case 100:
        prayerNameStr = 'fajr';
        break;
      case 101:
        prayerNameStr = 'sunrise';
        break;
      case 102:
        prayerNameStr = 'dhuhr';
        break;
      case 103:
        prayerNameStr = 'asr';
        break;
      case 104:
        prayerNameStr = 'maghrib';
        break;
      case 105:
        prayerNameStr = 'isha';
        break;
      default:
        prayerNameStr = 'unknown';
    }

    if (prayerNameStr == 'unknown') {
      debugPrint('[athanAlarmCallback] Unknown prayer ID: $id');
      return;
    }

    // ── Reschedule Tomorrow's Alarm ──────────────────────────────────────────
    // The native AlarmManager alarm was one-shot. We need to reschedule it for
    // the next day. This is done via the Dart isolate since we have access to
    // SharedPreferences and adhan calculation.
    try {
      final coordinates = adhan.Coordinates(config.latitude, config.longitude);
      adhan.CalculationParameters params;
      switch (config.method) {
        case CalculationMethodEnum.ummAlQura:
          params = adhan.CalculationMethod.umm_al_qura.getParameters();
          break;
        case CalculationMethodEnum.egyptian:
          params = adhan.CalculationMethod.egyptian.getParameters();
          break;
        case CalculationMethodEnum.mwl:
          params = adhan.CalculationMethod.muslim_world_league.getParameters();
          break;
        case CalculationMethodEnum.isna:
          params = adhan.CalculationMethod.north_america.getParameters();
          break;
        case CalculationMethodEnum.karachi:
          params = adhan.CalculationMethod.karachi.getParameters();
          break;
      }
      params.madhab = config.madhab == MadhabEnum.hanafi
          ? adhan.Madhab.hanafi
          : adhan.Madhab.shafi;

      final now = DateTime.now();

      // Catch-up storm guard: if this fires more than 15 minutes late, skip.
      final todayTimes = adhan.PrayerTimes(
          coordinates, adhan.DateComponents.from(now), params);
      DateTime? todayTargetTime = _getPrayerTime(todayTimes, prayerNameStr);
      if (todayTargetTime != null) {
        final diffInMinutes = now.difference(todayTargetTime).inMinutes;
        if (diffInMinutes > 15) {
          debugPrint(
              '[athanAlarmCallback] Catch-up storm guard: $diffInMinutes min late for $prayerNameStr. Skipping.');
          return;
        }
      }

      // Calculate tomorrow's time and reschedule
      final tomorrow = now.add(const Duration(days: 1));
      final tomorrowTimes = adhan.PrayerTimes(
          coordinates, adhan.DateComponents.from(tomorrow), params);

      DateTime? nextTargetTime = _getPrayerTime(tomorrowTimes, prayerNameStr);
      final preMins = config.preAthanMinutes[prayerNameStr] ?? 0;

      if (nextTargetTime != null) {
        if (isPreAdhan && preMins > 0) {
          nextTargetTime = nextTargetTime.subtract(Duration(minutes: preMins));
        }

        // Reschedule via the android_alarm_manager_plus (backup only — will be
        // overridden by native alarm scheduled via MethodChannel on next app open)
        await AndroidAlarmManager.oneShotAt(
          nextTargetTime.toLocal(),
          id,
          athanAlarmCallback,
          exact: true,
          wakeup: true,
          rescheduleOnReboot: true,
          alarmClock: true,
          allowWhileIdle: true,
        );
        debugPrint(
            '[athanAlarmCallback] Rescheduled backup alarm $id ($prayerNameStr) for ${nextTargetTime.toLocal()}');
      }
    } catch (e) {
      debugPrint('[athanAlarmCallback] Error rescheduling: $e');
    }

    // ── Pre-Adhan Notification Only ───────────────────────────────────────────
    // Full Athan notifications are owned EXCLUSIVELY by AthanForegroundService
    // (Kotlin). This Dart callback must NEVER show a full Athan notification or
    // it creates the duplicate that confused the user.
    // Pre-Adhan warnings (isPreAdhan == true) have no Kotlin counterpart, so
    // they are still shown here.
    if (!isPreAdhan) return;

    final preMins = config.preAthanMinutes[prayerNameStr] ?? 0;

    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await plugin.initialize(initSettings);

    final androidImplementation = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation
          .createNotificationChannel(const AndroidNotificationChannel(
        'pre_adhan_channel_v3',
        'Pre-Adhan Warning',
        description: 'Notification before Adhan time',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('salah'),
        enableVibration: true,
      ));
    }

    const androidDetails = AndroidNotificationDetails(
      'pre_adhan_channel_v3',
      'Pre-Adhan Warning',
      channelDescription: 'Notification before Adhan time',
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('salah'),
      playSound: true,
      category: AndroidNotificationCategory.alarm,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
    );

    await plugin.show(
      id,
      '⏳ ${_prayerNameDisplayFromStr(prayerNameStr)} Alert',
      'باقي $preMins دقائق على أذان ${_prayerNameDisplayFromStr(prayerNameStr)}',
      const NotificationDetails(android: androidDetails),
      payload: 'prayer_times',
    );
    debugPrint(
        '[athanAlarmCallback] Pre-Adhan notification shown for: $prayerNameStr');
  } catch (e, stack) {
    debugPrint('[athanAlarmCallback] ERROR: $e');
    debugPrint(stack.toString());
  }
}

DateTime? _getPrayerTime(adhan.PrayerTimes times, String prayer) {
  switch (prayer) {
    case 'fajr':
      return times.fajr;
    case 'sunrise':
      return times.sunrise;
    case 'dhuhr':
      return times.dhuhr;
    case 'asr':
      return times.asr;
    case 'maghrib':
      return times.maghrib;
    case 'isha':
      return times.isha;
    default:
      return null;
  }
}

String _prayerNameDisplayFromStr(String prayer) {
  switch (prayer) {
    case 'fajr':
      return 'Fajr';
    case 'sunrise':
      return 'Sunrise';
    case 'dhuhr':
      return 'Dhuhr';
    case 'asr':
      return 'Asr';
    case 'maghrib':
      return 'Maghrib';
    case 'isha':
      return 'Isha';
    default:
      return prayer;
  }
}

// ── Workmanager Callback ─────────────────────────────────────────────────────

@pragma('vm:entry-point')
void workmanagerDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    if (task == 'sync_alarms') {
      try {
        final prefs = await SharedPreferences.getInstance();
        final rawConfig = prefs.getString(PrayerConfig.prefKey);
        if (rawConfig != null) {
          final config = PrayerConfig.fromJsonString(rawConfig);

          final coordinates =
              adhan.Coordinates(config.latitude, config.longitude);
          adhan.CalculationParameters params;
          switch (config.method) {
            case CalculationMethodEnum.ummAlQura:
              params = adhan.CalculationMethod.umm_al_qura.getParameters();
              break;
            case CalculationMethodEnum.egyptian:
              params = adhan.CalculationMethod.egyptian.getParameters();
              break;
            case CalculationMethodEnum.mwl:
              params =
                  adhan.CalculationMethod.muslim_world_league.getParameters();
              break;
            case CalculationMethodEnum.isna:
              params = adhan.CalculationMethod.north_america.getParameters();
              break;
            case CalculationMethodEnum.karachi:
              params = adhan.CalculationMethod.karachi.getParameters();
              break;
          }
          params.madhab = config.madhab == MadhabEnum.hanafi
              ? adhan.Madhab.hanafi
              : adhan.Madhab.shafi;

          final now = DateTime.now();
          final todayTimes = adhan.PrayerTimes(
              coordinates, adhan.DateComponents.from(now), params);
          final tomorrowTimes = adhan.PrayerTimes(
              coordinates,
              adhan.DateComponents.from(now.add(const Duration(days: 1))),
              params);

          List<PrayerTimeEntry> toEntries(adhan.PrayerTimes t) {
            final offsets = config.prayerOffsets;
            DateTime adj(DateTime o, String k) =>
                o.add(Duration(minutes: offsets[k] ?? 0));
            return [
              PrayerTimeEntry(
                  prayer: PrayerName.fajr,
                  time: adj(t.fajr, 'fajr'),
                  alertMode: PrayerAlertMode.notification),
              PrayerTimeEntry(
                  prayer: PrayerName.sunrise,
                  time: adj(t.sunrise, 'sunrise'),
                  alertMode: PrayerAlertMode.notification),
              PrayerTimeEntry(
                  prayer: PrayerName.dhuhr,
                  time: adj(t.dhuhr, 'dhuhr'),
                  alertMode: PrayerAlertMode.notification),
              PrayerTimeEntry(
                  prayer: PrayerName.asr,
                  time: adj(t.asr, 'asr'),
                  alertMode: PrayerAlertMode.notification),
              PrayerTimeEntry(
                  prayer: PrayerName.maghrib,
                  time: adj(t.maghrib, 'maghrib'),
                  alertMode: PrayerAlertMode.notification),
              PrayerTimeEntry(
                  prayer: PrayerName.isha,
                  time: adj(t.isha, 'isha'),
                  alertMode: PrayerAlertMode.notification),
            ];
          }

          final upcomingEntries = [
            ...toEntries(todayTimes),
            ...toEntries(tomorrowTimes)
          ];
          // NOTE: scheduleAllAlarms requires the main isolate for MethodChannel calls.
          // WorkManager sync only updates SharedPreferences keys used by native alarm.
          // The full re-scheduling happens via BackgroundEngine on next app launch.
          await _syncAlarmsPrefsOnly(upcomingEntries, config);
          debugPrint(
              '[workmanagerDispatcher] Alarm prefs synced via WorkManager.');
        }
      } catch (e) {
        debugPrint('[workmanagerDispatcher] Error syncing alarms: $e');
      }
      return Future.value(true);
    }

    if (task == 'show_zekr_overlay') {
      try {
        final zekrService = AzkarService();
        final contextualZekr =
            await zekrService.getSmartContextualZekr(shortOnly: true);
        if (contextualZekr != null && contextualZekr.zekr.isNotEmpty) {
          final zekr = contextualZekr.zekr;
          final title = contextualZekr.title;
          final plugin = FlutterLocalNotificationsPlugin();
          const androidSettings =
              AndroidInitializationSettings('@mipmap/ic_launcher');
          const initSettings = InitializationSettings(android: androidSettings);
          await plugin.initialize(initSettings);

          final androidImplementation =
              plugin.resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>();

          if (androidImplementation != null) {
            await androidImplementation.createNotificationChannel(
              const AndroidNotificationChannel(
                'zekr_reminder_channel',
                'Zekr Reminder',
                description: 'Heads-up notifications for Zekr',
                importance: Importance.max,
                playSound: true,
                enableVibration: true,
              ),
            );
          }

          const androidDetails = AndroidNotificationDetails(
            'zekr_reminder_channel',
            'Zekr Reminder',
            channelDescription: 'Heads-up notifications for Zekr',
            importance: Importance.max,
            priority: Priority.high,
            ticker: 'ticker',
            styleInformation: BigTextStyleInformation(''),
            category: AndroidNotificationCategory.reminder,
            visibility: NotificationVisibility.public,
          );

          await plugin.show(
            888,
            title,
            zekr,
            const NotificationDetails(android: androidDetails),
          );
          debugPrint('[workmanagerDispatcher] Zekr notification shown: $zekr');
        }
      } catch (e, stack) {
        debugPrint('[workmanagerDispatcher] Zekr notification error: $e');
        debugPrint(stack.toString());
      }
    }
    return Future.value(true);
  });
}

/// Writes the resolved audio paths to SharedPreferences so the native
/// AthanAlarmReceiver can read them without needing a Flutter engine.
Future<void> _syncAlarmsPrefsOnly(
    List<PrayerTimeEntry> entries, PrayerConfig config) async {
  final prefs = await SharedPreferences.getInstance();
  for (final prayer in PrayerName.values) {
    final prayerEntries = entries.where((e) => e.prayer == prayer).toList();
    prayerEntries.sort((a, b) => a.time.compareTo(b.time));
    final now = DateTime.now();
    final next = prayerEntries.firstWhere(
      (e) => e.time.toLocal().isAfter(now),
      orElse: () => prayerEntries.first,
    );
    await prefs.setString(
      'athan_next_time_${prayer.name}',
      next.time.toIso8601String(),
    );
  }
}

// ── Azkar Reminder Callback ──────────────────────────────────────────────────

@pragma('vm:entry-point')
void azkarReminderCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  try {
    final bool isMorning = id == 300;
    final title = isMorning ? '☀️ أذكار الصباح' : '🌙 أذكار المساء';
    final body = isMorning
        ? 'حان وقت أذكار الصباح، لا تنس ذكر الله'
        : 'حان وقت أذكار المساء، لا تنس ذكر الله';
    final soundName = isMorning ? 'azkarsabah' : 'azkarmassa';
    final channelId = isMorning ? 'azkar_sabah_channel' : 'azkar_massa_channel';

    final plugin = FlutterLocalNotificationsPlugin();
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await plugin.initialize(initSettings);

    final androidImplementation = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(
        AndroidNotificationChannel(
          channelId,
          isMorning ? 'Morning Azkar' : 'Evening Azkar',
          description: 'Azkar reminders 40 mins after prayer',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(soundName),
          enableVibration: true,
        ),
      );
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      isMorning ? 'Morning Azkar' : 'Evening Azkar',
      channelDescription: 'Azkar reminders 40 mins after prayer',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(soundName),
      playSound: true,
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
    );

    await plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
    debugPrint('[azkarReminderCallback] Notification shown for id: $id');
  } catch (e, stack) {
    debugPrint('[azkarReminderCallback] Error: $e');
    debugPrint(stack.toString());
  }
}

// ── Zekr Notification Callback ───────────────────────────────────────────────

@pragma('vm:entry-point')
void zekrNotificationCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  try {
    final zekrService = AzkarService();
    final contextualZekr =
        await zekrService.getSmartContextualZekr(shortOnly: true);
    if (contextualZekr != null && contextualZekr.zekr.isNotEmpty) {
      final zekr = contextualZekr.zekr;
      final title = contextualZekr.title;
      final plugin = FlutterLocalNotificationsPlugin();
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await plugin.initialize(initSettings);

      final androidImplementation =
          plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'zekr_reminder_channel',
            'Zekr Reminder',
            description: 'Heads-up notifications for Zekr',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
      }

      const androidDetails = AndroidNotificationDetails(
        'zekr_reminder_channel',
        'Zekr Reminder',
        channelDescription: 'Heads-up notifications for Zekr',
        importance: Importance.max,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(''),
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      );

      await plugin.show(
        888,
        title,
        zekr,
        const NotificationDetails(android: androidDetails),
      );
    }
  } catch (e) {
    debugPrint('[zekrNotificationCallback] Error: $e');
  } finally {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool enabled = prefs.getBool('notifications_enabled') ?? true;
      final int interval = prefs.getInt('notification_interval') ?? 60;
      if (enabled && interval > 0) {
        await BackgroundEngine().scheduleZekrNotification(interval);
      }
    } catch (e) {
      debugPrint('[zekrNotificationCallback] Reschedule error: $e');
    }
  }
}

// ── Background Engine ────────────────────────────────────────────────────────

class BackgroundEngine {
  static final BackgroundEngine _instance = BackgroundEngine._internal();
  factory BackgroundEngine() => _instance;
  BackgroundEngine._internal();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    await AndroidAlarmManager.initialize();
    await Workmanager().initialize(workmanagerDispatcher, isInDebugMode: false);

    _initialized = true;
  }

  /// Schedules a Zekr Notification alarm
  Future<void> scheduleZekrNotification(int minutes) async {
    await AndroidAlarmManager.cancel(888);
    if (minutes <= 0) return;
    await AndroidAlarmManager.oneShot(
      Duration(minutes: minutes),
      888,
      zekrNotificationCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      allowWhileIdle: true,
    );
  }

  /// Cancels Zekr Notification alarm
  Future<void> cancelZekrNotification() async {
    await AndroidAlarmManager.cancel(888);
  }

  /// Cancels a specific alarm by ID (both native and backup AlarmManager alarms)
  Future<void> cancelAlarm(int id) async {
    // Cancel native alarm via MethodChannel
    try {
      await _kAthanAlarmChannel.invokeMethod('cancelAthanAlarm', {'id': id});
    } catch (e) {
      debugPrint('[BackgroundEngine] cancelAlarm native error (id=$id): $e');
    }
    // Also cancel backup alarm manager alarm
    try {
      await AndroidAlarmManager.cancel(id);
    } catch (e) {
      debugPrint('[BackgroundEngine] cancelAlarm backup error (id=$id): $e');
    }
  }

  /// Stops the AthanForegroundService if it is currently playing.
  Future<void> stopAthanService() async {
    try {
      await _kAthanAlarmChannel.invokeMethod('stopAthanService');
    } catch (e) {
      debugPrint('[BackgroundEngine] stopAthanService error: $e');
    }
  }

  /// Resolves the audio file path for a given muezzin ID.
  /// For bundled assets, copies the file to the app's documents directory
  /// so the native MediaPlayer can access it as an absolute file path.
  Future<String> _resolveAudioPath(
      String muezzinId, PrayerConfig config) async {
    try {
      final manager = MuezzinManager();
      await manager.init();
      final muezzin = manager.muezzins.firstWhere(
        (e) => e.id == muezzinId,
        orElse: () => manager.muezzins.first,
      );

      if (!muezzin.isLocal) {
        // Downloaded muezzin — get absolute file path directly
        final path = await manager.getAudioPath(muezzin);
        if (path.startsWith('assets/')) {
          // Not downloaded yet, fall through to bundled
        } else {
          return path;
        }
      }

      // Bundled asset: copy to cache directory so MediaPlayer can access it
      return await _copyAssetToCache(muezzin.url);
    } catch (e) {
      debugPrint(
          '[BackgroundEngine] _resolveAudioPath error: $e. Using default.');
      return await _copyAssetToCache('assets/audio/Takbir_mishary_alafasy.mp3');
    }
  }

  /// Copies a Flutter asset to the app's cache directory and returns the
  /// absolute file path. Cached files persist across launches.
  Future<String> _copyAssetToCache(String assetPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName =
        assetPath.replaceAll('/', '_').replaceAll('assets_audio_', '');
    final cachedFile = File('${dir.path}/athan_cache_$fileName');

    if (!await cachedFile.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await cachedFile.writeAsBytes(byteData.buffer.asUint8List());
      debugPrint('[BackgroundEngine] Asset cached: ${cachedFile.path}');
    }

    return cachedFile.path;
  }

  /// Schedules an Athan alarm using the NATIVE AlarmManager via MethodChannel.
  ///
  /// This is the PRIMARY scheduling method. It schedules:
  /// 1. A native AlarmManager alarm that fires AthanAlarmReceiver → AthanForegroundService
  ///    (plays audio reliably even when app is killed / Doze mode)
  /// 2. A backup android_alarm_manager_plus alarm that shows a notification
  ///    and handles rescheduling (in case native path fails)
  Future<void> scheduleAthan({
    required int id,
    required DateTime time,
    required String prayerName,
    required bool isModeA,
    required String title,
    required String body,
    required PrayerConfig config,
  }) async {
    final localTime = time.toLocal();
    if (localTime.isBefore(DateTime.now())) return;

    final muezzinId =
        config.prayerMuezzins[prayerName] ?? 'takbir_mishary_alafasy';
    final durationSeconds = config.athanDurationSeconds;

    // Only schedule audio for full athan alarms (not pre-adhan)
    final bool isPreAdhan = id >= 200 && id <= 205;

    if (!isPreAdhan) {
      // Resolve and cache audio path before scheduling
      String audioPath = 'assets/audio/Takbir_mishary_alafasy.mp3';
      try {
        audioPath = await _resolveAudioPath(muezzinId, config);
      } catch (e) {
        debugPrint('[BackgroundEngine] Audio path resolution failed: $e');
      }

      // ── Primary: Native AlarmManager → AthanForegroundService ──
      try {
        await _kAthanAlarmChannel.invokeMethod('scheduleAthanAlarm', {
          'id': id,
          'epochMillis': localTime.millisecondsSinceEpoch,
          'prayerName': prayerName,
          'audioPath': audioPath,
          'durationSeconds': durationSeconds,
        });
        debugPrint(
            '[BackgroundEngine] Native alarm scheduled: id=$id, prayer=$prayerName, time=$localTime');
      } catch (e) {
        debugPrint(
            '[BackgroundEngine] Native alarm scheduling failed: $e. Falling back to alarm_manager_plus only.');
      }
    }

    // ── Backup: android_alarm_manager_plus (notification + reschedule) ──
    await AndroidAlarmManager.oneShotAt(
      localTime,
      id,
      athanAlarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      alarmClock: true,
      allowWhileIdle: true,
      params: {
        'prayerName': prayerName,
        'isModeA': isModeA,
        'title': title,
        'body': body,
      },
    );
    debugPrint(
        '[BackgroundEngine] Backup alarm_manager_plus alarm set: id=$id');
  }

  /// Replaces existing alarm scheduling logic. Cancels old ones, sets new ones.
  Future<void> scheduleAllAlarms(
      List<PrayerTimeEntry> entries, PrayerConfig config) async {
    if (!_initialized) {
      debugPrint('[BackgroundEngine] scheduleAllAlarms: initializing first.');
      await init();
    }

    final now = DateTime.now();
    final notif = config.notifications;

    final Map<PrayerName, int> baseIds = {
      PrayerName.fajr: 100,
      PrayerName.sunrise: 101,
      PrayerName.dhuhr: 102,
      PrayerName.asr: 103,
      PrayerName.maghrib: 104,
      PrayerName.isha: 105,
    };

    // Cancel existing alarms (both native and backup)
    for (int id = 100; id <= 105; id++) {
      await cancelAlarm(id);
      await cancelAlarm(id + 100);
      try {
        await _kAthanAlarmChannel
            .invokeMethod('cancelSilentAlarm', {'id': id + 400});
        await _kAthanAlarmChannel
            .invokeMethod('cancelSilentAlarm', {'id': id + 500});
      } catch (e) {
        debugPrint('[BackgroundEngine] cancelSilentAlarm error (id=$id): $e');
      }
    }
    await cancelAlarm(300); // Morning Azkar
    await cancelAlarm(301); // Evening Azkar

    for (final prayer in PrayerName.values) {
      if (!baseIds.containsKey(prayer)) continue;
      if (!_isNotifEnabledForPrayer(prayer, notif)) continue;

      final prayerEntries = entries.where((e) => e.prayer == prayer).toList();
      prayerEntries.sort((a, b) => a.time.compareTo(b.time));

      PrayerTimeEntry? targetEntry;
      for (final entry in prayerEntries) {
        final prayerTime = entry.time.toLocal();
        DateTime activeUntil = prayerTime;
        
        if (config.autoSilentEnabled) {
          final dndEnd = prayerTime.add(Duration(minutes: config.autoSilentDelayMins + config.autoSilentDurationMins));
          if (dndEnd.isAfter(activeUntil)) activeUntil = dndEnd;
        }
        if (prayer == PrayerName.fajr || prayer == PrayerName.asr) {
          final azkarEnd = prayerTime.add(const Duration(minutes: 41));
          if (azkarEnd.isAfter(activeUntil)) activeUntil = azkarEnd;
        }

        if (activeUntil.isAfter(now)) {
          targetEntry = entry;
          break;
        }
      }

      if (targetEntry != null) {
        final slotId = baseIds[prayer]!;

        // 1. Schedule full Athan
        if (targetEntry.time.toLocal().isAfter(now)) {
          await scheduleAthan(
            id: slotId,
            time: targetEntry.time.toLocal(),
            prayerName: prayer.name,
            isModeA: true,
            title: '🕌 ${_prayerNameDisplay(prayer)}',
            body: 'حان الآن موعد أذان ${_prayerNameDisplay(prayer)}',
            config: config,
          );
        }

        // 2. Schedule Pre-Adhan if configured
        final preAthanMinutes = config.preAthanMinutes[prayer.name] ?? 0;
        if (preAthanMinutes > 0) {
          final preTime = targetEntry.time
              .subtract(Duration(minutes: preAthanMinutes))
              .toLocal();

          if (preTime.isBefore(now)) {
            // Today's pre-warning passed; find tomorrow's entry
            final tomorrowEntry = prayerEntries.firstWhere(
              (e) => e.time.toLocal().isAfter(targetEntry!.time.toLocal()),
              orElse: () => targetEntry!,
            );
            if (tomorrowEntry != targetEntry) {
              final tomorrowPreTime = tomorrowEntry.time
                  .subtract(Duration(minutes: preAthanMinutes))
                  .toLocal();
              if (tomorrowPreTime.isAfter(now)) {
                await scheduleAthan(
                  id: slotId + 100,
                  time: tomorrowPreTime,
                  prayerName: prayer.name,
                  isModeA: false,
                  title: '⏳ ${_prayerNameDisplay(prayer)} Alert',
                  body:
                      'باقي $preAthanMinutes دقائق على أذان ${_prayerNameDisplay(prayer)}',
                  config: config,
                );
              }
            }
          } else {
            await scheduleAthan(
              id: slotId + 100,
              time: preTime,
              prayerName: prayer.name,
              isModeA: false,
              title: '⏳ ${_prayerNameDisplay(prayer)} Alert',
              body:
                  'باقي $preAthanMinutes دقائق على أذان ${_prayerNameDisplay(prayer)}',
              config: config,
            );
          }
        }

        // 3. Smart Azkar Reminder (40 mins after Fajr/Asr)
        if (prayer == PrayerName.fajr || prayer == PrayerName.asr) {
          final isMorning = prayer == PrayerName.fajr;
          final azkarId = isMorning ? 300 : 301;
          final azkarTime =
              targetEntry.time.add(const Duration(minutes: 40)).toLocal();

          if (azkarTime.isBefore(now)) {
            // Today's Azkar passed; find tomorrow's entry
            final tomorrowEntry = prayerEntries.firstWhere(
              (e) => e.time.toLocal().isAfter(targetEntry!.time.toLocal()),
              orElse: () => targetEntry!,
            );
            if (tomorrowEntry != targetEntry) {
              final tomorrowAzkarTime =
                  tomorrowEntry.time.add(const Duration(minutes: 40)).toLocal();
              if (tomorrowAzkarTime.isAfter(now)) {
                await AndroidAlarmManager.oneShotAt(
                  tomorrowAzkarTime,
                  azkarId,
                  azkarReminderCallback,
                  exact: true,
                  wakeup: true,
                  rescheduleOnReboot: true,
                  alarmClock: true,
                  allowWhileIdle: true,
                );
              }
            }
          } else {
            await AndroidAlarmManager.oneShotAt(
              azkarTime,
              azkarId,
              azkarReminderCallback,
              exact: true,
              wakeup: true,
              rescheduleOnReboot: true,
              alarmClock: true,
              allowWhileIdle: true,
            );
          }
        }

        // 4. Auto-Silent Mode
        if (config.autoSilentEnabled && config.autoSilentDurationMins > 0) {
          final silentId = slotId + 400;
          final normalId = slotId + 500;

          final int silentStartDelay = config.autoSilentDelayMins;
          final int silentDuration = config.autoSilentDurationMins;

          final silentTime = targetEntry.time
              .add(Duration(minutes: silentStartDelay))
              .toLocal();
          final normalTime =
              silentTime.add(Duration(minutes: silentDuration)).toLocal();

          if (silentTime.isAfter(now)) {
            try {
              await _kAthanAlarmChannel.invokeMethod('scheduleSilentAlarm', {
                'id': silentId,
                'epochMillis': silentTime.millisecondsSinceEpoch,
                'isSilent': true,
              });
            } catch (e) {
              debugPrint('[BackgroundEngine] scheduleSilentAlarm error: $e');
            }
          }

          if (normalTime.isAfter(now)) {
            try {
              await _kAthanAlarmChannel.invokeMethod('scheduleSilentAlarm', {
                'id': normalId,
                'epochMillis': normalTime.millisecondsSinceEpoch,
                'isSilent': false,
              });
            } catch (e) {
              debugPrint('[BackgroundEngine] scheduleSilentAlarm error: $e');
            }
          }
        }
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
