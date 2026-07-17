// lib/features/prayer_times/data/models/prayer_config.dart
// ─────────────────────────────────────────────────────────────────────────────
// PrayerConfig — persistent user preferences for the prayer-times feature.
//
// Stored in SharedPreferences as a JSON-encoded string under the key
// 'prayer_config_v1'. Created fresh with sensible defaults on first launch.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:convert';

// ── Calculation Method ────────────────────────────────────────────────────────

/// The astronomical/juristic rulesets supported by the adhan package.
enum CalculationMethodEnum {
  ummAlQura,   // Umm al-Qura University, Makkah (default for Arabia)
  egyptian,    // Egyptian General Authority of Survey
  mwl,         // Muslim World League
  isna,        // Islamic Society of North America
  karachi,     // University of Islamic Sciences, Karachi
}

extension CalculationMethodEnumExt on CalculationMethodEnum {
  /// Short label used in SharedPreferences serialization.
  String get key => name;

  /// Human-readable label for the UI (English).
  String get labelEn {
    switch (this) {
      case CalculationMethodEnum.ummAlQura:  return 'Umm al-Qura';
      case CalculationMethodEnum.egyptian:   return 'Egyptian';
      case CalculationMethodEnum.mwl:        return 'Muslim World League';
      case CalculationMethodEnum.isna:       return 'ISNA';
      case CalculationMethodEnum.karachi:    return 'Karachi';
    }
  }

  /// Arabic label for the UI.
  String get labelAr {
    switch (this) {
      case CalculationMethodEnum.ummAlQura:  return 'أم القرى';
      case CalculationMethodEnum.egyptian:   return 'الهيئة المصرية';
      case CalculationMethodEnum.mwl:        return 'رابطة العالم الإسلامي';
      case CalculationMethodEnum.isna:       return 'ISNA';
      case CalculationMethodEnum.karachi:    return 'كراتشي';
    }
  }
}

// ── Madhab ────────────────────────────────────────────────────────────────────

/// Juristic school affecting Asr calculation timing.
enum MadhabEnum {
  shafi,   // Standard — shadow length 1× (majority position)
  hanafi,  // Shadow length 2× (longer Asr)
}

extension MadhabEnumExt on MadhabEnum {
  String get key => name;
  String get labelEn => this == MadhabEnum.shafi ? 'Shafi / Maliki / Hanbali' : 'Hanafi';
  String get labelAr => this == MadhabEnum.shafi ? 'شافعي / مالكي / حنبلي' : 'حنفي';
}

// ── PrayerNotifConfig ─────────────────────────────────────────────────────────

/// Per-prayer notification toggle.
class PrayerNotifConfig {
  const PrayerNotifConfig({
    this.fajrEnabled    = true,
    this.sunriseEnabled = false,
    this.dhuhrEnabled   = true,
    this.asrEnabled     = true,
    this.maghribEnabled = true,
    this.ishaEnabled    = true,
  });

  final bool fajrEnabled;
  final bool sunriseEnabled;
  final bool dhuhrEnabled;
  final bool asrEnabled;
  final bool maghribEnabled;
  final bool ishaEnabled;

  PrayerNotifConfig copyWith({
    bool? fajrEnabled,
    bool? sunriseEnabled,
    bool? dhuhrEnabled,
    bool? asrEnabled,
    bool? maghribEnabled,
    bool? ishaEnabled,
  }) {
    return PrayerNotifConfig(
      fajrEnabled:    fajrEnabled    ?? this.fajrEnabled,
      sunriseEnabled: sunriseEnabled ?? this.sunriseEnabled,
      dhuhrEnabled:   dhuhrEnabled   ?? this.dhuhrEnabled,
      asrEnabled:     asrEnabled     ?? this.asrEnabled,
      maghribEnabled: maghribEnabled ?? this.maghribEnabled,
      ishaEnabled:    ishaEnabled    ?? this.ishaEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'fajr':    fajrEnabled,
    'sunrise': sunriseEnabled,
    'dhuhr':   dhuhrEnabled,
    'asr':     asrEnabled,
    'maghrib': maghribEnabled,
    'isha':    ishaEnabled,
  };

  factory PrayerNotifConfig.fromJson(Map<String, dynamic> j) =>
      PrayerNotifConfig(
        fajrEnabled:    j['fajr']    as bool? ?? true,
        sunriseEnabled: j['sunrise'] as bool? ?? false,
        dhuhrEnabled:   j['dhuhr']   as bool? ?? true,
        asrEnabled:     j['asr']     as bool? ?? true,
        maghribEnabled: j['maghrib'] as bool? ?? true,
        ishaEnabled:    j['isha']    as bool? ?? true,
      );
}

// ── PrayerConfig ──────────────────────────────────────────────────────────────

/// Top-level preference container for the prayer-times subsystem.
class PrayerConfig {
  const PrayerConfig({
    this.latitude           = 21.4225,   // Makkah al-Mukarramah (fallback)
    this.longitude          = 39.8262,
    this.locationLabel      = 'Makkah al-Mukarramah',
    this.method             = CalculationMethodEnum.ummAlQura,
    this.madhab             = MadhabEnum.shafi,
    this.notifications      = const PrayerNotifConfig(),
    this.useGps             = true,
    this.hasManualMethodOverride = false,
    this.hasManualMadhabOverride = false,
    this.is24HourFormat     = false,
    this.hijriOffset        = 0,
    this.prayerOffsets      = const {
      'fajr': 0,
      'sunrise': 0,
      'dhuhr': 0,
      'asr': 0,
      'maghrib': 0,
      'isha': 0,
    },
    this.preAthanMinutes = const {
      'fajr': 0,
      'sunrise': 0,
      'dhuhr': 0,
      'asr': 0,
      'maghrib': 0,
      'isha': 0,
    },
    this.prayerMuezzins = const {
      'fajr': 'adhan_abdulbasit',
      'sunrise': 'adhan_abdulbasit',
      'dhuhr': 'adhan_abdulbasit',
      'asr': 'adhan_abdulbasit',
      'maghrib': 'adhan_abdulbasit',
      'isha': 'adhan_abdulbasit',
    },
  });

  /// Stored coordinates — updated whenever GPS succeeds.
  final double latitude;
  final double longitude;

  /// Human-readable location name shown on the screen.
  final String locationLabel;

  /// Which calculation ruleset to apply.
  final CalculationMethodEnum method;

  /// Asr timing school.
  final MadhabEnum madhab;

  /// Per-prayer notification on/off flags.
  final PrayerNotifConfig notifications;

  /// Whether to attempt GPS on each app launch.
  final bool useGps;

  /// Whether the user manually selected the calculation method.
  final bool hasManualMethodOverride;

  /// Whether the user manually configured the Madhab.
  final bool hasManualMadhabOverride;

  /// Whether the UI displays 24-hour formats (e.g. 16:30) or 12-hour (e.g. 04:30 PM).
  final bool is24HourFormat;

  /// Current moon sighting offset in days (-2 to +2).
  final int hijriOffset;

  /// Manual minutes offset adjustment for each of the 6 prayers.
  final Map<String, int> prayerOffsets;

  /// Minutes before prayer to sound the pre-alert. 0 means disabled.
  final Map<String, int> preAthanMinutes;

  /// Selected Muezzin IDs for each of the 6 prayers
  final Map<String, String> prayerMuezzins;

  // ── SharedPreferences persistence ─────────────────────────────────────────

  static const String _prefKey = 'prayer_config_v1';

  String toJsonString() => jsonEncode({
    'latitude':      latitude,
    'longitude':     longitude,
    'locationLabel': locationLabel,
    'method':        method.key,
    'madhab':        madhab.key,
    'notifications': notifications.toJson(),
    'useGps':        useGps,
    'hasManualMethodOverride': hasManualMethodOverride,
    'hasManualMadhabOverride': hasManualMadhabOverride,
    'is24HourFormat': is24HourFormat,
    'hijriOffset':    hijriOffset,
    'prayerOffsets':  prayerOffsets,
    'preAthanMinutes': preAthanMinutes,
    'prayerMuezzins': prayerMuezzins,
  });

  factory PrayerConfig.fromJsonString(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    
    final rawOffsets = j['prayerOffsets'] as Map<String, dynamic>?;
    final Map<String, int> parsedOffsets = {};
    if (rawOffsets != null) {
      rawOffsets.forEach((key, val) {
        parsedOffsets[key] = (val as num).toInt();
      });
    } else {
      parsedOffsets.addAll({
        'fajr': 0,
        'sunrise': 0,
        'dhuhr': 0,
        'asr': 0,
        'maghrib': 0,
        'isha': 0,
      });
    }

    final rawMuezzins = j['prayerMuezzins'] as Map<String, dynamic>?;
    final Map<String, String> parsedMuezzins = {};
    if (rawMuezzins != null) {
      rawMuezzins.forEach((key, val) {
        parsedMuezzins[key] = val.toString();
      });
    } else {
      parsedMuezzins.addAll({
        'fajr': 'adhan_abdulbasit',
        'sunrise': 'adhan_abdulbasit',
        'dhuhr': 'adhan_abdulbasit',
        'asr': 'adhan_abdulbasit',
        'maghrib': 'adhan_abdulbasit',
        'isha': 'adhan_abdulbasit',
      });
    }

    final rawPreAthan = j['preAthanMinutes'] as Map<String, dynamic>?;
    final Map<String, int> parsedPreAthan = {};
    if (rawPreAthan != null) {
      rawPreAthan.forEach((key, val) {
        parsedPreAthan[key] = (val as num).toInt();
      });
    } else {
      parsedPreAthan.addAll({
        'fajr': 0,
        'sunrise': 0,
        'dhuhr': 0,
        'asr': 0,
        'maghrib': 0,
        'isha': 0,
      });
    }

    return PrayerConfig(
      latitude:      (j['latitude']  as num?)?.toDouble() ?? 21.4225,
      longitude:     (j['longitude'] as num?)?.toDouble() ?? 39.8262,
      locationLabel: j['locationLabel'] as String? ?? 'Makkah al-Mukarramah',
      method: CalculationMethodEnum.values.firstWhere(
        (m) => m.key == (j['method'] as String?),
        orElse: () => CalculationMethodEnum.ummAlQura,
      ),
      madhab: MadhabEnum.values.firstWhere(
        (m) => m.key == (j['madhab'] as String?),
        orElse: () => MadhabEnum.shafi,
      ),
      notifications: PrayerNotifConfig.fromJson(
          (j['notifications'] as Map<String, dynamic>?) ?? {}),
      useGps: j['useGps'] as bool? ?? true,
      hasManualMethodOverride: j['hasManualMethodOverride'] as bool? ?? false,
      hasManualMadhabOverride: j['hasManualMadhabOverride'] as bool? ?? false,
      is24HourFormat: j['is24HourFormat'] as bool? ?? false,
      hijriOffset:    j['hijriOffset'] as int? ?? 0,
      prayerOffsets:  parsedOffsets,
      preAthanMinutes: parsedPreAthan,
      prayerMuezzins: parsedMuezzins,
    );
  }

  static String get prefKey => _prefKey;

  PrayerConfig copyWith({
    double? latitude,
    double? longitude,
    String? locationLabel,
    CalculationMethodEnum? method,
    MadhabEnum? madhab,
    PrayerNotifConfig? notifications,
    bool? useGps,
    bool? hasManualMethodOverride,
    bool? hasManualMadhabOverride,
    bool? is24HourFormat,
    int? hijriOffset,
    Map<String, int>? prayerOffsets,
    Map<String, int>? preAthanMinutes,
    Map<String, String>? prayerMuezzins,
  }) {
    return PrayerConfig(
      latitude:      latitude      ?? this.latitude,
      longitude:     longitude     ?? this.longitude,
      locationLabel: locationLabel ?? this.locationLabel,
      method:        method        ?? this.method,
      madhab:        madhab        ?? this.madhab,
      notifications: notifications ?? this.notifications,
      useGps:        useGps        ?? this.useGps,
      hasManualMethodOverride: hasManualMethodOverride ?? this.hasManualMethodOverride,
      hasManualMadhabOverride: hasManualMadhabOverride ?? this.hasManualMadhabOverride,
      is24HourFormat: is24HourFormat ?? this.is24HourFormat,
      hijriOffset:    hijriOffset    ?? this.hijriOffset,
      prayerOffsets:  prayerOffsets  ?? this.prayerOffsets,
      preAthanMinutes: preAthanMinutes ?? this.preAthanMinutes,
      prayerMuezzins: prayerMuezzins ?? this.prayerMuezzins,
    );
  }
}
