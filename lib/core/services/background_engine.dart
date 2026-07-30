import 'dart:ui';
import 'package:flutter/widgets.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as overlay;

import 'dart:isolate';
import 'package:adhan/adhan.dart' as adhan;

import '../../features/prayer_times/data/models/prayer_config.dart';
import '../../features/prayer_times/data/models/prayer_time_model.dart';
import '../../features/prayer_times/data/services/muezzin_manager.dart';
import '../../services/azkar_service.dart';
import 'athan_audio_service.dart';

// ── Background Notification Tap Handler ──────────────────────────────────────

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  if (notificationResponse.actionId == 'stop_athan') {
    final sendPort = IsolateNameServer.lookupPortByName('athan_stop_port');
    sendPort?.send('stop');

    // Also cancel the notification
    FlutterLocalNotificationsPlugin().cancel(notificationResponse.id ?? 0);
  }
}

// ── Alarm Manager Callback (Runs in Isolate) ─────────────────────────────────

@pragma('vm:entry-point')
void athanAlarmCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  debugPrint('Alarm triggered: $id');

  try {
    final prefs = await SharedPreferences.getInstance();
    final rawConfig = prefs.getString(PrayerConfig.prefKey);
    final config = rawConfig != null
        ? PrayerConfig.fromJsonString(rawConfig)
        : const PrayerConfig();

    final bool isTestAdhan = id == 199;
    final bool isPreAdhan = id >= 200 && id <= 205;
    final int baseId = isPreAdhan ? id - 100 : id;

    String prayerNameStr;
    if (isTestAdhan) {
      prayerNameStr = 'Test';
    } else {
      switch (baseId) {
        case 100: prayerNameStr = 'fajr'; break;
        case 101: prayerNameStr = 'sunrise'; break;
        case 102: prayerNameStr = 'dhuhr'; break;
        case 103: prayerNameStr = 'asr'; break;
        case 104: prayerNameStr = 'maghrib'; break;
        case 105: prayerNameStr = 'isha'; break;
        default: prayerNameStr = 'unknown';
      }
    }

    if (prayerNameStr == 'unknown') {
      debugPrint('Unknown prayer ID: $id');
      return;
    }

    // ── Reschedule Next Occurrence ───────────────────────────────────────────
    if (!isTestAdhan) {
      try {
        final coordinates = adhan.Coordinates(config.latitude, config.longitude);
        adhan.CalculationParameters params;
        switch (config.method) {
          case CalculationMethodEnum.ummAlQura:
            params = adhan.CalculationMethod.umm_al_qura.getParameters(); break;
          case CalculationMethodEnum.egyptian:
            params = adhan.CalculationMethod.egyptian.getParameters(); break;
          case CalculationMethodEnum.mwl:
            params = adhan.CalculationMethod.muslim_world_league.getParameters(); break;
          case CalculationMethodEnum.isna:
            params = adhan.CalculationMethod.north_america.getParameters(); break;
          case CalculationMethodEnum.karachi:
            params = adhan.CalculationMethod.karachi.getParameters(); break;
        }
        params.madhab = config.madhab == MadhabEnum.hanafi
            ? adhan.Madhab.hanafi
            : adhan.Madhab.shafi;

        final now = DateTime.now();
        
        // Calculate today's times to check for catch-up storms
        final todayTimes = adhan.PrayerTimes(
            coordinates, adhan.DateComponents.from(now), params);

        DateTime? targetTime;
        switch (prayerNameStr) {
          case 'fajr': targetTime = todayTimes.fajr; break;
          case 'sunrise': targetTime = todayTimes.sunrise; break;
          case 'dhuhr': targetTime = todayTimes.dhuhr; break;
          case 'asr': targetTime = todayTimes.asr; break;
          case 'maghrib': targetTime = todayTimes.maghrib; break;
          case 'isha': targetTime = todayTimes.isha; break;
        }

        if (targetTime != null) {
          final diffInMinutes = now.difference(targetTime).inMinutes;
          // If alarm triggered more than 15 minutes past the prayer time, skip stale notification
          if (diffInMinutes > 15) {
            debugPrint('Catch-up storm prevented! Alarm $id for $prayerNameStr is $diffInMinutes mins late.');
            return;
          }
        }

        // Calculate TOMORROW'S time and reschedule THIS specific alarm ID
        final tomorrow = now.add(const Duration(days: 1));
        final tomorrowTimes = adhan.PrayerTimes(
            coordinates, adhan.DateComponents.from(tomorrow), params);
        
        DateTime? nextTargetTime;
        switch (prayerNameStr) {
          case 'fajr': nextTargetTime = tomorrowTimes.fajr; break;
          case 'sunrise': nextTargetTime = tomorrowTimes.sunrise; break;
          case 'dhuhr': nextTargetTime = tomorrowTimes.dhuhr; break;
          case 'asr': nextTargetTime = tomorrowTimes.asr; break;
          case 'maghrib': nextTargetTime = tomorrowTimes.maghrib; break;
          case 'isha': nextTargetTime = tomorrowTimes.isha; break;
        }

        final preMins = config.preAthanMinutes[prayerNameStr] ?? 0;

        if (nextTargetTime != null) {
          if (isPreAdhan && preMins > 0) {
            nextTargetTime = nextTargetTime.subtract(Duration(minutes: preMins));
          }
          
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
          debugPrint('Successfully rescheduled $prayerNameStr (ID: $id) for ${nextTargetTime.toLocal()}');
        }

      } catch (e) {
        debugPrint('Error validating/rescheduling prayer timestamp: $e');
      }
    }

    final preMins = config.preAthanMinutes[prayerNameStr] ?? 0;
    final title = isPreAdhan
        ? '⏳ ${_prayerNameDisplayFromStr(prayerNameStr)} Alert'
        : '🕌 ${_prayerNameDisplayFromStr(prayerNameStr)}';
    final body = isPreAdhan
        ? 'باقي $preMins دقائق على أذان ${_prayerNameDisplayFromStr(prayerNameStr)}'
        : 'حان الآن موعد أذان ${_prayerNameDisplayFromStr(prayerNameStr)}';

    final plugin = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await plugin.initialize(
      initSettings,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final androidImplementation = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final muezzinId = config.prayerMuezzins[prayerNameStr] ?? 'adhan_abdulbasit';

    if (androidImplementation != null) {
      if (isPreAdhan) {
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
      } else {
        // Use v2 channel id to override any old configuration that had playSound: true
        final channelId = 'athan_bg_channel_${muezzinId}_v2';
        await androidImplementation
            .createNotificationChannel(AndroidNotificationChannel(
          channelId,
          'Athan Background Alerts',
          description: 'Ongoing Athan playback',
          importance: Importance.max,
          playSound: false, // SILENT. We play audio natively.
          enableVibration: true,
        ));
      }
    }

    AndroidNotificationDetails androidDetails;

    if (isPreAdhan) {
      androidDetails = const AndroidNotificationDetails(
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
    } else {
      final channelId = 'athan_bg_channel_${muezzinId}_v2';

      androidDetails = AndroidNotificationDetails(
        channelId,
        'Athan Background Alerts',
        channelDescription: 'Ongoing Athan playback',
        importance: Importance.max,
        priority: Priority.high,
        ongoing: true,
        autoCancel: false,
        playSound: false, // SILENT
        enableVibration: true,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        visibility: NotificationVisibility.public,
        actions: const [
          AndroidNotificationAction(
            'stop_athan',
            'Stop Athan',
            cancelNotification: true,
            showsUserInterface: true,
          )
        ],
      );
    }

    await plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails),
    );
    debugPrint('Notification shown successfully for alarm: $id');

    // ── Audio Playback for Full Adhan ────────────────────────────────────────
    if (!isPreAdhan) {
      final audioService = AthanAudioService();
      final completer = Completer<void>();
      
      final stopPort = ReceivePort();
      IsolateNameServer.removePortNameMapping('athan_stop_port');
      IsolateNameServer.registerPortWithName(stopPort.sendPort, 'athan_stop_port');
      
      stopPort.listen((message) {
        if (message == 'stop') {
          audioService.stopAthan();
          if (!completer.isCompleted) completer.complete();
        }
      });
      
      String audioPath = 'assets/audio/adhan_abdulbasit.mp3';
      try {
        final manager = MuezzinManager();
        await manager.init();
        final m = manager.muezzins.firstWhere(
          (e) => e.id == muezzinId, 
          orElse: () => manager.muezzins.first
        );
        audioPath = await manager.getAudioPath(m);
      } catch (e) {
        debugPrint('Muezzin resolution failed: $e');
      }

      // Wait for playAthan to naturally finish, keeping isolate alive!
      audioService.playAthan(audioPath).then((_) {
         if (!completer.isCompleted) completer.complete();
      });
      
      await completer.future;
      stopPort.close();
      
      // Cancel the ongoing notification once audio ends
      await plugin.cancel(id);
    }

  } catch (e, stack) {
    debugPrint('ERROR in athanAlarmCallback: $e');
    debugPrint(stack.toString());
  }
}

String _prayerNameDisplayFromStr(String prayer) {
  switch (prayer) {
    case 'fajr': return 'Fajr';
    case 'sunrise': return 'Sunrise';
    case 'dhuhr': return 'Dhuhr';
    case 'asr': return 'Asr';
    case 'maghrib': return 'Maghrib';
    case 'isha': return 'Isha';
    default: return prayer;
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
          
          final coordinates = adhan.Coordinates(config.latitude, config.longitude);
          adhan.CalculationParameters params;
          switch (config.method) {
            case CalculationMethodEnum.ummAlQura:
              params = adhan.CalculationMethod.umm_al_qura.getParameters(); break;
            case CalculationMethodEnum.egyptian:
              params = adhan.CalculationMethod.egyptian.getParameters(); break;
            case CalculationMethodEnum.mwl:
              params = adhan.CalculationMethod.muslim_world_league.getParameters(); break;
            case CalculationMethodEnum.isna:
              params = adhan.CalculationMethod.north_america.getParameters(); break;
            case CalculationMethodEnum.karachi:
              params = adhan.CalculationMethod.karachi.getParameters(); break;
          }
          params.madhab = config.madhab == MadhabEnum.hanafi
              ? adhan.Madhab.hanafi
              : adhan.Madhab.shafi;

          final now = DateTime.now();
          final todayTimes = adhan.PrayerTimes(coordinates, adhan.DateComponents.from(now), params);
          final tomorrowTimes = adhan.PrayerTimes(coordinates, adhan.DateComponents.from(now.add(const Duration(days: 1))), params);
          
          List<PrayerTimeEntry> toEntries(adhan.PrayerTimes t) {
            final offsets = config.prayerOffsets;
            DateTime adj(DateTime o, String k) => o.add(Duration(minutes: offsets[k] ?? 0));
            return [
              PrayerTimeEntry(prayer: PrayerName.fajr, time: adj(t.fajr, 'fajr'), alertMode: PrayerAlertMode.notification),
              PrayerTimeEntry(prayer: PrayerName.sunrise, time: adj(t.sunrise, 'sunrise'), alertMode: PrayerAlertMode.notification),
              PrayerTimeEntry(prayer: PrayerName.dhuhr, time: adj(t.dhuhr, 'dhuhr'), alertMode: PrayerAlertMode.notification),
              PrayerTimeEntry(prayer: PrayerName.asr, time: adj(t.asr, 'asr'), alertMode: PrayerAlertMode.notification),
              PrayerTimeEntry(prayer: PrayerName.maghrib, time: adj(t.maghrib, 'maghrib'), alertMode: PrayerAlertMode.notification),
              PrayerTimeEntry(prayer: PrayerName.isha, time: adj(t.isha, 'isha'), alertMode: PrayerAlertMode.notification),
            ];
          }
          
          final upcomingEntries = [...toEntries(todayTimes), ...toEntries(tomorrowTimes)];
          await BackgroundEngine().scheduleAllAlarms(upcomingEntries, config);
          debugPrint('Successfully synced alarms via Workmanager');
        }
      } catch (e) {
        debugPrint('Error syncing alarms: $e');
      }
      return Future.value(true);
    }

    if (task == 'show_zekr_overlay') {
      // 1. Fetch Zekr and show Heads-up Notification
      try {
        final zekrService = AzkarService();
        final zekr = await zekrService.getRandomShortZekr();
        if (zekr != null && zekr.isNotEmpty) {
          final plugin = FlutterLocalNotificationsPlugin();

          // Re-initialize local notifications for this isolate
          const androidSettings =
              AndroidInitializationSettings('@mipmap/ic_launcher');
          const initSettings = InitializationSettings(android: androidSettings);
          await plugin.initialize(
            initSettings,
            onDidReceiveBackgroundNotificationResponse:
                notificationTapBackground,
          );

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
            888, // Unique ID for Zekr notification
            '✨ ذكر الله', // Title
            zekr, // Body
            const NotificationDetails(android: androidDetails),
          );
          debugPrint('Zekr notification shown successfully: $zekr');
        }
      } catch (e, stack) {
        debugPrint('Zekr notification error: $e');
        debugPrint(stack.toString());
      }

      // 2. Show the floating overlay window
      try {
        final bool isGranted =
            await overlay.FlutterOverlayWindow.isPermissionGranted();
        if (isGranted) {
          final bool isActive = await overlay.FlutterOverlayWindow.isActive();
          if (!isActive) {
            await overlay.FlutterOverlayWindow.showOverlay(
              alignment: overlay.OverlayAlignment.center,
              visibility: overlay.NotificationVisibility.visibilityPublic,
              positionGravity: overlay.PositionGravity.auto,
              height: 320,
              width: 380,
              flag: overlay.OverlayFlag.defaultFlag,
              overlayTitle: 'Zekr Reminder',
              overlayContent: 'Showing Zekr overlay on screen',
            );
          }
        }
      } catch (e) {
        debugPrint('Overlay error: $e');
      }
    }
    return Future.value(true);
  });
}

// ── Zekr Notification Callback ───────────────────────────────────────────────────

@pragma('vm:entry-point')
void zekrNotificationCallback(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  try {
    final zekrService = AzkarService();
    final zekr = await zekrService.getRandomShortZekr();
    if (zekr != null && zekr.isNotEmpty) {
      final plugin = FlutterLocalNotificationsPlugin();
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await plugin.initialize(
        initSettings,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

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
        '✨ ذكر الله',
        zekr,
        const NotificationDetails(android: androidDetails),
      );
    }
  } catch (e) {
    debugPrint('Zekr notification alarm callback error: $e');
  } finally {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool enabled = prefs.getBool('notifications_enabled') ?? true;
      final int interval = prefs.getInt('notification_interval') ?? 60;
      if (enabled && interval > 0) {
        await BackgroundEngine().scheduleZekrNotification(interval);
      }
    } catch (e) {
      debugPrint('Zekr notification reschedule error: $e');
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

    // Register stop port for background notification actions
    try {
      final stopPort = ReceivePort();
      IsolateNameServer.removePortNameMapping('athan_stop_port');
      IsolateNameServer.registerPortWithName(stopPort.sendPort, 'athan_stop_port');
      stopPort.listen((message) {
        if (message == 'stop') {
          FlutterLocalNotificationsPlugin().cancelAll();
        }
      });
    } catch (e) {
      debugPrint('Error registering athan_stop_port: $e');
    }

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


  /// Cancels a specific alarm by ID
  Future<void> cancelAlarm(int id) async {
    await AndroidAlarmManager.cancel(id);
  }

  /// Schedules an Athan alarm
  Future<void> scheduleAthan({
    required int id,
    required DateTime time,
    required String prayerName,
    required bool isModeA,
    required String title,
    required String body,
  }) async {
    // Explicitly use local time
    final localTime = time.toLocal();

    // Avoid scheduling in the past
    if (localTime.isBefore(DateTime.now())) return;

    await AndroidAlarmManager.oneShotAt(
      localTime,
      id,
      athanAlarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
      alarmClock:
          true, // Shows alarm icon on Android, ensures precise execution
      allowWhileIdle: true,
      params: {
        'prayerName': prayerName,
        'isModeA': isModeA,
        'title': title,
        'body': body,
      },
    );
  }

  /// Replaces existing alarm scheduling logic. Cancels old ones, sets new ones.
  Future<void> scheduleAllAlarms(
      List<PrayerTimeEntry> entries, PrayerConfig config) async {
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

    // First cancel existing to avoid orphans
    for (int id = 100; id <= 105; id++) {
      await cancelAlarm(id);
      await cancelAlarm(id + 100); // For Pre-Athan
    }

    // For each prayer name, find the next future occurrence
    for (final prayer in PrayerName.values) {
      if (!baseIds.containsKey(prayer)) continue;

      final isNotifEnabled = _isNotifEnabledForPrayer(prayer, notif);
      if (!isNotifEnabled) continue;

      // Filter entries for this specific prayer
      final prayerEntries = entries.where((e) => e.prayer == prayer).toList();

      // Sort chronologically
      prayerEntries.sort((a, b) => a.time.compareTo(b.time));

      // Find the first occurrence in the future
      PrayerTimeEntry? targetEntry;
      for (final entry in prayerEntries) {
        if (entry.time.toLocal().isAfter(now)) {
          targetEntry = entry;
          break;
        }
      }

      if (targetEntry != null) {
        final slotId = baseIds[prayer]!;
        const isModeA = true;

        // 1. Schedule Adhan
        await scheduleAthan(
          id: slotId,
          time: targetEntry.time.toLocal(),
          prayerName: prayer.name,
          isModeA: isModeA,
          title: '🕌 ${_prayerNameDisplay(prayer)}',
          body: 'حان الآن موعد أذان ${_prayerNameDisplay(prayer)}',
        );

        // 2. Schedule Pre-Adhan if enabled
        final preAthanMinutes = config.preAthanMinutes[prayer.name] ?? 0;
        if (preAthanMinutes > 0) {
          final preTime = targetEntry.time
              .subtract(Duration(minutes: preAthanMinutes))
              .toLocal();

          if (preTime.isBefore(now)) {
            // Today's pre-warning has passed. Find tomorrow's entry
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
                  id: slotId + 100, // Pre-Adhan ID (200-205)
                  time: tomorrowPreTime,
                  prayerName: prayer.name,
                  isModeA: false,
                  title: '⏳ ${_prayerNameDisplay(prayer)} Alert',
                  body:
                      'باقي $preAthanMinutes دقائق على أذان ${_prayerNameDisplay(prayer)}',
                );
              }
            }
          } else {
            // Pre-warning is in the future, schedule normally
            await scheduleAthan(
              id: slotId + 100, // Pre-Adhan ID (200-205)
              time: preTime,
              prayerName: prayer.name,
              isModeA: false,
              title: '⏳ ${_prayerNameDisplay(prayer)} Alert',
              body:
                  'باقي $preAthanMinutes دقائق على أذان ${_prayerNameDisplay(prayer)}',
            );
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
