// lib/features/calendar/presentation/screens/date_converter_screen.dart
// ─────────────────────────────────────────────────────────────────────────────
// DateConverterScreen — Interactive three-way date converter.
// Changing any of the three calendar pickers instantly recalculates
// and shows the equivalent dates in the other two systems in real time.
//
// Calendars supported:
//   1. Gregorian  — standard Dart DateTime picker
//   2. Hijri       — year / month / day spinners (1 – 1600 AH)
//   3. Ethiopian   — year / month / day spinners (using EthiopianCalendarHelper)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ethiopian_calendar.dart';
import '../../../../theme_notifier.dart';
import '../controllers/calendar_controller.dart';

class DateConverterScreen extends StatefulWidget {
  const DateConverterScreen({super.key});

  @override
  State<DateConverterScreen> createState() => _DateConverterScreenState();
}

class _DateConverterScreenState extends State<DateConverterScreen>
    with TickerProviderStateMixin {
  final CalendarController _ctrl = CalendarController();

  // ── Gregorian fields ───────────────────────────────────────────────────────
  late DateTime _greg;
  late TextEditingController _gregDay, _gregMonth, _gregYear;

  // ── Hijri fields ───────────────────────────────────────────────────────────
  late HijriCalendar _hijri;
  late TextEditingController _hijriDay, _hijriMonth, _hijriYear;

  // ── Ethiopian fields ───────────────────────────────────────────────────────
  late EthiopianDate _eth;
  late TextEditingController _ethDay, _ethMonth, _ethYear;

  // active source
  _CalSource _active = _CalSource.gregorian;

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _greg  = DateTime.now();
    _hijri = _ctrl.current.hijri;
    _eth   = _ctrl.current.ethiopian;

    _greg  = _ctrl.current.gregorian;
    _initControllers();
  }

  void _initControllers() {
    _gregDay   = TextEditingController(text: '${_greg.day}');
    _gregMonth = TextEditingController(text: '${_greg.month}');
    _gregYear  = TextEditingController(text: '${_greg.year}');

    _hijriDay   = TextEditingController(text: '${_hijri.hDay}');
    _hijriMonth = TextEditingController(text: '${_hijri.hMonth}');
    _hijriYear  = TextEditingController(text: '${_hijri.hYear}');

    _ethDay   = TextEditingController(text: '${_eth.day}');
    _ethMonth = TextEditingController(text: '${_eth.month}');
    _ethYear  = TextEditingController(text: '${_eth.year}');
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    for (final c in [
      _gregDay, _gregMonth, _gregYear,
      _hijriDay, _hijriMonth, _hijriYear,
      _ethDay, _ethMonth, _ethYear,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Conversion ─────────────────────────────────────────────────────────────

  void _convertFromGregorian() {
    try {
      final d = int.parse(_gregDay.text.trim());
      final m = int.parse(_gregMonth.text.trim());
      final y = int.parse(_gregYear.text.trim());
      final date = DateTime(y, m.clamp(1, 12), d.clamp(1, 31));
      _ctrl.convertToAll(date);
      _greg  = _ctrl.current.gregorian;
      _hijri = _ctrl.current.hijri;
      _eth   = _ctrl.current.ethiopian;
      _updateOthersFromGreg();
      _pulse();
    } catch (_) {}
  }

  void _convertFromHijri() {
    try {
      final d = int.parse(_hijriDay.text.trim());
      final m = int.parse(_hijriMonth.text.trim());
      final y = int.parse(_hijriYear.text.trim());
      final h = HijriCalendar()
        ..hDay   = d.clamp(1, 30)
        ..hMonth = m.clamp(1, 12)
        ..hYear  = y;
      final greg = h.hijriToGregorian(y, m.clamp(1, 12), d.clamp(1, 30));
      _ctrl.convertToAll(greg);
      _greg  = _ctrl.current.gregorian;
      _hijri = _ctrl.current.hijri;
      _eth   = _ctrl.current.ethiopian;
      _updateOthersFromHijri();
      _pulse();
    } catch (_) {}
  }

  void _convertFromEthiopian() {
    try {
      final d = int.parse(_ethDay.text.trim());
      final m = int.parse(_ethMonth.text.trim());
      final y = int.parse(_ethYear.text.trim());
      final ethDate = EthiopianDate(
        year:  y,
        month: m.clamp(1, 13),
        day:   d.clamp(1, 30),
      );
      final greg = EthiopianCalendarHelper.toGregorian(ethDate);
      _ctrl.convertToAll(greg);
      _greg  = _ctrl.current.gregorian;
      _hijri = _ctrl.current.hijri;
      _eth   = _ctrl.current.ethiopian;
      _updateOthersFromEth();
      _pulse();
    } catch (_) {}
  }

  void _updateOthersFromGreg() {
    _hijriDay.text   = '${_hijri.hDay}';
    _hijriMonth.text = '${_hijri.hMonth}';
    _hijriYear.text  = '${_hijri.hYear}';
    _ethDay.text     = '${_eth.day}';
    _ethMonth.text   = '${_eth.month}';
    _ethYear.text    = '${_eth.year}';
  }

  void _updateOthersFromHijri() {
    _gregDay.text   = '${_greg.day}';
    _gregMonth.text = '${_greg.month}';
    _gregYear.text  = '${_greg.year}';
    _ethDay.text    = '${_eth.day}';
    _ethMonth.text  = '${_eth.month}';
    _ethYear.text   = '${_eth.year}';
  }

  void _updateOthersFromEth() {
    _gregDay.text    = '${_greg.day}';
    _gregMonth.text  = '${_greg.month}';
    _gregYear.text   = '${_greg.year}';
    _hijriDay.text   = '${_hijri.hDay}';
    _hijriMonth.text = '${_hijri.hMonth}';
    _hijriYear.text  = '${_hijri.hYear}';
  }

  void _pulse() {
    _pulseCtrl.forward(from: 0.0);
    setState(() {});
  }

  // ── Date picker shortcuts ─────────────────────────────────────────────────

  Future<void> _pickGregorianDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _greg,
      firstDate: DateTime(622),
      lastDate: DateTime(2200),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary:   AppColors.emeraldLight,
            onPrimary: Colors.white,
            surface:   AppColors.surfaceCard,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _gregDay.text   = '${picked.day}';
      _gregMonth.text = '${picked.month}';
      _gregYear.text  = '${picked.year}';
      _active = _CalSource.gregorian;
      _convertFromGregorian();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark  = AppTheme.notifier.value == QuranTheme.dark;
    final bg      = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textPri = isDark ? AppColors.textPrimary  : Colors.black87;
    final locale  = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    final isRtl   = locale == 'ar';

    return Directionality(
      textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.surfaceCard : Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            _title(locale),
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
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ── Result summary banner ─────────────────────────────────────
                    _ResultBanner(ctrl: _ctrl, isDark: isDark, locale: locale),

                    const SizedBox(height: 8),

                    // ── Gregorian picker ──────────────────────────────────────────
                    _CalendarCard(
                      label:     _gregLabel(locale),
                      icon:      Icons.calendar_today_rounded,
                      accentColor: const Color(0xFF1565C0),
                      isActive:  _active == _CalSource.gregorian,
                      isDark:    isDark,
                      onActivate: () => setState(() => _active = _CalSource.gregorian),
                      content: Column(
                        children: [
                          _DayMonthYearRow(
                            dayCtrl:   _gregDay,
                            monthCtrl: _gregMonth,
                            yearCtrl:  _gregYear,
                            isDark:    isDark,
                            maxDay:    31,
                            maxMonth:  12,
                            onChanged: () {
                              _active = _CalSource.gregorian;
                              _convertFromGregorian();
                            },
                          ),
                          const SizedBox(height: 4),
                          TextButton.icon(
                            onPressed: _pickGregorianDate,
                            icon: const Icon(Icons.date_range_rounded,
                                color: Color(0xFF1565C0), size: 18),
                            label: Text(
                              _pickLabel(locale),
                              style: const TextStyle(color: Color(0xFF1565C0)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ── Arrows decoration ────────────────────────────────────────
                    Center(
                      child: AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Opacity(
                          opacity:
                              (0.4 + 0.6 * (1 - _pulseCtrl.value)).clamp(0.4, 1.0),
                          child: const Icon(
                            Icons.swap_vert_circle_rounded,
                            color: AppColors.emeraldLight,
                            size: 30,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ── Hijri picker ──────────────────────────────────────────────
                    _CalendarCard(
                      label:     _hijriLabel(locale),
                      icon:      Icons.brightness_3_rounded,
                      accentColor: AppColors.goldMid,
                      isActive:  _active == _CalSource.hijri,
                      isDark:    isDark,
                      onActivate: () => setState(() => _active = _CalSource.hijri),
                      content: _DayMonthYearRow(
                        dayCtrl:   _hijriDay,
                        monthCtrl: _hijriMonth,
                        yearCtrl:  _hijriYear,
                        isDark:    isDark,
                        maxDay:    30,
                        maxMonth:  12,
                        onChanged: () {
                          _active = _CalSource.hijri;
                          _convertFromHijri();
                        },
                      ),
                    ),

                    const SizedBox(height: 6),

                    // ── Ethiopian picker ──────────────────────────────────────────
                    _CalendarCard(
                      label:     _ethLabel(locale),
                      icon:      Icons.wb_sunny_rounded,
                      accentColor: const Color(0xFFDD2C00),
                      isActive:  _active == _CalSource.ethiopian,
                      isDark:    isDark,
                      onActivate: () => setState(() => _active = _CalSource.ethiopian),
                      content: _DayMonthYearRow(
                        dayCtrl:   _ethDay,
                        monthCtrl: _ethMonth,
                        yearCtrl:  _ethYear,
                        isDark:    isDark,
                        maxDay:    30,
                        maxMonth:  13,
                        onChanged: () {
                          _active = _CalSource.ethiopian;
                          _convertFromEthiopian();
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    // ── Convert button ────────────────────────────────────────────
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emeraldMid,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.compare_arrows_rounded),
                        label: Text(
                          _convertLabel(locale),
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        onPressed: () {
                          switch (_active) {
                            case _CalSource.gregorian:
                              _convertFromGregorian();
                              break;
                            case _CalSource.hijri:
                              _convertFromHijri();
                              break;
                            case _CalSource.ethiopian:
                              _convertFromEthiopian();
                              break;
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Localized labels ───────────────────────────────────────────────────────

  String _title(String l) => switch (l) {
        'ar' => 'تحويل التاريخ',
        'am' => 'ቀን መቀያየሪያ',
        'om' => 'Jijiirraa Guyyaa',
        _    => 'Date Converter',
      };

  String _gregLabel(String l) => switch (l) {
        'ar' => 'الميلادي (غريغوري)',
        'am' => 'ግሪጎሪያን ቀን አቆጣጠር',
        'om' => 'Gregorian',
        _    => 'Gregorian Calendar',
      };

  String _hijriLabel(String l) => switch (l) {
        'ar' => 'التقويم الهجري',
        'am' => 'ሂጅሪ ቀን አቆጣጠር',
        'om' => 'Kalandara Hijraa',
        _    => 'Hijri Calendar',
      };

  String _ethLabel(String l) => switch (l) {
        'ar' => 'التقويم الإثيوبي',
        'am' => 'የኢትዮጵያ ቀን አቆጣጠር',
        'om' => 'Kalandara Itoophiyaa',
        _    => 'Ethiopian Calendar',
      };

  String _pickLabel(String l) => switch (l) {
        'ar' => 'اختر من التقويم',
        'am' => 'ቀን ምረጥ',
        _    => 'Pick from Calendar',
      };

  String _convertLabel(String l) => switch (l) {
        'ar' => 'تحويل التاريخ',
        'am' => 'ቀን ቀይር',
        'om' => 'Jijjiiri',
        _    => 'Convert Date',
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

enum _CalSource { gregorian, hijri, ethiopian }

class _ResultBanner extends StatelessWidget {
  const _ResultBanner({
    required this.ctrl,
    required this.isDark,
    required this.locale,
  });
  final CalendarController ctrl;
  final bool isDark;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final td = ctrl.current;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0D2B3E), const Color(0xFF162A3A)]
              : [const Color(0xFFE8F5E9), const Color(0xFFF1F8E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.emeraldLight.withValues(alpha: 0.30),
          width: 1.3,
        ),
      ),
      child: Column(
        children: [
          _ResultRow(
            icon:  Icons.calendar_today_rounded,
            color: const Color(0xFF1565C0),
            label: td.formattedGregorian(locale: locale),
            isDark: isDark,
          ),
          const Divider(height: 16, thickness: 0.5),
          _ResultRow(
            icon:  Icons.brightness_3_rounded,
            color: AppColors.goldMid,
            label: td.formattedHijri(locale: locale),
            isDark: isDark,
          ),
          const Divider(height: 16, thickness: 0.5),
          _ResultRow(
            icon:  Icons.wb_sunny_rounded,
            color: const Color(0xFFDD2C00),
            label: td.formattedEthiopian(locale: locale),
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.isDark,
  });
  final IconData icon;
  final Color color;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.textPrimary : Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({
    required this.label,
    required this.icon,
    required this.accentColor,
    required this.isActive,
    required this.isDark,
    required this.onActivate,
    required this.content,
  });

  final String   label;
  final IconData icon;
  final Color    accentColor;
  final bool     isActive;
  final bool     isDark;
  final VoidCallback onActivate;
  final Widget   content;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceCard : AppColors.surfaceCardLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? accentColor
              : (isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08)),
          width: isActive ? 2.0 : 1.0,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onActivate,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: accentColor, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textPrimary
                            : Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(
                            color: accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                content,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayMonthYearRow extends StatelessWidget {
  const _DayMonthYearRow({
    required this.dayCtrl,
    required this.monthCtrl,
    required this.yearCtrl,
    required this.isDark,
    required this.maxDay,
    required this.maxMonth,
    required this.onChanged,
  });

  final TextEditingController dayCtrl;
  final TextEditingController monthCtrl;
  final TextEditingController yearCtrl;
  final bool isDark;
  final int  maxDay;
  final int  maxMonth;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _NumField(
            ctrl:      dayCtrl,
            hint:      'DD',
            max:       maxDay,
            isDark:    isDark,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _NumField(
            ctrl:      monthCtrl,
            hint:      'MM',
            max:       maxMonth,
            isDark:    isDark,
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _NumField(
            ctrl:      yearCtrl,
            hint:      'YYYY',
            max:       9999,
            isDark:    isDark,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({
    required this.ctrl,
    required this.hint,
    required this.max,
    required this.isDark,
    required this.onChanged,
  });

  final TextEditingController ctrl;
  final String hint;
  final int    max;
  final bool   isDark;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      textAlign: TextAlign.center,
      style: TextStyle(
        color:      isDark ? AppColors.textPrimary : Colors.black87,
        fontWeight: FontWeight.w700,
        fontSize:   15,
      ),
      decoration: InputDecoration(
        hintText:        hint,
        hintStyle:       TextStyle(
          color: isDark ? AppColors.textMuted : Colors.black38,
        ),
        filled:      true,
        fillColor:   isDark
            ? AppColors.surfaceElevated
            : const Color(0xFFF0F4F2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:   BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      ),
      onChanged: (_) => onChanged(),
    );
  }
}
