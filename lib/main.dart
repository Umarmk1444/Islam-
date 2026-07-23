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
import 'core/services/background_engine.dart';
import 'widgets/system_zekr_overlay.dart';

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
}

// ─────────────────────────────────────────────────────────────────────────────
// Overlay entry-point (flutter_overlay_window)
// ─────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SystemZekrOverlay(),
        ),
      ),
    ),
  );
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
              title: 'Quran & Dawah',
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
              home: const SplashScreen(),
            );
          },
        );
      },
    );
  }
}
