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
import '../core/constants/app_colors.dart';
import '../features/prayer_times/presentation/controllers/prayer_controller.dart';
import '../features/prayer_times/presentation/screens/prayer_settings_screen.dart';
import 'minbar_downloads_screen.dart';
import '../services/app_update_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS SCREEN — Professional Islamic Redesign
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
  String _appVersion = 'Version 1.0.0';

  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;

  final List<String> _languages = ['Amharic', 'Oromo', 'English', 'Arabic'];

  static const Map<String, Map<String, String>> _l10n = {
    'en': {
      'settings_title': 'Settings',
      'appearance': 'APPEARANCE & THEMES',
      'language': 'APP LANGUAGE',
      'prayer_section': 'PRAYER & ATHAN',
      'prayer_settings': 'Prayer Times & Athan',
      'prayer_desc': 'Muezzin voices, calculation method & adjustments',
      'notifications': 'REMINDERS & NOTIFICATIONS',
      'storage_section': 'STORAGE & OFFLINE',
      'downloads': 'Downloaded Audio Library',
      'downloads_desc': 'Manage offline surahs & lectures',
      'share_info': 'SHARE & INFORMATION',
      'share_app': 'Share Quran Zone',
      'rate_us': 'Rate Us on Google Play',
      'contact_us': 'Contact Developer & Feedback',
      'privacy_policy': 'Privacy Policy',
      'privacy_desc': 'Your data security & offline privacy',
      'about_app': 'About Quran Zone',
      'check_updates': 'Check for Updates',
      'check_updates_desc': 'Search for new features & updates',
      'theme_dark': 'Dark Mode',
      'theme_cream': 'Warm Cream',
      'theme_white': 'Pure Light',
      'daily_notif': 'Daily Islamic Reminders',
      'daily_notif_desc': 'Periodic Quran & Dhikr notifications',
      'freq_title': 'Reminder Frequency',
    },
    'ar': {
      'settings_title': 'الإعدادات',
      'appearance': 'المظهر والثيمات',
      'language': 'لغة التطبيق',
      'prayer_section': 'مواقيت الصلاة والأذان',
      'prayer_settings': 'إعدادات الصلاة والأذان',
      'prayer_desc': 'أصوات المؤذنين، طرق الحساب، وتعديل الدقائق',
      'notifications': 'التنبيهات والأذكار',
      'storage_section': 'التخزين والمحفوظات',
      'downloads': 'التسجيلات المحملة',
      'downloads_desc': 'إدارة السور والمحاضرات بدون إنترنت',
      'share_info': 'عن التطبيق والمشاركة',
      'share_app': 'مشاركة تطبيق Quran Zone',
      'rate_us': 'تقييم التطبيق على المتجر',
      'contact_us': 'تواصل مع المطور والملاحظات',
      'privacy_policy': 'سياسة الخصوصية',
      'privacy_desc': 'حماية البيانات وخصوصية المستخدم',
      'about_app': 'عن تطبيق Quran Zone',
      'check_updates': 'التحقق من وجود تحديثات',
      'check_updates_desc': 'البحث عن أحدث المزايا والإصدارات',
      'theme_dark': 'الوضع الداكن',
      'theme_cream': 'كريمي دافئ',
      'theme_white': 'أبيض ناصع',
      'daily_notif': 'التنبيهات والأذكار اليومية',
      'daily_notif_desc': 'إشعارات دورية بالقرآن والأذكار في الخلفية',
      'freq_title': 'تكرار التذكير',
    },
    'am': {
      'settings_title': 'ቅንብሮች',
      'appearance': 'መልክ እና ገጽታ',
      'language': 'የመተግበሪያ ቋንቋ',
      'prayer_section': 'የሶላት ጊዜያት እና አዛን',
      'prayer_settings': 'የሶላት እና የአዛን ቅንብሮች',
      'prayer_desc': 'የሙአዚን ድምጾች፣ የስሌት ዘዴ እና ማስተካከያዎች',
      'notifications': 'ማስታወሻዎች እና አዝካር',
      'storage_section': 'ማከማቻ እና የወረዱ ፋይሎች',
      'downloads': 'የወረዱ የድምጽ ፋይሎች',
      'downloads_desc': 'ያለ ኢንተርኔት የሚያዳምጡትን ያስተዳድሩ',
      'share_info': 'ስለ መተግበሪያው እና ማጋራት',
      'share_app': 'መተግበሪያውን ያጋሩ',
      'rate_us': 'በፕሌይ ስቶር ደረጃ ይስጡ',
      'contact_us': 'አዘጋጁን ያነጋግሩ',
      'privacy_policy': 'የግላዊነት ፖሊሲ',
      'privacy_desc': 'የውሂብ ደህንነት እና ግላዊነት',
      'about_app': 'ስለ መተግበሪያው',
      'check_updates': 'አዲስ ዝመናዎችን ይፈልጉ',
      'check_updates_desc': 'አዲስ ስሪት እና ማሻሻያዎችን ያረጋግጡ',
      'theme_dark': 'ጨለማ ገጽታ',
      'theme_cream': 'ክሬም ገጽታ',
      'theme_white': 'ነጭ ገጽታ',
      'daily_notif': 'ዕለታዊ ማስታወሻዎች',
      'daily_notif_desc': 'የቁርኣን እና የአዝካር ማሳሰቢያዎች',
      'freq_title': 'የማስታወሻ ድግግሞሽ',
    },
    'om': {
      'settings_title': 'Qindaa\'ina',
      'appearance': 'Bifaa fi Haala',
      'language': 'Afaan Appilikeeshinii',
      'prayer_section': 'Yeroo Salaataa fi Azaana',
      'prayer_settings': 'Qindaa\'ina Salaataa fi Azaanaa',
      'prayer_desc': 'Sagalee Mu\'azzinaa, mala herregaa fi sirreeffama',
      'notifications': 'Yaadachiisaa fi Azkaara',
      'storage_section': 'Kuusaa fi Buufataalee',
      'downloads': 'Sagaleewwan Buufaman',
      'downloads_desc': 'Toora malee fayyadamuuf kanneen qophaa\'an',
      'share_info': 'Waa\'ee App fi Qooduu',
      'share_app': 'Appilikeeshinii Qoodaa',
      'rate_us': 'Play Store irratti sadarkaa kennaa',
      'contact_us': 'Hojjataa qunnamaa',
      'privacy_policy': 'Imaammata Dhuunfaa',
      'privacy_desc': 'Nageenya daataa fi dhuunfaa keessanii',
      'about_app': 'Waa\'ee Appilikeeshinii',
      'check_updates': 'Fooyya\'iinsa Haaraa Barbaadi',
      'check_updates_desc': 'Wanta haaraa jiraachuu ilaali',
      'theme_dark': 'Haala Dukkanaa',
      'theme_cream': 'Kiriimii Hoo\'aa',
      'theme_white': 'Adii Qulqulluu',
      'daily_notif': 'Yaadachiisa Guyyaa',
      'daily_notif_desc': 'Akeekkachiisa Qur\'aanaa fi Azkaaraa',
      'freq_title': 'Yeroo Yaadachiisaa',
    },
  };

  String _tr(BuildContext context, String key) {
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    return _l10n[lang]?[key] ?? _l10n['ar']?[key] ?? _l10n['en']![key]!;
  }

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _headerCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
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

    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _appVersion = 'Version ${packageInfo.version} (Build ${packageInfo.buildNumber})';
    });
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
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showLanguageDialog(Color primaryColor, Color mainTextColor,
      Color cardColor, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            l10n.selectLanguage,
            style: TextStyle(
                color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: _languages.map((lang) {
              final isSelected = lang == _selectedLanguage;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
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
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? primaryColor.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        color: isSelected ? primaryColor : AppColors.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(lang,
                          style: TextStyle(
                              color: mainTextColor,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 14)),
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

  Future<void> _openPrivacyPolicy(BuildContext context, Color cardBg, Color textMain, Color textSub, Color primary) async {
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

  void _showPrivacyPolicyDialog(BuildContext context, Color cardBg, Color textMain, Color textSub, Color primary) {
    final isArabic = Localizations.maybeLocaleOf(context)?.languageCode == 'ar';

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
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
                        '• Google Play Services and AdMob may process non-personalized diagnostic and ad data.',
                  style: TextStyle(
                    color: textSub,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final Uri url = Uri.parse('http://quranzone.com.et/');
                await launchUrl(url, mode: LaunchMode.externalApplication);
              },
              child: Text(
                isArabic ? 'فتح الموقع' : 'Open Website',
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
        final Color textSub = textMain.withValues(alpha: 0.7);
        final Color cardBg = AppTheme.getCardBgColor(theme);
        final Color borderColor = AppTheme.getBorderColor(theme);
        final bool isDark = theme == QuranTheme.dark;
        final bool isCream = theme == QuranTheme.cream;

        final Color scaffoldBg = isDark
            ? const Color(0xFF080D10)
            : (isCream ? const Color(0xFFFBF8F0) : const Color(0xFFF2F5F0));

        final Color appBarBg = isDark
            ? const Color(0xFF0D1F17)
            : (isCream ? const Color(0xFFF4EEDC) : const Color(0xFF1B5E20));

        final Color appBarTextColor = (isCream) ? AppColors.emeraldDeep : Colors.white;

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Adaptive Elegant AppBar ─────────────────────────────────────
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: appBarBg,
                elevation: 0,
                centerTitle: true,
                title: FadeTransition(
                  opacity: _headerFade,
                  child: Text(
                    _tr(context, 'settings_title'),
                    style: TextStyle(
                      color: appBarTextColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                      fontFamily: isArabic ? 'Amiri' : null,
                    ),
                  ),
                ),
              ),

              // ── Body ────────────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 1. APPEARANCE & THEMES
                    _label(_tr(context, 'appearance'), primary),
                    _ThemePickerCard(
                      currentTheme: theme,
                      primary: primary,
                      cardBg: cardBg,
                      isDark: isDark,
                      isArabic: isArabic,
                      darkLabel: _tr(context, 'theme_dark'),
                      creamLabel: _tr(context, 'theme_cream'),
                      whiteLabel: _tr(context, 'theme_white'),
                    ),
                    const SizedBox(height: 6),

                    // 2. LANGUAGE SELECTOR
                    _label(_tr(context, 'language'), primary),
                    _PremiumCard(isDark: isDark, cardBg: cardBg, children: [
                      _LiquidTile(
                        icon: Icons.translate_rounded,
                        iconColor: const Color(0xFF00ACC1),
                        title: l10n.appLanguage,
                        subtitle: _selectedLanguage,
                        trailing: _ChipBadge(
                            label: _selectedLanguage, color: primary),
                        onTap: () => _showLanguageDialog(
                            primary, textMain, cardBg, l10n),
                        isDark: isDark,
                        textColor: textMain,
                      ),
                    ]),
                    const SizedBox(height: 6),

                    // 3. PRAYER TIMES & ATHAN (New Direct Settings Integration)
                    _label(_tr(context, 'prayer_section'), primary),
                    _PremiumCard(isDark: isDark, cardBg: cardBg, children: [
                      _LiquidTile(
                        icon: Icons.mosque_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: _tr(context, 'prayer_settings'),
                        subtitle: _tr(context, 'prayer_desc'),
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
                      ),
                    ]),
                    const SizedBox(height: 6),

                    // 4. NOTIFICATIONS & REMINDERS
                    _label(_tr(context, 'notifications'), primary),
                    _PremiumCard(isDark: isDark, cardBg: cardBg, children: [
                      _SwitchTile(
                        icon: Icons.notifications_active_rounded,
                        iconColor: const Color(0xFFE91E63),
                        title: _tr(context, 'daily_notif'),
                        subtitle: _tr(context, 'daily_notif_desc'),
                        value: _notificationsEnabled,
                        activeColor: primary,
                        onChanged: _toggleNotifications,
                        isDark: isDark,
                        textColor: textMain,
                      ),
                      AnimatedSize(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        child: _notificationsEnabled
                            ? _IntervalPicker(
                                value: _notificationInterval,
                                primary: primary,
                                textColor: textMain,
                                title: _tr(context, 'freq_title'),
                                onChanged: _setNotificationInterval,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ]),
                    const SizedBox(height: 6),

                    // 5. STORAGE & OFFLINE DOWNLOADS
                    _label(_tr(context, 'storage_section'), primary),
                    _PremiumCard(isDark: isDark, cardBg: cardBg, children: [
                      _LiquidTile(
                        icon: Icons.download_for_offline_rounded,
                        iconColor: const Color(0xFF0D9488),
                        title: _tr(context, 'downloads'),
                        subtitle: _tr(context, 'downloads_desc'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MinbarDownloadsScreen()),
                          );
                        },
                        isDark: isDark,
                        textColor: textMain,
                      ),
                    ]),
                    const SizedBox(height: 6),

                    // 6. SHARE, PRIVACY & INFO
                    _label(_tr(context, 'share_info'), primary),
                    _PremiumCard(isDark: isDark, cardBg: cardBg, children: [
                      _LiquidTile(
                        icon: Icons.ios_share_rounded,
                        iconColor: const Color(0xFF0288D1),
                        title: _tr(context, 'share_app'),
                        onTap: () {
                          Share.share(
                            'Download Quran Zone for a beautiful Quran & Islamic experience: https://play.google.com/store/apps/details?id=com.umer.quranzone',
                          );
                        },
                        isDark: isDark,
                        textColor: textMain,
                      ),
                      _LiquidDivider(borderColor),
                      _LiquidTile(
                        icon: Icons.star_rate_rounded,
                        iconColor: const Color(0xFFF9A825),
                        title: _tr(context, 'rate_us'),
                        onTap: () async {
                          final Uri url = Uri.parse(
                              'https://play.google.com/store/apps/details?id=com.umer.quranzone');
                          if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                            debugPrint('Could not launch');
                          }
                        },
                        isDark: isDark,
                        textColor: textMain,
                      ),
                      _LiquidDivider(borderColor),
                      _LiquidTile(
                        icon: Icons.support_agent_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: _tr(context, 'contact_us'),
                        subtitle: '@UMER_jr • umer.et.jm@gmail.com',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: cardBg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              contentPadding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                              content: _DeveloperCard(
                                primary: primary,
                                isDark: isDark,
                                onChat: () async {
                                  final Uri url = Uri.parse('https://t.me/UMER_jr');
                                  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                                    debugPrint('Could not launch Telegram');
                                  }
                                },
                                onEmail: () async {
                                  final Uri emailUri = Uri(
                                    scheme: 'mailto',
                                    path: 'umer.et.jm@gmail.com',
                                    query: 'subject=Quran Zone App Feedback',
                                  );
                                  if (!await launchUrl(emailUri)) {
                                    debugPrint('Could not launch email');
                                  }
                                },
                                onCopy: () {
                                  final nav = Navigator.of(context);
                                  Clipboard.setData(const ClipboardData(text: '@UMER_jr')).then((_) {
                                    if (!mounted) return;
                                    nav.pop();
                                    _showSnack(l10n.copiedToClipboard, primary);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                        isDark: isDark,
                        textColor: textMain,
                      ),
                      _LiquidDivider(borderColor),
                      _LiquidTile(
                        icon: Icons.security_rounded,
                        iconColor: const Color(0xFF3B82F6),
                        title: _tr(context, 'privacy_policy'),
                        subtitle: 'quranzone.com.et',
                        onTap: () => _openPrivacyPolicy(context, cardBg, textMain, textSub, primary),
                        isDark: isDark,
                        textColor: textMain,
                      ),
                      _LiquidDivider(borderColor),
                      _LiquidTile(
                        icon: Icons.system_update_rounded,
                        iconColor: const Color(0xFF06B6D4),
                        title: _tr(context, 'check_updates'),
                        subtitle: _tr(context, 'check_updates_desc'),
                        onTap: () => AppUpdateService.instance.checkForUpdate(context, isManual: true),
                        isDark: isDark,
                        textColor: textMain,
                      ),
                      _LiquidDivider(borderColor),
                      _LiquidTile(
                        icon: Icons.info_outline_rounded,
                        iconColor: const Color(0xFF10B981),
                        title: _tr(context, 'about_app'),
                        subtitle: _appVersion,
                        onTap: () => _openAboutQuranZoneDialog(context, isDark, cardBg, textMain, textSub, primary),
                        isDark: isDark,
                        textColor: textMain,
                      ),
                    ]),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Made with ❤️ for the Ummah by Umer',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.25)
                              : Colors.black.withValues(alpha: 0.25),
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

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
            ? const Color(0xFF0F1715)
            : (AppTheme.notifier.value == QuranTheme.cream
                ? const Color(0xFFFBF7EE)
                : Colors.white);
        final itemCardBg = isDark
            ? const Color(0xFF162420)
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
                : 'Authentic Madinah Mushaf (Uthmani script) with synced ayah & word highlights, 4 Tafsir books (Ibn Kathir, Muyassar, Baghawi, Saadi), word meanings & Quranic syntax (I\'rab).',
          },
          {
            'icon': Icons.podcasts_rounded,
            'color': const Color(0xFF6366F1),
            'title': isArabic ? 'المنبر والصوتيات والبث الحي' : 'Minbar Audios & 24/7 Live Media',
            'desc': isArabic
                ? 'مكتبة صوتية لأكثر من ١٠٠ قارئ، أكثر من ١٧٥ إذاعة إسلامية مباشرة على مدار الساعة، وبث حي عالي الدقة من المسجد الحرام بمكة والمسجد النبوي بالمدينة المنورة.'
                : '100+ Renowned Quran Reciters, 175+ Live Islamic radio stations 24/7, and HD direct live video streams from Makkah & Madinah.',
          },
          {
            'icon': Icons.access_time_filled_rounded,
            'color': const Color(0xFFF59E0B),
            'title': isArabic ? 'مواقيت الصلاة، الأذان والقبلة 3D' : 'Prayer Times, Athan & 3D Qibla',
            'desc': isArabic
                ? 'حسابات فلكية بالغة الدقة لمواقيت الصلاة عالمياً، تنبيهات الأذان بأصوات كبار المؤذنين، بوصلة القبلة التفاعلية ثلاثية الأبعاد، واستكشاف المساجد القريبة.'
                : 'Precision astronomical prayer schedules, background Athan notifications with various Muezzin voices, 3D compass Qibla finder, and nearby Mosque locator.',
          },
          {
            'icon': Icons.library_books_rounded,
            'color': const Color(0xFF0D9488),
            'title': isArabic ? 'المكتبة الإسلامية وصحيح البخاري' : 'Islamic Library & Sahih Al-Bukhari',
            'desc': isArabic
                ? 'صحيح البخاري كاملاً بالأسانيد والأبواب، موسوعة قصص الأنبياء، السيرة النبوية العطرة، سير الصحابة والصحابيات، الفتاوى والأحكام، والرقية الشرعية الموثوقة.'
                : 'Complete Sahih Al-Bukhari with authentic hadith chains, Stories of the Prophets, Seerah of the Prophet ﷺ, Companions (Sahaba), Fiqh & Fatawa, and Authentic Ruqyah.',
          },
          {
            'icon': Icons.auto_stories_rounded,
            'color': const Color(0xFFEC4899),
            'title': isArabic ? 'حصن المسلم والأذكار التفاعلية' : 'Hisn Al-Muslim & Daily Remembrance',
            'desc': isArabic
                ? 'أذكار الصباح والمساء، أذكار بعد الصلاة والنوم والاستيقاظ، سبحة إلكترونية ذكية، تلاوات صوتية للأذكار، وفضائل كل ذكر من السنة النبوية.'
                : 'Comprehensive Morning & Evening Adhkar, Post-Salah Dua, interactive digital Tasbih counters, audio recitations, and the virtues of each Dhikr.',
          },
          {
            'icon': Icons.school_rounded,
            'color': const Color(0xFF0284C7),
            'title': isArabic ? 'القاعدة النورانية وتعلّم التلاوة' : 'Qaida Nooraniyah & Quran Phonetics',
            'desc': isArabic
                ? 'دروس القاعدة النورانية التفاعلية الكاملة لتعليم النطق العربي الفصيح، مخارج الحروف، أحكام التجويد، وإتقان تلاوة القرآن الكريم خطوة بخطوة بالرسم والتلوين المعتمد.'
                : 'Complete interactive Qaida Nooraniyah curriculum to master correct Arabic pronunciation, Tajweed rules, letter articulation points (Makharij), and Quran recitation with authentic color-coded lessons.',
          },
          {
            'icon': Icons.quiz_rounded,
            'color': const Color(0xFF8B5CF6),
            'title': isArabic ? 'المسابقات والاختبارات الإسلامية' : 'Interactive Islamic Knowledge Quiz',
            'desc': isArabic
                ? 'مسابقات تثقيفية ثرية وممتعة في القرآن الكريم، الحديث الشريف، السيرة النبوية، والتاريخ الإسلامي لتنمية حصيلتك المعرفية.'
                : 'Engaging interactive quizzes across Quran, Hadith, Seerah, and Islamic history to enrich and test your Islamic knowledge.',
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
                            // 1. Header Emblem & Title
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const LinearGradient(
                                        colors: [goldColor, emeraldColor],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: emeraldColor.withValues(alpha: 0.3),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: Image.asset(
                                        'assets/images/app_icon.png',
                                        width: 72,
                                        height: 72,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Quran Zone',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: textMain,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                                        decoration: BoxDecoration(
                                          color: primary.withValues(alpha: 0.14),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: primary.withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          _appVersion,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isArabic ? 'رفيقك الإيماني الشامل' : 'Your Comprehensive Islamic Companion',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textSub,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 2. Noble Quranic Verse Card
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [const Color(0xFF1B2A24), const Color(0xFF13201B)]
                                      : [const Color(0xFFEBF7F2), const Color(0xFFF4FAF7)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: emeraldColor.withValues(alpha: 0.25),
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
                                      color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857),
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isArabic
                                        ? 'سورة الذاريات: ٥٥'
                                        : '"And remind, for indeed, the reminder benefits the believers." — [Surah Adh-Dhariyat: 55]',
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
                            const SizedBox(height: 18),

                            // 3. Heartfelt Mission Description
                            Text(
                              isArabic ? 'رسالتنا وهدفنا' : 'Our Purpose & Vision',
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
                                fontSize: 13,
                                color: textSub,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 4. Feature Tickets (Grid/List of Cards)
                            Text(
                              isArabic ? 'أبرز ما يقدمه لك التطبيق' : 'Core Pillars & Features',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textMain,
                              ),
                            ),
                            const SizedBox(height: 10),

                            for (final ticket in featureTickets)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: itemCardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.05)
                                        : Colors.black.withValues(alpha: 0.05),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: (ticket['color'] as Color).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        ticket['icon'] as IconData,
                                        color: ticket['color'] as Color,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            ticket['title'] as String,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: textMain,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            ticket['desc'] as String,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: textSub,
                                              height: 1.45,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 8),

                            // 5. Sadaqah Jariyah & Ummah Dedication Card
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isDark
                                      ? [const Color(0xFF261D12), const Color(0xFF1B140B)]
                                      : [const Color(0xFFFFF9EE), const Color(0xFFFDF2DC)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: goldColor.withValues(alpha: 0.35),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: goldColor.withValues(alpha: 0.16),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.favorite_rounded, color: goldColor, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isArabic ? 'صدقة جارية للأمة الإسلامية' : 'Sadaqah Jariyah for the Ummah',
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isArabic
                                              ? 'هذا العمل خالص لوجه الله تعالى وبلا مقابل. نسأل الله أن يتقبله وينفع به المسلمين في مشارق الأرض ومغاربها، وأن يثقل به موازين حسنات كل من استخدمه وساهم في نشره.'
                                              : 'Built purely for the pleasure of Allah ﷻ without barrier. We pray Allah accepts it as a continuous charity, placing it on the scale of good deeds for all who benefit from it or share it with others.',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDark ? const Color(0xFFE5D5B8) : const Color(0xFF78350F),
                                            height: 1.45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),

                            // 6. Action Buttons: Share & Close
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Share.share(
                                    isArabic
                                        ? 'أنصحكم بتحميل تطبيق Quran Zone للقرآن الكريم ومواقيت الصلاة والأذكار والمكتبة الإسلامية:\nhttps://play.google.com/store/apps/details?id=com.umer.quranzone\nقال رسول الله ﷺ: "من دل على خير فله مثل أجر فاعله"'
                                        : 'Experience Quran Zone — A complete Islamic companion with the Holy Quran, Prayer Times, Adhkar, and Islamic Library:\nhttps://play.google.com/store/apps/details?id=com.umer.quranzone\n"Whoever guides someone to goodness will have a reward like one who did it." (Sahih Muslim)',
                                  );
                                },
                                icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
                                label: Text(
                                  isArabic ? 'انشر الخير وشارك التطبيق' : 'Share the Reward with Loved Ones',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: emeraldColor,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: isDark ? Colors.white24 : Colors.black12,
                                    width: 1,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  isArabic ? 'إغلاق' : 'Close',
                                  style: TextStyle(
                                    color: textMain,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
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

  Widget _label(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 4, bottom: 7, top: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color.withValues(alpha: 0.85),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _PremiumCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;
  final Color cardBg;

  const _PremiumCard({
    required this.children,
    required this.isDark,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _LiquidDivider extends StatelessWidget {
  final Color color;
  const _LiquidDivider(this.color);

  @override
  Widget build(BuildContext context) {
    return Divider(
        height: 1,
        thickness: 0.6,
        color: color.withValues(alpha: 0.12),
        indent: 52);
  }
}

class _LiquidTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool isDark;
  final Color textColor;

  const _LiquidTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
    required this.isDark,
    required this.textColor,
  });

  @override
  State<_LiquidTile> createState() => _LiquidTileState();
}

class _LiquidTileState extends State<_LiquidTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _press;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 80),
        lowerBound: 0.97,
        upperBound: 1.0,
        value: 1.0);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _press.reverse(),
      onTapUp: (_) {
        _press.forward();
        widget.onTap();
      },
      onTapCancel: () => _press.forward(),
      child: AnimatedBuilder(
        animation: _press,
        builder: (_, child) =>
            Transform.scale(scale: _press.value, child: child),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: widget.textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: TextStyle(
                          color: widget.isDark ? Colors.white38 : Colors.black45,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.trailing != null)
                widget.trailing!
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: widget.isDark ? Colors.white24 : Colors.black26,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;
  final bool isDark;
  final Color textColor;

  const _SwitchTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.activeColor,
    required this.onChanged,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    )),
                Text(subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black45,
                      fontSize: 11.5,
                    )),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: value,
              activeThumbColor: activeColor,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _IntervalPicker extends StatelessWidget {
  final int value;
  final Color primary;
  final Color textColor;
  final String title;
  final ValueChanged<int> onChanged;

  const _IntervalPicker({
    required this.value,
    required this.primary,
    required this.textColor,
    required this.title,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const intervals = [5, 15, 30, 60, 120];
    const labels = ['5m', '15m', '30m', '1h', '2h'];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
              height: 1,
              thickness: 0.6,
              color: primary.withValues(alpha: 0.15)),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
                color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: List.generate(intervals.length, (i) {
              final selected = intervals[i] == value;
              return GestureDetector(
                onTap: () => onChanged(intervals[i]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? primary : primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: selected ? Colors.white : primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

class _ThemePickerCard extends StatelessWidget {
  final QuranTheme currentTheme;
  final Color primary;
  final Color cardBg;
  final bool isDark;
  final bool isArabic;
  final String darkLabel;
  final String creamLabel;
  final String whiteLabel;

  const _ThemePickerCard({
    required this.currentTheme,
    required this.primary,
    required this.cardBg,
    required this.isDark,
    required this.isArabic,
    required this.darkLabel,
    required this.creamLabel,
    required this.whiteLabel,
  });

  @override
  Widget build(BuildContext context) {
    final themes = [
      (QuranTheme.dark, darkLabel, Icons.nights_stay_rounded),
      (QuranTheme.cream, creamLabel, Icons.wb_sunny_rounded),
      (QuranTheme.white, whiteLabel, Icons.light_mode_rounded),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Row(
        children: themes.map((t) {
          final selected = currentTheme == t.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => AppTheme.changeTheme(t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? primary
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.04)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: selected
                        ? primary
                        : (isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.08)),
                    width: 1.3,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t.$3,
                      size: 19,
                      color: selected
                          ? Colors.white
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      t.$2,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                        fontSize: 11,
                        fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                        fontFamily: isArabic ? 'Amiri' : null,
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

class _ChipBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ChipBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11.5, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _DeveloperCard extends StatelessWidget {
  final Color primary;
  final bool isDark;
  final VoidCallback onChat;
  final VoidCallback onEmail;
  final VoidCallback onCopy;

  const _DeveloperCard({
    required this.primary,
    required this.isDark,
    required this.onChat,
    required this.onEmail,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor = isDark ? Colors.white60 : Colors.black54;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [primary, primary.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.code_rounded, size: 32, color: Colors.white),
        ),
        const SizedBox(height: 14),
        Text(
          'Umer Muktar',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 3),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Lead Developer & Creator',
            style: TextStyle(
              color: primary,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Have suggestions, questions, or encountered an issue? Feel free to reach out directly anytime!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: subColor,
            fontSize: 12.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: onChat,
            icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
            label: const Text(
              'Chat on Telegram (@UMER_jr)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0088CC),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton.icon(
            onPressed: onEmail,
            icon: const Icon(Icons.email_outlined, size: 18, color: Colors.white),
            label: const Text(
              'Send Email (umer.et.jm@gmail.com)',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primary,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: onCopy,
          icon: Icon(Icons.copy_rounded, size: 14, color: primary),
          label: Text(
            'Copy Telegram Handle',
            style: TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}
