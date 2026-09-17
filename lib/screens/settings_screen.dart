import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../l10n/app_localizations.dart';
import '../theme_notifier.dart';
import '../language_notifier.dart';
import '../services/notification_service.dart';
import '../core/services/background_engine.dart';
import '../features/prayer_times/presentation/controllers/prayer_controller.dart';
import '../features/prayer_times/presentation/screens/prayer_settings_screen.dart';
import 'minbar_downloads_screen.dart';
import '../services/app_update_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS SCREEN — Modern Luxury Islamic Redesign
// Featuring VIP Creator & Community Showcase (TikTok: @umer.almuktar)
// ─────────────────────────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _selectedLanguage = 'English';
  bool _notificationsEnabled = true;
  int _notificationInterval = 60;
  String _appVersion = 'Version 1.1.1 (Build 9)';

  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;

  final List<String> _languages = ['Amharic', 'Oromo', 'English', 'Arabic'];

  static const Map<String, Map<String, String>> _l10n = {
    'en': {
      'settings_title': 'Settings',
      'settings_subtitle': 'Customise your spiritual sanctuary & experience',
      'appearance': 'APPEARANCE & THEMES',
      'language': 'APP LANGUAGE',
      'prayer_section': 'PRAYER & ATHAN',
      'prayer_settings': 'Prayer Times & Athan',
      'prayer_desc': 'Muezzin voices, calculation method & minute adjustments',
      'notifications': 'REMINDERS & NOTIFICATIONS',
      'storage_section': 'STORAGE & OFFLINE',
      'downloads': 'Downloaded Audio Library',
      'downloads_desc': 'Manage offline surahs, recitations & lectures',
      'creator_community': 'CREATOR & COMMUNITY SPOTLIGHT',
      'creator_name': 'Umer Muktar',
      'creator_role': 'Lead Developer & Creator',
      'tiktok_title': 'Official TikTok Channel',
      'tiktok_desc': 'Follow for Quran recitations, reflections & app updates',
      'tiktok_follow': 'Follow on TikTok',
      'copy_handle': 'Copy @umer.almuktar',
      'copied_to_clipboard': 'Copied @umer.almuktar to clipboard!',
      'telegram_btn': 'Telegram (@UMER_jr)',
      'email_btn': 'Email Feedback',
      'creator_note': 'Your support, prayers and feedback elevate this project for the entire Ummah.',
      'share_info': 'SUPPORT, PRIVACY & INFO',
      'share_app': 'Share Quran Zone',
      'rate_us': 'Rate Us on Google Play',
      'contact_us': 'Contact Developer & Feedback',
      'privacy_policy': 'Privacy Policy',
      'privacy_desc': 'Your data security & offline privacy',
      'about_app': 'About Quran Zone',
      'check_updates': 'Check for Updates',
      'check_updates_desc': 'Search for new features & updates',
      'theme_dark': 'Dark Mode',
      'theme_dark_desc': 'Midnight Moss & Gold',
      'theme_cream': 'Warm Cream',
      'theme_cream_desc': 'Parchment & Antique Gold',
      'theme_white': 'Pure Light',
      'theme_white_desc': 'Clean Mint & Emerald',
      'daily_notif': 'Daily Islamic Reminders',
      'daily_notif_desc': 'Periodic Quran & Dhikr notifications in background',
      'freq_title': 'Reminder Frequency',
    },
    'ar': {
      'settings_title': 'الإعدادات',
      'settings_subtitle': 'تخصيص بيئة التطبيق وتجربتك الإيمانية',
      'appearance': 'المظهر والثيمات',
      'language': 'لغة التطبيق',
      'prayer_section': 'مواقيت الصلاة والأذان',
      'prayer_settings': 'إعدادات الصلاة والأذان',
      'prayer_desc': 'أصوات المؤذنين، طرق الحساب، وتعديل الدقائق',
      'notifications': 'التنبيهات والأذكار',
      'storage_section': 'التخزين والمحفوظات',
      'downloads': 'التسجيلات المحملة',
      'downloads_desc': 'إدارة السور والمحاضرات بدون إنترنت',
      'creator_community': 'المطور ومجتمع التطبيق',
      'creator_name': 'عمر المختار',
      'creator_role': 'مطور ومصمم التطبيق',
      'tiktok_title': 'قناة تيك توك الرسمية',
      'tiktok_desc': 'تابعنا للتلاوات القرآنية، الخواطر الإيمانية، وآخر التحديثات',
      'tiktok_follow': 'متابعة على تيك توك',
      'copy_handle': 'نسخ المعرف @umer.almuktar',
      'copied_to_clipboard': 'تم نسخ @umer.almuktar إلى الحافظة!',
      'telegram_btn': 'تيليجرام (@UMER_jr)',
      'email_btn': 'إرسال ملاحظة عبر البريد',
      'creator_note': 'دعاؤكم وملاحظاتكم ومشاركتكم للتطبيق تثري هذا العمل لخدمة الأمة الإسلامية.',
      'share_info': 'الدعم والخصوصية ومعلومات التطبيق',
      'share_app': 'مشاركة تطبيق Quran Zone',
      'rate_us': 'تقييم التطبيق على متجر جوجل',
      'contact_us': 'تواصل مع المطور والملاحظات',
      'privacy_policy': 'سياسة الخصوصية',
      'privacy_desc': 'حماية البيانات وخصوصية المستخدم',
      'about_app': 'عن تطبيق Quran Zone',
      'check_updates': 'التحقق من وجود تحديثات',
      'check_updates_desc': 'البحث عن أحدث المزايا والإصدارات',
      'theme_dark': 'الوضع الداكن',
      'theme_dark_desc': 'أخضر ليلي مع ذهبي',
      'theme_cream': 'كريمي دافئ',
      'theme_cream_desc': 'ورق المصحف وذهب عتيق',
      'theme_white': 'أبيض ناصع',
      'theme_white_desc': 'أبيض هادئ مع زمردي',
      'daily_notif': 'التنبيهات والأذكار اليومية',
      'daily_notif_desc': 'إشعارات دورية بالقرآن والأذكار في الخلفية',
      'freq_title': 'تكرار التذكير',
    },
    'am': {
      'settings_title': 'ቅንብሮች',
      'settings_subtitle': 'የመተግበሪያውን ገጽታ እና መንፈሳዊ ጉዞዎን ያብጁ',
      'appearance': 'መልክ እና ገጽታዎች',
      'language': 'የመተግበሪያ ቋንቋ',
      'prayer_section': 'የሶላት ጊዜያት እና አዛን',
      'prayer_settings': 'የሶላት እና የአዛን ቅንብሮች',
      'prayer_desc': 'የሙአዚን ድምጾች፣ የስሌት ዘዴ እና ማስተካከያዎች',
      'notifications': 'ማስታወሻዎች እና አዝካር',
      'storage_section': 'ማከማቻ እና የወረዱ ፋይሎች',
      'downloads': 'የወረዱ የድምጽ ፋይሎች',
      'downloads_desc': 'ያለ ኢንተርኔት የሚያዳምጡትን ያስተዳድሩ',
      'creator_community': 'አዘጋጅ እና ማህበረሰብ',
      'creator_name': 'ኡመር ሙክታር',
      'creator_role': 'ዋና አዘጋጅ እና ፈጣሪ',
      'tiktok_title': 'ኦፊሴላዊ የቲክቶክ ገጽ',
      'tiktok_desc': 'ለቁርኣን ቲላዋዎች፣ መንፈሳዊ ማስታወሻዎች እና አዳዲስ ዝመናዎች ይከተሉ',
      'tiktok_follow': 'በቲክቶክ ይከተሉ',
      'copy_handle': '@umer.almuktar ቅዳ',
      'copied_to_clipboard': '@umer.almuktar ወደ ቅንጥብ ሰሌዳ ተቀድቷል!',
      'telegram_btn': 'ቴሌግራም (@UMER_jr)',
      'email_btn': 'አስተያየት በኢሜይል ይላኩ',
      'creator_note': 'የእርስዎ ዱዓ እና ድጋፍ ይህ መተግበሪያ ለመላው ኡማህ የተሻለ እንዲሆን ይረዳል::',
      'share_info': 'ስለ መተግበሪያው፣ ግላዊነት እና ድጋፍ',
      'share_app': 'መተግበሪያውን ያጋሩ',
      'rate_us': 'በፕሌይ ስቶር ደረጃ ይስጡ',
      'contact_us': 'አዘጋጁን ያነጋግሩ',
      'privacy_policy': 'የግላዊነት ፖሊሲ',
      'privacy_desc': 'የውሂብ ደህንነት እና ግላዊነት',
      'about_app': 'ስለ መተግበሪያው',
      'check_updates': 'አዲስ ዝመናዎችን ይፈልጉ',
      'check_updates_desc': 'አዲስ ስሪት እና ማሻሻያዎችን ያረጋግጡ',
      'theme_dark': 'ጨለማ ገጽታ',
      'theme_dark_desc': 'የሌሊት አረንጓዴ እና ወርቅ',
      'theme_cream': 'ክሬም ገጽታ',
      'theme_cream_desc': 'ሞቅ ያለ ወረቀት እና ጥንታዊ ወርቅ',
      'theme_white': 'ነጭ ገጽታ',
      'theme_white_desc': 'ንጹህ ነጭ እና ኤመራልድ',
      'daily_notif': 'ዕለታዊ ማስታወሻዎች',
      'daily_notif_desc': 'የቁርኣን እና የአዝካር ማሳሰቢያዎች',
      'freq_title': 'የማስታወሻ ድግግሞሽ',
    },
    'om': {
      'settings_title': 'Qindaa\'ina',
      'settings_subtitle': 'Haala appilikeeshinii fi sagantaa keessan sirreessaa',
      'appearance': 'Bifaa fi Haala',
      'language': 'Afaan Appilikeeshinii',
      'prayer_section': 'Yeroo Salaataa fi Azaana',
      'prayer_settings': 'Qindaa\'ina Salaataa fi Azaanaa',
      'prayer_desc': 'Sagalee Mu\'azzinaa, mala herregaa fi sirreeffama',
      'notifications': 'Yaadachiisaa fi Azkaara',
      'storage_section': 'Kuusaa fi Buufataalee',
      'downloads': 'Sagaleewwan Buufaman',
      'downloads_desc': 'Toora malee fayyadamuuf kanneen qophaa\'an',
      'creator_community': 'Hojjataa fi Hawaasa',
      'creator_name': 'Umar Muktaar',
      'creator_role': 'Hojjataa fi Qindeessaa App',
      'tiktok_title': 'Marsariitii Tiiktokii Ofiisaalaa',
      'tiktok_desc': 'Qiraatii Qur\'aanaa, yaadachiisa amantii fi odeeffannoof nu hordofaa',
      'tiktok_follow': 'Tiiktokii irratti hordofaa',
      'copy_handle': '@umer.almuktar Kopiisi',
      'copied_to_clipboard': '@umer.almuktar garagalfameera!',
      'telegram_btn': 'Telegiraamii (@UMER_jr)',
      'email_btn': 'Yaada Imeeyliin Ergaa',
      'creator_note': 'Du\'aayin fi deeggarsi keessan hojii kana ummataaf fooyyessuuf gargaara.',
      'share_info': 'Waa\'ee App, Dhuunfaa fi Deeggarsa',
      'share_app': 'Appilikeeshinii Qoodaa',
      'rate_us': 'Play Store irratti sadarkaa kennaa',
      'contact_us': 'Hojjataa qunnamaa',
      'privacy_policy': 'Imaammata Dhuunfaa',
      'privacy_desc': 'Nageenya daataa fi dhuunfaa keessanii',
      'about_app': 'Waa\'ee Appilikeeshinii',
      'check_updates': 'Fooyya\'iinsa Haaraa Barbaadi',
      'check_updates_desc': 'Wanta haaraa jiraachuu ilaali',
      'theme_dark': 'Haala Dukkanaa',
      'theme_dark_desc': 'Magariisa halkanii fi Warqee',
      'theme_cream': 'Kiriimii Hoo\'aa',
      'theme_cream_desc': 'Waraqaa fi Warqee durii',
      'theme_white': 'Adii Qulqulluu',
      'theme_white_desc': 'Adii qulqulluu fi Eemiraaldi',
      'daily_notif': 'Yaadachiisa Guyyaa',
      'daily_notif_desc': 'Akeekkachiisa Qur\'aanaa fi Azkaaraa',
      'freq_title': 'Yeroo Yaadachiisaa',
    },
  };

  String _tr(BuildContext context, String key) {
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    return _l10n[lang]?[key] ?? _l10n['ar']?[key] ?? _l10n['en']![key] ?? key;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerCtrl.forward();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selectedLanguage = prefs.getString('app_language') ?? 'English';
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _notificationInterval = prefs.getInt('notification_interval') ?? 60;
    });

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _appVersion = 'v${packageInfo.version} (Build ${packageInfo.buildNumber})';
      });
    } catch (_) {
      // Fallback already set
    }
  }

  Future<void> _setLanguage(String lang) async {
    await AppLanguage.changeLanguage(lang);
    if (!mounted) return;
    setState(() => _selectedLanguage = lang);
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    if (!mounted) return;
    setState(() => _notificationsEnabled = value);
    if (value) {
      await NotificationService().scheduleIslamicReminders();
      await BackgroundEngine().scheduleZekrNotification(_notificationInterval);
    } else {
      await NotificationService().cancelNotifications();
      await BackgroundEngine().cancelZekrNotification();
    }
  }

  Future<void> _setNotificationInterval(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notification_interval', value);
    if (!mounted) return;
    setState(() => _notificationInterval = value);
    if (_notificationsEnabled) {
      await BackgroundEngine().scheduleZekrNotification(value);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  // ── Action Handlers ────────────────────────────────────────────────────────

  Future<void> _openTikTok() async {
    final Uri url = Uri.parse('https://www.tiktok.com/@umer.almuktar');
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error launching TikTok: $e');
      if (mounted) {
        _copyTikTokHandle();
      }
    }
  }

  void _copyTikTokHandle() {
    Clipboard.setData(const ClipboardData(text: '@umer.almuktar')).then((_) {
      if (!mounted) return;
      _showSnack(_tr(context, 'copied_to_clipboard'), const Color(0xFFFE2C55));
    });
  }

  Future<void> _openTelegram() async {
    final Uri url = Uri.parse('https://t.me/UMER_jr');
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint('Error launching Telegram: $e');
    }
  }

  Future<void> _openEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'umer.et.jm@gmail.com',
      query: 'subject=Quran Zone Feedback & Suggestions',
    );
    try {
      await launchUrl(emailUri);
    } catch (e) {
      debugPrint('Error launching Email: $e');
    }
  }

  void _showLanguageDialog(
    Color primaryColor,
    Color mainTextColor,
    Color cardColor,
    AppLocalizations l10n,
  ) {
    final Map<String, String> langNativeNames = {
      'Arabic': 'العربية',
      'English': 'English',
      'Amharic': 'አማርኛ',
      'Oromo': 'Afaan Oromoo',
    };

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.translate_rounded, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                l10n.selectLanguage,
                style: TextStyle(
                  color: mainTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _languages.map((lang) {
              final isSelected = lang == _selectedLanguage;
              final native = langNativeNames[lang] ?? lang;
              return InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  _setLanguage(lang);
                  Navigator.pop(ctx);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? primaryColor.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor.withValues(alpha: 0.5)
                          : Colors.grey.withValues(alpha: 0.15),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: isSelected ? primaryColor : Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              native,
                              style: TextStyle(
                                color: mainTextColor,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              lang,
                              style: TextStyle(
                                color: mainTextColor.withValues(alpha: 0.55),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Future<void> _openPrivacyPolicy(
    BuildContext context,
    Color cardBg,
    Color textMain,
    Color textSub,
    Color primary,
  ) async {
    final Uri url = Uri.parse('http://quranzone.com.et/');
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        _showPrivacyPolicyDialog(context, cardBg, textMain, textSub, primary);
      }
    } catch (_) {
      if (context.mounted) {
        _showPrivacyPolicyDialog(context, cardBg, textMain, textSub, primary);
      }
    }
  }

  void _showPrivacyPolicyDialog(
    BuildContext context,
    Color cardBg,
    Color textMain,
    Color textSub,
    Color primary,
  ) {
    final isArabic = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              Icon(Icons.security_rounded, color: primary, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _tr(context, 'privacy_policy'),
                  style: TextStyle(
                    color: textMain,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: isArabic ? 'Amiri' : null,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              isArabic
                  ? 'تطبيق Quran Zone يلتزم بأعلى معايير الخصوصية والأمان:\n\n'
                    '• الموقع الرسمي للسياسة: quranzone.com.et\n'
                    '• لا نقوم بجمع أو بيع أي بيانات شخصية للمستخدمين.\n'
                    '• يتم تخزين إعداداتك ومفضلتك محلياً 100% داخل جهازك.\n'
                    '• إذن الموقع الجغرافي (GPS) يُستخدم حصراً لحساب مواقيت الصلاة واتجاه القبلة محلياً.\n'
                    '• قد تستخدم خدمات Google Play وAdMob معرفات إعلانية مجهولة الهوية لعرض إعلانات غير مخصصة.'
                  : 'Quran Zone is committed to total user privacy and data security:\n\n'
                    '• Official Website: quranzone.com.et\n'
                    '• We do not collect, sell, or track any personal user information.\n'
                    '• All bookmarks, preferences, and favorites are stored 100% locally on your device.\n'
                    '• Location permission (GPS) is solely used for accurate prayer calculations and Qibla direction.\n'
                    '• Google Play Services and AdMob may process non-personalized diagnostic data.',
              style: TextStyle(color: textSub, fontSize: 13, height: 1.55),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final Uri url = Uri.parse('http://quranzone.com.et/');
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
              child: Text(
                isArabic ? 'الموقع الرسمي' : 'Open Website',
                style: TextStyle(color: primary, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                isArabic ? 'إغلاق' : 'Close',
                style: TextStyle(color: textSub),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Main Build Method ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final isArabic = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';

    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final Color primary = AppTheme.getPrimaryColor(theme);
        final Color textMain = AppTheme.getMainTextColor(theme);
        final Color textSub = textMain.withValues(alpha: 0.65);
        final Color cardBg = AppTheme.getCardBgColor(theme);
        final Color borderColor = AppTheme.getBorderColor(theme);
        final bool isDark = theme == QuranTheme.dark;
        final bool isCream = theme == QuranTheme.cream;

        final Color scaffoldBg = isDark
            ? const Color(0xFF070E0B)
            : (isCream ? const Color(0xFFFBF8F0) : const Color(0xFFF3F6F3));

        final Color heroBannerBg = isDark
            ? const Color(0xFF0E1F18)
            : (isCream ? const Color(0xFFF4EDDC) : const Color(0xFFE8EFE8));

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── 1. Elegant App Bar & Hero Header ───────────────────────────
              SliverToBoxAdapter(
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                    child: FadeTransition(
                      opacity: _headerFade,
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: heroBannerBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: borderColor.withValues(alpha: isDark ? 0.3 : 0.4),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Glowing App Emblem
                            Container(
                              width: 54,
                              height: 54,
                              padding: const EdgeInsets.all(2.5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    borderColor,
                                    primary,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: primary.withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/app_icon.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Title & Version Badge
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        'Quran Zone',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: textMain,
                                          letterSpacing: 0.3,
                                          fontFamily: isArabic ? 'Amiri' : null,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: primary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: primary.withValues(alpha: 0.35),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          _appVersion,
                                          style: TextStyle(
                                            color: primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _tr(context, 'settings_subtitle'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSub,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── 2. Settings Content Body ────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── SECTION A: APPEARANCE & THEMES ────────────────────────
                    _sectionHeader(
                      icon: Icons.palette_outlined,
                      title: _tr(context, 'appearance'),
                      color: primary,
                    ),
                    _ThemeSwatchSelector(
                      currentTheme: theme,
                      primary: primary,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      isDark: isDark,
                      isArabic: isArabic,
                      darkLabel: _tr(context, 'theme_dark'),
                      darkDesc: _tr(context, 'theme_dark_desc'),
                      creamLabel: _tr(context, 'theme_cream'),
                      creamDesc: _tr(context, 'theme_cream_desc'),
                      whiteLabel: _tr(context, 'theme_white'),
                      whiteDesc: _tr(context, 'theme_white_desc'),
                    ),
                    const SizedBox(height: 14),

                    // ── SECTION B: APP LANGUAGE ──────────────────────────────
                    _sectionHeader(
                      icon: Icons.translate_rounded,
                      title: _tr(context, 'language'),
                      color: const Color(0xFF0284C7),
                    ),
                    _ModernCard(
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      children: [
                        _ModernActionTile(
                          icon: Icons.language_rounded,
                          iconGradient: const [Color(0xFF0284C7), Color(0xFF0369A1)],
                          title: l10n.appLanguage,
                          subtitle: _selectedLanguage,
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: primary.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedLanguage,
                                  style: TextStyle(
                                    color: primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_drop_down_rounded, color: primary, size: 18),
                              ],
                            ),
                          ),
                          onTap: () => _showLanguageDialog(primary, textMain, cardBg, l10n),
                          isDark: isDark,
                          textColor: textMain,
                          subtextColor: textSub,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── SECTION C: PRAYER & SPIRITUAL REMINDERS ───────────────
                    _sectionHeader(
                      icon: Icons.mosque_rounded,
                      title: _tr(context, 'prayer_section'),
                      color: const Color(0xFF10B981),
                    ),
                    _ModernCard(
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      children: [
                        _ModernActionTile(
                          icon: Icons.access_time_filled_rounded,
                          iconGradient: const [Color(0xFF10B981), Color(0xFF059669)],
                          title: _tr(context, 'prayer_settings'),
                          subtitle: _tr(context, 'prayer_desc'),
                          trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PrayerSettingsScreen(controller: PrayerController()),
                              ),
                            );
                          },
                          isDark: isDark,
                          textColor: textMain,
                          subtextColor: textSub,
                        ),
                        _divider(isDark, borderColor),
                        _ModernSwitchTile(
                          icon: Icons.notifications_active_rounded,
                          iconGradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                          title: _tr(context, 'daily_notif'),
                          subtitle: _tr(context, 'daily_notif_desc'),
                          value: _notificationsEnabled,
                          activeColor: primary,
                          onChanged: _toggleNotifications,
                          isDark: isDark,
                          textColor: textMain,
                          subtextColor: textSub,
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInOut,
                          child: _notificationsEnabled
                              ? _ModernIntervalPicker(
                                  value: _notificationInterval,
                                  primary: primary,
                                  textColor: textMain,
                                  subtextColor: textSub,
                                  title: _tr(context, 'freq_title'),
                                  onChanged: _setNotificationInterval,
                                  isDark: isDark,
                                )
                              : const SizedBox.shrink(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── SECTION D: STORAGE & OFFLINE ─────────────────────────
                    _sectionHeader(
                      icon: Icons.folder_special_rounded,
                      title: _tr(context, 'storage_section'),
                      color: const Color(0xFF0D9488),
                    ),
                    _ModernCard(
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      children: [
                        _ModernActionTile(
                          icon: Icons.download_done_rounded,
                          iconGradient: const [Color(0xFF0D9488), Color(0xFF0F766E)],
                          title: _tr(context, 'downloads'),
                          subtitle: _tr(context, 'downloads_desc'),
                          trailing: const Icon(Icons.chevron_right_rounded, size: 22),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MinbarDownloadsScreen()),
                            );
                          },
                          isDark: isDark,
                          textColor: textMain,
                          subtextColor: textSub,
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ── 🌟 SECTION E: VIP CREATOR & COMMUNITY SPOTLIGHT (TIKTOK: @umer.almuktar) ──
                    _sectionHeader(
                      icon: Icons.stars_rounded,
                      title: _tr(context, 'creator_community'),
                      color: const Color(0xFFFE2C55), // Vibrant TikTok Accent
                      badgeText: 'VIP SPOTLIGHT',
                    ),
                    _TikTokSpotlightCard(
                      isDark: isDark,
                      cardBg: cardBg,
                      primary: primary,
                      goldBorder: borderColor,
                      creatorName: _tr(context, 'creator_name'),
                      creatorRole: _tr(context, 'creator_role'),
                      tiktokTitle: _tr(context, 'tiktok_title'),
                      tiktokDesc: _tr(context, 'tiktok_desc'),
                      followLabel: _tr(context, 'tiktok_follow'),
                      copyLabel: _tr(context, 'copy_handle'),
                      telegramLabel: _tr(context, 'telegram_btn'),
                      emailLabel: _tr(context, 'email_btn'),
                      creatorNote: _tr(context, 'creator_note'),
                      onFollowTikTok: _openTikTok,
                      onCopyHandle: _copyTikTokHandle,
                      onTelegram: _openTelegram,
                      onEmail: _openEmail,
                    ),
                    const SizedBox(height: 18),

                    // ── SECTION F: SUPPORT, PRIVACY & ABOUT ──────────────────
                    _sectionHeader(
                      icon: Icons.info_outline_rounded,
                      title: _tr(context, 'share_info'),
                      color: const Color(0xFF6366F1),
                    ),
                    _ModernCard(
                      isDark: isDark,
                      cardBg: cardBg,
                      borderColor: borderColor,
                      children: [
                        _ModernActionTile(
                          icon: Icons.star_rate_rounded,
                          iconGradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                          title: _tr(context, 'rate_us'),
                          subtitle: 'Support Quran Zone with 5 stars',
                          onTap: () async {
                            final Uri url = Uri.parse(
                                'https://play.google.com/store/apps/details?id=com.umer.quranzone');
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          },
                          isDark: isDark,
                          textColor: textMain,
                          subtextColor: textSub,
                        ),
                        _divider(isDark, borderColor),
                        _ModernActionTile(
                          icon: Icons.share_rounded,
                          iconGradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                          title: _tr(context, 'share_app'),
                          subtitle: 'Guide others to goodness & earn reward',
                          onTap: () {
                            Share.share(
                              'Download Quran Zone for an exquisite Quran & Islamic experience:\nhttps://play.google.com/store/apps/details?id=com.umer.quranzone',
                            );
                          },
                          isDark: isDark,
                          textColor: textMain,
                          subtextColor: textSub,
                        ),
                        _divider(isDark, borderColor),
                        _ModernActionTile(
                          icon: Icons.system_update_rounded,
                          iconGradient: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
                          title: _tr(context, 'check_updates'),
                          subtitle: _tr(context, 'check_updates_desc'),
                          onTap: () => AppUpdateService.instance.checkForUpdate(context, isManual: true),
                          isDark: isDark,
                          textColor: textMain,
                          subtextColor: textSub,
                        ),
                        _divider(isDark, borderColor),
                        _ModernActionTile(
                          icon: Icons.security_rounded,
                          iconGradient: const [Color(0xFF10B981), Color(0xFF047857)],
                          title: _tr(context, 'privacy_policy'),
                          subtitle: 'quranzone.com.et • 100% Offline & Private',
                          onTap: () => _openPrivacyPolicy(context, cardBg, textMain, textSub, primary),
                          isDark: isDark,
                          textColor: textMain,
                          subtextColor: textSub,
                        ),
                        _divider(isDark, borderColor),
                        _ModernActionTile(
                          icon: Icons.auto_stories_rounded,
                          iconGradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                          title: _tr(context, 'about_app'),
                          subtitle: 'Comprehensive overview & Sadaqah Jariyah',
                          onTap: () => _openAboutQuranZoneDialog(
                            context,
                            isDark,
                            cardBg,
                            textMain,
                            textSub,
                            primary,
                          ),
                          isDark: isDark,
                          textColor: textMain,
                          subtextColor: textSub,
                        ),
                      ],
                    ),

                    // ── FOOTER DEDICATION ─────────────────────────────────────
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.favorite_rounded,
                                  size: 14, color: primary.withValues(alpha: 0.6)),
                              const SizedBox(width: 6),
                              Text(
                                'Handcrafted for the Ummah by Umer Muktar',
                                style: TextStyle(
                                  color: textSub.withValues(alpha: 0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'TikTok: @umer.almuktar',
                            style: TextStyle(
                              color: const Color(0xFFFE2C55).withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Helper UI Methods ──────────────────────────────────────────────────────

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required Color color,
    String? badgeText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8, top: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: 0.7,
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFE2C55), Color(0xFF25F4EE)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider(bool isDark, Color borderColor) {
    return Divider(
      height: 1,
      thickness: 0.8,
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.05),
      indent: 58,
      endIndent: 14,
    );
  }

  // ── About Quran Zone Modal ─────────────────────────────────────────────────

  void _openAboutQuranZoneDialog(
    BuildContext context,
    bool isDark,
    Color cardBg,
    Color textMain,
    Color textSub,
    Color primary,
  ) {
    final locale = Localizations.localeOf(context).languageCode;
    final isArabic = locale == 'ar';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final surfaceBg = isDark
            ? const Color(0xFF0D1612)
            : (AppTheme.notifier.value == QuranTheme.cream
                ? const Color(0xFFFBF7EE)
                : Colors.white);
        final itemCardBg = isDark
            ? const Color(0xFF14221C)
            : (AppTheme.notifier.value == QuranTheme.cream
                ? const Color(0xFFF3EDE0)
                : const Color(0xFFF8FAFB));
        const goldColor = Color(0xFFD4AF37);
        const emeraldColor = Color(0xFF10B981);

        String getMissionText() {
          switch (locale) {
            case 'ar':
              return 'صُمم تطبيق Quran Zone ليكون ملاذك الروحي ورفيقك الإيماني اليومي، يربطك بكتاب الله عز وجل وسنة نبيه ﷺ أينما كنت بأعلى درجات الإتقان والجمال.';
            case 'am':
              return 'ቁርኣን ዞን (Quran Zone) የዕለት ተዕለት መንፈሳዊ መጠጊያዎ እና ታማኝ ጓደኛዎ እንዲሆን ተዘጋጅቷል። ዓላማችን ከአላህ ﷻ ቃል እና ከነቢያችን ﷺ ሱና ጋር በውበት ማስተሳሰር ነው።';
            case 'om':
              return 'Quran Zone bakka tasgabbii lubbuu keessanii kan guyyuu akka ta\'uuf qophaa\'e. Kaayyoon keenya Qur\'aana Rabbii ﷻ fi Sunnah Nabiyyii ﷺ haala bareedaan gara onnee keessanitti dhiheessuudha.';
            default:
              return 'Quran Zone was handcrafted to be your daily spiritual sanctuary, seamlessly connecting you with the Words of Allah ﷻ and the Sunnah of His Messenger ﷺ wherever you are in the world.';
          }
        }

        final List<Map<String, dynamic>> featureTickets = [
          {
            'icon': Icons.menu_book_rounded,
            'color': const Color(0xFF10B981),
            'title': isArabic ? 'القرآن الكريم والتفاسير' : 'The Noble Quran & Tafsir',
            'desc': isArabic
                ? 'مصحف المدينة النبوية بالخط العثماني، تلاوة متزامنة آية بآية مع تلوين الكلمات، ٤ تفاسير معتمدة (ابن كثير، الميسر، البغوي، السعدي)، معاني الكلمات، وإعراب القرآن كاملاً.'
                : 'Authentic Madinah Mushaf (Uthmani script) with synced ayah & word highlights, 4 Tafsir books, word meanings & Quranic syntax (I\'rab).',
          },
          {
            'icon': Icons.podcasts_rounded,
            'color': const Color(0xFF6366F1),
            'title': isArabic ? 'المنبر والصوتيات والبث الحي' : 'Minbar Audios & 24/7 Live Media',
            'desc': isArabic
                ? 'مكتبة صوتية لأكثر من ١٠٠ قارئ، أكثر من ١٧٥ إذاعة إسلامية مباشرة على مدار الساعة، وبث حي عالي الدقة من الحرمين الشريفين.'
                : '100+ Renowned Quran Reciters, 175+ Live Islamic radio stations 24/7, and HD direct live video streams from Makkah & Madinah.',
          },
          {
            'icon': Icons.access_time_filled_rounded,
            'color': const Color(0xFFF59E0B),
            'title': isArabic ? 'مواقيت الصلاة، الأذان والقبلة 3D' : 'Prayer Times, Athan & 3D Qibla',
            'desc': isArabic
                ? 'حسابات فلكية بالغة الدقة لمواقيت الصلاة عالمياً، تنبيهات الأذان بأصوات كبار المؤذنين، وبوصلة القبلة ثلاثية الأبعاد.'
                : 'Precision astronomical prayer schedules, background Athan notifications with various Muezzin voices, 3D compass Qibla finder.',
          },
          {
            'icon': Icons.library_books_rounded,
            'color': const Color(0xFF0D9488),
            'title': isArabic ? 'المكتبة الإسلامية وصحيح البخاري' : 'Islamic Library & Sahih Al-Bukhari',
            'desc': isArabic
                ? 'صحيح البخاري كاملاً بالأسانيد والأبواب، قصص الأنبياء، السيرة النبوية، سير الصحابة، والفتاوى الشرعية الموثوقة.'
                : 'Complete Sahih Al-Bukhari with hadith chains, Stories of the Prophets, Seerah, Companions, and Authentic Ruqyah.',
          },
          {
            'icon': Icons.auto_stories_rounded,
            'color': const Color(0xFFEC4899),
            'title': isArabic ? 'حصن المسلم والأذكار التفاعلية' : 'Hisn Al-Muslim & Daily Remembrance',
            'desc': isArabic
                ? 'أذكار الصباح والمساء، أذكار بعد الصلاة، سبحة إلكترونية ذكية، تلاوات صوتية للأذكار، وفضائل كل ذكر.'
                : 'Comprehensive Morning & Evening Adhkar, Post-Salah Dua, interactive digital Tasbih counters, and authentic virtues.',
          },
        ];

        return DraggableScrollableSheet(
          initialChildSize: 0.88,
          maxChildSize: 0.95,
          minChildSize: 0.55,
          builder: (context, scrollController) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Container(
                  decoration: BoxDecoration(
                    color: surfaceBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 25,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Drag Handle
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Container(
                          width: 44,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.black26,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      // Scrollable Body
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
                          children: [
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [goldColor, emeraldColor],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/images/app_icon.png',
                                        width: 68,
                                        height: 68,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Quran Zone',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isArabic
                                        ? 'رفيقك الإيماني الشامل'
                                        : 'Your Comprehensive Islamic Sanctuary',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textSub,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Noble Ayah
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: itemCardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: emeraldColor.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '﴿ وَذَكِّرْ فَإِنَّ الذِّكْرَىٰ تَنفَعُ الْمُؤْمِنِينَ ﴾',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? const Color(0xFF6EE7B7)
                                          : const Color(0xFF047857),
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isArabic
                                        ? 'سورة الذاريات: ٥٥'
                                        : '"And remind, for indeed, the reminder benefits the believers." — [51:55]',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: textSub,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Mission
                            Text(
                              isArabic ? 'رسالتنا' : 'Our Mission',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textMain,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              getMissionText(),
                              style: TextStyle(fontSize: 13, color: textSub, height: 1.55),
                            ),
                            const SizedBox(height: 16),

                            // Feature Tickets
                            for (final ticket in featureTickets)
                              Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: itemCardBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isDark ? Colors.white10 : Colors.black12,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: (ticket['color'] as Color).withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        ticket['icon'] as IconData,
                                        color: ticket['color'] as Color,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ticket['title'] as String,
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.bold,
                                              color: textMain,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            ticket['desc'] as String,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: textSub,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 14),

                            // Sadaqah Jariyah Card
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: goldColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: goldColor.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.favorite_rounded, color: goldColor, size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isArabic
                                              ? 'صدقة جارية للأمة الإسلامية'
                                              : 'Sadaqah Jariyah for the Ummah',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isArabic
                                              ? 'هذا العمل خالص لوجه الله تعالى وبلا مقابل. نسأل الله أن يتقبله وينفع به المسلمين أجمعين.'
                                              : 'Built purely for the pleasure of Allah ﷻ without barrier. We pray Allah accepts it as a continuous charity for all believers.',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: isDark ? const Color(0xFFE5D5B8) : const Color(0xFF78350F),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Share.share(
                                    'Download Quran Zone for an exquisite Quran & Islamic experience:\nhttps://play.google.com/store/apps/details?id=com.umer.quranzone',
                                  );
                                },
                                icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
                                label: Text(
                                  isArabic ? 'شارك التطبيق واكسب الأجر' : 'Share Quran Zone',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: emeraldColor,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 1: Modern Card Container
// ─────────────────────────────────────────────────────────────────────────────

class _ModernCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;

  const _ModernCard({
    required this.children,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.07),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 2: Modern Action Tile
// ─────────────────────────────────────────────────────────────────────────────

class _ModernActionTile extends StatelessWidget {
  final IconData icon;
  final List<Color> iconGradient;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool isDark;
  final Color textColor;
  final Color subtextColor;

  const _ModernActionTile({
    required this.icon,
    required this.iconGradient,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
    required this.isDark,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: iconGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: iconGradient.first.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null)
              trailing!
            else
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : Colors.black38,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 3: Modern Switch Tile
// ─────────────────────────────────────────────────────────────────────────────

class _ModernSwitchTile extends StatelessWidget {
  final IconData icon;
  final List<Color> iconGradient;
  final String title;
  final String subtitle;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;
  final bool isDark;
  final Color textColor;
  final Color subtextColor;

  const _ModernSwitchTile({
    required this.icon,
    required this.iconGradient,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.activeColor,
    required this.onChanged,
    required this.isDark,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: iconGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: iconGradient.first.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: activeColor.withValues(alpha: 0.5),
            activeThumbColor: activeColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 4: Modern Interval Picker
// ─────────────────────────────────────────────────────────────────────────────

class _ModernIntervalPicker extends StatelessWidget {
  final int value;
  final Color primary;
  final Color textColor;
  final Color subtextColor;
  final String title;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const _ModernIntervalPicker({
    required this.value,
    required this.primary,
    required this.textColor,
    required this.subtextColor,
    required this.title,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    const intervals = [5, 15, 30, 60, 120];
    const labels = ['5m', '15m', '30m', '1h', '2h'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: primary.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 16, color: primary),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(intervals.length, (i) {
              final selected = intervals[i] == value;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(intervals[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: selected ? primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? primary
                            : (isDark ? Colors.white24 : Colors.black12),
                        width: selected ? 1.5 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        labels[i],
                        style: TextStyle(
                          color: selected ? Colors.white : subtextColor,
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 5: Theme Swatch Selector (Interactive Previews)
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeSwatchSelector extends StatelessWidget {
  final QuranTheme currentTheme;
  final Color primary;
  final Color cardBg;
  final Color borderColor;
  final bool isDark;
  final bool isArabic;
  final String darkLabel;
  final String darkDesc;
  final String creamLabel;
  final String creamDesc;
  final String whiteLabel;
  final String whiteDesc;

  const _ThemeSwatchSelector({
    required this.currentTheme,
    required this.primary,
    required this.cardBg,
    required this.borderColor,
    required this.isDark,
    required this.isArabic,
    required this.darkLabel,
    required this.darkDesc,
    required this.creamLabel,
    required this.creamDesc,
    required this.whiteLabel,
    required this.whiteDesc,
  });

  @override
  Widget build(BuildContext context) {
    final themeOptions = [
      (
        QuranTheme.dark,
        darkLabel,
        darkDesc,
        Icons.nights_stay_rounded,
        const Color(0xFF0D1F17), // Preview background
        const Color(0xFFE8C77A), // Preview gold
        Colors.white,
      ),
      (
        QuranTheme.cream,
        creamLabel,
        creamDesc,
        Icons.wb_sunny_rounded,
        const Color(0xFFFDFBF0), // Preview parchment
        const Color(0xFF1B4332), // Preview deep green
        const Color(0xFF1A120B),
      ),
      (
        QuranTheme.white,
        whiteLabel,
        whiteDesc,
        Icons.light_mode_rounded,
        Colors.white,
        const Color(0xFF10B981), // Preview emerald
        const Color(0xFF111827),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.07),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: themeOptions.map((t) {
          final isSelected = currentTheme == t.$1;

          return Expanded(
            child: GestureDetector(
              onTap: () => AppTheme.changeTheme(t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.fromLTRB(8, 12, 8, 10),
                decoration: BoxDecoration(
                  color: t.$5, // Theme preview color
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? borderColor
                        : (isDark ? Colors.white12 : Colors.black12),
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: borderColor.withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: t.$6.withValues(alpha: 0.18),
                          ),
                          child: Icon(t.$4, size: 20, color: t.$6),
                        ),
                        if (isSelected)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: borderColor,
                              ),
                              child: const Icon(Icons.check, size: 11, color: Colors.black),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      t.$2,
                      style: TextStyle(
                        color: t.$7,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        fontFamily: isArabic ? 'Amiri' : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t.$3,
                      style: TextStyle(
                        color: t.$7.withValues(alpha: 0.6),
                        fontSize: 9.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🌟 COMPONENT 6: VIP Creator & Community Showcase Card (TikTok: @umer.almuktar)
// ─────────────────────────────────────────────────────────────────────────────

class _TikTokSpotlightCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final Color primary;
  final Color goldBorder;
  final String creatorName;
  final String creatorRole;
  final String tiktokTitle;
  final String tiktokDesc;
  final String followLabel;
  final String copyLabel;
  final String telegramLabel;
  final String emailLabel;
  final String creatorNote;
  final VoidCallback onFollowTikTok;
  final VoidCallback onCopyHandle;
  final VoidCallback onTelegram;
  final VoidCallback onEmail;

  const _TikTokSpotlightCard({
    required this.isDark,
    required this.cardBg,
    required this.primary,
    required this.goldBorder,
    required this.creatorName,
    required this.creatorRole,
    required this.tiktokTitle,
    required this.tiktokDesc,
    required this.followLabel,
    required this.copyLabel,
    required this.telegramLabel,
    required this.emailLabel,
    required this.creatorNote,
    required this.onFollowTikTok,
    required this.onCopyHandle,
    required this.onTelegram,
    required this.onEmail,
  });

  @override
  Widget build(BuildContext context) {
    const tiktokPink = Color(0xFFFE2C55);
    const tiktokCyan = Color(0xFF25F4EE);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0F1E19), const Color(0xFF08120E)]
              : [const Color(0xFFF9F6EE), const Color(0xFFF2ECE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: tiktokPink.withValues(alpha: 0.45),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: tiktokPink.withValues(alpha: isDark ? 0.25 : 0.1),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header: Creator Profile Badge ──────────────────────────────────
          Row(
            children: [
              // Glowing Creator Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [tiktokCyan, tiktokPink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: tiktokPink.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(2.5),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF09120E) : Colors.white,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.person_rounded,
                        size: 28,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          creatorName,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: Color(0xFF00B2FF),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: goldBorder.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: goldBorder.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        creatorRole,
                        style: TextStyle(
                          color: isDark ? const Color(0xFFE8C77A) : const Color(0xFF7A5900),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Spotlight Box: TikTok @umer.almuktar ────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF060B09) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // TikTok Badge Icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: tiktokCyan.withValues(alpha: 0.45),
                            blurRadius: 8,
                            offset: const Offset(-2, 0),
                          ),
                          BoxShadow(
                            color: tiktokPink.withValues(alpha: 0.45),
                            blurRadius: 8,
                            offset: const Offset(2, 0),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.music_note_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tiktokTitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '@umer.almuktar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: tiktokPink,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  tiktokDesc,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),

                // Primary CTA: Follow on TikTok Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: onFollowTikTok,
                    icon: const Icon(Icons.open_in_new_rounded, size: 18, color: Colors.white),
                    label: Text(
                      followLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: tiktokPink,
                      elevation: 4,
                      shadowColor: tiktokPink.withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Secondary CTA: Copy Handle
                Center(
                  child: TextButton.icon(
                    onPressed: onCopyHandle,
                    icon: const Icon(Icons.copy_rounded, size: 14, color: tiktokPink),
                    label: Text(
                      copyLabel,
                      style: const TextStyle(
                        color: tiktokPink,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Multi-channel Connect: Telegram & Email ─────────────────────────
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: onTelegram,
                    icon: const Icon(Icons.send_rounded, size: 16, color: Color(0xFF0088CC)),
                    label: Text(
                      telegramLabel,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: const Color(0xFF0088CC).withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton.icon(
                    onPressed: onEmail,
                    icon: Icon(Icons.email_outlined, size: 16, color: primary),
                    label: Text(
                      emailLabel,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: primary.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Spiritual Note
          Text(
            creatorNote,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white54 : Colors.black54,
              fontStyle: FontStyle.italic,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
