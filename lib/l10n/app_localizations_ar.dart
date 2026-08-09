// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get settings => 'الإعدادات';

  @override
  String get appLanguage => 'لغة التطبيق';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get preferences => 'التفضيلات';

  @override
  String get appTheme => 'مظهر التطبيق';

  @override
  String get themeCream => 'كريمي';

  @override
  String get themeDark => 'داكن';

  @override
  String get themeWhite => 'أبيض';

  @override
  String get dailyNotifications => 'الإشعارات اليومية';

  @override
  String get dailyNotificationsDesc => 'تلقي آيات وتذكيرات يومية';

  @override
  String get storageAndData => 'التخزين والبيانات';

  @override
  String get clearDownloadedAudio => 'مسح الصوتيات المحملة';

  @override
  String get freeUpSpace => 'تفريغ مساحة على جهازك';

  @override
  String get audioCacheCleared => 'تم مسح ذاكرة التخزين المؤقت للصوت.';

  @override
  String get noAudioFound => 'لم يتم العثور على ملفات صوتية.';

  @override
  String get supportAndAbout => 'الدعم وحول التطبيق';

  @override
  String get shareApp => 'مشاركة التطبيق';

  @override
  String get shareAppText =>
      'قم بتنزيل تطبيق قرآن زون لقراءة القرآن والاستماع إلى العلماء الإسلاميين!';

  @override
  String get rateUs => 'قيمنا';

  @override
  String get contactUs => 'اتصل بنا';

  @override
  String get aboutApp => 'حول تطبيق قرآن زون';

  @override
  String get madeWithLove => 'صُنع بـ ♥ للأمة';

  @override
  String get navQuran => 'القرآن';

  @override
  String get navDawah => 'الدعوة';

  @override
  String get navDashboard => 'لوحة المعلومات';

  @override
  String get navMinbar => 'المنبر';

  @override
  String get navSettings => 'الإعدادات';

  @override
  String get dawahScholars => 'علماء الدعوة';

  @override
  String availableItems(int count) {
    return '$count عناصر متاحة';
  }

  @override
  String get downloadAll => 'تحميل الكل';

  @override
  String get lectures => 'المحاضرات';

  @override
  String get version => 'الإصدار';

  @override
  String get contactDeveloper => 'تواصل مع المطور';

  @override
  String get contactDeveloperDesc => 'رابط مباشر مع المطور @UMER_jr';

  @override
  String get contactDeveloperText =>
      'لأي مشكلة أو اقتراح أو استفسار، لا تتردد في التواصل معي مباشرة عبر تليجرام.';

  @override
  String get chatOnTelegram => 'دردش عبر تليجرام';

  @override
  String get copyUsername => 'نسخ اسم المستخدم';

  @override
  String get copiedToClipboard => 'تم النسخ إلى الحافظة: @UMER_jr';

  @override
  String get translation => 'الترجمة';

  @override
  String get tafsir => 'التفسير';

  @override
  String get nextAyah => 'الآية التالية';

  @override
  String get previousAyah => 'الآية السابقة';

  @override
  String get repetition => 'التكرار';

  @override
  String get delayInterval => 'الانتظار بين الآيتين';

  @override
  String get reciterAlafasy => 'مشاري راشد العفاسي';

  @override
  String get infinite => 'لا نهائي';

  @override
  String get none => 'بدون';

  @override
  String secondsShort(int count) {
    return '$countث';
  }

  @override
  String get verseDuration => 'طول الآية';

  @override
  String get actionTafsir => 'التفسير';

  @override
  String get actionTranslation => 'الترجمة';

  @override
  String get actionListen => 'استماع';

  @override
  String get actionCopyAyah => 'نسخ الآية';

  @override
  String get actionCopyPage => 'نسخ الصفحة';

  @override
  String get actionShareText => 'مشاركة النص';

  @override
  String get actionShareImage => 'مشاركة الصورة';

  @override
  String get actionSaveBookmark => 'حفظ العلامة';

  @override
  String get actionGoToBookmark => 'الذهاب للعلامة';

  @override
  String get actionIndex => 'الفهرس';

  @override
  String get actionClose => 'إغلاق';

  @override
  String get actionSearch => 'البحث';

  @override
  String get actionTheme => 'المظهر';

  @override
  String get audioReciter => 'القارئ';

  @override
  String get loading => 'جاري التحميل...';

  @override
  String get errorFetchingData => 'خطأ في جلب البيانات';

  @override
  String get selectAction => 'اختر إجراء';

  @override
  String get selectLanguageTafsir => 'اختر لغة التفسير';

  @override
  String get selectLanguageTranslation => 'اختر لغة الترجمة';

  @override
  String get selectTafsirBook => 'اختر كتاب التفسير';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'الإنجليزية';

  @override
  String get languageAmharic => 'الأمهرية';

  @override
  String get languageOromo => 'الأورومية';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get noTafsirAvailable => 'لا يتوفر تفسير لهذه اللغة';

  @override
  String get noTranslationAvailable => 'الترجمة غير متوفرة';

  @override
  String get prayerTimes => 'مواقيت الصلاة';

  @override
  String get nextPrayer => 'الصلاة القادمة';

  @override
  String get countdown => 'العد التنازلي';

  @override
  String get prayerFajr => 'الفجر';

  @override
  String get prayerSunrise => 'الشروق';

  @override
  String get prayerDhuhr => 'الظهر';

  @override
  String get prayerAsr => 'العصر';

  @override
  String get prayerMaghrib => 'المغرب';

  @override
  String get prayerIsha => 'العشاء';

  @override
  String get calcMethod => 'طريقة الحساب';

  @override
  String get madhab => 'المذهب (العصر)';

  @override
  String get locationSync => 'مزامنة الموقع';

  @override
  String get notifEnabled => 'الإشعار مفعّل';

  @override
  String get notifDisabled => 'الإشعار معطّل';

  @override
  String get methodUmmAlQura => 'أم القرى';

  @override
  String get methodEgyptian => 'الهيئة المصرية';

  @override
  String get methodMWL => 'رابطة العالم الإسلامي';

  @override
  String get methodISNA => 'ISNA';

  @override
  String get methodKarachi => 'كراتشي';

  @override
  String get madhabHanafi => 'حنفي';

  @override
  String get madhabShafi => 'شافعي / مالكي / حنبلي';

  @override
  String get gpsPermissionDenied => 'تم رفض إذن الموقع';

  @override
  String get usingFallbackLocation => 'استخدام الموقع الاحتياطي: مكة';

  @override
  String get prayerSettingsTitle => 'إعدادات الصلاة';

  @override
  String get qiblaTitle => 'اتجاه القبلة';

  @override
  String get qiblaAlignPhone => 'ضع هاتفك بشكل مسطح للحصول على دقة أفضل';

  @override
  String get qiblaDistance => 'المسافة إلى الكعبة';

  @override
  String get qiblaAngle => 'زاوية القبلة';

  @override
  String get qiblaKm => 'كم';

  @override
  String qiblaCompassError(String error) {
    return 'خطأ في قراءة مستشعر البوصلة: $error';
  }

  @override
  String get qiblaNoCompass => 'لم يتم الكشف عن مستشعر البوصلة.';

  @override
  String qiblaStaticAngle(String angle) {
    return 'زاوية القبلة الثابتة: $angle°';
  }

  @override
  String get qiblaLocationDisabled => 'خدمات الموقع معطلة.';

  @override
  String get qiblaPermissionDenied => 'تم رفض إذن الموقع.';

  @override
  String get qiblaPermissionPermanentlyDenied => 'تم رفض إذن الموقع بشكل دائم.';

  @override
  String qiblaFailedInit(String error) {
    return 'فشل تهيئة الموقع: $error';
  }

  @override
  String get qiblaNorth => 'الشمال';

  @override
  String get qiblaEast => 'الشرق';

  @override
  String get qiblaSouth => 'الجنوب';

  @override
  String get qiblaWest => 'الغرب';

  @override
  String get qiblaPermissionRequired => 'إذن الموقع مطلوب';

  @override
  String get qiblaEnableLocation => 'تمكين الموقع';

  @override
  String get athanNotifDesc => 'تفعيل التنبيه بصوت الأذان';

  @override
  String get preAthanWarning => 'تنبيه اقتراب الصلاة';

  @override
  String get off => 'إيقاف';

  @override
  String get minLabel => 'د';

  @override
  String get custom => 'مخصص';

  @override
  String get timeAdjustment => 'تعديل الوقت (يدوي)';

  @override
  String get adjustAthan => 'تقديم أو تأخير الأذان';

  @override
  String get muezzinVoice => 'صوت المؤذن';

  @override
  String get customTimeMin => 'وقت مخصص (بالدقائق)';

  @override
  String get example30 => 'مثال: 30';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get chooseMuezzin => 'اختر المؤذن';

  @override
  String get muezzinMecca => 'الحرم المكي - علي ملا';

  @override
  String get muezzinNasser => 'ناصر القطامي';

  @override
  String get muezzinZahrani => 'منصور الزهراني';

  @override
  String get muezzinDosari => 'ياسر الدوسري';

  @override
  String get muezzinAbdulbasit => 'عبدالباسط عبدالصمد';

  @override
  String get muezzinAlafasy => 'مشاري العفاسي';

  @override
  String get navLibrary => 'المكتبة';

  @override
  String get libraryAll => 'الكل';

  @override
  String get libraryFavorites => 'المفضلة';

  @override
  String get noStoriesFound => 'لا توجد قصص.';

  @override
  String readingsCount(int count) {
    return 'القراءات: $count';
  }

  @override
  String get playbackSettings => 'إعدادات التشغيل';

  @override
  String get intervalGap => 'الفاصل';

  @override
  String get playbackSpeed => 'السرعة';

  @override
  String get noneOffLabel => 'لا';

  @override
  String get secLabel => 'ث';

  @override
  String get ayahLabel => 'آية';

  @override
  String get sleepTimer => 'مؤقت النوم';

  @override
  String get stopAudioAfter => 'إيقاف الصوت تلقائياً بعد:';

  @override
  String get minutesLabel => 'دقيقة';

  @override
  String get customMinHint => 'دقيقة مخصصة...';

  @override
  String get start => 'بدء';

  @override
  String get timerCanceled => 'تم إلغاء المؤقت';

  @override
  String get cancelCurrentTimer => 'إلغاء المؤقت الحالي';

  @override
  String get minbarQuranTitle => 'القرآن الكريم';

  @override
  String get minbarDawahTitle => 'الدعوة والدروس (بالعربية)';

  @override
  String get minbarAmharicLessons => 'الدعوة والدروس (بالأمهرية)';

  @override
  String get minbarOromoLessons => 'الدعوة والدروس (بالأورومية)';

  @override
  String get minbarDownloadsTitle => 'مكتبتي (التنزيلات)';

  @override
  String get minbarQuranSubtitle => 'تلاوات عذبة بأصوات كبار القراء';

  @override
  String get minbarDawahSubtitle => 'خطب، أدعية، رقية شرعية، وابتهالات';

  @override
  String get minbarDownloadsSubtitle => 'الاستماع للملفات الصوتية بدون إنترنت';

  @override
  String get minbarComingSoon => 'قريباً';

  @override
  String get minbarHeaderSubtitle =>
      'استمع إلى تلاوات القرآن الكريم والدروس الإسلامية';

  @override
  String get forceSyncTimeAndLocation => 'فرض مزامنة الوقت والموقع';

  @override
  String get tapToSetLocation => 'اضغط لتحديد الموقع';

  @override
  String get notificationAlarmRequired =>
      'إشعار التنبيه مطلوب لرفع الأذان في وقته بدقة';

  @override
  String get backgroundExecution => 'التشغيل في الخلفية';

  @override
  String get setupGuide => 'دليل الإعداد';

  @override
  String get selectLocation => 'اختر الموقع';

  @override
  String get country => 'الدولة';

  @override
  String get cityRegion => 'المدينة / المنطقة';

  @override
  String get search => 'بحث...';

  @override
  String get saveLocation => 'حفظ الموقع';

  @override
  String get fajr => 'الفجر';

  @override
  String get sunrise => 'الشروق';

  @override
  String get dhuhr => 'الظهر';

  @override
  String get asr => 'العصر';

  @override
  String get maghrib => 'المغرب';

  @override
  String get isha => 'العشاء';

  @override
  String get autoDetectLocation => 'تحديد الموقع تلقائيًا (GPS)';

  @override
  String get calculationMethod => 'طريقة الحساب';

  @override
  String get generalSettings => 'عام';

  @override
  String get twentyFourHourClock => 'نظام 24 ساعة';

  @override
  String get hijriDateOffset => 'تعديل التاريخ الهجري';

  @override
  String get hijriOffsetDescription => 'تعديل للتوافق مع رؤية الهلال المحلية';

  @override
  String get advancedSettings => 'متقدم';

  @override
  String get ensureAthanPlaysInBackground => 'ضمان عمل الأذان في الخلفية';

  @override
  String get recalculatePrayerTimes => 'إعادة حساب جميع أوقات الصلاة الآن';

  @override
  String get syncingLocation => 'جاري مزامنة الموقع...';

  @override
  String get neverMissPrayer => 'لا تفوت أي صلاة';

  @override
  String get setupGuideDescription =>
      'لضمان عمل الأذان في الخلفية في الوقت المحدد بدقة، يرجى تفعيل الأذونات التالية.';

  @override
  String get notificationsTitle => 'الإشعارات';

  @override
  String get notificationsSubtitle => 'مطلوب لإظهار تنبيهات الأذان';

  @override
  String get exactAlarmsTitle => 'المنبهات الدقيقة';

  @override
  String get batteryOptimizationSubtitle =>
      'يمنع الهاتف من إغلاق الأذان لتوفير البطارية';

  @override
  String get done => 'تم';

  @override
  String get completeSetupAbove => 'أكمل الإعداد أعلاه';

  @override
  String get allow => 'سماح';
}
