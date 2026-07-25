import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_om.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('ar'),
    Locale('en'),
    Locale('om')
  ];

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @appTheme.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get appTheme;

  /// No description provided for @themeCream.
  ///
  /// In en, this message translates to:
  /// **'Cream'**
  String get themeCream;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get themeWhite;

  /// No description provided for @dailyNotifications.
  ///
  /// In en, this message translates to:
  /// **'Daily Notifications'**
  String get dailyNotifications;

  /// No description provided for @dailyNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Receive daily verses & reminders'**
  String get dailyNotificationsDesc;

  /// No description provided for @storageAndData.
  ///
  /// In en, this message translates to:
  /// **'Storage & Data'**
  String get storageAndData;

  /// No description provided for @clearDownloadedAudio.
  ///
  /// In en, this message translates to:
  /// **'Clear Downloaded Audio'**
  String get clearDownloadedAudio;

  /// No description provided for @freeUpSpace.
  ///
  /// In en, this message translates to:
  /// **'Free up space on your device'**
  String get freeUpSpace;

  /// No description provided for @audioCacheCleared.
  ///
  /// In en, this message translates to:
  /// **'Audio cache cleared.'**
  String get audioCacheCleared;

  /// No description provided for @noAudioFound.
  ///
  /// In en, this message translates to:
  /// **'No audio files found.'**
  String get noAudioFound;

  /// No description provided for @supportAndAbout.
  ///
  /// In en, this message translates to:
  /// **'Support & About'**
  String get supportAndAbout;

  /// No description provided for @shareApp.
  ///
  /// In en, this message translates to:
  /// **'Share App'**
  String get shareApp;

  /// No description provided for @shareAppText.
  ///
  /// In en, this message translates to:
  /// **'Download the Quran Zone app to read the Quran and listen to Islamic scholars!'**
  String get shareAppText;

  /// No description provided for @rateUs.
  ///
  /// In en, this message translates to:
  /// **'Rate Us'**
  String get rateUs;

  /// No description provided for @contactUs.
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About Quran Zone App'**
  String get aboutApp;

  /// No description provided for @madeWithLove.
  ///
  /// In en, this message translates to:
  /// **'Made with ♥ for the Ummah'**
  String get madeWithLove;

  /// No description provided for @navQuran.
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get navQuran;

  /// No description provided for @navDawah.
  ///
  /// In en, this message translates to:
  /// **'Dawah'**
  String get navDawah;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navMinbar.
  ///
  /// In en, this message translates to:
  /// **'Minbar'**
  String get navMinbar;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @dawahScholars.
  ///
  /// In en, this message translates to:
  /// **'Dawah Scholars'**
  String get dawahScholars;

  /// No description provided for @availableItems.
  ///
  /// In en, this message translates to:
  /// **'{count} Available Items'**
  String availableItems(int count);

  /// No description provided for @downloadAll.
  ///
  /// In en, this message translates to:
  /// **'Download All'**
  String get downloadAll;

  /// No description provided for @lectures.
  ///
  /// In en, this message translates to:
  /// **'Lectures'**
  String get lectures;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @contactDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Contact Developer'**
  String get contactDeveloper;

  /// No description provided for @contactDeveloperDesc.
  ///
  /// In en, this message translates to:
  /// **'Direct link with developer @UMER_jr'**
  String get contactDeveloperDesc;

  /// No description provided for @contactDeveloperText.
  ///
  /// In en, this message translates to:
  /// **'For any issues, recommendations, or general inquiries, please feel free to contact me directly via Telegram.'**
  String get contactDeveloperText;

  /// No description provided for @chatOnTelegram.
  ///
  /// In en, this message translates to:
  /// **'Chat on Telegram'**
  String get chatOnTelegram;

  /// No description provided for @copyUsername.
  ///
  /// In en, this message translates to:
  /// **'Copy Username'**
  String get copyUsername;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Saved to clipboard: @UMER_jr'**
  String get copiedToClipboard;

  /// No description provided for @translation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translation;

  /// No description provided for @tafsir.
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get tafsir;

  /// No description provided for @nextAyah.
  ///
  /// In en, this message translates to:
  /// **'Next Ayah'**
  String get nextAyah;

  /// No description provided for @previousAyah.
  ///
  /// In en, this message translates to:
  /// **'Previous Ayah'**
  String get previousAyah;

  /// No description provided for @repetition.
  ///
  /// In en, this message translates to:
  /// **'Repetition'**
  String get repetition;

  /// No description provided for @delayInterval.
  ///
  /// In en, this message translates to:
  /// **'Delay Between Ayahs'**
  String get delayInterval;

  /// No description provided for @reciterAlafasy.
  ///
  /// In en, this message translates to:
  /// **'Mishary Rashid Alafasy'**
  String get reciterAlafasy;

  /// No description provided for @infinite.
  ///
  /// In en, this message translates to:
  /// **'Infinite'**
  String get infinite;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @secondsShort.
  ///
  /// In en, this message translates to:
  /// **'{count}s'**
  String secondsShort(int count);

  /// No description provided for @verseDuration.
  ///
  /// In en, this message translates to:
  /// **'Verse Length'**
  String get verseDuration;

  /// No description provided for @actionTafsir.
  ///
  /// In en, this message translates to:
  /// **'Tafsir'**
  String get actionTafsir;

  /// No description provided for @actionTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get actionTranslation;

  /// No description provided for @actionListen.
  ///
  /// In en, this message translates to:
  /// **'Listen / Audio'**
  String get actionListen;

  /// No description provided for @actionCopyAyah.
  ///
  /// In en, this message translates to:
  /// **'Copy Ayah Text'**
  String get actionCopyAyah;

  /// No description provided for @actionCopyPage.
  ///
  /// In en, this message translates to:
  /// **'Copy Page Text'**
  String get actionCopyPage;

  /// No description provided for @actionShareText.
  ///
  /// In en, this message translates to:
  /// **'Share Text'**
  String get actionShareText;

  /// No description provided for @actionShareImage.
  ///
  /// In en, this message translates to:
  /// **'Share Image'**
  String get actionShareImage;

  /// No description provided for @actionSaveBookmark.
  ///
  /// In en, this message translates to:
  /// **'Save Bookmark'**
  String get actionSaveBookmark;

  /// No description provided for @actionGoToBookmark.
  ///
  /// In en, this message translates to:
  /// **'Go to Bookmark'**
  String get actionGoToBookmark;

  /// No description provided for @actionIndex.
  ///
  /// In en, this message translates to:
  /// **'Index'**
  String get actionIndex;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get actionSearch;

  /// No description provided for @actionTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get actionTheme;

  /// No description provided for @audioReciter.
  ///
  /// In en, this message translates to:
  /// **'Reciter'**
  String get audioReciter;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @errorFetchingData.
  ///
  /// In en, this message translates to:
  /// **'Error fetching data'**
  String get errorFetchingData;

  /// No description provided for @selectAction.
  ///
  /// In en, this message translates to:
  /// **'Select Action'**
  String get selectAction;

  /// No description provided for @selectLanguageTafsir.
  ///
  /// In en, this message translates to:
  /// **'Select Tafsir Language'**
  String get selectLanguageTafsir;

  /// No description provided for @selectLanguageTranslation.
  ///
  /// In en, this message translates to:
  /// **'Select Translation Language'**
  String get selectLanguageTranslation;

  /// No description provided for @selectTafsirBook.
  ///
  /// In en, this message translates to:
  /// **'Select Tafsir Book'**
  String get selectTafsirBook;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageAmharic.
  ///
  /// In en, this message translates to:
  /// **'Amharic'**
  String get languageAmharic;

  /// No description provided for @languageOromo.
  ///
  /// In en, this message translates to:
  /// **'Oromo'**
  String get languageOromo;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noTafsirAvailable.
  ///
  /// In en, this message translates to:
  /// **'No tafsir available for this language'**
  String get noTafsirAvailable;

  /// No description provided for @noTranslationAvailable.
  ///
  /// In en, this message translates to:
  /// **'No translation available'**
  String get noTranslationAvailable;

  /// No description provided for @prayerTimes.
  ///
  /// In en, this message translates to:
  /// **'Prayer Times'**
  String get prayerTimes;

  /// No description provided for @nextPrayer.
  ///
  /// In en, this message translates to:
  /// **'Next Prayer'**
  String get nextPrayer;

  /// No description provided for @countdown.
  ///
  /// In en, this message translates to:
  /// **'Countdown'**
  String get countdown;

  /// No description provided for @prayerFajr.
  ///
  /// In en, this message translates to:
  /// **'Fajr'**
  String get prayerFajr;

  /// No description provided for @prayerSunrise.
  ///
  /// In en, this message translates to:
  /// **'Sunrise'**
  String get prayerSunrise;

  /// No description provided for @prayerDhuhr.
  ///
  /// In en, this message translates to:
  /// **'Dhuhr'**
  String get prayerDhuhr;

  /// No description provided for @prayerAsr.
  ///
  /// In en, this message translates to:
  /// **'Asr'**
  String get prayerAsr;

  /// No description provided for @prayerMaghrib.
  ///
  /// In en, this message translates to:
  /// **'Maghrib'**
  String get prayerMaghrib;

  /// No description provided for @prayerIsha.
  ///
  /// In en, this message translates to:
  /// **'Isha'**
  String get prayerIsha;

  /// No description provided for @calcMethod.
  ///
  /// In en, this message translates to:
  /// **'Calculation Method'**
  String get calcMethod;

  /// No description provided for @madhab.
  ///
  /// In en, this message translates to:
  /// **'Madhab (Asr)'**
  String get madhab;

  /// No description provided for @locationSync.
  ///
  /// In en, this message translates to:
  /// **'Sync GPS Location'**
  String get locationSync;

  /// No description provided for @notifEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notification On'**
  String get notifEnabled;

  /// No description provided for @notifDisabled.
  ///
  /// In en, this message translates to:
  /// **'Notification Off'**
  String get notifDisabled;

  /// No description provided for @methodUmmAlQura.
  ///
  /// In en, this message translates to:
  /// **'Umm al-Qura'**
  String get methodUmmAlQura;

  /// No description provided for @methodEgyptian.
  ///
  /// In en, this message translates to:
  /// **'Egyptian'**
  String get methodEgyptian;

  /// No description provided for @methodMWL.
  ///
  /// In en, this message translates to:
  /// **'Muslim World League'**
  String get methodMWL;

  /// No description provided for @methodISNA.
  ///
  /// In en, this message translates to:
  /// **'ISNA'**
  String get methodISNA;

  /// No description provided for @methodKarachi.
  ///
  /// In en, this message translates to:
  /// **'Karachi'**
  String get methodKarachi;

  /// No description provided for @madhabHanafi.
  ///
  /// In en, this message translates to:
  /// **'Hanafi'**
  String get madhabHanafi;

  /// No description provided for @madhabShafi.
  ///
  /// In en, this message translates to:
  /// **'Shafi / Maliki / Hanbali'**
  String get madhabShafi;

  /// No description provided for @gpsPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied'**
  String get gpsPermissionDenied;

  /// No description provided for @usingFallbackLocation.
  ///
  /// In en, this message translates to:
  /// **'Using fallback: Makkah'**
  String get usingFallbackLocation;

  /// No description provided for @prayerSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Prayer Settings'**
  String get prayerSettingsTitle;

  /// No description provided for @qiblaTitle.
  ///
  /// In en, this message translates to:
  /// **'Qibla Direction'**
  String get qiblaTitle;

  /// No description provided for @qiblaAlignPhone.
  ///
  /// In en, this message translates to:
  /// **'Align your phone flat for accuracy'**
  String get qiblaAlignPhone;

  /// No description provided for @qiblaDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance to Kaaba'**
  String get qiblaDistance;

  /// No description provided for @qiblaAngle.
  ///
  /// In en, this message translates to:
  /// **'Qibla Angle'**
  String get qiblaAngle;

  /// No description provided for @qiblaKm.
  ///
  /// In en, this message translates to:
  /// **'KM'**
  String get qiblaKm;

  /// No description provided for @qiblaCompassError.
  ///
  /// In en, this message translates to:
  /// **'Error reading compass sensor: {error}'**
  String qiblaCompassError(String error);

  /// No description provided for @qiblaNoCompass.
  ///
  /// In en, this message translates to:
  /// **'Compass hardware not detected.'**
  String get qiblaNoCompass;

  /// No description provided for @qiblaStaticAngle.
  ///
  /// In en, this message translates to:
  /// **'Static Qibla Angle: {angle}°'**
  String qiblaStaticAngle(String angle);

  /// No description provided for @qiblaLocationDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are disabled.'**
  String get qiblaLocationDisabled;

  /// No description provided for @qiblaPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are denied.'**
  String get qiblaPermissionDenied;

  /// No description provided for @qiblaPermissionPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied.'**
  String get qiblaPermissionPermanentlyDenied;

  /// No description provided for @qiblaFailedInit.
  ///
  /// In en, this message translates to:
  /// **'Failed to initialize: {error}'**
  String qiblaFailedInit(String error);

  /// No description provided for @qiblaNorth.
  ///
  /// In en, this message translates to:
  /// **'North'**
  String get qiblaNorth;

  /// No description provided for @qiblaEast.
  ///
  /// In en, this message translates to:
  /// **'East'**
  String get qiblaEast;

  /// No description provided for @qiblaSouth.
  ///
  /// In en, this message translates to:
  /// **'South'**
  String get qiblaSouth;

  /// No description provided for @qiblaWest.
  ///
  /// In en, this message translates to:
  /// **'West'**
  String get qiblaWest;

  /// No description provided for @qiblaPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Location Permission Required'**
  String get qiblaPermissionRequired;

  /// No description provided for @qiblaEnableLocation.
  ///
  /// In en, this message translates to:
  /// **'Enable Location'**
  String get qiblaEnableLocation;

  /// No description provided for @athanNotifDesc.
  ///
  /// In en, this message translates to:
  /// **'Enable Athan sound alert'**
  String get athanNotifDesc;

  /// No description provided for @preAthanWarning.
  ///
  /// In en, this message translates to:
  /// **'Pre-Prayer Warning'**
  String get preAthanWarning;

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @minLabel.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get minLabel;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @timeAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Time Adjustment (Manual)'**
  String get timeAdjustment;

  /// No description provided for @adjustAthan.
  ///
  /// In en, this message translates to:
  /// **'Advance or delay Athan'**
  String get adjustAthan;

  /// No description provided for @muezzinVoice.
  ///
  /// In en, this message translates to:
  /// **'Muezzin Voice'**
  String get muezzinVoice;

  /// No description provided for @customTimeMin.
  ///
  /// In en, this message translates to:
  /// **'Custom Time (Minutes)'**
  String get customTimeMin;

  /// No description provided for @example30.
  ///
  /// In en, this message translates to:
  /// **'Example: 30'**
  String get example30;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @chooseMuezzin.
  ///
  /// In en, this message translates to:
  /// **'Choose Muezzin'**
  String get chooseMuezzin;

  /// No description provided for @muezzinMecca.
  ///
  /// In en, this message translates to:
  /// **'Mecca - Ali Mulla'**
  String get muezzinMecca;

  /// No description provided for @muezzinNasser.
  ///
  /// In en, this message translates to:
  /// **'Nasser Al Qatami'**
  String get muezzinNasser;

  /// No description provided for @muezzinZahrani.
  ///
  /// In en, this message translates to:
  /// **'Mansour Al Zahrani'**
  String get muezzinZahrani;

  /// No description provided for @muezzinDosari.
  ///
  /// In en, this message translates to:
  /// **'Yasser Al Dosari'**
  String get muezzinDosari;

  /// No description provided for @muezzinAbdulbasit.
  ///
  /// In en, this message translates to:
  /// **'Abdulbasit Abdulsamad'**
  String get muezzinAbdulbasit;

  /// No description provided for @muezzinAlafasy.
  ///
  /// In en, this message translates to:
  /// **'Mishary Alafasy'**
  String get muezzinAlafasy;

  /// No description provided for @navLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get navLibrary;

  /// No description provided for @libraryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get libraryAll;

  /// No description provided for @libraryFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get libraryFavorites;

  /// No description provided for @noStoriesFound.
  ///
  /// In en, this message translates to:
  /// **'No stories found.'**
  String get noStoriesFound;

  /// No description provided for @readingsCount.
  ///
  /// In en, this message translates to:
  /// **'Readings: {count}'**
  String readingsCount(int count);

  /// No description provided for @playbackSettings.
  ///
  /// In en, this message translates to:
  /// **'Playback Settings'**
  String get playbackSettings;

  /// No description provided for @intervalGap.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get intervalGap;

  /// No description provided for @playbackSpeed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get playbackSpeed;

  /// No description provided for @noneOffLabel.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noneOffLabel;

  /// No description provided for @secLabel.
  ///
  /// In en, this message translates to:
  /// **'Sec'**
  String get secLabel;

  /// No description provided for @ayahLabel.
  ///
  /// In en, this message translates to:
  /// **'Ayah'**
  String get ayahLabel;

  /// No description provided for @sleepTimer.
  ///
  /// In en, this message translates to:
  /// **'Sleep Timer'**
  String get sleepTimer;

  /// No description provided for @stopAudioAfter.
  ///
  /// In en, this message translates to:
  /// **'Stop audio automatically after:'**
  String get stopAudioAfter;

  /// No description provided for @minutesLabel.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get minutesLabel;

  /// No description provided for @customMinHint.
  ///
  /// In en, this message translates to:
  /// **'Custom minute...'**
  String get customMinHint;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @timerCanceled.
  ///
  /// In en, this message translates to:
  /// **'Timer canceled'**
  String get timerCanceled;

  /// No description provided for @cancelCurrentTimer.
  ///
  /// In en, this message translates to:
  /// **'Cancel current timer'**
  String get cancelCurrentTimer;

  /// No description provided for @minbarQuranTitle.
  ///
  /// In en, this message translates to:
  /// **'القرآن الكريم'**
  String get minbarQuranTitle;

  /// No description provided for @minbarDawahTitle.
  ///
  /// In en, this message translates to:
  /// **'Arabic Dawah & Lectures'**
  String get minbarDawahTitle;

  /// No description provided for @minbarAmharicLessons.
  ///
  /// In en, this message translates to:
  /// **'Amharic Dawah & Lectures'**
  String get minbarAmharicLessons;

  /// No description provided for @minbarOromoLessons.
  ///
  /// In en, this message translates to:
  /// **'Oromo Dawah & Lectures'**
  String get minbarOromoLessons;

  /// No description provided for @minbarDownloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Library (Downloads)'**
  String get minbarDownloadsTitle;

  /// No description provided for @minbarQuranSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recitations by world-renowned reciters'**
  String get minbarQuranSubtitle;

  /// No description provided for @minbarDawahSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Khutbah, Dua, Ruqyah, & Ibtehalat'**
  String get minbarDawahSubtitle;

  /// No description provided for @minbarDownloadsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Listen to downloaded audio offline'**
  String get minbarDownloadsSubtitle;

  /// No description provided for @minbarComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get minbarComingSoon;

  /// No description provided for @minbarHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Listen to القرآن الكريم recitations and Islamic lessons'**
  String get minbarHeaderSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['am', 'ar', 'en', 'om'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am':
      return AppLocalizationsAm();
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'om':
      return AppLocalizationsOm();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
