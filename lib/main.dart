import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'theme_notifier.dart';
import 'language_notifier.dart';

import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'fallback_localizations.dart';

import 'package:just_audio_background/just_audio_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTheme.init();
  await AppLanguage.init();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.sadaga.quran_dawah.channel.audio',
    androidNotificationChannelName: 'Audio Playback',
    androidNotificationOngoing: true,
  );

  // Only init notifications on mobile — not on web/chrome
  try {
    await NotificationService().init();
  } catch (_) {}
  runApp(const QuranDawahApp());
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

