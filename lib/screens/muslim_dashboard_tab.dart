import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/database/database_helper.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../theme_notifier.dart';
import 'quran_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../features/prayer_times/presentation/screens/prayer_times_screen.dart';
import '../features/prayer_times/presentation/controllers/prayer_controller.dart';
import '../features/calendar/presentation/screens/hijri_calendar_screen.dart';
import '../features/qibla/presentation/screens/qibla_screen.dart';
import 'azkar_screen.dart';
import 'tasbih_screen.dart';
import '../core/utils/map_launcher.dart';
import 'qaida_nooraniyah_screen.dart';
import '../widgets/liquid_pressable.dart';
import '../widgets/custom_banner_ad.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MuslimDashboardTab — Tab 1
// ─────────────────────────────────────────────────────────────────────────────
// Layout uses Column + Expanded so everything fits on one screen — no scroll.
// ─────────────────────────────────────────────────────────────────────────────

class MuslimDashboardTab extends StatefulWidget {
  const MuslimDashboardTab({super.key});

  @override
  State<MuslimDashboardTab> createState() => _MuslimDashboardTabState();
}

bool _globalHasAnimatedDashboard = false;

class _MuslimDashboardTabState extends State<MuslimDashboardTab>
    with SingleTickerProviderStateMixin {
  static const _localizedTitle = {
    'en': 'Quran Zone',
    'ar': 'Quran Zone',
    'am': 'Quran Zone',
    'om': 'Quran Zone',
  };

  static const _sectionTitle = {
    'en': 'Islamic Tools',
    'ar': 'أدوات إسلامية',
    'am': 'ኢስላማዊ መሣሪያዎች',
    'om': 'Meeshaalee Islaamaa',
  };

  static const _taglineMap = {
    'en': 'Your daily companion for Quran & Worship',
    'ar': 'رفيقك اليومي للقرآن الكريم والعبادة',
    'am': 'ለቁርአንና ለዒባዳ ዕለታዊ ጓደኛዎ',
    'om': 'Hiriyaa kee guyyaa guyyaa Quraanaaf',
  };

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);

    if (!_globalHasAnimatedDashboard) {
      _pulseCtrl.forward();
      Future.delayed(const Duration(milliseconds: 2000), () {
        _globalHasAnimatedDashboard = true;
      });
    } else {
      _pulseCtrl.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final title = _localizedTitle[locale] ?? _localizedTitle['ar']!;
    final secTitle = _sectionTitle[locale] ?? _sectionTitle['ar']!;
    final tagline = _taglineMap[locale] ?? _taglineMap['ar']!;

    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final isDark = theme == QuranTheme.dark;
        final isCream = theme == QuranTheme.cream;

        final Color bg = isDark
            ? const Color(0xFF09110D)
            : (isCream ? const Color(0xFFFBF8F0) : const Color(0xFFF7F8F9));
        final Color headerTextColor = isDark
            ? AppColors.textPrimary
            : (isCream ? const Color(0xFF2C1E07) : AppColors.emeraldDeep);
        final Color headerSubtextColor = isDark
            ? Colors.white60
            : (isCream ? const Color(0xFF8B6B38) : const Color(0xFF4B6358));
        final Color secTitleColor = isDark
            ? Colors.white
            : (isCream ? const Color(0xFF3D2A08) : const Color(0xFF032616));

        return Scaffold(
          backgroundColor: bg,
          body: SafeArea(
            child: ValueListenableBuilder<bool>(
              valueListenable: kAdVisibleNotifier,
              builder: (context, isAdVisible, _) {
                // Clean dynamic layout spacing
                const double space8 = 8;
                const double space10 = 10;
                const double space6 = 6;
                const double space12 = 12;
                final double gridRatio = isAdVisible
                    ? 1.34
                    : 1.27; // Increased ratio to shrink height
                const double paddingBottom =
                    40; // Extra padding at the bottom to leave room for ad pushed content

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Header with Brand Icon & Tagline ──────────────────
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark
                                            ? const Color(0xFFD4AF37)
                                            : const Color(0xFF0D5D44))
                                        .withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/app_icon.png',
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
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
                                    title,
                                    style:
                                        AppTextStyles.headlineMedium.copyWith(
                                      color: headerTextColor,
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 1),
                                  Text(
                                    tagline,
                                    style: TextStyle(
                                      color: headerSubtextColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      fontFamily:
                                          locale == 'ar' ? 'Amiri' : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── 1. Miqat / Prayer Times Card ───────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _MiqatCard(isAdVisible: isAdVisible),
                      ),
                      const SizedBox(height: space8),

                      // ── 2. Quran Gateway Card ───────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: _ResumeReadingCard(isAdVisible: isAdVisible),
                      ),
                      const SizedBox(height: space10),

                      // ── Section Title ───────────────────────────────────────
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          secTitle,
                          style: AppTextStyles.headlineMedium.copyWith(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: secTitleColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: space6),

                      // ── 3. Tools Grid — Fills list scroll view ─────────────
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets.fromLTRB(12, 0, 12, paddingBottom),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: space12,
                          crossAxisSpacing: space12,
                          childAspectRatio: gridRatio,
                        ),
                        itemCount: _tools.length,
                        itemBuilder: (context, index) {
                          return _ToolGridCell(
                            item: _tools[index],
                            pulseAnim: _pulseAnim,
                            phaseOffset: index * 0.15,
                            entranceDelay: Duration(milliseconds: index * 80),
                            isAdVisible: isAdVisible,
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 1. MIQAT CARD — Compact Prayer Times Grid
// ═════════════════════════════════════════════════════════════════════════════

class _MiqatCard extends StatelessWidget {
  final bool isAdVisible;
  const _MiqatCard({required this.isAdVisible});

  static const _prayerNames = {
    'en': {
      'fajr': 'Fajr',
      'sunrise': 'Sunrise',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha'
    },
    'ar': {
      'fajr': 'الفجر',
      'sunrise': 'الشروق',
      'dhuhr': 'الظهر',
      'asr': 'العصر',
      'maghrib': 'المغرب',
      'isha': 'العشاء'
    },
    'am': {
      'fajr': 'ፈጅር',
      'sunrise': 'ሸምስ',
      'dhuhr': 'ዙሁር',
      'asr': 'ዓሥር',
      'maghrib': 'ማግሪብ',
      'isha': 'ዒሻ'
    },
    'om': {
      'fajr': 'Fajrii',
      'sunrise': 'B. Aduu',
      'dhuhr': 'Zuhr',
      'asr': 'Asar',
      'maghrib': 'Magrib',
      'isha': 'Ishaa'
    },
  };

  static const _qiblaLabels = {
    'en': 'Qibla',
    'ar': 'القبلة',
    'am': 'ቂብላ',
    'om': 'Qiblaa',
  };

  @override
  Widget build(BuildContext context) {
    final ctrl = PrayerController();
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';

    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        final model = ctrl.model;
        if (ctrl.isLocationMissing && !ctrl.isLoading) {
          return LiquidPressable(
            onTap: () => ctrl.syncLocation(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0D4F3C), Color(0xFF1A7A5E)],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D4F3C).withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          locale == 'ar' ? 'مواقيت الصلاة' : 'Prayer Times',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          locale == 'ar'
                              ? 'اضغط هنا لتحديد موقعك وعرض أوقات الصلاة'
                              : 'Tap here to enable location & see prayer times',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
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
        }

        if (model == null || ctrl.isLoading) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 40),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0D4F3C), Color(0xFF1A7A5E)],
              ),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          );
        }

        final hijriStr = locale == 'ar'
            ? model.hijriDate.formattedAr
            : model.hijriDate.formattedEn;
        final gregStr = DateFormat('d MMM yyyy').format(model.date);
        final nextPrayerEntry = model.nextPrayer;
        final nameMap = _prayerNames[locale] ?? _prayerNames['en']!;
        final nextPrayerName =
            nameMap[nextPrayerEntry.prayer.name] ?? nextPrayerEntry.prayer.name;
        final nextPrayerTime = DateFormat('HH:mm').format(nextPrayerEntry.time);

        return LiquidPressable(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PrayerTimesScreen(controller: ctrl),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: model.miqatGradientColors,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color:
                      model.miqatGradientColors.first.withValues(alpha: 0.45),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Date + Location ──────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Text(hijriStr,
                            style: AppTextStyles.arabicSmall.copyWith(
                                color: AppColors.goldLight, fontSize: 12)),
                        const SizedBox(width: 8),
                        const Text('·',
                            style:
                                TextStyle(color: Colors.white38, fontSize: 12)),
                        const SizedBox(width: 8),
                        Text(gregStr,
                            style: const TextStyle(
                                color: Colors.white60, fontSize: 11)),
                        const SizedBox(width: 16),
                        const Icon(Icons.location_on_outlined,
                            size: 12, color: Colors.white54),
                        const SizedBox(width: 4),
                        Text(
                          model.locationLabel,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Next Prayer & Countdown ──────────────────────────────────
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    locale == 'ar'
                                        ? 'الصلاة القادمة'
                                        : 'Next Prayer',
                                    style: const TextStyle(
                                        color: Colors.white60, fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        nextPrayerName,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        nextPrayerTime,
                                        style: const TextStyle(
                                            color: AppColors.goldLight,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              ValueListenableBuilder<String>(
                                valueListenable: ctrl.countdownNotifier,
                                builder: (context, countdown, _) {
                                  return Text(
                                    '-$countdown',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      fontFeatures: [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const QiblaScreen(),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.explore_outlined,
                                    color: AppColors.goldLight, size: 24),
                                const SizedBox(height: 4),
                                Text(
                                  _qiblaLabels[locale] ?? _qiblaLabels['ar']!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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
        );
      },
    );
  }
}

class _ResumeReadingCard extends StatefulWidget {
  final bool isAdVisible;
  const _ResumeReadingCard({required this.isAdVisible});

  @override
  State<_ResumeReadingCard> createState() => _ResumeReadingCardState();
}

class _ResumeReadingCardState extends State<_ResumeReadingCard>
    with SingleTickerProviderStateMixin {
  int _lastPage = 1;
  double _progressPct = 0.0016;
  String _ayahNameAr = 'سورة الفاتحة';
  String _ayahNameEn = 'Al-Fatihah 1:1';

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _loadLastReadPosition();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLastReadPosition() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastPage = prefs.getInt('last_quran_page') ?? 1;

      String foundAr = 'سورة الفاتحة';
      String foundEn = 'Al-Fatihah 1:1';

      final db = await DatabaseHelper.instance.database;
      final List<Map<String, dynamic>> results = await db.rawQuery(
        'SELECT sura, sura_num, aya_num FROM quran WHERE page_aya = ? ORDER BY id_quran_ayat LIMIT 1',
        [lastPage],
      );

      if (results.isNotEmpty) {
        final row = results.first;
        final String surahArabic = row['sura'] as String;
        final int surahNum = row['sura_num'] as int;
        final int ayahNum = row['aya_num'] as int;
        final String translit =
            DatabaseHelper.surahTransliterations[surahNum - 1];

        foundAr = 'سورة $surahArabic';
        foundEn = '$translit $ayahNum';
      }

      if (mounted) {
        setState(() {
          _lastPage = lastPage;
          _progressPct = lastPage / 604.0;
          _ayahNameAr = foundAr;
          _ayahNameEn = foundEn;
        });
      }
    } catch (e, stack) {
      debugPrint('Error loading last read position from DB: $e\n$stack');
    }
  }

  void _navigateToQuran(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuranScreen(initialPage: _lastPage),
      ),
    ).then((_) => _loadLastReadPosition());
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final pctStr = (_progressPct * 100).toStringAsFixed(0);

    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final isDark = theme == QuranTheme.dark;
        final isCream = theme == QuranTheme.cream;

        // Theme-tailored Color Palettes
        final Color cardBg1 = isDark
            ? const Color(0xFF071120)
            : (isCream ? const Color(0xFFFFFDF8) : Colors.white);
        final Color cardBg2 = isDark
            ? const Color(0xFF032616)
            : (isCream ? const Color(0xFFF5EEDB) : const Color(0xFFF0F7F3));
        final Color cardBorder = isDark
            ? const Color(0xFFD4AF37).withValues(alpha: 0.35)
            : (isCream
                ? const Color(0xFFD4AF37).withValues(alpha: 0.32)
                : const Color(0xFF0D5D44).withValues(alpha: 0.20));
        final Color titleColor = isDark
            ? Colors.white
            : (isCream ? const Color(0xFF2C1E07) : const Color(0xFF032616));
        final Color goldAccent = isDark
            ? const Color(0xFFFFD700)
            : (isCream ? const Color(0xFFB8860B) : const Color(0xFF0D5D44));
        final Color progressTrack = isDark
            ? Colors.white.withValues(alpha: 0.12)
            : (isCream
                ? const Color(0xFFD4AF37).withValues(alpha: 0.16)
                : const Color(0xFF0D5D44).withValues(alpha: 0.10));
        final Color ayahColor = isDark
            ? const Color(0xFFFFD700).withValues(alpha: 0.90)
            : (isCream ? const Color(0xFF8B5E14) : const Color(0xFF0D5D44));
        final Color progressTextColor = isDark
            ? Colors.white70
            : (isCream ? const Color(0xFF6E5630) : const Color(0xFF4A6B5D));

        final String title, action, progress, ayah;
        if (locale == 'ar') {
          title = 'القرآن الكريم';
          action = 'استمر في القراءة ←';
          progress = 'صفحة $_lastPage · $pctStr٪';
          ayah = _ayahNameAr;
        } else if (locale == 'am') {
          title = 'ቅዱስ ቁርአን';
          action = 'ማንበብ ይቀጥሉ →';
          progress = 'ገጽ $_lastPage · $pctStr%';
          ayah = _ayahNameEn;
        } else if (locale == 'om') {
          title = 'Quraana Qulqulluu';
          action = 'Dubbisuu Itti Fufi →';
          progress = 'Fuula $_lastPage · $pctStr%';
          ayah = _ayahNameEn;
        } else {
          title = 'The Holy Quran';
          action = 'Resume Reading →';
          progress = 'Page $_lastPage · $pctStr%';
          ayah = _ayahNameEn;
        }

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.85, end: 1.0),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          builder: (context, scaleVal, child) {
            return Transform.scale(
              scale: scaleVal,
              child: child,
            );
          },
          child: LiquidPressable(
            onTap: () => _navigateToQuran(context),
            scaleFactor: 0.96,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                final t = _pulseAnim.value;
                final scale = 1.0 + 0.012 * t;
                final double shadowSpread = 1.0 + 1.5 * t;
                final double glowOpacity =
                    isDark ? (0.12 + 0.12 * t) : (0.04 + 0.08 * t);

                return Transform.scale(
                  scale: scale,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [cardBg1, cardBg2],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: cardBorder,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: (isDark
                                  ? const Color(0xFFD4AF37)
                                  : const Color(0xFFB8860B))
                              .withValues(alpha: glowOpacity),
                          blurRadius: 18,
                          spreadRadius: shadowSpread,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        children: [
                          // --- Subtle Islamic Geometric Background Pattern ---
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _IslamicPatternPainter(
                                color: (isDark
                                        ? const Color(0xFFFFD700)
                                        : const Color(0xFFB8860B))
                                    .withValues(alpha: 0.04),
                              ),
                            ),
                          ),
                          // --- Soft Glowing Lighting Effect ---
                          Positioned(
                            top: -25,
                            right: locale == 'ar' ? null : -20,
                            left: locale == 'ar' ? -20 : null,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    (isDark
                                            ? const Color(0xFFFFD700)
                                            : Colors.white)
                                        .withValues(alpha: 0.18 + (0.08 * t)),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // --- Main Content ---
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  // Layered Quran Iconography
                                  SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: goldAccent.withValues(
                                                  alpha: 0.25 * t),
                                              width: 1,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: isDark
                                                  ? [
                                                      const Color(0xFFD4AF37)
                                                          .withValues(
                                                              alpha: 0.22),
                                                      const Color(0xFFFFD700)
                                                          .withValues(
                                                              alpha: 0.06),
                                                    ]
                                                  : (isCream
                                                      ? [
                                                          Colors.white,
                                                          const Color(
                                                              0xFFF8F1E2)
                                                        ]
                                                      : [
                                                          Colors.white,
                                                          const Color(
                                                              0xFFEBF6F1)
                                                        ]),
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            border: Border.all(
                                              color: goldAccent.withValues(
                                                  alpha: 0.45),
                                              width: 1.4,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: goldAccent.withValues(
                                                    alpha: 0.2),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.auto_stories_rounded,
                                            color: goldAccent,
                                            size: 22,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Text & Progress Content
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                title,
                                                style: TextStyle(
                                                  color: titleColor,
                                                  fontSize: 15.5,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 0.3,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            // Action Link
                                            Text(
                                              action,
                                              style: TextStyle(
                                                color: goldAccent,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        // ── Upgraded Luxurious Progress Bar (Height: 4px) ──
                                        Stack(
                                          alignment: locale == 'ar'
                                              ? Alignment.centerRight
                                              : Alignment.centerLeft,
                                          children: [
                                            Container(
                                              height: 4,
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: progressTrack,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                            FractionallySizedBox(
                                              widthFactor:
                                                  _progressPct.clamp(0.01, 1.0),
                                              child: Container(
                                                height: 4,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: isDark
                                                        ? [
                                                            const Color(
                                                                0xFFFFD700),
                                                            const Color(
                                                                0xFF00E676),
                                                          ]
                                                        : (isCream
                                                            ? [
                                                                const Color(
                                                                    0xFFD4AF37),
                                                                const Color(
                                                                    0xFF9E7D23),
                                                              ]
                                                            : [
                                                                const Color(
                                                                    0xFF0D5D44),
                                                                const Color(
                                                                    0xFF2E7D32),
                                                              ]),
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color:
                                                          goldAccent.withValues(
                                                              alpha: 0.4),
                                                      blurRadius: 4,
                                                      spreadRadius: 0.5,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        // Ayah and Progress Info
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                ayah,
                                                style: TextStyle(
                                                  color: ayahColor,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              progress,
                                              style: TextStyle(
                                                color: progressTextColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _IslamicPatternPainter extends CustomPainter {
  final Color color;

  _IslamicPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double step = 40.0;
    for (double x = -step; x < size.width + step; x += step) {
      for (double y = -step; y < size.height + step; y += step) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(0.785398); // 45 degrees
        canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: 22, height: 22), paint);
        canvas.rotate(-0.785398);
        canvas.drawRect(
            Rect.fromCenter(center: Offset.zero, width: 22, height: 22), paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _IslamicPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 3. ISLAMIC TOOLS GRID — 8 tools, fills remaining screen, no scroll
// ═════════════════════════════════════════════════════════════════════════════

class _ToolItem {
  const _ToolItem({
    required this.key,
    required this.svgIconName,
    required this.color,
    required this.labels,
  });

  final String key;
  final String svgIconName;
  final Color color;
  final Map<String, String> labels;
}

const _tools = <_ToolItem>[
  // Row 1
  _ToolItem(
    key: 'moazin',
    svgIconName: 'prayer_times',
    color: Color(0xFF00897B),
    labels: {
      'en': 'Moazin',
      'ar': 'مواقيت الصلاة',
      'am': 'ሙአዚን',
      'om': 'Yeroo Salaataa',
    },
  ),
  _ToolItem(
    key: 'azkar',
    svgIconName: 'quran',
    color: Color(0xFFE65100),
    labels: {
      'en': 'Azkar',
      'ar': 'الأذكار',
      'am': 'አዝካር',
      'om': 'Azkaara',
    },
  ),
  // Row 2
  _ToolItem(
    key: 'tasbih',
    svgIconName: 'tasbih',
    color: Color(0xFF558B2F),
    labels: {
      'en': 'Tasbih',
      'ar': 'التسبيح',
      'am': 'ተስቢህ',
      'om': 'Tasbiiha',
    },
  ),

  // Row 3
  _ToolItem(
    key: 'qaida_noorania',
    svgIconName: 'qaida_noorania',
    color: Color(0xFFF9A825),
    labels: {
      'en': 'Qaidah An-Nooraniyah',
      'ar': 'القاعدة النورانية',
      'am': 'ቃዒዳ ኑራንያ',
      'om': 'Qaa\'idaa Nuuraaniyaa',
    },
  ),

  _ToolItem(
    key: 'mosque',
    svgIconName: 'nearby_mosques',
    color: Color(0xFF00838F),
    labels: {
      'en': 'Nearest Mosques',
      'ar': 'المسجد الأقرب',
      'am': 'የቅርብ መስጊዶች',
      'om': 'Masjiida Dhihoo',
    },
  ),
  // Row 5
  _ToolItem(
    key: 'calendar',
    svgIconName: 'hijri_calendar',
    color: Color(0xFF6A1B9A),
    labels: {
      'en': 'Calendar',
      'ar': 'التقويم الهجري',
      'am': 'ካላንደር',
      'om': 'Kalandara Hijraa',
    },
  ),
];

class _ToolGridCell extends StatefulWidget {
  final _ToolItem item;
  final Animation<double> pulseAnim;
  final double phaseOffset;
  final Duration entranceDelay;
  final bool isAdVisible;

  const _ToolGridCell({
    required this.item,
    required this.pulseAnim,
    required this.phaseOffset,
    required this.entranceDelay,
    required this.isAdVisible,
  });

  @override
  State<_ToolGridCell> createState() => _ToolGridCellState();
}

class _ToolGridCellState extends State<_ToolGridCell> {
  double _phased(double raw) {
    final shifted = (raw + widget.phaseOffset) % 1.0;
    final tri = shifted < 0.5 ? shifted * 2.0 : (1.0 - shifted) * 2.0;
    return Curves.easeInOut.transform(tri);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final label = widget.item.labels[locale] ?? widget.item.labels['ar']!;

    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final isDark = theme == QuranTheme.dark;
        final isCream = theme == QuranTheme.cream;

        final titleColor = isDark
            ? Colors.white
            : (isCream ? const Color(0xFF2C1E07) : const Color(0xFF0C2417));
        final accent = widget.item.color;
        final bright = Color.lerp(accent, Colors.white, 0.35)!;

        return LiquidPressable(
          scaleFactor: 0.94,
          onTap: () {
            switch (widget.item.key) {
              case 'moazin':
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PrayerTimesScreen(controller: PrayerController()),
                    ));
                break;
              case 'calendar':
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HijriCalendarScreen(),
                    ));
                break;
              case 'mosque':
                findNearestMosques();
                break;
              case 'azkar':
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AzkarScreen(),
                    ));
                break;
              case 'tasbih':
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TasbihScreen(),
                    ));
                break;
              case 'qaida_noorania':
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QaidaNooraniyahScreen(),
                    ));
                break;
            }
          },
          child: AnimatedBuilder(
            animation: widget.pulseAnim,
            builder: (_, child) {
              final t = _globalHasAnimatedDashboard
                  ? 0.0
                  : _phased(widget.pulseAnim.value);

              // Scale: 1.00 -> 1.025
              final scale = 1.0 + 0.025 * t;

              // Glow breathing
              final glowAlpha = isDark
                  ? (0.10 + 0.30 * t)
                  : (isCream ? (0.06 + 0.18 * t) : (0.05 + 0.15 * t));
              final glowBlur = 8.0 + 14.0 * t;
              final glowSpread = 0.5 + 1.5 * t;

              // Border breathing
              final borderAlpha = isDark
                  ? (0.22 + 0.35 * t)
                  : (isCream ? (0.20 + 0.25 * t) : (0.15 + 0.20 * t));
              final borderWidth = 1.2 + 0.5 * t;

              final currentAccent = Color.lerp(accent, bright, t * 0.5)!;
              final deep = isDark
                  ? Color.lerp(accent, const Color(0xFF0C0C14), 0.72)!
                  : (isCream
                      ? Color.lerp(accent, const Color(0xFFFAF4E6), 0.85)!
                      : Color.lerp(accent, Colors.white, 0.90)!);

              // Fill gradient matching card style
              final Color bg1 = isDark
                  ? currentAccent.withValues(alpha: 0.16 + 0.18 * t)
                  : (isCream
                      ? Colors.white.withValues(alpha: 0.85)
                      : Colors.white);
              final Color bg2 = isDark
                  ? deep.withValues(alpha: 0.05 + 0.08 * t)
                  : (isCream
                      ? const Color(0xFFF7EED9).withValues(alpha: 0.75)
                      : const Color(0xFFF4FAF6));

              return Transform.scale(
                scale: scale,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [bg1, bg2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? currentAccent.withValues(alpha: borderAlpha)
                          : (isCream
                              ? const Color(0xFFD4AF37)
                                  .withValues(alpha: borderAlpha)
                              : currentAccent.withValues(alpha: borderAlpha)),
                      width: borderWidth,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.35)
                            : Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: currentAccent.withValues(alpha: glowAlpha),
                        blurRadius: glowBlur,
                        spreadRadius: glowSpread,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Subtle Accent glow orb
                        Positioned(
                          top: -20,
                          left: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  currentAccent.withValues(
                                      alpha: isDark
                                          ? 0.30 * t
                                          : (isCream ? 0.15 * t : 0.12 * t)),
                                  currentAccent.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Main cell contents
                        Positioned.fill(child: child!),
                      ],
                    ),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: widget.pulseAnim,
                    builder: (_, __) {
                      final t = _phased(widget.pulseAnim.value);
                      final currentAccent =
                          Color.lerp(accent, bright, t * 0.5)!;
                      final deep = isDark
                          ? Color.lerp(accent, const Color(0xFF0C0C14), 0.72)!
                          : (isCream
                              ? Color.lerp(
                                  accent, const Color(0xFFE8DAC0), 0.5)!
                              : Color.lerp(
                                  accent, const Color(0xFF093322), 0.4)!);

                      return Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [currentAccent, deep],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: currentAccent.withValues(
                                  alpha: 0.30 + 0.25 * t),
                              blurRadius: 8 + 10 * t,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/${isDark ? 'dark' : 'light'}/${widget.item.svgIconName}.svg',
                            width: 26,
                            height: 26,
                            colorFilter: const ColorFilter.mode(
                                Colors.white, BlendMode.srcIn),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 7),
                  Text(
                    label,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      height: 1.15,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
