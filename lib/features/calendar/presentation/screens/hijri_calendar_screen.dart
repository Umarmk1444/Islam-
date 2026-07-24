// lib/features/calendar/presentation/screens/hijri_calendar_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// HijriCalendarScreen — Beautiful monthly calendar showing:
//   • Gregorian date (primary, large)
//   • Hijri day (secondary, shown inside each day cell)
//   • Ethiopian day (tertiary, shown as a small badge)
// Supports dark / light theme and app locale.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../theme_notifier.dart';
import '../controllers/calendar_controller.dart';
import 'date_converter_screen.dart';

class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key});

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen>
    with SingleTickerProviderStateMixin {
  final CalendarController _ctrl = CalendarController();
  late AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl.goToToday();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _shiftMonth(int delta) async {
    await _fadeCtrl.animateTo(0.0);
    _ctrl.shiftMonth(delta);
    await _fadeCtrl.animateTo(1.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = AppTheme.notifier.value == QuranTheme.dark;
    final bg       = isDark ? AppColors.surfaceDark  : AppColors.surfaceLight;
    final cardBg   = isDark ? AppColors.surfaceCard  : AppColors.surfaceCardLight;
    final textPri  = isDark ? AppColors.textPrimary  : Colors.black87;
    final textSec  = isDark ? AppColors.textSecondary : Colors.black54;
    final locale   = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final isRtl    = locale == 'ar';

    return Directionality(
      textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.surfaceCard : Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            _appBarTitle(locale),
            style: TextStyle(
              color: textPri,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: textPri),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              tooltip: 'Today',
              icon: const Icon(Icons.today_rounded, color: AppColors.emeraldLight),
              onPressed: () {
                _ctrl.goToToday();
                setState(() {});
              },
            ),
          ],
        ),
        body: ListenableBuilder(
          listenable: _ctrl,
          builder: (context, _) {
            if (_ctrl.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.emeraldLight),
              );
            }

            final base  = _ctrl.selectedGregorian;
            final eth   = _ctrl.current.ethiopian;
            final grid  = _ctrl.buildMonthGrid(base);
            final today = DateTime.now();

            return Column(
              children: [
                // ── Header: triple-calendar month banner ─────────────────────
                _MonthBanner(
                  gregorianMonth: DateFormat('MMMM yyyy').format(base),
                  hijriLabel:     _ctrl.current.formattedHijri(locale: locale),
                  ethLabel:       eth.formatted(amharic: locale == 'am'),
                  isDark:         isDark,
                  textPri:        textPri,
                  textSec:        textSec,
                  onPrevious:     () => _shiftMonth(-1),
                  onNext:         () => _shiftMonth(1),
                ),

                // ── Weekday headers ──────────────────────────────────────────
                _WeekdayHeader(isDark: isDark, textSec: textSec, locale: locale),

                const SizedBox(height: 4),

                // ── Day grid ─────────────────────────────────────────────────
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeCtrl,
                    child: GridView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 6,
                        crossAxisSpacing: 6,
                      ),
                      itemCount: grid.length,
                      itemBuilder: (context, i) {
                        final day = grid[i];
                        if (day == null) return const SizedBox.shrink();
                        final isToday = day.year == today.year &&
                            day.month == today.month &&
                            day.day == today.day;
                        final hijriDay =
                            _ctrl.hijriDayLabel(day);
                        final ethDay   =
                            _ctrl.ethiopianDayLabel(day);
                        return _DayCell(
                          day:       day,
                          hijriDay:  hijriDay,
                          ethDay:    ethDay,
                          isToday:   isToday,
                          isDark:    isDark,
                          cardBg:    cardBg,
                          textPri:   textPri,
                          textSec:   textSec,
                          onTap: () => _ctrl.convertToAll(day),
                        );
                      },
                    ),
                  ),
                ),

                // ── Legend ───────────────────────────────────────────────────
                _Legend(isDark: isDark, textSec: textSec),

                // ── Date Converter Button ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? AppColors.surfaceCard : Colors.white,
                      foregroundColor: textPri,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: AppColors.emeraldLight.withValues(alpha: 0.35),
                          width: 1.3,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size.fromHeight(50),
                    ),
                    icon: const Icon(Icons.sync_alt, color: AppColors.emeraldLight),
                    label: Text(
                      locale == 'ar' ? 'محول التاريخ' : 
                      locale == 'am' ? 'ቀን መለወጫ' : 
                      locale == 'om' ? 'Jijjiirraa Guyyaa' : 
                      'Date Converter',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DateConverterScreen()),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _appBarTitle(String locale) {
    switch (locale) {
      case 'ar': return 'التقويم الهجري';
      case 'am': return 'የሂጅራ ቀን አቆጣጠር';
      case 'om': return 'Kalandara Hijraa';
      default:   return 'Hijri Calendar';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _MonthBanner extends StatelessWidget {
  const _MonthBanner({
    required this.gregorianMonth,
    required this.hijriLabel,
    required this.ethLabel,
    required this.isDark,
    required this.textPri,
    required this.textSec,
    required this.onPrevious,
    required this.onNext,
  });

  final String gregorianMonth;
  final String hijriLabel;
  final String ethLabel;
  final bool   isDark;
  final Color  textPri;
  final Color  textSec;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D2B3E), const Color(0xFF1A3B52)]
              : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.emeraldLight.withValues(alpha: 0.35),
          width: 1.3,
        ),
      ),
      child: Row(
        children: [
          _NavButton(icon: Icons.chevron_left_rounded, onTap: onPrevious, isDark: isDark),
          Expanded(
            child: Column(
              children: [
                Text(
                  gregorianMonth,
                  style: TextStyle(
                    color: textPri,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  hijriLabel,
                  style: TextStyle(
                    color: isDark ? AppColors.goldLight : const Color(0xFF1565C0),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  ethLabel,
                  style: TextStyle(
                    color: isDark ? textSec : const Color(0xFFDD2C00),
                    fontSize: 11.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          _NavButton(icon: Icons.chevron_right_rounded, onTap: onNext, isDark: isDark),
        ],
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            color: isDark ? AppColors.emeraldLight : AppColors.emeraldMid,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({
    required this.isDark,
    required this.textSec,
    required this.locale,
  });
  final bool isDark;
  final Color textSec;
  final String locale;

  static const _en = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _ar = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];
  static const _am = ['ሰ', 'ማ', 'ሮ', 'ሐ', 'አ', 'ቅ', 'እ'];

  @override
  Widget build(BuildContext context) {
    final labels = locale == 'ar' ? _ar : locale == 'am' ? _am : _en;
    final isFridayHighlight = [4]; // Index of Friday (5th weekday, 0-based = 4)

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: List.generate(7, (i) {
          final isFri = isFridayHighlight.contains(i);
          return Expanded(
            child: Center(
              child: Text(
                labels[i],
                style: TextStyle(
                  color: isFri ? AppColors.prayerFajr : textSec,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.hijriDay,
    required this.ethDay,
    required this.isToday,
    required this.isDark,
    required this.cardBg,
    required this.textPri,
    required this.textSec,
    required this.onTap,
  });

  final DateTime day;
  final String   hijriDay;
  final String   ethDay;
  final bool     isToday;
  final bool     isDark;
  final Color    cardBg;
  final Color    textPri;
  final Color    textSec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isFriday = day.weekday == DateTime.friday;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isToday
              ? AppColors.emeraldMid
              : isFriday
                  ? AppColors.prayerFajr.withValues(alpha: isDark ? 0.18 : 0.12)
                  : cardBg,
          borderRadius: BorderRadius.circular(10),
          border: isToday
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.06),
                ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Gregorian day (large)
              Text(
                '${day.day}',
                style: TextStyle(
                  color: isToday ? Colors.white : textPri,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              // Hijri day (gold)
              // Hijri day (gold/emerald)
              Text(
                hijriDay,
                style: TextStyle(
                  color: isToday
                      ? Colors.white70
                      : (isDark 
                          ? AppColors.goldLight.withValues(alpha: 0.9)
                          : const Color(0xFF1565C0)),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              // Ethiopian day (muted)
              Text(
                ethDay,
                style: TextStyle(
                  color: isToday
                      ? Colors.white54
                      : (isDark
                          ? textSec.withValues(alpha: 0.7)
                          : const Color(0xFFDD2C00)),
                  fontSize: 8.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.isDark, required this.textSec});
  final bool isDark;
  final Color textSec;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendDot(
            color: AppColors.emeraldMid,
            label: 'Today',
            textSec: textSec,
          ),
          const SizedBox(width: 20),
          _LegendDot(
            color: isDark ? AppColors.goldLight : const Color(0xFF1565C0),
            label: 'Hijri',
            textSec: textSec,
          ),
          const SizedBox(width: 20),
          _LegendDot(
            color: isDark ? textSec : const Color(0xFFDD2C00),
            label: 'Ethiopian',
            textSec: textSec,
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.textSec,
  });
  final Color color;
  final String label;
  final Color textSec;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: textSec, fontSize: 11)),
      ],
    );
  }
}
