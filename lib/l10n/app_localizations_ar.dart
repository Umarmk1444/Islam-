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
      'قم بتنزيل تطبيق القرآن والدعوة لقراءة القرآن والاستماع إلى العلماء الإسلاميين!';

  @override
  String get rateUs => 'قيمنا';

  @override
  String get contactUs => 'اتصل بنا';

  @override
  String get aboutApp => 'حول تطبيق القرآن والدعوة';

  @override
  String get madeWithLove => 'صُنع بـ ♥ للأمة';

  @override
  String get navQuran => 'القرآن';

  @override
  String get navDawah => 'الدعوة';

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
}
