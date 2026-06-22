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
  /// **'Download the Quran & Dawah app to read the Quran and listen to Islamic scholars!'**
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
  /// **'About Quran & Dawah App'**
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
