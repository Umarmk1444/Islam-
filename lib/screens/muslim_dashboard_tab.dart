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
import 'quiz_intro_screen.dart';
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

class _MuslimDashboardTabState extends State<MuslimDashboardTab>
    with SingleTickerProviderStateMixin {
  static const _localizedTitle = {
    'en': 'Quran Zone',
    'ar': 'قرآن زون',
    'am': 'Quran Zone',
    'om': 'Quran Zone',
  };

  static const _sectionTitle = {
    'en': 'Islamic Tools',
    'ar': 'أدوات إسلامية',
    'am': 'ኢስላማዊ መሣሪያዎች',
    'om': 'Meeshaalee Islaamaa',
  };

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.notifier.value == QuranTheme.dark;
    final bg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final title = _localizedTitle[locale] ?? _localizedTitle['ar']!;
    final secTitle = _sectionTitle[locale] ?? _sectionTitle['ar']!;

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
            final double gridRatio = isAdVisible ? 1.25 : 1.18;
            const double paddingBottom = 12;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header ─────────────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      children: [
                        const Text('🕌', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        Text(
                          title,
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColors.emeraldDeep,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── 1. Miqat / Prayer Times Card ───────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _MiqatCard(isAdVisible: isAdVisible),
                  ),
                  const SizedBox(height: space8),

                  // ── 2. Quran Gateway Card ───────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _ResumeReadingCard(isAdVisible: isAdVisible),
                  ),
                  const SizedBox(height: space10),

                  // ── Section Title ───────────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Text(
                      secTitle,
                      style: AppTextStyles.headlineMedium.copyWith(
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: space6),

                  // ── 3. Tools Grid — Fills list scroll view ─────────────────────────
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, paddingBottom),
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

  @override
  Widget build(BuildContext context) {
    final ctrl = PrayerController();
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';

    return AnimatedBuilder(
      animation: ctrl,
      builder: (context, _) {
        final model = ctrl.model;
        if (model == null || ctrl.isLoading) {
          return Container(
            height: 140,
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
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.explore_outlined,
                                    color: AppColors.goldLight, size: 24),
                                SizedBox(height: 4),
                                Text(
                                  'القبلة',
                                  style: TextStyle(
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
    final isDark = AppTheme.notifier.value == QuranTheme.dark;
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final pctStr = (_progressPct * 100).toStringAsFixed(0);

    // Royal emerald and gold color scheme
    const Color emeraldDark = Color(0xFF063A20);
    const Color emeraldDeep = Color(0xFF032212);
    const Color emeraldLight = Color(0xFF0F6636);
    const Color goldColor = Color(0xFFFFD54F);

    final Color textPrimary = isDark ? Colors.white : const Color(0xFF0D3B23);
    final Color textSecondary =
        isDark ? Colors.white70 : const Color(0xFF1E5235);
    final Color progressValColor = isDark ? goldColor : const Color(0xFF2E7D32);

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

    return LiquidPressable(
      onTap: () => _navigateToQuran(context),
      scaleFactor: 0.96,
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (context, child) {
          final t = _pulseAnim.value;
          final scale = 1.0 + 0.025 * t;

          final Color currentBorder = Color.lerp(
            isDark ? emeraldLight : const Color(0xFF81C784),
            goldColor.withValues(alpha: 0.95),
            t * 0.55,
          )!;
          final double borderWidth = 1.4 + 1.0 * t;

          final glowColor = Color.lerp(
            isDark ? emeraldLight : const Color(0xFF81C784),
            goldColor,
            0.65,
          )!;
          final double shadowAlpha =
              isDark ? (0.20 + 0.35 * t) : (0.10 + 0.20 * t);
          final double blurRadius = 10.0 + 20.0 * t;
          final double spreadRadius = 0.8 + 3.0 * t;

          return Transform.scale(
            scale: scale,
            child: Container(
              height: 84,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [emeraldDark, emeraldDeep]
                      : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: currentBorder, width: borderWidth),
                boxShadow: [
                  BoxShadow(
                    color: glowColor.withValues(alpha: shadowAlpha),
                    blurRadius: blurRadius,
                    spreadRadius: spreadRadius,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Gold radial glow orb (upper right) - intensified
                    Positioned(
                      top: -45,
                      right: -25,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              goldColor.withValues(
                                  alpha: isDark ? 0.32 * t : 0.22 * t),
                              goldColor.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Emerald radial glow orb (lower left) - intensified
                    Positioned(
                      bottom: -35,
                      left: -35,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              emeraldLight.withValues(
                                  alpha: isDark ? 0.38 * t : 0.26 * t),
                              emeraldLight.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Special golden glow orb right behind the book icon to make it emit light
                    Positioned(
                      left: 12,
                      top: 10,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              goldColor.withValues(
                                  alpha: isDark ? 0.70 * t : 0.50 * t),
                              goldColor.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Main Content centered perfectly using Positioned.fill
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            // Golden medal style book container
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [goldColor, Color(0xFFF57F17)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: goldColor.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Text(
                                          title,
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          action,
                                          style: TextStyle(
                                            color: isDark
                                                ? goldColor
                                                : const Color(0xFFE65100),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _progressPct,
                                      backgroundColor: isDark
                                          ? Colors.white12
                                          : const Color(0xFFC8E6C9),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          progressValColor),
                                      minHeight: 5,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Row(
                                      children: [
                                        Text(
                                          ayah,
                                          style: TextStyle(
                                            color: isDark
                                                ? goldColor
                                                : const Color(0xFF2E7D32),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          progress,
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
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
    );
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
    key: 'quiz',
    svgIconName: 'quiz',
    color: Color(0xFFF9A825),
    labels: {
      'en': 'Quiz & Games',
      'ar': 'مسابقات',
      'am': 'ጥያቄና መልስ',
      'om': 'Gaaffii fi Deebii',
    },
  ),

  _ToolItem(
    key: 'mosque',
    svgIconName: 'nearby_mosques',
    color: Color(0xFF00838F),
    labels: {
      'en': 'Nearest Mosques',
      'ar': 'دليل المساجد',
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

class _ToolGridCellState extends State<_ToolGridCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.entranceDelay, () {
      if (mounted) _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  double _phased(double raw) {
    final shifted = (raw + widget.phaseOffset) % 1.0;
    final tri = shifted < 0.5 ? shifted * 2.0 : (1.0 - shifted) * 2.0;
    return Curves.easeInOut.transform(tri);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.notifier.value == QuranTheme.dark;
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final label = widget.item.labels[locale] ?? widget.item.labels['ar']!;

    final titleColor = isDark ? Colors.white : Colors.black87;
    final accent = widget.item.color;
    final bright = Color.lerp(accent, Colors.white, 0.30)!;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: LiquidPressable(
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
              case 'quiz':
                Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const QuizIntroScreen(),
                    ));
                break;
            }
          },
          child: AnimatedBuilder(
            animation: widget.pulseAnim,
            builder: (_, child) {
              final t = _phased(widget.pulseAnim.value);

              // Scale: 1.00 -> 1.03
              final scale = 1.0 + 0.03 * t;

              // Glow breathing
              final glowAlpha = isDark ? (0.10 + 0.35 * t) : (0.08 + 0.28 * t);
              final glowBlur = 8.0 + 16.0 * t;
              final glowSpread = 0.5 + 2.0 * t;

              // Border breathing
              final borderAlpha =
                  isDark ? (0.22 + 0.38 * t) : (0.14 + 0.32 * t);
              final borderWidth = 1.2 + 0.6 * t;

              // Interpolate dynamic accent and create a dynamic deep color matching library's depth
              final currentAccent = Color.lerp(accent, bright, t * 0.5)!;
              final deep = Color.lerp(accent, const Color(0xFF0C0C14), 0.72)!;

              // Fill gradient matching card style
              final fillA = isDark ? (0.16 + 0.20 * t) : (0.08 + 0.12 * t);
              final fillB = isDark ? (0.05 + 0.10 * t) : (0.02 + 0.05 * t);

              return Transform.scale(
                scale: scale,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        currentAccent.withValues(alpha: fillA),
                        deep.withValues(alpha: fillB),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: currentAccent.withValues(alpha: borderAlpha),
                      width: borderWidth,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: currentAccent.withValues(alpha: glowAlpha),
                        blurRadius: glowBlur,
                        spreadRadius: glowSpread,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        // Accent color internal glowing orb
                        Positioned(
                          top: -25,
                          left: -25,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  currentAccent.withValues(
                                      alpha: isDark ? 0.35 * t : 0.28 * t),
                                  currentAccent.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Deep color internal glowing orb
                        Positioned(
                          bottom: -20,
                          right: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  deep.withValues(
                                      alpha: isDark ? 0.28 * t : 0.20 * t),
                                  deep.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Main cell contents (centered correctly using Positioned.fill)
                        Positioned.fill(child: child!),
                      ],
                    ),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: widget.pulseAnim,
                    builder: (_, __) {
                      final t = _phased(widget.pulseAnim.value);
                      final bright = Color.lerp(accent, Colors.white, 0.30)!;
                      final currentAccent =
                          Color.lerp(accent, bright, t * 0.5)!;
                      final deep =
                          Color.lerp(accent, const Color(0xFF0C0C14), 0.72)!;
                      return Container(
                        width: 54,
                        height: 54,
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
                                  alpha: 0.35 + 0.30 * t),
                              blurRadius: 10 + 14 * t,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'assets/icons/${isDark ? 'dark' : 'light'}/${widget.item.svgIconName}.svg',
                            width: 28,
                            height: 28,
                            colorFilter: const ColorFilter.mode(
                                Colors.white, BlendMode.srcIn),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
