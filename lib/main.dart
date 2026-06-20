import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'theme_notifier.dart';
import 'language_notifier.dart';
import 'screens/quran_screen.dart';
import 'screens/dawah_screen.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';
import 'fallback_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTheme.init();
  await AppLanguage.init();
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
              home: const MainNavigator(),
            );
          },
        );
      },
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({Key? key}) : super(key: key);

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const QuranScreen(),
    const DawahScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_book),
            label: l10n.navQuran,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.record_voice_over),
            label: l10n.navDawah,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
