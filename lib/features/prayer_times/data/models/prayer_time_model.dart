import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

/// The five canonical daily prayers plus special night-time segments.
enum PrayerName {
  fajr,
  sunrise,   // Shuruq — not a prayer, but a key Miqat boundary
  duha,      // Optional — displayed as a card section
  dhuhr,
  asr,
  maghrib,
  isha,
  tahajjud,  // Last-third-of-the-night marker (derived, not fetched from API)
}

/// The broad segment of the day used to contextualise UI gradients and Azkar.
enum DaySegment {
  lastThirdNight, // ~1:30 AM → Fajr
  fajr,           // Fajr → Sunrise
  morning,        // Sunrise → Dhuhr
  afternoon,      // Dhuhr → Asr
  evening,        // Asr → Maghrib
  night,          // Maghrib → Isha
  lateNight,      // Isha → last third
}

/// Alert/notification mode per prayer.
enum PrayerAlertMode {
  silent,     // no alert
  adhan,      // play full adhan
  beep,       // short beep
  notification, // system notification only
}

// ─────────────────────────────────────────────────────────────────────────────
// PrayerTimeEntry — a single prayer slot
// ─────────────────────────────────────────────────────────────────────────────

/// Represents one individual prayer entry within a daily schedule.
class PrayerTimeEntry {
  const PrayerTimeEntry({
    required this.prayer,
    required this.time,
    this.alertMode = PrayerAlertMode.adhan,
    this.isAutoSilentEnabled = false,
    this.autoSilentDurationMinutes = 15,
  });

  final PrayerName prayer;

  /// Scheduled time for this prayer (date component is today's date).
  final DateTime time;

  /// How the user wants to be notified for this prayer.
  final PrayerAlertMode alertMode;

  /// If true, the phone ringer is silenced automatically at prayer time
  /// and restored after [autoSilentDurationMinutes].
  final bool isAutoSilentEnabled;
  final int autoSilentDurationMinutes;

  PrayerTimeEntry copyWith({
    PrayerName? prayer,
    DateTime? time,
    PrayerAlertMode? alertMode,
    bool? isAutoSilentEnabled,
    int? autoSilentDurationMinutes,
  }) {
    return PrayerTimeEntry(
      prayer: prayer ?? this.prayer,
      time: time ?? this.time,
      alertMode: alertMode ?? this.alertMode,
      isAutoSilentEnabled: isAutoSilentEnabled ?? this.isAutoSilentEnabled,
      autoSilentDurationMinutes:
          autoSilentDurationMinutes ?? this.autoSilentDurationMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'prayer': prayer.name,
        'time': time.toIso8601String(),
        'alertMode': alertMode.name,
        'isAutoSilentEnabled': isAutoSilentEnabled,
        'autoSilentDurationMinutes': autoSilentDurationMinutes,
      };

  factory PrayerTimeEntry.fromJson(Map<String, dynamic> json) {
    return PrayerTimeEntry(
      prayer: PrayerName.values.byName(json['prayer'] as String),
      time: DateTime.parse(json['time'] as String),
      alertMode: PrayerAlertMode.values
          .byName(json['alertMode'] as String? ?? 'adhan'),
      isAutoSilentEnabled:
          json['isAutoSilentEnabled'] as bool? ?? false,
      autoSilentDurationMinutes:
          json['autoSilentDurationMinutes'] as int? ?? 15,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HijriDate — lightweight Hijri calendar value
// ─────────────────────────────────────────────────────────────────────────────

/// Minimal Hijri date container.
/// Full conversion logic lives in `core/utils/hijri_date_helper.dart`.
class HijriDate {
  const HijriDate({
    required this.year,
    required this.month,
    required this.day,
    required this.monthNameAr,
    required this.monthNameEn,
  });

  final int year;
  final int month;
  final int day;
  final String monthNameAr;
  final String monthNameEn;

  String get formattedAr => '$day $monthNameAr $year هـ';
  String get formattedEn => '$day $monthNameEn $year AH';

  Map<String, dynamic> toJson() => {
        'year': year,
        'month': month,
        'day': day,
        'monthNameAr': monthNameAr,
        'monthNameEn': monthNameEn,
      };

  factory HijriDate.fromJson(Map<String, dynamic> json) => HijriDate(
        year: json['year'] as int,
        month: json['month'] as int,
        day: json['day'] as int,
        monthNameAr: json['monthNameAr'] as String,
        monthNameEn: json['monthNameEn'] as String,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// PrayerTimeModel — full daily schedule (the main data model)
// ─────────────────────────────────────────────────────────────────────────────

/// Complete daily prayer schedule used throughout the app.
///
/// Contains:
/// - All five prayers + Sunrise, Duha and Tahajjud markers.
/// - Today's Gregorian and Hijri dates.
/// - The currently active [DaySegment] for contextual UI rendering.
/// - The next upcoming prayer for the Miqat countdown card.
///
/// This model is **immutable** — use [copyWith] to derive state.
class PrayerTimeModel {
  const PrayerTimeModel({
    required this.date,
    required this.hijriDate,
    required this.locationLabel,
    required this.latitude,
    required this.longitude,
    required this.entries,
    required this.daySegment,
    required this.nextPrayer,
    required this.calculationMethod,
    this.qiblaDirection = 0.0,
  });

  /// Gregorian date this schedule is for.
  final DateTime date;

  /// Corresponding Hijri date.
  final HijriDate hijriDate;

  /// Human-readable city/locality name displayed on the Miqat card.
  final String locationLabel;

  final double latitude;
  final double longitude;

  /// Ordered list of [PrayerTimeEntry] for this day.
  /// Typical length: 8 (Fajr, Sunrise, Duha, Dhuhr, Asr, Maghrib, Isha, Tahajjud).
  final List<PrayerTimeEntry> entries;

  /// The day segment derived from the current time — drives gradient & Azkar.
  final DaySegment daySegment;

  /// The next prayer whose countdown is shown in the Miqat card.
  final PrayerTimeEntry nextPrayer;

  /// e.g. "MWL", "ISNA", "Egypt", "Umm al-Qura".
  final String calculationMethod;

  /// Degrees from True North toward Kaaba — used by QiblaScreen.
  final double qiblaDirection;

  // ── Derived helpers ────────────────────────────────────────────────────────

  /// Returns the [PrayerTimeEntry] with the given [name], or null.
  PrayerTimeEntry? entryFor(PrayerName name) {
    for (final e in entries) {
      if (e.prayer == name) return e;
    }
    return null;
  }

  /// Duration remaining until the [nextPrayer].
  Duration get countdownDuration {
    final now = DateTime.now();
    return nextPrayer.time.difference(now);
  }

  /// Gradient to use on the Miqat card based on [daySegment].
  List<Color> get miqatGradientColors {
    switch (daySegment) {
      case DaySegment.lastThirdNight:
      case DaySegment.lateNight:
        return const [Color(0xFF0D1B2A), Color(0xFF1A2A4A)];
      case DaySegment.fajr:
        return const [Color(0xFF1B263B), Color(0xFF3A1C71)];
      case DaySegment.morning:
        return const [Color(0xFF7B2D00), Color(0xFFFF8C42)];
      case DaySegment.afternoon:
        return const [Color(0xFF0D4F3C), Color(0xFF1A7A5E)];
      case DaySegment.evening:
        return const [Color(0xFF6B1F3E), Color(0xFFEF476F)];
      case DaySegment.night:
        return const [Color(0xFF2D1B69), Color(0xFF8B5CF6)];
    }
  }

  PrayerTimeModel copyWith({
    DateTime? date,
    HijriDate? hijriDate,
    String? locationLabel,
    double? latitude,
    double? longitude,
    List<PrayerTimeEntry>? entries,
    DaySegment? daySegment,
    PrayerTimeEntry? nextPrayer,
    String? calculationMethod,
    double? qiblaDirection,
  }) {
    return PrayerTimeModel(
      date: date ?? this.date,
      hijriDate: hijriDate ?? this.hijriDate,
      locationLabel: locationLabel ?? this.locationLabel,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      entries: entries ?? this.entries,
      daySegment: daySegment ?? this.daySegment,
      nextPrayer: nextPrayer ?? this.nextPrayer,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      qiblaDirection: qiblaDirection ?? this.qiblaDirection,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'hijriDate': hijriDate.toJson(),
        'locationLabel': locationLabel,
        'latitude': latitude,
        'longitude': longitude,
        'entries': entries.map((e) => e.toJson()).toList(),
        'daySegment': daySegment.name,
        'nextPrayer': nextPrayer.toJson(),
        'calculationMethod': calculationMethod,
        'qiblaDirection': qiblaDirection,
      };

  factory PrayerTimeModel.fromJson(Map<String, dynamic> json) {
    final rawEntries = json['entries'] as List<dynamic>? ?? [];
    final entries = rawEntries
        .map((e) => PrayerTimeEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    final nextPrayerJson =
        json['nextPrayer'] as Map<String, dynamic>? ?? rawEntries.first;
    return PrayerTimeModel(
      date: DateTime.parse(json['date'] as String),
      hijriDate:
          HijriDate.fromJson(json['hijriDate'] as Map<String, dynamic>),
      locationLabel: json['locationLabel'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      entries: entries,
      daySegment:
          DaySegment.values.byName(json['daySegment'] as String? ?? 'afternoon'),
      nextPrayer: PrayerTimeEntry.fromJson(
          nextPrayerJson is Map<String, dynamic>
              ? nextPrayerJson
              : entries.first.toJson()),
      calculationMethod: json['calculationMethod'] as String? ?? 'MWL',
      qiblaDirection: (json['qiblaDirection'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() =>
      'PrayerTimeModel(date: $date, next: ${nextPrayer.prayer.name}, '
      'segment: ${daySegment.name}, location: $locationLabel)';
}
