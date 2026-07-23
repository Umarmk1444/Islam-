import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'theme_notifier.dart';
import 'language_notifier.dart';
import 'dashboard_scale_notifier.dart';

import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'fallback_localizations.dart';
import 'core/database/database_helper.dart';

import 'package:just_audio_background/just_audio_background.dart';
import 'core/services/background_engine.dart';
import 'widgets/system_zekr_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundEngine().init();
  await AppTheme.init();
  await AppLanguage.init();
  await DashboardScale.init();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.sadaga.quran_dawah.channel.audio',
    androidNotificationChannelName: 'Audio Playback',
    androidNotificationOngoing: true,
  );

  // Only init notifications on mobile — not on web/chrome
  try {
    await NotificationService().init();
  } catch (_) {}

  // ── TEMPORARY DEBUG: dump raw DB text for Sajdah verses ───────────────
  await _debugDumpAyah(surah: 32, ayah: 15);
  await _debugDumpAyah(surah: 96, ayah: 19);
  // ── END DEBUG ─────────────────────────────────────────────────────────────

  runApp(const QuranDawahApp());
}

@pragma("vm:entry-point")
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

/// Queries the raw `aya` column from the database for the given [surah]:[ayah]
/// and prints every character with its Unicode code point. Remove when done.
Future<void> _debugDumpAyah({required int surah, required int ayah}) async {
  try {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
      'SELECT aya FROM quran WHERE sura_num = ? AND aya_num = ? LIMIT 1',
      [surah, ayah],
    );
    if (rows.isEmpty) {
      debugPrint('[DB_DEBUG] No row found for $surah:$ayah');
      return;
    }
    final text = rows.first['aya'] as String? ?? '';
    debugPrint('════════════════════════════════════════════════');
    debugPrint('[DB_DEBUG] RAW DB text for Surah $surah : Ayah $ayah');
    debugPrint('[DB_DEBUG] Total chars: ${text.length}');
    debugPrint('[DB_DEBUG] Full string: "$text"');
    debugPrint('────────────────────────────────────────────────');
    for (int i = 0; i < text.length; i++) {
      final c = text[i];
      final hex = c.codeUnitAt(0).toRadixString(16).toUpperCase().padLeft(4, '0');
      debugPrint('[DB_DEBUG] [$i] char="$c"  U+$hex  (decimal=${c.codeUnitAt(0)})');
    }
    debugPrint('════════════════════════════════════════════════');
  } catch (e) {
    debugPrint('[DB_DEBUG] ERROR: $e');
  }
}

class QuranDawahApp extends StatelessWidget {
  const QuranDawahApp({Key? key}) : super(key: key);

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
                  brightness: theme == QuranTheme.dark ? Brightness.dark : Brightness.light,
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

