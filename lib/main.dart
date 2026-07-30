import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'theme_notifier.dart';
import 'language_notifier.dart';
import 'dashboard_scale_notifier.dart';

import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'fallback_localizations.dart';

import 'package:just_audio_background/just_audio_background.dart';
import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/services/background_engine.dart';

import 'services/minbar_player.dart';
import 'widgets/custom_banner_ad.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ENTRY POINT
//
// Performance contract:
//   • Only lightweight SharedPrefs reads happen before runApp() — ~10 ms total.
//   • All heavy I/O (WorkManager, audio background, notifications) is deferred
//     to _initHeavyServices(), which runs after the first frame has been painted.
//   • The database is opened lazily by DatabaseHelper on first use inside the
//     SplashScreen — never blocking the UI thread here.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Fast prefs reads: must happen before runApp to avoid theme/language
  //    flash. SharedPreferences is cached after the first call, so all three
  //    run against the same in-memory instance (~2 ms each).
  await Future.wait([
    AppTheme.init(),
    AppLanguage.init(),
    DashboardScale.init(),
  ]);

  // Initialize AdMob Banner Ads
  try {
    MobileAds.instance.initialize();
  } catch (e) {
    debugPrint('AdMob initialization error: $e');
  }

  runApp(const QuranDawahApp());
}

// ── Heavy services — called after the first frame is on screen ───────────────
//    Registered via WidgetsBinding.addPostFrameCallback inside QuranDawahApp.
Future<void> _initHeavyServices() async {
  // 1. Workmanager + AndroidAlarmManager registration.
  await BackgroundEngine().init();

  // 2. Audio background service (required before any audio playback).
  //    The Quran screen is several taps away, so this has plenty of time.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.sadaga.quran_dawah.channel.audio',
    androidNotificationChannelName: 'Audio Playback',
    androidNotificationOngoing: true,
  );

  // 3. Local notifications — channels + Islamic reminders scheduling.
  //    Wrapped in try/catch: non-fatal if permissions aren't granted yet.
  try {
    await NotificationService().init();
  } catch (_) {}

  // 4. Init MinbarPlayer listeners
  MinbarPlayer.init();

  // 5. Cancel old Workmanager overlay task and register new tasks
  try {
    await Workmanager().cancelByUniqueName("auto_zekr_overlay");
    
    // Register background sync task for alarms
    await Workmanager().registerPeriodicTask(
      "sync_alarms_task",
      "sync_alarms",
      frequency: const Duration(hours: 12),
      existingWorkPolicy: ExistingWorkPolicy.keep,
    );

    final prefs = await SharedPreferences.getInstance();

    final bool notifEnabled = prefs.getBool('notifications_enabled') ?? true;
    final int notifInterval = prefs.getInt('notification_interval') ?? 60;
    if (notifEnabled) {
      await BackgroundEngine().scheduleZekrNotification(notifInterval);
    }
  } catch (_) {}
}

// ─────────────────────────────────────────────────────────────────────────────
// Root application widget
// ─────────────────────────────────────────────────────────────────────────────

class QuranDawahApp extends StatefulWidget {
  const QuranDawahApp({Key? key}) : super(key: key);

  @override
  State<QuranDawahApp> createState() => _QuranDawahAppState();
}

class _QuranDawahAppState extends State<QuranDawahApp> {
  @override
  void initState() {
    super.initState();
    // Defer all heavy I/O until the engine has rendered the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initHeavyServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        return ValueListenableBuilder<Locale>(
          valueListenable: AppLanguage.notifier,
          builder: (context, locale, _) {
            return MaterialApp(
              title: 'Quran Zone',
              debugShowCheckedModeBanner: false,
              locale: locale,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                FallbackMaterialLocalizationsDelegate(),
                FallbackWidgetsLocalizationsDelegate(),
                FallbackCupertinoLocalizationsDelegate(),
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('am'),
                Locale('om'),
                Locale('ar'),
              ],
              theme: ThemeData(
                primaryColor: AppTheme.getPrimaryColor(theme),
                scaffoldBackgroundColor: AppTheme.getScreenBgColor(theme),
                cardTheme: CardThemeData(
                  color: AppTheme.getPageBgColor(theme),
                ),
                appBarTheme: AppBarTheme(
                  backgroundColor: AppTheme.getAppBarBgColor(theme),
                  elevation: 1,
                  centerTitle: true,
                  titleTextStyle: TextStyle(
                    color: AppTheme.getAppBarTextColor(theme),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  iconTheme: IconThemeData(
                    color: AppTheme.getAppBarTextColor(theme),
                  ),
                ),
                colorScheme: ColorScheme.fromSwatch().copyWith(
                  secondary: AppTheme.getPrimaryColor(theme),
                  primary: AppTheme.getPrimaryColor(theme),
                  brightness: theme == QuranTheme.dark
                      ? Brightness.dark
                      : Brightness.light,
                ),
                bottomNavigationBarTheme: BottomNavigationBarThemeData(
                  backgroundColor: AppTheme.getBottomBarBgColor(theme),
                  selectedItemColor: AppTheme.getPrimaryColor(theme),
                  unselectedItemColor: Colors.grey,
                ),
              ),
              // ── Root-level builder: wraps ALL routes ──────────────
              // The PersistentBannerAd lives here so it is visible on
              // every single screen in the app (except the Holy Quran
              // reading screen, which sets kQuranScreenActive = true).
              builder: (context, child) {
                return ValueListenableBuilder<bool>(
                  valueListenable: kQuranScreenActive,
                  builder: (context, isQuranActive, _) {
                    return ColoredBox(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: Column(
                        children: [
                          if (!isQuranActive)
                            const SafeArea(
                              bottom: false,
                              child: PersistentBannerAd(),
                            ),
                          Expanded(
                            child: isQuranActive
                                ? (child ?? const SizedBox.shrink())
                                : MediaQuery(
                                    data: MediaQuery.of(context).copyWith(
                                      padding: MediaQuery.of(context)
                                          .padding
                                          .copyWith(top: 0),
                                    ),
                                    child: child ?? const SizedBox.shrink(),
                                  ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}
