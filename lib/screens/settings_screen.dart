import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../l10n/app_localizations.dart';
import '../theme_notifier.dart';
import '../language_notifier.dart';
import '../services/notification_service.dart';
import '../core/services/background_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SETTINGS SCREEN — Premium Liquid Redesign
// ─────────────────────────────────────────────────────────────────────────────

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with TickerProviderStateMixin {
  String _selectedLanguage = 'English';
  bool _notificationsEnabled = true;
  int _notificationInterval = 60;

  late final AnimationController _headerCtrl;
  late final Animation<double> _headerFade;

  final List<String> _languages = ['Amharic', 'Oromo', 'English', 'Arabic'];

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
                        color: isSelected ? primaryColor : Colors.grey,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final Color primary = AppTheme.getPrimaryColor(theme);
        final Color textMain = AppTheme.getMainTextColor(theme);
        final Color textSub = textMain.withValues(alpha: 0.7);
        final Color cardBg = AppTheme.getCardBgColor(theme);
        final Color borderColor = AppTheme.getBorderColor(theme);
        final bool isDark = theme == QuranTheme.dark;
        final Color scaffoldBg =
            isDark ? const Color(0xFF080D10) : const Color(0xFFF2F5F0);

        return Scaffold(
          backgroundColor: scaffoldBg,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── Gradient SliverAppBar ──────────────────────────────────────
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor:
                    isDark ? const Color(0xFF0D1F17) : const Color(0xFF1B5E20),
                elevation: 0,
                flexibleSpace: LayoutBuilder(
                  builder: (context, constraints) {
                    final top = constraints.biggest.height;
                    final statusBarHeight = MediaQuery.of(context).padding.top;
                    final collapsedThreshold =
                        kToolbarHeight + statusBarHeight + 15;
                    final isCollapsed = top <= collapsedThreshold;

                    return FlexibleSpaceBar(
                      collapseMode: CollapseMode.parallax,
                      centerTitle: true,
                      expandedTitleScale: 1.0,
                      titlePadding: const EdgeInsets.only(bottom: 14),
                      title: AnimatedOpacity(
                        duration: const Duration(milliseconds: 150),
                        opacity: isCollapsed ? 1.0 : 0.0,
                        child: Text(
                          l10n.settings,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: isDark
                                    ? [
                                        const Color(0xFF0D2E1F),
                                        const Color(0xFF0F1F17),
                                      ]
                                    : [
                                        const Color(0xFF1B6B38),
                                        const Color(0xFF0D4F3C),
                                      ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: -30,
                            top: -30,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.04),
                              ),
                            ),
                          ),
                          Positioned(
                            left: -20,
                            bottom: -40,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.03),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 16,
                            left: 20,
                            right: 20,
                            child: FadeTransition(
                              opacity: _headerFade,
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.tune_rounded,
                                        color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        l10n.settings,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                      Text(
                                        'Quran Zone',
                                        style: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.6),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Body ────────────────────────────────────────────────────────
              SliverPadding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _label('APPEARANCE', primary),
                    _ThemePickerCard(
                      currentTheme: theme,
                      primary: primary,
                      cardBg: cardBg,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 6),
                    _label('LANGUAGE', primary),
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
                    _label('NOTIFICATIONS', primary),
                    _PremiumCard(isDark: isDark, cardBg: cardBg, children: [
                      _SwitchTile(
                        icon: Icons.notifications_active_rounded,
                        iconColor: const Color(0xFFE91E63),
                        title: l10n.dailyNotifications,
                        subtitle: l10n.dailyNotificationsDesc,
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
                                onChanged: _setNotificationInterval,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ]),
                    const SizedBox(height: 6),
                    _label('SHARE & INFO', primary),
                    _PremiumCard(isDark: isDark, cardBg: cardBg, children: [
                      _LiquidTile(
                        icon: Icons.ios_share_rounded,
                        iconColor: const Color(0xFF0288D1),
                        title: l10n.shareApp,
                        onTap: () {
                          Share.share(
                            '${l10n.shareApp}\n\nDownload Quran Zone for a beautiful Quran experience: https://play.google.com/store/apps/details?id=com.umer.quranzone',
                          );
                        },
                        isDark: isDark,
                        textColor: textMain,
                      ),
                      _LiquidDivider(borderColor),
                      _LiquidTile(
                        icon: Icons.star_rate_rounded,
                        iconColor: const Color(0xFFF9A825),
                        title: l10n.rateUs,
                        onTap: () async {
                          final Uri url = Uri.parse(
                              'https://play.google.com/store/apps/details?id=com.umer.quranzone');
                          if (!await launchUrl(url,
                              mode: LaunchMode.externalApplication)) {
                            debugPrint('Could not launch');
                          }
                        },
                        isDark: isDark,
                        textColor: textMain,
                      ),
                      _LiquidDivider(borderColor),
                      _LiquidTile(
                        icon: Icons.mail_outline_rounded,
                        iconColor: const Color(0xFF00897B),
                        title: l10n.contactUs,
                        onTap: () async {
                          final Uri emailUri = Uri(
                            scheme: 'mailto',
                            path: 'umer.et.jm@gmail.com',
                            query: 'subject=Quran Zone App Feedback',
                          );
                          if (!await launchUrl(emailUri)) {
                            debugPrint('Could not launch email');
                          }
                        },
                        isDark: isDark,
                        textColor: textMain,
                      ),
                      _LiquidDivider(borderColor),
                      _LiquidTile(
                        icon: Icons.info_outline_rounded,
                        iconColor: Colors.grey,
                        title: l10n.aboutApp,
                        subtitle: 'Version 1.0.0',
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              String getTranslatedAboutDescription(BuildContext ctx) {
                                final locale = Localizations.localeOf(ctx).languageCode;
                                switch (locale) {
                                  case 'ar':
                                    return 'تطبيق Quran Zone هو تطبيق إسلامي شامل يضم القرآن الكريم، مواقيت الصلاة الدقيقة مع تنبيهات الأذان في الخلفية، العثور على المساجد القريبة، اتجاه القبلة، والمزيد. صُنع بحب لمساعدة المسلمين على التواصل مع دينهم بسهولة.';
                                  case 'am':
                                    return 'ቁርኣን ዞን (Quran Zone) ቅዱስ ቁርኣንን፣ ትክክለኛ የሶላት ጊዜያትን ከ አዛን ማሳሰቢያዎች ጋር፣ በአቅራቢያ የሚገኙ መስጊዶችን መፈለጊያ፣ የቂብላ አቅጣጫ እና ሌሎችንም ያካተተ የተሟላ ኢስላማዊ መተግበሪያ ነው። ሙስሊሞች ከእምነታቸው ጋር በቀላሉ እንዲገናኙ ለመርዳት በፍቅር የተሰራ።';
                                  case 'om':
                                    return 'Quran Zone appilikeeshinii Islaamaa guutuu yoo ta\'u, Qur\'aana Qulqulluu, yeroo salaataa sirrii ta\'e akeekkachiisa Azaanii wajjin, masjiidota dhihoo jiran barbaaduu, kallattii Qiblaa fi kanneen biroo of keessatti qabata. Muslimoonni amantii isaanii wajjin haala salphaa ta\'een akka wal qunnaman gargaaruuf jaalalaan kan hojjetame.';
                                  default:
                                    return 'Quran Zone is a comprehensive Islamic app featuring the Holy Quran, accurate prayer times with Athan (Muezzin) background alerts, finding nearby mosques, Qibla direction, and much more. Built with love to help Muslims easily connect with their faith.';
                                }
                              }

                              return AlertDialog(
                              backgroundColor: cardBg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Row(
                                children: [
                                  Image.asset(
                                    'assets/images/app_icon.png',
                                    width: 40,
                                    height: 40,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Quran Zone',
                                    style: TextStyle(
                                      color: textMain,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    getTranslatedAboutDescription(context),
                                    style: TextStyle(
                                      color: textSub,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Version 1.0.0',
                                    style: TextStyle(
                                      color: textMain,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(
                                    'Close',
                                    style: TextStyle(color: primary),
                                  ),
                                ),
                              ],
                            );
                            },
                          );
                        },
                        isDark: isDark,
                        textColor: textMain,
                      ),
                    ]),
                    const SizedBox(height: 12),
                    _DeveloperCard(
                      primary: primary,
                      isDark: isDark,
                      onChat: () async {
                        final Uri url = Uri.parse('https://t.me/UMER_jr');
                        if (!await launchUrl(url,
                            mode: LaunchMode.externalApplication)) {
                          debugPrint('Could not launch Telegram');
                        }
                      },
                      onCopy: () {
                        Clipboard.setData(const ClipboardData(text: '@UMER_jr'))
                            .then((_) {
                          if (!mounted) return;
                          _showSnack(l10n.copiedToClipboard, primary);
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'Made with ❤️ for the Ummah',   // Hardcoded EN — never translated
                        style: TextStyle(
                          color: Colors.grey.withValues(alpha: 0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),  // breathing room above bottom nav
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

  Widget _label(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 7, top: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color.withValues(alpha: 0.8),
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LOCALIZATION HELPERS
// ─────────────────────────────────────────────────────────────────────────────


String _getIntervalTitle(String locale) {
  switch (locale) {
    case 'en':
      return 'Reminder Frequency';
    case 'am':
      return 'የማስታወሻ ድግግሞሽ';
    case 'om':
      return 'Yeroo Yaadachiisaa';
    default:
      return 'تكرار التذكير';
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
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 17),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(widget.title,
                        style: TextStyle(
                          color: widget.textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        )),
                    if (widget.subtitle != null)
                      Text(widget.subtitle!,
                          style: TextStyle(
                            color:
                                widget.isDark ? Colors.white38 : Colors.black45,
                            fontSize: 11,
                          )),
                  ],
                ),
              ),
              widget.trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: widget.isDark ? Colors.white24 : Colors.black26,
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    )),
                Text(subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black45,
                      fontSize: 11,
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
    ));
  }
}

class _IntervalPicker extends StatelessWidget {
  final int value;
  final Color primary;
  final Color textColor;
  final ValueChanged<int> onChanged;

  const _IntervalPicker({
    required this.value,
    required this.primary,
    required this.textColor,
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
          const SizedBox(height: 10),
          Text(
              _getIntervalTitle(
                  Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar'),
              style: TextStyle(
                  color: textColor, fontSize: 12, fontWeight: FontWeight.w600)),
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

  const _ThemePickerCard({
    required this.currentTheme,
    required this.primary,
    required this.cardBg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final themes = [
      (QuranTheme.dark, 'Dark', Icons.nights_stay_rounded),
      (QuranTheme.cream, 'Cream', Icons.wb_sunny_rounded),
      (QuranTheme.white, 'Light', Icons.light_mode_rounded),
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
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: themes.map((t) {
          final selected = currentTheme == t.$1;
          return Expanded(
            child: GestureDetector(
              onTap: () => AppTheme.changeTheme(t.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 4),
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
                            : Colors.black.withValues(alpha: 0.1)),
                    width: 1.5,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t.$3,
                      size: 18,
                      color: selected
                          ? Colors.white
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      t.$2,
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : (isDark ? Colors.white60 : Colors.black54),
                        fontSize: 11,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.w500,
                      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _DeveloperCard extends StatelessWidget {
  final Color primary;
  final bool isDark;
  final VoidCallback onChat;
  final VoidCallback onCopy;

  const _DeveloperCard({
    required this.primary,
    required this.isDark,
    required this.onChat,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  primary.withValues(alpha: 0.18),
                  primary.withValues(alpha: 0.06),
                ]
              : [
                  primary.withValues(alpha: 0.12),
                  primary.withValues(alpha: 0.03),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: primary.withValues(alpha: isDark ? 0.3 : 0.2)),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primary, primary.withValues(alpha: 0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: primary.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: const Icon(Icons.code_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.contactDeveloper,
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    l10n.contactDeveloperDesc,
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black45,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: primary, size: 11),
                    const SizedBox(width: 3),
                    Text('Dev',
                        style: TextStyle(
                            color: primary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.contactDeveloperText,
            style: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
              fontSize: 11,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onChat,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: primary.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.telegram,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              l10n.chatOnTelegram,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: onCopy,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: primary.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copy_rounded, color: primary, size: 15),
                        const SizedBox(width: 5),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              l10n.copyUsername,
                              style: TextStyle(
                                  color: primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
