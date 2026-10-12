import 'dart:math' as math;
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
import '../services/permission_health_service.dart';
import '../features/prayer_times/presentation/screens/permissions_setup_screen.dart';
import '../widgets/custom_banner_ad.dart';
import '../core/database/hadith_database_helper.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS SCREEN — Modern Luxury Islamic Redesign
// Circular Ripple Reveal (Telegram-Style) & VIP TikTok Spotlight Showcase
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
  String _appVersion = 'Version 1.2.0 (Build 10)';

  // Entrance & Header Animations
  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;

  // ── Circular Reveal Animation State ────────────────────────────────────────
  late QuranTheme _baseTheme;
  late QuranTheme _targetTheme;
  late final AnimationController _revealCtrl;
  late final Animation<double> _revealAnim;
  bool _isRevealing = false;
  Offset _revealOrigin = Offset.zero;
  double _maxRadius = 1000.0;

  late ScrollController _baseScrollCtrl;
  ScrollController? _revealScrollCtrl;

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
      'creator_community': 'COMMUNITY & CHANNELS',
      'creator_name': 'Quran Zone',
      'creator_role': 'Official channels, recitations & feedback',
      'tiktok_title': 'TikTok Channel',
      'tiktok_desc': 'Quran recitations, reflections & app updates',
      'tiktok_follow': 'Visit TikTok',
      'copy_handle': 'Copy',
      'tap_to_copy': 'Tap anywhere to copy handle',
      'copied_to_clipboard': 'Copied handle to clipboard!',
      'telegram_btn': 'Telegram',
      'email_btn': 'Email',
      'creator_note': 'Sadaqah Jariyah • Purely for the sake of Allah',
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
      'creator_community': 'قنوات التواصل والمجتمع',
      'creator_name': 'Quran Zone',
      'creator_role': 'تلاوات قرآنية، تدبرات، وتواصل مباشر',
      'tiktok_title': 'قناة تيك توك',
      'tiktok_desc': 'تلاوات خاشعة، تدبرات قرآنية، وآخر تحديثات التطبيق',
      'tiktok_follow': 'زيارة تيك توك',
      'copy_handle': 'نسخ',
      'tap_to_copy': 'اضغط في أي مكان لنسخ الحساب',
      'copied_to_clipboard': 'تم نسخ الحساب إلى الحافظة!',
      'telegram_btn': 'تيليجرام',
      'email_btn': 'إرسال ملاحظة',
      'creator_note': 'عمل خالص لوجه الله تعالى • نسألكم صالح الدعاء',
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
      'creator_community': 'ማህበረሰብ እና አድራሻዎች',
      'creator_name': 'Quran Zone',
      'creator_role': 'የቁርኣን ቲላዋዎችና ማህበራዊ ገጾች',
      'tiktok_title': 'TikTok Channel',
      'tiktok_desc': 'የቁርኣን ቲላዋዎችና ዝመናዎች',
      'tiktok_follow': 'Visit TikTok',
      'copy_handle': 'Copy',
      'tap_to_copy': 'ለመቅዳት የትም ይጫኑ',
      'copied_to_clipboard': 'አድራሻው ወደ ቅንጥብ ሰሌዳ ተቀድቷል!',
      'telegram_btn': 'ቴሌግራም',
      'email_btn': 'ኢሜይል',
      'creator_note': 'የጋራ ሰደቃ • ለአላህ ተብሎ የተዘጋጀ',
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
      'settings_subtitle':
          'Haala appilikeeshinii fi sagantaa keessan sirreessaa',
      'appearance': 'Bifaa fi Haala',
      'language': 'Afaan Appilikeeshinii',
      'prayer_section': 'Yeroo Salaataa fi Azaana',
      'prayer_settings': 'Qindaa\'ina Salaataa fi Azaanaa',
      'prayer_desc': 'Sagalee Mu\'azzinaa, mala herregaa fi sirreeffama',
      'notifications': 'Yaadachiisaa fi Azkaara',
      'storage_section': 'Kuusaa fi Buufataalee',
      'downloads': 'Sagaleewwan Buufaman',
      'downloads_desc': 'Toora malee fayyadamuuf kanneen qophaa\'an',
      'creator_community': 'Hawaasaa fi Quunnamtii',
      'creator_name': 'Quran Zone',
      'creator_role': 'Qiraatii Qur\'aanaa fi quunnamtii',
      'tiktok_title': 'TikTok Channel',
      'tiktok_desc': 'Qiraatii Qur\'aanaa fi odeeffannoo',
      'tiktok_follow': 'Visit TikTok',
      'copy_handle': 'Copy',
      'tap_to_copy': 'Kopiisuuf bakka kamiyyuu tuqaa',
      'copied_to_clipboard': 'Garagalfameera!',
      'telegram_btn': 'Telegiraamii',
      'email_btn': 'Imeeylii',
      'creator_note':
          'Sadaqah Jaariyaa • Waaqayyoof jedhamee kan qophaa\'e',
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

  String _getRateUsSubtitle(String lang) {
    switch (lang) {
      case 'ar':
        return 'ادعم تطبيق Quran Zone بـ 5 نجوم على متجر Google';
      case 'am':
        return 'በGoogle Play 5 ኮከቦችን በመስጠት ይደግፉን';
      case 'om':
        return 'Google Play irratti urjii 5 kennuun nu deeggaraa';
      default:
        return 'Support Quran Zone with 5 stars on Google Play';
    }
  }

  String _getShareAppSubtitle(String lang) {
    switch (lang) {
      case 'ar':
        return 'الدال على الخير كفاعله • شارك التطبيق واكسب الأجر';
      case 'am':
        return 'መልካምን ያመላከተ እንደ ሠሪው ነው • መተግበሪያውን ያጋሩ';
      case 'om':
        return 'Nama gara gaariitti qajeelche akka nama hojjateeti';
      default:
        return 'Guide others to goodness & earn continuous reward';
    }
  }

  String _getPrivacySubtitle(String lang) {
    switch (lang) {
      case 'ar':
        return 'quranzone.com.et • حفظ محلي 100% بدون تتبع';
      case 'am':
        return 'quranzone.com.et • 100% ከመስመር ውጭ እና ደህንነቱ የተጠበቀ';
      case 'om':
        return 'quranzone.com.et • 100% toora interneetii malee fi amansiisaa';
      default:
        return 'quranzone.com.et • 100% Offline, secure & private';
    }
  }

  String _getAboutSubtitle(String lang) {
    switch (lang) {
      case 'ar':
        return 'نبذة شاملة عن رسالة التطبيق ومزاياه الاستثنائية';
      case 'am':
        return 'አጠቃላይ እይታ እና የሰደቃ ጃሪያህ መረጃ';
      case 'om':
        return 'Ibsa waliigalaa fi odeeffannoo Sadaqah Jariyah';
      default:
        return 'Comprehensive overview & app dedication';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    PermissionHealthService.checkHealth();

    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _headerCtrl.forward();

    _baseTheme = AppTheme.notifier.value;
    _targetTheme = AppTheme.notifier.value;
    AppTheme.notifier.addListener(_onExternalThemeChanged);
    AppLanguage.notifier.addListener(_onExternalLanguageChanged);
    _baseScrollCtrl = ScrollController();

    _revealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _revealAnim =
        CurvedAnimation(parent: _revealCtrl, curve: Curves.easeInOutCubic);

    _revealCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _baseTheme = _targetTheme;
          _isRevealing = false;
        });
        _revealScrollCtrl?.dispose();
        _revealScrollCtrl = null;
      }
    });
  }

  void _onExternalThemeChanged() {
    if (!_isRevealing && mounted) {
      final currentTheme = AppTheme.notifier.value;
      if (_baseTheme != currentTheme) {
        setState(() {
          _baseTheme = currentTheme;
          _targetTheme = currentTheme;
        });
      }
    }
  }

  void _onExternalLanguageChanged() {
    if (mounted) {
      setState(() {
        _selectedLanguage =
            _getLangNameFromLocale(AppLanguage.notifier.value);
      });
    }
  }

  String _getLangNameFromLocale(Locale locale) {
    switch (locale.languageCode) {
      case 'ar':
        return 'Arabic';
      case 'am':
        return 'Amharic';
      case 'om':
        return 'Oromo';
      case 'en':
      default:
        return 'English';
    }
  }

  @override
  void dispose() {
    AppTheme.notifier.removeListener(_onExternalThemeChanged);
    AppLanguage.notifier.removeListener(_onExternalLanguageChanged);
    _headerCtrl.dispose();
    _revealCtrl.dispose();
    _baseScrollCtrl.dispose();
    _revealScrollCtrl?.dispose();
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
        _appVersion =
            'v${packageInfo.version} (Build ${packageInfo.buildNumber})';
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

  String _formatInterval(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    return '${hours}h';
  }

  void _showIntervalSheet(
      BuildContext context, Color primary, Color textMain, Color cardBg) {
    final intervals = [5, 15, 30, 60, 120];
    final labels = ['5 min', '15 min', '30 min', '1 hour', '2 hours'];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _tr(context, 'freq_title'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: textMain,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(intervals.length, (i) {
                    final isSelected = _notificationInterval == intervals[i];
                    return ChoiceChip(
                      label: Text(labels[i]),
                      selected: isSelected,
                      selectedColor: primary,
                      backgroundColor: isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.05),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : textMain,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) {
                          _setNotificationInterval(intervals[i]);
                          Navigator.pop(ctx);
                        }
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
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

  // ── Circular Reveal Trigger ────────────────────────────────────────────────

  void _startCircularThemeReveal(QuranTheme newTheme, Offset origin) {
    if (newTheme == _baseTheme || _isRevealing) return;

    HapticFeedback.selectionClick();

    // Map global origin to SettingsScreen's local coordinate space
    // to account for any horizontal centering margins (e.g. ConstrainedBox maxWidth 850 on desktop/web)
    final RenderBox? screenBox = context.findRenderObject() as RenderBox?;
    final Offset localOrigin = screenBox != null && screenBox.hasSize
        ? screenBox.globalToLocal(origin)
        : origin;
    final Size localSize = screenBox != null && screenBox.hasSize
        ? screenBox.size
        : MediaQuery.sizeOf(context);

    // Calculate maximum radius to engulf every corner of screen
    final double dx =
        math.max(localOrigin.dx, localSize.width - localOrigin.dx);
    final double dy =
        math.max(localOrigin.dy, localSize.height - localOrigin.dy);
    _maxRadius = math.sqrt(dx * dx + dy * dy) + 60.0;
    _revealOrigin = localOrigin;
    _targetTheme = newTheme;

    // Instantiate synced scroll controller for the reveal layer
    final double currentOffset =
        _baseScrollCtrl.hasClients ? _baseScrollCtrl.offset : 0.0;
    _revealScrollCtrl?.dispose();
    _revealScrollCtrl = ScrollController(initialScrollOffset: currentOffset);

    setState(() {
      _isRevealing = true;
    });

    // Immediately synchronize global theme so bottom tabs, status bar & screen animate simultaneously
    AppTheme.changeTheme(newTheme);

    _revealCtrl.forward(from: 0.0);
  }

  // ── Action Handlers ────────────────────────────────────────────────────────

  Future<void> _openTikTok() async {
    final Uri url = Uri.parse('https://www.tiktok.com/@umer.almuktar');
    try {
      final launched =
          await launchUrl(url, mode: LaunchMode.externalApplication);
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
    HapticFeedback.lightImpact();
    Clipboard.setData(const ClipboardData(text: '@umer.almuktar')).then((_) {
      if (!mounted) return;
      _showSnack(_tr(context, 'copied_to_clipboard'), const Color(0xFFFE2C55));
    });
  }

  Future<void> _openTelegram() async {
    final Uri url = Uri.parse('https://t.me/UMER_jr');
    try {
      final launched =
          await launchUrl(url, mode: LaunchMode.externalApplication);
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.translate_rounded,
                    color: primaryColor, size: 20),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
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

  Future<void> _showStorageManagerSheet(
    BuildContext context,
    Color primary,
    Color textMain,
    Color cardBg,
    bool isDark,
    bool isArabic,
  ) async {
    final hadithSize = await HadithDatabaseHelper.instance.getDatabaseSizeBytes();
    final hadithMb = (hadithSize / (1024 * 1024)).toStringAsFixed(1);
    final isHadithExtracted = hadithSize > 50 * 1024 * 1024;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.storage_rounded, color: primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isArabic ? 'إدارة المساحة والتخزين' : 'Storage Management',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          color: textMain,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isArabic ? 'موسوعة الحديث الشريف' : 'Hadith Encyclopedia',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                color: textMain,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isHadithExtracted
                                    ? primary.withValues(alpha: 0.15)
                                    : Colors.grey.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isHadithExtracted
                                    ? '$hadithMb MB'
                                    : (isArabic ? 'غير مهيأة (0 MB)' : 'Not unpacked (0 MB)'),
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isHadithExtracted ? primary : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isArabic
                              ? (isHadithExtracted
                                  ? 'قاعدة بيانات الأحاديث (40,937 حديثاً) مهيأة وتعمل بالكامل بدون إنترنت.'
                                  : 'الموسوعة موجودة في وضع الضغط ولا تستهلك أي مساحة إضافية على جهازك.')
                              : (isHadithExtracted
                                  ? 'Hadith database (40,937 hadiths) unpacked and available offline.'
                                  : 'Database is kept compressed and takes zero additional storage.'),
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 12.5,
                            color: textMain.withValues(alpha: 0.7),
                            height: 1.4,
                          ),
                        ),
                        if (isHadithExtracted) ...[
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded, size: 18),
                            label: Text(
                              isArabic ? 'مسح بيانات الحديث وتوفير المساحة' : 'Free Up Hadith Storage (~187 MB)',
                              style: const TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold),
                            ),
                            onPressed: () async {
                              await HadithDatabaseHelper.instance.deleteDatabaseFile();
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (context.mounted) {
                                _showSnack(
                                  isArabic
                                      ? 'تم مسح بيانات الحديث وتوفير المساحة بنجاح'
                                      : 'Hadith database cleared and storage freed.',
                                  Colors.redAccent,
                                );
                              }
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic ? 'الصوتيات والخطب المحملة' : 'Downloaded Audio',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                color: textMain,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isArabic ? 'إدارة السور والمقاطع المحفوظة' : 'Manage offline surahs & audio',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 12,
                                color: textMain.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MinbarDownloadsScreen()),
                            );
                          },
                          child: Text(
                            isArabic ? 'إدارة' : 'Manage',
                            style: TextStyle(fontFamily: 'Amiri', color: primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
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
      final launched =
          await launchUrl(url, mode: LaunchMode.externalApplication);
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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

  // ── Helper Color Resolvers ─────────────────────────────────────────────────

  Color _getScaffoldBg(QuranTheme theme) {
    switch (theme) {
      case QuranTheme.dark:
        return const Color(0xFF070E0B);
      case QuranTheme.cream:
        return const Color(0xFFFBF8F0);
      case QuranTheme.white:
        return const Color(0xFFF3F6F3);
    }
  }

  Color _getHeroBg(QuranTheme theme) {
    switch (theme) {
      case QuranTheme.dark:
        return const Color(0xFF0E1F18);
      case QuranTheme.cream:
        return const Color(0xFFF4EDDC);
      case QuranTheme.white:
        return const Color(0xFFE8EFE8);
    }
  }

  // ── Main Build Method with Circular Reveal Stack ───────────────────────────

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Stack(
      children: [
        // ── 1. Base Layer (Current Theme) ───────────────────────────────────
        _buildSettingsView(_baseTheme, _baseScrollCtrl),

        // ── 2. Circular Reveal Layer (Expands radially from tapped button) ───
        if (_isRevealing && _revealScrollCtrl != null)
          AnimatedBuilder(
            animation: _revealAnim,
            builder: (context, _) {
              final double radius =
                  1.0 + (_revealAnim.value * (_maxRadius - 1.0));

              return Stack(
                children: [
                  ClipPath(
                    clipper: CircularRevealClipper(
                      center: _revealOrigin,
                      radius: radius,
                    ),
                    child: _buildSettingsView(_targetTheme, _revealScrollCtrl!),
                  ),
                  // Glowing circular ripple edge starting from 1px
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _RippleRingPainter(
                          center: _revealOrigin,
                          radius: radius,
                          color: AppTheme.getBorderColor(_targetTheme),
                          progress: _revealAnim.value,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildSettingsView(QuranTheme theme, ScrollController scrollCtrl) {
    final l10n = AppLocalizations.of(context)!;
    final bool isArabic =
        AppLanguage.notifier.value.languageCode == 'ar' ||
            _selectedLanguage == 'Arabic' ||
            Localizations.maybeLocaleOf(context)?.languageCode == 'ar' ||
            Directionality.of(context) == TextDirection.rtl;
    final lang = isArabic
        ? 'ar'
        : (Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar');

    final Color primary = AppTheme.getPrimaryColor(theme);
    final Color textMain = AppTheme.getMainTextColor(theme);
    final Color textSub = textMain.withValues(alpha: 0.65);
    final Color cardBg = AppTheme.getCardBgColor(theme);
    final Color borderColor = AppTheme.getBorderColor(theme);
    final bool isDark = theme == QuranTheme.dark;
    final Color scaffoldBg = _getScaffoldBg(theme);
    final Color heroBannerBg = _getHeroBg(theme);

    return ValueListenableBuilder<bool>(
      valueListenable: kAdVisibleNotifier,
      builder: (context, isAdVisible, _) {
        final double bottomClearance =
            MediaQuery.paddingOf(context).bottom + (isAdVisible ? 165.0 : 125.0);

        return Scaffold(
      backgroundColor: scaffoldBg,
      body: CustomScrollView(
        controller: scrollCtrl,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── 1. Elegant Compact Hero Header (One UI / iOS 18) ───────────────
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: FadeTransition(
                  opacity: _headerFade,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: heroBannerBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            borderColor.withValues(alpha: isDark ? 0.25 : 0.35),
                        width: 1.1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isDark ? 0.3 : 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Glowing App Emblem
                        Container(
                          width: 36,
                          height: 36,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [borderColor, primary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: primary.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
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
                        const SizedBox(width: 10),
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: textMain,
                                      letterSpacing: 0.3,
                                      fontFamily: isArabic ? 'Amiri' : null,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5, vertical: 1.2),
                                    decoration: BoxDecoration(
                                      color: primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: primary.withValues(alpha: 0.35),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      _appVersion,
                                      style: TextStyle(
                                        color: primary,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _tr(context, 'settings_subtitle'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSub,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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

          // ── 2. Settings Content Body ────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── 🛡️ PERMISSIONS & SYSTEM HEALTH CENTER ────────────────────
                _PermissionsHealthCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  primary: primary,
                  borderColor: borderColor,
                ),

                // ── SECTION A: PREFERENCES (THEME & LANGUAGE SIDE-BY-SIDE) ───
                _sectionHeader(
                  icon: Icons.tune_rounded,
                  title: isArabic ? 'التخصيص واللغة' : 'PREFERENCES & LANGUAGE',
                  color: primary,
                ),
                Row(
                  children: [
                    // Theme Bento Card
                    Expanded(
                      flex: 11,
                      child: _CompactThemeCard(
                        currentTheme: theme,
                        primary: primary,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        isDark: isDark,
                        isArabic: isArabic,
                        darkLabel: _tr(context, 'theme_dark'),
                        creamLabel: _tr(context, 'theme_cream'),
                        whiteLabel: _tr(context, 'theme_white'),
                        onThemeSelected: _startCircularThemeReveal,
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Language Bento Card
                    Expanded(
                      flex: 9,
                      child: _CompactLanguageCard(
                        selectedLanguage: _selectedLanguage,
                        primary: primary,
                        cardBg: cardBg,
                        borderColor: borderColor,
                        isDark: isDark,
                        isArabic: isArabic,
                        title: 'Language',
                        onTap: () => _showLanguageDialog(
                            primary, textMain, cardBg, l10n),
                        textColor: textMain,
                        subtextColor: textSub,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ── SECTION B: DAILY WORSHIP & OFFLINE CONTENT ────────────────
                _sectionHeader(
                  icon: Icons.mosque_rounded,
                  title: isArabic
                      ? 'العبادات والمحتوى'
                      : 'DAILY WORSHIP & OFFLINE',
                  color: const Color(0xFF10B981),
                ),
                _ModernCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  borderColor: borderColor,
                  children: [
                    _CompactTile(
                      icon: Icons.access_time_filled_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: _tr(context, 'prayer_settings'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PrayerSettingsScreen(
                                controller: PrayerController()),
                          ),
                        );
                      },
                      isDark: isDark,
                      textColor: textMain,
                      isRtl: isArabic,
                    ),
                    _divider(isDark, borderColor, indent: 52),
                    _CompactSwitchTile(
                      icon: Icons.notifications_active_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: _tr(context, 'daily_notif'),
                      value: _notificationsEnabled,
                      activeColor: primary,
                      onChanged: _toggleNotifications,
                      isDark: isDark,
                      textColor: textMain,
                      intervalBadge: _notificationsEnabled
                          ? GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _showIntervalSheet(
                                  context, primary, textMain, cardBg),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: primary.withValues(alpha: 0.35),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatInterval(_notificationInterval),
                                      style: TextStyle(
                                        color: primary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 1),
                                    Icon(Icons.arrow_drop_down_rounded,
                                        size: 14, color: primary),
                                  ],
                                ),
                              ),
                            )
                          : null,
                    ),
                    _divider(isDark, borderColor, indent: 52),
                    _CompactTile(
                      icon: Icons.download_done_rounded,
                      iconColor: const Color(0xFF0D9488),
                      title: _tr(context, 'downloads'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const MinbarDownloadsScreen()),
                        );
                      },
                      isDark: isDark,
                      textColor: textMain,
                      isRtl: isArabic,
                    ),
                    _divider(isDark, borderColor, indent: 52),
                    _CompactTile(
                      icon: Icons.storage_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      title: isArabic ? 'إدارة المساحة والتخزين' : 'Storage Management',
                      onTap: () => _showStorageManagerSheet(
                        context,
                        primary,
                        textMain,
                        cardBg,
                        isDark,
                        isArabic,
                      ),
                      isDark: isDark,
                      textColor: textMain,
                      isRtl: isArabic,
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // ── SECTION C: SUPPORT, PRIVACY & ABOUT ───────────────────────
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
                      icon: Icons.system_update_rounded,
                      iconGradient: const [
                        Color(0xFF06B6D4),
                        Color(0xFF0891B2)
                      ],
                      title: _tr(context, 'check_updates'),
                      subtitle: _tr(context, 'check_updates_desc'),
                      onTap: () => AppUpdateService.instance
                          .checkForUpdate(context, isManual: true),
                      isDark: isDark,
                      textColor: textMain,
                      subtextColor: textSub,
                      isRtl: isArabic,
                    ),
                    _divider(isDark, borderColor, indent: 68),
                    _ModernActionTile(
                      icon: Icons.star_rate_rounded,
                      iconGradient: const [
                        Color(0xFFF59E0B),
                        Color(0xFFD97706)
                      ],
                      title: _tr(context, 'rate_us'),
                      subtitle: _getRateUsSubtitle(lang),
                      onTap: () async {
                        final Uri url = Uri.parse(
                            'https://play.google.com/store/apps/details?id=com.umer.quranzone');
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      },
                      isDark: isDark,
                      textColor: textMain,
                      subtextColor: textSub,
                      isRtl: isArabic,
                    ),
                    _divider(isDark, borderColor, indent: 68),
                    _ModernActionTile(
                      icon: Icons.share_rounded,
                      iconGradient: const [
                        Color(0xFF3B82F6),
                        Color(0xFF1D4ED8)
                      ],
                      title: _tr(context, 'share_app'),
                      subtitle: _getShareAppSubtitle(lang),
                      onTap: () {
                        Share.share(
                          'Download Quran Zone for an exquisite Quran & Islamic experience:\nhttps://play.google.com/store/apps/details?id=com.umer.quranzone',
                        );
                      },
                      isDark: isDark,
                      textColor: textMain,
                      subtextColor: textSub,
                      isRtl: isArabic,
                    ),
                    _divider(isDark, borderColor, indent: 68),
                    _ModernActionTile(
                      icon: Icons.security_rounded,
                      iconGradient: const [
                        Color(0xFF10B981),
                        Color(0xFF047857)
                      ],
                      title: _tr(context, 'privacy_policy'),
                      subtitle: _getPrivacySubtitle(lang),
                      onTap: () => _openPrivacyPolicy(
                          context, cardBg, textMain, textSub, primary),
                      isDark: isDark,
                      textColor: textMain,
                      subtextColor: textSub,
                      isRtl: isArabic,
                    ),
                    _divider(isDark, borderColor, indent: 68),
                    _ModernActionTile(
                      icon: Icons.auto_stories_rounded,
                      iconGradient: const [
                        Color(0xFF8B5CF6),
                        Color(0xFF6D28D9)
                      ],
                      title: _tr(context, 'about_app'),
                      subtitle: _getAboutSubtitle(lang),
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
                      isRtl: isArabic,
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // ── 🌟 SECTION D: COMMUNITY & OFFICIAL CHANNELS ───────────────
                _sectionHeader(
                  icon: Icons.forum_rounded,
                  title: _tr(context, 'creator_community'),
                  color: const Color(0xFF10B981),
                  badgeText: isArabic ? 'تواصل ومتابعة' : 'OFFICIAL',
                ),
                _IslamicCommunityCard(
                  isDark: isDark,
                  cardBg: cardBg,
                  primary: primary,
                  borderColor: borderColor,
                  creatorName: _tr(context, 'creator_name'),
                  creatorRole: _tr(context, 'creator_role'),
                  creatorNote: _tr(context, 'creator_note'),
                  onTikTok: _openTikTok,
                  onTelegram: _openTelegram,
                  onEmail: _openEmail,
                ),

                // ── FOOTER DEDICATION ─────────────────────────────────────────
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_rounded,
                              size: 12, color: primary.withValues(alpha: 0.6)),
                          const SizedBox(width: 5),
                          Text(
                            isArabic
                                ? 'Quran Zone • صدقة جارية لوجه الله تعالى'
                                : 'Quran Zone • Sadaqah Jariyah for the Ummah',
                            style: TextStyle(
                              color: textSub.withValues(alpha: 0.8),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isArabic
                            ? 'نسألكم صالح الدعاء'
                            : 'Keep us in your sincere Du\'a',
                        style: TextStyle(
                          color: textSub.withValues(alpha: 0.55),
                          fontSize: 10,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: bottomClearance),
              ]),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  // ── Section Header with Overflow Safety ────────────────────────────────────

  Widget _sectionHeader({
    required IconData icon,
    required String title,
    required Color color,
    String? badgeText,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 5, top: 9),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.6,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFE2C55), Color(0xFF25F4EE)],
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                badgeText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8.5,
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

  Widget _divider(bool isDark, Color borderColor, {double indent = 54}) {
    return Divider(
      height: 1,
      thickness: 0.8,
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.05),
      indent: indent,
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
            'icon': Icons.picture_as_pdf_rounded,
            'color': const Color(0xFFEF4444),
            'title': isArabic
                ? 'قارئ كتب PDF ورف كتبي الخاص'
                : 'Islamic PDF Reader & Personal Bookshelf',
            'desc': isArabic
                ? 'قارئ كتب PDF متكامل ومطور: قراءة بالتمرير الرأسي المستمر، ترجمة النصوص الفورية، البحث في Google، وسؤال الذكاء الاصطناعي (AI) مباشرة من الصفحة، مع حفظ تلقائي لآخر صفحة ومشاركة الكتب.'
                : 'Complete built-in PDF reader: continuous vertical scrolling, instant text translation, Google Search & on-device AI queries, automatic page tracking, and easy book sharing.',
          },
          {
            'icon': Icons.menu_book_rounded,
            'color': const Color(0xFF10B981),
            'title': isArabic
                ? 'القرآن الكريم والتفاسير'
                : 'The Noble Quran & Tafsir',
            'desc': isArabic
                ? 'مصحف المدينة النبوية بالخط العثماني، تلاوة متزامنة آية بآية مع تلوين الكلمات، ٤ تفاسير معتمدة (ابن كثير، الميسر، البغوي، السعدي)، معاني الكلمات، وإعراب القرآن كاملاً.'
                : 'Authentic Madinah Mushaf (Uthmani script) with synced ayah & word highlights, 4 Tafsir books, word meanings & Quranic syntax (I\'rab).',
          },
          {
            'icon': Icons.podcasts_rounded,
            'color': const Color(0xFF6366F1),
            'title': isArabic
                ? 'المنبر والصوتيات والبث الحي'
                : 'Minbar Audios & 24/7 Live Media',
            'desc': isArabic
                ? 'مكتبة صوتية لأكثر من ١٠٠ قارئ، أكثر من ١٧٥ إذاعة إسلامية مباشرة على مدار الساعة، وبث حي عالي الدقة من الحرمين الشريفين.'
                : '100+ Renowned Quran Reciters, 175+ Live Islamic radio stations 24/7, and HD direct live video streams from Makkah & Madinah.',
          },
          {
            'icon': Icons.access_time_filled_rounded,
            'color': const Color(0xFFF59E0B),
            'title': isArabic
                ? 'مواقيت الصلاة، الأذان والقبلة 3D'
                : 'Prayer Times, Athan & 3D Qibla',
            'desc': isArabic
                ? 'حسابات فلكية بالغة الدقة لمواقيت الصلاة عالمياً، تنبيهات الأذان بأصوات كبار المؤذنين، وبوصلة القبلة ثلاثية الأبعاد.'
                : 'Precision astronomical prayer schedules, background Athan notifications with various Muezzin voices, 3D compass Qibla finder.',
          },
          {
            'icon': Icons.library_books_rounded,
            'color': const Color(0xFF0D9488),
            'title': isArabic
                ? 'المكتبة الإسلامية وصحيح البخاري'
                : 'Islamic Library & Sahih Al-Bukhari',
            'desc': isArabic
                ? 'صحيح البخاري كاملاً بالأسانيد والأبواب، قصص الأنبياء، السيرة النبوية، سير الصحابة، والفتاوى الشرعية الموثوقة.'
                : 'Complete Sahih Al-Bukhari with hadith chains, Stories of the Prophets, Seerah, Companions, and Authentic Ruqyah.',
          },
          {
            'icon': Icons.auto_stories_rounded,
            'color': const Color(0xFFEC4899),
            'title': isArabic
                ? 'حصن المسلم والأذكار التفاعلية'
                : 'Hisn Al-Muslim & Daily Remembrance',
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
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(28)),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
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
                              style: TextStyle(
                                  fontSize: 13, color: textSub, height: 1.55),
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
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black12,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: (ticket['color'] as Color)
                                            .withValues(alpha: 0.14),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                border: Border.all(
                                    color: goldColor.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.favorite_rounded,
                                      color: goldColor, size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isArabic
                                              ? 'صدقة جارية للأمة الإسلامية'
                                              : 'Sadaqah Jariyah for the Ummah',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? const Color(0xFFFDE68A)
                                                : const Color(0xFF92400E),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isArabic
                                              ? 'هذا العمل خالص لوجه الله تعالى وبلا مقابل. نسأل الله أن يتقبله وينفع به المسلمين أجمعين.'
                                              : 'Built purely for the pleasure of Allah ﷻ without barrier. We pray Allah accepts it as a continuous charity for all believers.',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: isDark
                                                ? const Color(0xFFE5D5B8)
                                                : const Color(0xFF78350F),
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
                                icon: const Icon(Icons.share_rounded,
                                    size: 18, color: Colors.white),
                                label: Text(
                                  isArabic
                                      ? 'شارك التطبيق واكسب الأجر'
                                      : 'Share Quran Zone',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: emeraldColor,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
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
// COMPONENT 0a: Compact Action Tile (no subtitle, reduced height)
// ─────────────────────────────────────────────────────────────────────────────

class _CompactTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;
  final bool isDark;
  final Color textColor;
  final bool? isRtl;

  const _CompactTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
    required this.isDark,
    required this.textColor,
    this.isRtl,
  });

  @override
  Widget build(BuildContext context) {
    final bool rtl = isRtl ??
        (AppLanguage.notifier.value.languageCode == 'ar' ||
            Directionality.of(context) == TextDirection.rtl ||
            Localizations.maybeLocaleOf(context)?.languageCode == 'ar');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 15.5),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(
              rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : Colors.black38,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 0b: Compact Switch Tile (no subtitle, reduced height)
// ─────────────────────────────────────────────────────────────────────────────

class _CompactSwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;
  final bool isDark;
  final Color textColor;
  final Widget? intervalBadge;

  const _CompactSwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.activeColor,
    required this.onChanged,
    required this.isDark,
    required this.textColor,
    this.intervalBadge,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 15.5),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (intervalBadge != null) ...[
              const SizedBox(width: 6),
              intervalBadge!,
            ],
            const SizedBox(width: 6),
            Transform.scale(
              scale: 0.82,
              child: Switch.adaptive(
                value: value,
                activeTrackColor: activeColor.withValues(alpha: 0.5),
                activeThumbColor: activeColor,
                inactiveTrackColor: isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08),
                inactiveThumbColor: isDark
                    ? Colors.white.withValues(alpha: 0.65)
                    : Colors.black.withValues(alpha: 0.45),
                trackOutlineColor:
                    WidgetStateProperty.all(Colors.transparent),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: onChanged,
              ),
            ),
          ],
        ),
      ),
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
  final VoidCallback onTap;
  final bool isDark;
  final Color textColor;
  final Color subtextColor;
  final bool? isRtl;

  const _ModernActionTile({
    required this.icon,
    required this.iconGradient,
    required this.title,
    this.subtitle,
    required this.onTap,
    required this.isDark,
    required this.textColor,
    required this.subtextColor,
    this.isRtl,
  });

  @override
  Widget build(BuildContext context) {
    final bool rtl = isRtl ??
        (AppLanguage.notifier.value.languageCode == 'ar' ||
            Directionality.of(context) == TextDirection.rtl ||
            Localizations.maybeLocaleOf(context)?.languageCode == 'ar');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: iconGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: iconGradient.first.withValues(alpha: 0.3),
                    blurRadius: 7,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 20),
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
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              rtl
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
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
// ─────────────────────────────────────────────────────────────────────────────
// 🛡️ COMPONENT: System & Athan Permissions Health Center
// ─────────────────────────────────────────────────────────────────────────────

class _PermissionsHealthCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final Color primary;
  final Color borderColor;

  const _PermissionsHealthCard({
    required this.isDark,
    required this.cardBg,
    required this.primary,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isArabic =
        Localizations.maybeLocaleOf(context)?.languageCode == 'ar';

    return ValueListenableBuilder<int>(
      valueListenable: PermissionHealthService.missingCountNotifier,
      builder: (context, missingCount, _) {
        if (missingCount <= 0) {
          // All systems optimal - subtle dignified green banner
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF071B11) : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.35),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isArabic
                            ? 'حالة النظام والأذان ممتازة'
                            : 'All Systems & Permissions Optimal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF065F46),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        isArabic
                            ? 'كافة الصلاحيات مفعلة لضمان استقرار أوقات الأذان'
                            : 'All permissions active for punctual background Athan',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? Colors.white70 : const Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Missing permissions alert card with review action
        const alertColor = Color(0xFFE53935);
        return Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF220C0C) : const Color(0xFFFFF3F3),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: alertColor.withValues(alpha: 0.4),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: alertColor.withValues(alpha: isDark ? 0.2 : 0.08),
                blurRadius: 12,
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
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: alertColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: alertColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isArabic
                                  ? 'تنبيه إعدادات النظام والأذان'
                                  : 'System Permissions Health',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: alertColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$missingCount ${isArabic ? 'مفقودة' : 'Missing'}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isArabic
                              ? 'لضمان دقة الأذان في موعده والتنبيهات، يرجى تفعيل الصلاحيات.'
                              : 'To ensure punctual Athan alarms, please review disabled permissions.',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? Colors.white70 : Colors.black54,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 36,
                child: FilledButton.icon(
                  onPressed: () async {
                    await PermissionsSetupScreen.showAsModal(context);
                    await PermissionHealthService.checkHealth();
                  },
                  icon: const Icon(Icons.tune_rounded, size: 15),
                  label: Text(
                    isArabic
                        ? 'مراجعة وتفعيل الصلاحيات المعطلة'
                        : 'Review & Enable Permissions',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: alertColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🌟 COMPONENT 6: Authentic Islamic Community & Creator Hub
// ─────────────────────────────────────────────────────────────────────────────

class _IslamicCommunityCard extends StatelessWidget {
  final bool isDark;
  final Color cardBg;
  final Color primary;
  final Color borderColor;
  final String creatorName;
  final String creatorRole;
  final String creatorNote;
  final VoidCallback onTikTok;
  final VoidCallback onTelegram;
  final VoidCallback onEmail;

  const _IslamicCommunityCard({
    required this.isDark,
    required this.cardBg,
    required this.primary,
    required this.borderColor,
    required this.creatorName,
    required this.creatorRole,
    required this.creatorNote,
    required this.onTikTok,
    required this.onTelegram,
    required this.onEmail,
  });

  @override
  Widget build(BuildContext context) {
    const emeraldAccent = Color(0xFF10B981);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: emeraldAccent.withValues(alpha: isDark ? 0.35 : 0.25),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: emeraldAccent.withValues(alpha: isDark ? 0.12 : 0.05),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Row 1: Official Channels & Community ────────────────────────────
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: emeraldAccent.withValues(alpha: isDark ? 0.16 : 0.10),
                  border: Border.all(
                    color: emeraldAccent.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.forum_rounded,
                    size: 19,
                    color: emeraldAccent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      creatorName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 1.5),
                    Text(
                      creatorRole,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.black.withValues(alpha: 0.6),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Row 2: 3 Equal Side-by-Side Channels (TikTok, Telegram, Email) ───
          Row(
            children: [
              // 1. TikTok Button
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: onTikTok,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: const Color(0xFFFE2C55).withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                      backgroundColor:
                          const Color(0xFFFE2C55).withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.music_note_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'TikTok',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFFFF5277)
                                : const Color(0xFFFE2C55),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),

              // 2. Telegram Button
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: onTelegram,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Color(0xFF0088CC),
                        width: 1.2,
                      ),
                      backgroundColor:
                          const Color(0xFF0088CC).withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CustomPaint(
                            painter: _TelegramIconPainter(),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Telegram',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF54C5F8)
                                : const Color(0xFF0088CC),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 7),

              // 3. Email Button
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: OutlinedButton(
                    onPressed: onEmail,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: primary.withValues(alpha: 0.45),
                        width: 1.2,
                      ),
                      backgroundColor: primary.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.email_outlined, size: 15, color: primary),
                        const SizedBox(width: 5),
                        Text(
                          'Email',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),

          // Spiritual Note
          Text(
            creatorNote,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? Colors.white38 : Colors.black38,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 7: Compact Theme Card (Bento-style, 3 theme swatches in a row)
// ─────────────────────────────────────────────────────────────────────────────

class _CompactThemeCard extends StatelessWidget {
  final QuranTheme currentTheme;
  final Color primary;
  final Color cardBg;
  final Color borderColor;
  final bool isDark;
  final bool isArabic;
  final String darkLabel;
  final String creamLabel;
  final String whiteLabel;
  final void Function(QuranTheme theme, Offset origin) onThemeSelected;

  const _CompactThemeCard({
    required this.currentTheme,
    required this.primary,
    required this.cardBg,
    required this.borderColor,
    required this.isDark,
    required this.isArabic,
    required this.darkLabel,
    required this.creamLabel,
    required this.whiteLabel,
    required this.onThemeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final themeOptions = [
      (
        QuranTheme.dark,
        darkLabel,
        Icons.nights_stay_rounded,
        const Color(0xFF0D1F17),
        const Color(0xFFE8C77A),
        Colors.white,
      ),
      (
        QuranTheme.cream,
        creamLabel,
        Icons.wb_sunny_rounded,
        const Color(0xFFFDFBF0),
        const Color(0xFF1B4332),
        const Color(0xFF1A120B),
      ),
      (
        QuranTheme.white,
        whiteLabel,
        Icons.light_mode_rounded,
        Colors.white,
        const Color(0xFF10B981),
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
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.palette_rounded, size: 13, color: primary),
                const SizedBox(width: 5),
                Text(
                  isArabic ? 'المظهر' : 'Theme',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: primary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    currentTheme == QuranTheme.dark
                        ? darkLabel
                        : (currentTheme == QuranTheme.cream
                            ? creamLabel
                            : whiteLabel),
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: primary.withValues(alpha: 0.85),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: themeOptions.map((t) {
              final isSelected = currentTheme == t.$1;
              return Expanded(
                child: _ThemeSwatchButton(
                  theme: t.$1,
                  isSelected: isSelected,
                  bgColor: t.$4,
                  borderColor: borderColor,
                  iconColor: t.$5,
                  icon: t.$3,
                  isDark: isDark,
                  onSelected: onThemeSelected,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 7.1: Individual Theme Swatch Button with Exact Tap Origin Tracking
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeSwatchButton extends StatefulWidget {
  final QuranTheme theme;
  final bool isSelected;
  final Color bgColor;
  final Color borderColor;
  final Color iconColor;
  final IconData icon;
  final bool isDark;
  final void Function(QuranTheme theme, Offset origin) onSelected;

  const _ThemeSwatchButton({
    Key? key,
    required this.theme,
    required this.isSelected,
    required this.bgColor,
    required this.borderColor,
    required this.iconColor,
    required this.icon,
    required this.isDark,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<_ThemeSwatchButton> createState() => _ThemeSwatchButtonState();
}

class _ThemeSwatchButtonState extends State<_ThemeSwatchButton> {
  Offset? _tapPosition;

  void _triggerReveal([Offset? directTap]) {
    final box = context.findRenderObject() as RenderBox?;
    Offset origin;
    if (box != null && box.hasSize) {
      final Rect bounds = box.localToGlobal(Offset.zero) & box.size;
      final Offset center = box.localToGlobal(box.size.center(Offset.zero));
      final tap = directTap ?? _tapPosition;
      if (tap != null && bounds.contains(tap)) {
        origin = tap;
      } else {
        origin = center;
      }
    } else {
      origin = directTap ?? _tapPosition ?? Offset.zero;
    }
    _tapPosition = null;
    widget.onSelected(widget.theme, origin);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => _tapPosition = details.globalPosition,
      onTapCancel: () => _tapPosition = null,
      onTap: () => _triggerReveal(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 2.5),
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
        decoration: BoxDecoration(
          color: widget.bgColor,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: widget.isSelected
                ? widget.borderColor
                : (widget.isDark ? Colors.white12 : Colors.black12),
            width: widget.isSelected ? 2 : 1,
          ),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: widget.borderColor.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.iconColor.withValues(alpha: 0.18),
                ),
                child: Icon(widget.icon, size: 15, color: widget.iconColor),
              ),
              if (widget.isSelected)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.borderColor,
                    ),
                    child: const Icon(Icons.check,
                        size: 8, color: Colors.black),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 8: Compact Language Card (Bento-style)
// ─────────────────────────────────────────────────────────────────────────────

class _CompactLanguageCard extends StatelessWidget {
  final String selectedLanguage;
  final Color primary;
  final Color cardBg;
  final Color borderColor;
  final bool isDark;
  final bool isArabic;
  final String title;
  final VoidCallback onTap;
  final Color textColor;
  final Color subtextColor;

  const _CompactLanguageCard({
    required this.selectedLanguage,
    required this.primary,
    required this.cardBg,
    required this.borderColor,
    required this.isDark,
    required this.isArabic,
    required this.title,
    required this.onTap,
    required this.textColor,
    required this.subtextColor,
  });

  static const Map<String, String> _flagEmoji = {
    'Arabic': '🇸🇦',
    'English': '🇬🇧',
    'Amharic': '🇪🇹',
    'Oromo': '🇪🇹',
  };

  static const Map<String, String> _nativeNames = {
    'Arabic': 'العربية',
    'English': 'English',
    'Amharic': 'አማርኛ',
    'Oromo': 'Oromoo',
  };

  @override
  Widget build(BuildContext context) {
    final flag = _flagEmoji[selectedLanguage] ?? '🌐';
    final nativeName = _nativeNames[selectedLanguage] ?? selectedLanguage;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.07),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.translate_rounded, size: 13, color: primary),
                const SizedBox(width: 5),
                Text(
                  'Language',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: primary,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: subtextColor,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  flag,
                  style: const TextStyle(fontSize: 22),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nativeName,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        selectedLanguage,
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENT 9: Telegram Icon Painter (real Telegram paper-plane logo)
// ─────────────────────────────────────────────────────────────────────────────

class _TelegramIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paint = Paint()
      ..color = const Color(0xFF0088CC)
      ..style = PaintingStyle.fill;

    // Telegram paper-plane path (simplified, proportional to size)
    final path = Path();
    // Main body arrow
    path.moveTo(w * 0.05, h * 0.45);
    path.lineTo(w * 0.95, h * 0.1);
    path.lineTo(w * 0.65, h * 0.9);
    path.lineTo(w * 0.42, h * 0.67);
    path.close();
    canvas.drawPath(path, paint);

    // Tail fold
    final tail = Path();
    tail.moveTo(w * 0.42, h * 0.67);
    tail.lineTo(w * 0.38, h * 0.52);
    tail.lineTo(w * 0.95, h * 0.1);
    tail.close();
    canvas.drawPath(tail, paint..color = const Color(0xFF54C5F8));
  }

  @override
  bool shouldRepaint(_TelegramIconPainter _) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CIRCULAR REVEAL CLIPPER & RIPPLE RING PAINTER (Telegram-Style)
// ─────────────────────────────────────────────────────────────────────────────

class CircularRevealClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  const CircularRevealClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) {
    return Path()..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(CircularRevealClipper oldClipper) {
    return oldClipper.radius != radius || oldClipper.center != center;
  }
}

class _RippleRingPainter extends CustomPainter {
  final Offset center;
  final double radius;
  final Color color;
  final double progress;

  _RippleRingPainter({
    required this.center,
    required this.radius,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (radius < 1.0) return;
    final double alpha = (1.0 - progress * 0.65).clamp(0.0, 1.0);
    final double ringScale = (radius / 25.0).clamp(0.0, 1.0);

    // Glowing outer aura (softly blooms from 1px without an awkward blob)
    if (radius > 2.0) {
      final aura = Paint()
        ..color = color.withValues(alpha: alpha * 0.35 * ringScale)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (6.0 * ringScale).clamp(1.0, 6.0)
        ..maskFilter = MaskFilter.blur(
            BlurStyle.normal, (3.0 * ringScale).clamp(0.5, 3.0));
      canvas.drawCircle(center, radius, aura);
    }

    // Sharp wavefront ring starting right from 1px
    final core = Paint()
      ..color = color.withValues(alpha: alpha * 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (2.5 * ringScale).clamp(0.8, 2.5);
    canvas.drawCircle(center, radius, core);
  }

  @override
  bool shouldRepaint(_RippleRingPainter old) =>
      old.radius != radius || old.progress != progress || old.color != color;
}
