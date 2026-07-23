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
  String get navDashboard => 'Dashboard';

  @override
  String get navMinbar => 'Minbar';

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

  @override
  String get contactDeveloper => 'Contact Developer';

  @override
  String get contactDeveloperDesc => 'Direct link with developer @UMER_jr';

  @override
  String get contactDeveloperText =>
      'For any issues, recommendations, or general inquiries, please feel free to contact me directly via Telegram.';

  @override
  String get chatOnTelegram => 'Chat on Telegram';

  @override
  String get copyUsername => 'Copy Username';

  @override
  String get copiedToClipboard => 'Saved to clipboard: @UMER_jr';

  @override
  String get translation => 'Translation';

  @override
  String get tafsir => 'Tafsir';

  @override
  String get nextAyah => 'Next Ayah';

  @override
  String get previousAyah => 'Previous Ayah';

  @override
  String get repetition => 'Repetition';

  @override
  String get delayInterval => 'Delay Between Ayahs';

  @override
  String get reciterAlafasy => 'Mishary Rashid Alafasy';

  @override
  String get infinite => 'Infinite';

  @override
  String get none => 'None';

  @override
  String secondsShort(int count) {
    return '${count}s';
  }

  @override
  String get verseDuration => 'Verse Length';

  @override
  String get actionTafsir => 'Tafsir';

  @override
  String get actionTranslation => 'Translation';

  @override
  String get actionListen => 'Listen / Audio';

  @override
  String get actionCopyAyah => 'Copy Ayah Text';

  @override
  String get actionCopyPage => 'Copy Page Text';

  @override
  String get actionShareText => 'Share Text';

  @override
  String get actionShareImage => 'Share Image';

  @override
  String get actionSaveBookmark => 'Save Bookmark';

  @override
  String get actionGoToBookmark => 'Go to Bookmark';

  @override
  String get actionIndex => 'Index';

  @override
  String get actionClose => 'Close';

  @override
  String get actionSearch => 'Search';

  @override
  String get actionTheme => 'Theme';

  @override
  String get audioReciter => 'Reciter';

  @override
  String get loading => 'Loading...';

  @override
  String get errorFetchingData => 'Error fetching data';

  @override
  String get selectAction => 'Select Action';

  @override
  String get selectLanguageTafsir => 'Select Tafsir Language';

  @override
  String get selectLanguageTranslation => 'Select Translation Language';

  @override
  String get selectTafsirBook => 'Select Tafsir Book';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageAmharic => 'Amharic';

  @override
  String get languageOromo => 'Oromo';

  @override
  String get retry => 'Retry';

  @override
  String get noTafsirAvailable => 'No tafsir available for this language';

  @override
  String get noTranslationAvailable => 'No translation available';

  @override
  String get prayerTimes => 'Prayer Times';

  @override
  String get nextPrayer => 'Next Prayer';

  @override
  String get countdown => 'Countdown';

  @override
  String get prayerFajr => 'Fajr';

  @override
  String get prayerSunrise => 'Sunrise';

  @override
  String get prayerDhuhr => 'Dhuhr';

  @override
  String get prayerAsr => 'Asr';

  @override
  String get prayerMaghrib => 'Maghrib';

  @override
  String get prayerIsha => 'Isha';

  @override
  String get calcMethod => 'Calculation Method';

  @override
  String get madhab => 'Madhab (Asr)';

  @override
  String get locationSync => 'Sync GPS Location';

  @override
  String get notifEnabled => 'Notification On';

  @override
  String get notifDisabled => 'Notification Off';

  @override
  String get methodUmmAlQura => 'Umm al-Qura';

  @override
  String get methodEgyptian => 'Egyptian';

  @override
  String get methodMWL => 'Muslim World League';

  @override
  String get methodISNA => 'ISNA';

  @override
  String get methodKarachi => 'Karachi';

  @override
  String get madhabHanafi => 'Hanafi';

  @override
  String get madhabShafi => 'Shafi / Maliki / Hanbali';

  @override
  String get gpsPermissionDenied => 'Location permission denied';

  @override
  String get usingFallbackLocation => 'Using fallback: Makkah';

  @override
  String get prayerSettingsTitle => 'Prayer Settings';

  @override
  String get qiblaTitle => 'Qibla Direction';

  @override
  String get qiblaAlignPhone => 'Align your phone flat for accuracy';

  @override
  String get qiblaDistance => 'Distance to Kaaba';

  @override
  String get qiblaAngle => 'Qibla Angle';

  @override
  String get qiblaKm => 'KM';

  @override
  String qiblaCompassError(String error) {
    return 'Error reading compass sensor: $error';
  }

  @override
  String get qiblaNoCompass => 'Compass hardware not detected.';

  @override
  String qiblaStaticAngle(String angle) {
    return 'Static Qibla Angle: $angle°';
  }

  @override
  String get qiblaLocationDisabled => 'Location services are disabled.';

  @override
  String get qiblaPermissionDenied => 'Location permissions are denied.';

  @override
  String get qiblaPermissionPermanentlyDenied =>
      'Location permissions are permanently denied.';

  @override
  String qiblaFailedInit(String error) {
    return 'Failed to initialize: $error';
  }

  @override
  String get qiblaNorth => 'North';

  @override
  String get qiblaEast => 'East';

  @override
  String get qiblaSouth => 'South';

  @override
  String get qiblaWest => 'West';

  @override
  String get qiblaPermissionRequired => 'Location Permission Required';

  @override
  String get qiblaEnableLocation => 'Enable Location';

  @override
  String get athanNotifDesc => 'Enable Athan sound alert';

  @override
  String get preAthanWarning => 'Pre-Prayer Warning';

  @override
  String get off => 'Off';

  @override
  String get minLabel => 'm';

  @override
  String get custom => 'Custom';

  @override
  String get timeAdjustment => 'Time Adjustment (Manual)';

  @override
  String get adjustAthan => 'Advance or delay Athan';

  @override
  String get muezzinVoice => 'Muezzin Voice';

  @override
  String get customTimeMin => 'Custom Time (Minutes)';

  @override
  String get example30 => 'Example: 30';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get chooseMuezzin => 'Choose Muezzin';

  @override
  String get muezzinMecca => 'Mecca - Ali Mulla';

  @override
  String get muezzinNasser => 'Nasser Al Qatami';

  @override
  String get muezzinZahrani => 'Mansour Al Zahrani';

  @override
  String get muezzinDosari => 'Yasser Al Dosari';

  @override
  String get muezzinAbdulbasit => 'Abdulbasit Abdulsamad';

  @override
  String get muezzinAlafasy => 'Mishary Alafasy';

  @override
  String get navLibrary => 'Library';

  @override
  String get libraryAll => 'All';

  @override
  String get libraryFavorites => 'Favorites';

  @override
  String get noStoriesFound => 'No stories found.';

  @override
  String readingsCount(int count) {
    return 'Readings: $count';
  }

  @override
  String get playbackSettings => 'Playback Settings';

  @override
  String get intervalGap => 'Interval';

  @override
  String get playbackSpeed => 'Speed';

  @override
  String get noneOffLabel => 'None';

  @override
  String get secLabel => 'Sec';

  @override
  String get ayahLabel => 'Ayah';

  @override
  String get sleepTimer => 'Sleep Timer';

  @override
  String get stopAudioAfter => 'Stop audio automatically after:';

  @override
  String get minutesLabel => 'Min';

  @override
  String get customMinHint => 'Custom minute...';

  @override
  String get start => 'Start';

  @override
  String get timerCanceled => 'Timer canceled';

  @override
  String get cancelCurrentTimer => 'Cancel current timer';
}
