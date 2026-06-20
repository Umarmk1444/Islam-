// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get settings => 'Settings';

  @override
  String get appLanguage => 'App Language';

  @override
  String get selectLanguage => 'Select Language';

  @override
  String get preferences => 'Preferences';

  @override
  String get appTheme => 'App Theme';

  @override
  String get themeCream => 'Cream';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeWhite => 'White';

  @override
  String get dailyNotifications => 'Daily Notifications';

  @override
  String get dailyNotificationsDesc => 'Receive daily verses & reminders';

  @override
  String get storageAndData => 'Storage & Data';

  @override
  String get clearDownloadedAudio => 'Clear Downloaded Audio';

  @override
  String get freeUpSpace => 'Free up space on your device';

  @override
  String get audioCacheCleared => 'Audio cache cleared.';

  @override
  String get noAudioFound => 'No audio files found.';

  @override
  String get supportAndAbout => 'Support & About';

  @override
  String get shareApp => 'Share App';

  @override
  String get shareAppText =>
      'Download the Quran & Dawah app to read the Quran and listen to Islamic scholars!';

  @override
  String get rateUs => 'Rate Us';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get aboutApp => 'About Quran & Dawah App';

  @override
  String get madeWithLove => 'Made with ♥ for the Ummah';

  @override
  String get navQuran => 'Quran';

  @override
  String get navDawah => 'Dawah';

  @override
  String get navSettings => 'Settings';

  @override
  String get dawahScholars => 'Dawah Scholars';

  @override
  String availableItems(int count) {
    return '$count Available Items';
  }

  @override
  String get downloadAll => 'Download All';

  @override
  String get lectures => 'Lectures';

  @override
  String get version => 'Version';
}
