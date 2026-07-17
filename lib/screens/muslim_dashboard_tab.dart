import 'package:flutter/material.dart';
import '../core/database/database_helper.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../theme_notifier.dart';
import 'quran_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../features/prayer_times/presentation/controllers/prayer_controller.dart';
import '../features/prayer_times/presentation/screens/prayer_times_screen.dart';
import '../features/calendar/presentation/screens/hijri_calendar_screen.dart';
import '../features/calendar/presentation/screens/date_converter_screen.dart';
import '../features/qibla/presentation/screens/qibla_screen.dart';
import 'azkar_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MuslimDashboardTab — Tab 1
// ─────────────────────────────────────────────────────────────────────────────
// Layout uses Column + Expanded so everything fits on one screen — no scroll.
// ─────────────────────────────────────────────────────────────────────────────

class MuslimDashboardTab extends StatelessWidget {
  const MuslimDashboardTab({super.key});

  static const _localizedTitle = {
    'en': 'Muslim Hub',
    'ar': 'مركز المسلم',
    'am': 'የሙስሊም ማዕከል',
    'om': 'Wiirtuu Muslimaa',
  };

  static const _sectionTitle = {
    'en': 'Islamic Tools',
    'ar': 'أدوات إسلامية',
    'am': 'ኢስላማዊ መሣሪያዎች',
    'om': 'Meeshaalee Islaamaa',
  };

  @override
  Widget build(BuildContext context) {
    final isDark  = AppTheme.notifier.value == QuranTheme.dark;
    final bg      = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final locale  = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final title   = _localizedTitle[locale] ?? _localizedTitle['ar']!;
    final secTitle = _sectionTitle[locale] ?? _sectionTitle['ar']!;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 8, 6),
              child: Row(
                children: [
                  const Text('🕌', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: isDark ? AppColors.textPrimary : AppColors.emeraldDeep,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: isDark ? AppColors.textSecondary : AppColors.emeraldDeep,
                      size: 22,
                    ),
                    onPressed: () {},
                    tooltip: 'Notification Settings',
                  ),
                ],
              ),
            ),

            // ── 1. Miqat / Prayer Times Card ─────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _MiqatCard(),
            ),
            const SizedBox(height: 10),

            // ── 2. Quran Gateway Card ────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _ResumeReadingCard(),
            ),
            const SizedBox(height: 10),

            // ── Section Title ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                secTitle,
                style: AppTextStyles.headlineMedium.copyWith(fontSize: 15),
              ),
            ),
            const SizedBox(height: 8),

            // ── 3. 8-Tools Grid — LayoutBuilder auto-fits; zero scroll ────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: LayoutBuilder(
                  builder: (_, constraints) {
                    const int rows  = 4;
                    const int cols  = 2;
                    const double sp = 8.0;
                    final cellH = (constraints.maxHeight - (rows - 1) * sp) / rows;
                    final cellW = (constraints.maxWidth  - (cols - 1) * sp) / cols;
                    final ratio = (cellW / cellH).clamp(0.8, 4.0);
                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: sp,
                        crossAxisSpacing: sp,
                        childAspectRatio: ratio,
                      ),
                      itemCount: _tools.length,
                      itemBuilder: (_, i) => _ToolGridCell(item: _tools[i]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// 1. MIQAT CARD — Compact Prayer Times Grid
// ═════════════════════════════════════════════════════════════════════════════

class _MiqatCard extends StatelessWidget {
  const _MiqatCard();

  static const _prayerNames = {
    'en': {
      'fajr': 'Fajr',
      'sunrise': 'Sunrise',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
    },
    'ar': {
      'fajr': 'الفجر',
      'sunrise': 'الشروق',
      'dhuhr': 'الظهر',
      'asr': 'العصر',
      'maghrib': 'المغرب',
      'isha': 'العشاء',
    },
    'am': {
      'fajr': 'ፈጅር',
      'sunrise': 'ሸምስ',
      'dhuhr': 'ዙሁር',
      'asr': 'ዓሥር',
      'maghrib': 'ማግሪብ',
      'isha': 'ዒሻ',
    },
    'om': {
      'fajr': 'Fajrii',
      'sunrise': 'B. Aduu',
      'dhuhr': 'Zuhr',
      'asr': 'Asar',
      'maghrib': 'Magrib',
      'isha': 'Ishaa',
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
          // Compact skeleton or loading card
          return Container(
            height: 90,
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
        final nextPrayerName = model.nextPrayer.prayer;

        return GestureDetector(
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
                  color: model.miqatGradientColors.first.withValues(alpha: 0.45),
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        hijriStr,
                        style: AppTextStyles.arabicSmall
                            .copyWith(color: AppColors.goldLight, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      const Text('·',
                          style: TextStyle(color: Colors.white38, fontSize: 12)),
                      const SizedBox(width: 8),
                      Text(
                        gregStr,
                        style: const TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                      const Spacer(),
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: Colors.white54),
                      const SizedBox(width: 2),
                      Text(
                        model.locationLabel,
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ),

                // ── Prayer Times Row ─────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(18),
                      bottomRight: Radius.circular(18),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(model.entries.length, (i) {
                      final entry = model.entries[i];
                      final isNext = entry.prayer == nextPrayerName;
                      final nameMap = _prayerNames[locale] ?? _prayerNames['en']!;
                      final pName = nameMap[entry.prayer.name] ?? entry.prayer.name;
                      final pTime = DateFormat('HH:mm').format(entry.time);

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            pName,
                            style: TextStyle(
                              color: isNext ? AppColors.goldLight : Colors.white60,
                              fontSize: 10,
                              fontWeight:
                                  isNext ? FontWeight.w700 : FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            pTime,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight:
                                  isNext ? FontWeight.w700 : FontWeight.w500,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 2),
                          if (isNext)
                            Container(
                              width: 20,
                              height: 2,
                              decoration: BoxDecoration(
                                color: AppColors.goldLight,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            )
                          else
                            const SizedBox(height: 2),
                        ],
                      );
                    }),
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

// ═════════════════════════════════════════════════════════════════════════════
// 2. QURAN GATEWAY CARD — Dynamic position + Compact
// ═════════════════════════════════════════════════════════════════════════════

class _ResumeReadingCard extends StatefulWidget {
  const _ResumeReadingCard();

  @override
  State<_ResumeReadingCard> createState() => _ResumeReadingCardState();
}

class _ResumeReadingCardState extends State<_ResumeReadingCard> {
  int    _lastPage    = 1;
  double _progressPct = 0.0016;
  String _ayahNameAr  = 'سورة الفاتحة';
  String _ayahNameEn  = 'Al-Fatihah 1:1';

  @override
  void initState() {
    super.initState();
    _loadLastReadPosition();
  }

  Future<void> _loadLastReadPosition() async {
    try {
      final prefs    = await SharedPreferences.getInstance();
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
        final String translit = DatabaseHelper.surahTransliterations[surahNum - 1];

        foundAr = 'سورة $surahArabic';
        foundEn = '$translit $ayahNum';
      }

      if (mounted) {
        setState(() {
          _lastPage    = lastPage;
          _progressPct = lastPage / 604.0;
          _ayahNameAr  = foundAr;
          _ayahNameEn  = foundEn;
        });
      }
    } catch (_) {}
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
    final isDark   = AppTheme.notifier.value == QuranTheme.dark;
    final locale   = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final pctStr   = (_progressPct * 100).toStringAsFixed(0);

    final Color cardBg = isDark ? const Color(0xFF0F2B1D) : const Color(0xFFE8F5E9);
    final Color border = isDark ? const Color(0xFF1E5B3C) : const Color(0xFFC8E6C9);
    final Color accent = isDark ? const Color(0xFFA5D6A7) : const Color(0xFF2E7D32);
    final Color textPrimary = isDark ? const Color(0xFFE0F2F1) : const Color(0xFF1B5E20);

    final String title, action, progress, ayah;
    if (locale == 'ar') {
      title    = 'القرآن الكريم';
      action   = 'استمر في القراءة ←';
      progress = 'صفحة $_lastPage · $pctStr٪';
      ayah     = _ayahNameAr;
    } else if (locale == 'am') {
      title    = 'ቅዱስ ቁርአን';
      action   = 'ማንበብ ይቀጥሉ →';
      progress = 'ገጽ $_lastPage · $pctStr%';
      ayah     = _ayahNameEn;
    } else if (locale == 'om') {
      title    = 'Quraana Qulqulluu';
      action   = 'Dubbisuu Itti Fufi →';
      progress = 'Fuula $_lastPage · $pctStr%';
      ayah     = _ayahNameEn;
    } else {
      title    = 'The Holy Quran';
      action   = 'Resume Reading →';
      progress = 'Page $_lastPage · $pctStr%';
      ayah     = _ayahNameEn;
    }

    return GestureDetector(
      onTap: () => _navigateToQuran(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : Colors.grey.shade300.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E4620)
                    : const Color(0xFFC8E6C9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.menu_book_rounded, color: accent, size: 24),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                      Text(action,
                          style: TextStyle(
                              color: accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: _progressPct,
                      backgroundColor: isDark
                          ? const Color(0xFF123524)
                          : const Color(0xFFDCEDC8),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ayah,
                          style: TextStyle(
                              color: accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w500)),
                      Text(progress,
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey.shade600,
                              fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
    required this.icon,
    required this.color,
    required this.labels,
    required this.sublabels,
  });

  final String key;
  final IconData icon;
  final Color color;
  final Map<String, String> labels;
  final Map<String, String> sublabels;
}

const _tools = <_ToolItem>[
  // Row 1
  _ToolItem(
    key: 'moazin',
    icon: Icons.access_time_rounded,
    color: Color(0xFF00897B),
    labels: {
      'en': 'Prayer Times',
      'ar': 'مواقيت الصلاة',
      'am': 'የሶላት ወቅት',
      'om': 'Yeroo Salaataa',
    },
    sublabels: {
      'en': 'Al-Moazin',
      'ar': 'المؤذن',
      'am': 'አል-ሙአዚን',
      'om': 'Al-Moazin',
    },
  ),
  _ToolItem(
    key: 'azkar',
    icon: Icons.auto_stories_rounded,
    color: Color(0xFFE65100),
    labels: {
      'en': 'Azkar Hub',
      'ar': 'الأذكار',
      'am': 'አዝካር',
      'om': 'Azkaara',
    },
    sublabels: {
      'en': 'Daily Remembrance',
      'ar': 'أذكار اليوم',
      'am': 'የዕለት አዝካር',
      'om': 'Dhikrii Guyyaa',
    },
  ),
  // Row 2
  _ToolItem(
    key: 'qibla',
    icon: Icons.explore_rounded,
    color: Color(0xFF1565C0),
    labels: {
      'en': 'Qibla',
      'ar': 'القبلة',
      'am': 'ቂብላ',
      'om': 'Qiblaa',
    },
    sublabels: {
      'en': 'Direction Finder',
      'ar': 'اتجاه القبلة',
      'am': 'ቂብላ ጠቋሚ',
      'om': 'Kallattii Qiblaa',
    },
  ),
  _ToolItem(
    key: 'calendar',
    icon: Icons.calendar_month_rounded,
    color: Color(0xFF6A1B9A),
    labels: {
      'en': 'Hijri Calendar',
      'ar': 'التقويم الهجري',
      'am': 'የሂጅራ ቀን',
      'om': 'Kalandara Hijraa',
    },
    sublabels: {
      'en': 'Islamic Dates',
      'ar': 'التاريخ الإسلامي',
      'am': 'እስላማዊ ቀናት',
      'om': 'Guyyoota Hijraa',
    },
  ),
  // Row 3
  _ToolItem(
    key: 'tasbih',
    icon: Icons.touch_app_rounded,
    color: Color(0xFF558B2F),
    labels: {
      'en': 'Tasbih',
      'ar': 'التسبيح',
      'am': 'ተስቢህ',
      'om': 'Tasbiiha',
    },
    sublabels: {
      'en': 'Dhikr Counter',
      'ar': 'عداد الذكر',
      'am': 'የዚክር ቆጣሪ',
      'om': 'Lakkooftuu Dhikrii',
    },
  ),
  _ToolItem(
    key: 'mosque',
    icon: Icons.mosque_outlined,
    color: Color(0xFF00838F),
    labels: {
      'en': 'Mosques',
      'ar': 'دليل المساجد',
      'am': 'መስጊዶች',
      'om': 'Masiidota',
    },
    sublabels: {
      'en': 'Find Nearest',
      'ar': 'أقرب المساجد',
      'am': 'የቅርብ መስጊዶች',
      'om': 'Masiidota Dhiyoo',
    },
  ),
  // Row 4
  _ToolItem(
    key: 'converter',
    icon: Icons.compare_arrows_rounded,
    color: Color(0xFF4527A0),
    labels: {
      'en': 'Date Converter',
      'ar': 'تحويل التاريخ',
      'am': 'ቀን ቀያሪ',
      'om': 'Jijiirraa Guyyaa',
    },
    sublabels: {
      'en': 'Hijri ↔ Gregorian',
      'ar': 'هجري ↔ ميلادي',
      'am': 'ሂጅራ ↔ ሚላዲ',
      'om': 'Hijraa ↔ Gregorian',
    },
  ),
  _ToolItem(
    key: 'ruqyah',
    icon: Icons.health_and_safety_rounded,
    color: Color(0xFFB71C1C),
    labels: {
      'en': 'Al-Ruqyah',
      'ar': 'الرقية الشرعية',
      'am': 'ሩቅያህ',
      'om': 'Ruqiyaa',
    },
    sublabels: {
      'en': 'Reader & Audio',
      'ar': 'قراءة واستماع',
      'am': 'ንባብ እና ድምፅ',
      'om': 'Dubbisaa & Sagalee',
    },
  ),
];


class _ToolGridCell extends StatefulWidget {
  const _ToolGridCell({required this.item});
  final _ToolItem item;

  @override
  State<_ToolGridCell> createState() => _ToolGridCellState();
}

class _ToolGridCellState extends State<_ToolGridCell>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(_) => _ctrl.reverse();
  void _up(_)   => _ctrl.forward();

  @override
  Widget build(BuildContext context) {
    final isDark   = AppTheme.notifier.value == QuranTheme.dark;
    final locale   = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final label    = widget.item.labels[locale]    ?? widget.item.labels['ar']!;
    final sublabel = widget.item.sublabels[locale] ?? widget.item.sublabels['ar']!;

    // ── Theme-correct surfaces (uses AppColors, not colorScheme.surface) ─────
    final cardBg      = isDark ? AppColors.surfaceCard      : AppColors.surfaceCardLight;
    final titleColor  = isDark ? Colors.white               : Colors.black87;
    final subColor    = isDark ? Colors.white54             : Colors.black45;
    final iconBg      = widget.item.color.withValues(alpha: 0.14);
    // Vibrant colored border — visible in both dark & light
    final borderColor = widget.item.color.withValues(alpha: isDark ? 0.60 : 0.50);

    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: () => _ctrl.forward(),
      onTap: () {
        switch (widget.item.key) {
          case 'moazin':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PrayerTimesScreen(controller: PrayerController()),
              ),
            );
            break;
          case 'qibla':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const QiblaScreen(),
              ),
            );
            break;
          case 'calendar':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HijriCalendarScreen(),
              ),
            );
            break;
          case 'converter':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DateConverterScreen(),
              ),
            );
            break;
          case 'azkar':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AzkarScreen(),
              ),
            );
            break;
        }
      },
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) =>
            Transform.scale(scale: _ctrl.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.5),
            boxShadow: isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: widget.item.color.withValues(alpha: 0.10),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          // Column layout: icon centred on top, labels below
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Coloured circular icon ───────────────────────────────────
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.item.icon,
                  color: widget.item.color,
                  size: 26,
                ),
              ),
              const SizedBox(height: 8),

              // ── Tool name ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  label,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),

              // ── Subtitle ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  sublabel,
                  style: TextStyle(
                    color: subColor,
                    fontSize: 10,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
