// lib/features/calendar/presentation/controllers/calendar_controller.dart
// ─────────────────────────────────────────────────────────────────────────────
// CalendarController — Unified three-calendar controller (Gregorian, Hijri,
// Ethiopian). Exposes formatted display strings and a conversion method so
// that changing one calendar system immediately recalculates the other two.
//
// The controller reads `hijriOffset` from SharedPreferences (set by the user
// in Prayer-times settings) to keep Hijri dates consistent app-wide.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/ethiopian_calendar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data holder returned by conversions
// ─────────────────────────────────────────────────────────────────────────────

class TripleDate {
  const TripleDate({
    required this.gregorian,
    required this.hijri,
    required this.ethiopian,
  });

  /// The base Gregorian date.
  final DateTime gregorian;

  /// Hijri date (with user's offset already applied).
  final HijriCalendar hijri;

  /// Ethiopian Ge'ez date.
  final EthiopianDate ethiopian;

  // ── Formatted display strings ──────────────────────────────────────────────

  String formattedGregorian({String locale = 'en'}) =>
      DateFormat('d MMMM yyyy', locale == 'ar' ? 'en' : locale)
          .format(gregorian);

  String formattedHijri({String locale = 'en'}) {
    final day   = hijri.hDay;
    final month = _hijriMonthName(hijri.hMonth, locale);
    final year  = hijri.hYear;
    final era   = locale == 'ar' ? 'هـ' : 'AH';
    return '$day $month $year $era';
  }

  String formattedEthiopian({String locale = 'en'}) =>
      ethiopian.formatted(amharic: locale == 'am' || locale == 'ar');

  // Arabic/Amharic Hijri month names
  static String _hijriMonthName(int month, String locale) {
    const en = [
      'Muharram', 'Safar', 'Rabi\' I', 'Rabi\' II',
      'Jumada I', 'Jumada II', 'Rajab', 'Sha\'ban',
      'Ramadan', 'Shawwal', 'Dhu al-Qi\'dah', 'Dhu al-Hijjah',
    ];
    const ar = [
      'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر',
      'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان',
      'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
    ];
    const am = [
      'ሙሐረም', 'ሶፈር', 'ረቢዐ አወል', 'ረቢዐ ሣኒ',
      'ጀማድ አወል', 'ጀማድ ሣኒ', 'ረጀብ', 'ሸዕባን',
      'ረመዷን', 'ሸዋል', 'ዙልቀዳ', 'ዙልሒጃ',
    ];
    final idx = (month - 1).clamp(0, 11);
    if (locale == 'ar') return ar[idx];
    if (locale == 'am' || locale == 'om') return am[idx];
    return en[idx];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CalendarController
// ─────────────────────────────────────────────────────────────────────────────

class CalendarController extends ChangeNotifier {
  // Singleton so all screens share the same state.
  static final CalendarController _instance = CalendarController._internal();
  factory CalendarController() => _instance;
  CalendarController._internal() {
    _current = _compute(_selectedGregorian);
    _init();
  }

  // ── State ──────────────────────────────────────────────────────────────────

  DateTime _selectedGregorian = DateTime.now();
  int      _hijriOffset       = 0;
  bool     _isLoading         = true;

  DateTime get selectedGregorian => _selectedGregorian;
  int      get hijriOffset       => _hijriOffset;
  bool     get isLoading         => _isLoading;

  late TripleDate _current;
  TripleDate get current => _current;

  // ── Initialisation ─────────────────────────────────────────────────────────

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _hijriOffset = prefs.getInt('hijri_offset') ?? 0;
    _selectedGregorian = DateTime.now();
    _current = _compute(_selectedGregorian);
    _isLoading = false;
    notifyListeners();
  }

  // ── Core conversion ────────────────────────────────────────────────────────

  /// Converts any Gregorian [date] into the corresponding Hijri + Ethiopian
  /// dates and stores the result as [current].
  void convertToAll(DateTime date) {
    _selectedGregorian = DateTime(date.year, date.month, date.day);
    _current = _compute(_selectedGregorian);
    notifyListeners();
  }

  TripleDate _compute(DateTime gregorian) {
    final adjustedForHijri = gregorian.add(Duration(days: _hijriOffset));
    final hijri = HijriCalendar.fromDate(adjustedForHijri);
    final ethiopian = EthiopianCalendarHelper.fromGregorian(gregorian);
    return TripleDate(
      gregorian:  gregorian,
      hijri:      hijri,
      ethiopian:  ethiopian,
    );
  }

  // ── Navigate calendar pages ─────────────────────────────────────────────────

  /// Moves the selected date forward or backward by [months] months.
  void shiftMonth(int months) {
    final d = _selectedGregorian;
    final newDate = DateTime(d.year, d.month + months, 1);
    _selectedGregorian = newDate;
    _current = _compute(newDate);
    notifyListeners();
  }

  /// Resets to today.
  void goToToday() {
    _selectedGregorian = DateTime.now();
    _current = _compute(_selectedGregorian);
    notifyListeners();
  }

  // ── Persist hijriOffset changes ────────────────────────────────────────────

  Future<void> setHijriOffset(int offset) async {
    _hijriOffset = offset;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('hijri_offset', offset);
    _current = _compute(_selectedGregorian);
    notifyListeners();
  }

  // ── Month grid helper ───────────────────────────────────────────────────────

  /// Returns every day in the month containing [base], padded to full weeks.
  List<DateTime?> buildMonthGrid(DateTime base) {
    final first = DateTime(base.year, base.month, 1);
    final lastDay = DateTime(base.year, base.month + 1, 0).day;

    // Monday = 0 offset
    final startPad = (first.weekday - 1) % 7;
    final cells = <DateTime?>[];
    for (int i = 0; i < startPad; i++) {
      cells.add(null);
    }
    for (int d = 1; d <= lastDay; d++) {
      cells.add(DateTime(base.year, base.month, d));
    }
    // Pad trailing
    while (cells.length % 7 != 0) {
      cells.add(null);
    }
    return cells;
  }

  /// Returns the Hijri day label for a given Gregorian date (for the grid).
  String hijriDayLabel(DateTime date) {
    final adjusted = date.add(Duration(days: _hijriOffset));
    final h = HijriCalendar.fromDate(adjusted);
    return '${h.hDay}';
  }

  /// Returns the Ethiopian day label for a given Gregorian date (for the grid).
  String ethiopianDayLabel(DateTime date) {
    final eth = EthiopianCalendarHelper.fromGregorian(date);
    return '${eth.day}';
  }
}
