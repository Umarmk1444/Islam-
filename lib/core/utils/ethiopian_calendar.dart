// lib/core/utils/ethiopian_calendar.dart
// ─────────────────────────────────────────────────────────────────────────────
// EthiopianCalendarHelper — Lightweight offline conversion for the Ethiopian
// (Ge'ez / Ethiopic) calendar.
//
// The Ethiopian calendar has 13 months:
//   • 12 ordinary months of exactly 30 days each
//   • 1 intercalary month (Pagume/Pagumē) with 5 days (6 days in a leap year)
//
// The Ethiopian calendar is approximately 7 years and 8-9 months behind the
// Gregorian calendar. Year 1 of the Ethiopian calendar corresponds to the
// Incarnation Era (Amete Alem or Amete Mihret dating).
//
// Algorithm reference: Julian Day Number conversion method.
// ─────────────────────────────────────────────────────────────────────────────

class EthiopianDate {
  const EthiopianDate({
    required this.year,
    required this.month,
    required this.day,
  });

  final int year;
  final int month;
  final int day;

  /// Month names in Amharic (Ethiopic script).
  static const List<String> monthNamesAm = [
    'መስከረም', // 1 — Meskerem
    'ጥቅምት',   // 2 — Tikimt
    'ህዳር',    // 3 — Hidar
    'ታህሳስ',   // 4 — Tahsas
    'ጥር',     // 5 — Tir
    'የካቲት',   // 6 — Yekatit
    'መጋቢት',   // 7 — Megabit
    'ሚያዚያ',   // 8 — Miyazia
    'ግንቦት',   // 9 — Ginbot
    'ሰኔ',     // 10 — Sene
    'ሐምሌ',    // 11 — Hamle
    'ነሐሴ',    // 12 — Nehase
    'ጳጉሜ',   // 13 — Pagume
  ];

  /// Month names in English transliteration.
  static const List<String> monthNamesEn = [
    'Meskerem',
    'Tikimt',
    'Hidar',
    'Tahsas',
    'Tir',
    'Yekatit',
    'Megabit',
    'Miyazia',
    'Ginbot',
    'Sene',
    'Hamle',
    'Nehase',
    'Pagume',
  ];

  /// Returns the full formatted date string.
  ///
  /// Example (Amharic): "17 ጥቅምት 2017 ዓ.ም"
  /// Example (English): "17 Tikimt 2017 EC"
  String formatted({bool amharic = true}) {
    final monthName = amharic
        ? monthNamesAm[month.clamp(1, 13) - 1]
        : monthNamesEn[month.clamp(1, 13) - 1];
    final era = amharic ? 'ዓ.ም' : 'EC';
    return '$day $monthName $year $era';
  }

  @override
  String toString() => formatted(amharic: false);
}

/// Converts between Gregorian (DateTime) and Ethiopian calendar.
class EthiopianCalendarHelper {
  EthiopianCalendarHelper._();

  // ── Julian Day Number helpers ──────────────────────────────────────────────

  /// Converts a Gregorian calendar date to a Julian Day Number.
  static int _gregorianToJDN(int year, int month, int day) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
  }

  /// Converts a Julian Day Number to an Ethiopian date.
  ///
  /// The Ethiopic epoch (1 Meskerem 1 EC) in Julian Day Number is 1724221.
  static EthiopianDate _jdnToEthiopian(int jdn) {
    const int jdnEpoch = 1724221; // JDN of 1 Meskerem 1 EC
    final r = jdn - jdnEpoch;
    final n = r % 1461; // days within a 4-year cycle
    final year = 4 * (r ~/ 1461) + n ~/ 365;
    final dayOfYear = n % 365;
    final month = dayOfYear ~/ 30 + 1;
    final day = dayOfYear % 30 + 1;

    // Clamp to valid values
    return EthiopianDate(
      year:  year,
      month: month.clamp(1, 13),
      day:   day.clamp(1, 30),
    );
  }

  /// Converts an Ethiopian date back to a Julian Day Number.
  static int _ethiopianToJDN(int year, int month, int day) {
    const int jdnEpoch = 1724221;
    return jdnEpoch +
        365 * year +
        year ~/ 4 +
        30 * (month - 1) +
        day -
        1;
  }

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Converts a Dart [DateTime] (Gregorian) to an [EthiopianDate].
  static EthiopianDate fromGregorian(DateTime date) {
    final jdn = _gregorianToJDN(date.year, date.month, date.day);
    return _jdnToEthiopian(jdn);
  }

  /// Converts an [EthiopianDate] to a Dart [DateTime] (Gregorian).
  static DateTime toGregorian(EthiopianDate eth) {
    final jdn = _ethiopianToJDN(eth.year, eth.month, eth.day);
    // Convert JDN to Gregorian
    final a = jdn + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - (146097 * b) ~/ 4;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - (1461 * d) ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    final day   = e - (153 * m + 2) ~/ 5 + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year  = 100 * b + d - 4800 + m ~/ 10;
    return DateTime(year, month, day);
  }

  /// Returns the number of days in an Ethiopian month.
  /// Months 1-12 always have 30 days.
  /// Month 13 (Pagume) has 5 days, or 6 in a leap year.
  static int daysInMonth(int year, int month) {
    if (month < 13) return 30;
    // Ethiopian leap year: year % 4 == 3
    return (year % 4 == 3) ? 6 : 5;
  }

  /// Returns true if the given Ethiopian year is a leap year.
  static bool isLeapYear(int year) => year % 4 == 3;
}
