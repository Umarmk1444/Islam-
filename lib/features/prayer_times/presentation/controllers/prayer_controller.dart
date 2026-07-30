// lib/features/prayer_times/presentation/controllers/prayer_controller.dart
// ─────────────────────────────────────────────────────────────────────────────
// PrayerController — ChangeNotifier driving all prayer-times UI.
//
// Responsibilities:
//  • Loads stored PrayerConfig from SharedPreferences on startup.
//  • Requests GPS via geolocator; falls back to stored/Makkah coordinates.
//  • Uses the 'adhan' package as a pure-offline calculation engine.
//  • Converts adhan output → existing PrayerTimeModel / PrayerTimeEntry domain.
//  • Computes Hijri date via arithmetic algorithm (no network needed).
//  • Ticks a 1-second countdown timer until the next prayer.
//  • Exposes mutation methods: changeMethod, changeMadhab, toggleNotification,
//    syncLocation — each persists to SharedPreferences and reschedules alerts.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart' as adhan;

import '../../data/models/prayer_config.dart';
import '../../data/models/prayer_time_model.dart';
import '../../../../core/services/background_engine.dart';
import '../../../../services/notification_service.dart';
import 'package:hijri/hijri_calendar.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const double _makkahLat = 21.4225;
const double _makkahLng = 39.8262;
const String _makkahLabel = 'Makkah al-Mukarramah';

// ── PrayerController ──────────────────────────────────────────────────────────

class PrayerController extends ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────────────────────────

  static final PrayerController _instance = PrayerController._internal();
  factory PrayerController() => _instance;
  PrayerController._internal() {
    _init();
  }

  // ── Public state ───────────────────────────────────────────────────────────

  PrayerConfig config = const PrayerConfig();
  PrayerTimeModel? model;           // null while loading
  final ValueNotifier<String> countdownNotifier = ValueNotifier<String>('--:--:--');
  bool isLoading = true;
  String? errorMessage;

  // ── Private internals ──────────────────────────────────────────────────────

  Timer? _countdownTimer;
  SharedPreferences? _prefs;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    // Note: Singleton is usually kept alive, but clean up timer if disposed
    _countdownTimer?.cancel();
    super.dispose();
  }

  // ── Initialization flow ────────────────────────────────────────────────────

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadConfig();
    await _resolveLocation();
    _compute();
    _scheduleNotifications();
    _startCountdownTimer();
    isLoading = false;
    notifyListeners();
  }

  void _loadConfig() {
    final raw = _prefs?.getString(PrayerConfig.prefKey);
    if (raw != null) {
      try {
        config = PrayerConfig.fromJsonString(raw);
      } catch (_) {
        config = const PrayerConfig();
      }
    } else {
      // First launch smart auto-detection from locale
      final country = ui.PlatformDispatcher.instance.locale.countryCode;
      final autoMethod = _detectMethod(_makkahLat, _makkahLng, country);
      config = PrayerConfig(
        latitude: _makkahLat,
        longitude: _makkahLng,
        locationLabel: _makkahLabel,
        method: autoMethod,
        madhab: MadhabEnum.shafi, // Zero-config global default
        hasManualMethodOverride: false,
        hasManualMadhabOverride: false,
      );
    }
  }

  Future<void> _saveConfig() async {
    await _prefs?.setString(PrayerConfig.prefKey, config.toJsonString());
  }

  // ── GPS / location resolution ──────────────────────────────────────────────

  /// Requests location permission and fetches a fresh GPS fix.
  /// If permission is denied or an error occurs, retains stored coordinates.
  Future<void> _resolveLocation() async {
    if (!config.useGps) return;
    try {
      await Future.microtask(() async {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          _applyFallbackMakkah();
          return;
        }

        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          _applyFallbackMakkah();
          return;
        }

        final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 3),
          ),
        );

        final label = _coordsToLabel(pos.latitude, pos.longitude);

        config = config.copyWith(
          latitude:      pos.latitude,
          longitude:     pos.longitude,
          locationLabel: label,
        );

        _applySmartDefaults(pos.latitude, pos.longitude, null);
        await _saveConfig();
      }).timeout(const Duration(seconds: 4), onTimeout: () {
        _applyFallbackMakkah();
      });
    } catch (_) {
      _applyFallbackMakkah();
    }
  }

  void _applyFallbackMakkah() {
    if (config.latitude == _makkahLat && config.longitude == _makkahLng) {
      config = config.copyWith(
        latitude:      _makkahLat,
        longitude:     _makkahLng,
        locationLabel: _makkahLabel,
      );
      _applySmartDefaults(_makkahLat, _makkahLng, 'SA');
    }
  }

  /// Derives a short display label from decimal coordinates.
  String _coordsToLabel(double lat, double lng) {
    final ns = lat >= 0 ? 'N' : 'S';
    final ew = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(2)}°$ns, ${lng.abs().toStringAsFixed(2)}°$ew';
  }

  // ── Prayer time computation ────────────────────────────────────────────────

  void _compute() {
    try {
      final coordinates = adhan.Coordinates(config.latitude, config.longitude);
      final params = _buildParams();
      final date = adhan.DateComponents.from(DateTime.now());
      final times = adhan.PrayerTimes(coordinates, date, params);

      final now = DateTime.now();
      final hijri = _toHijri(now);
      final entries = _toEntries(times);
      final daySegment = _computeSegment(times, now);
      final nextEntry = _findNextPrayer(entries, now);

      model = PrayerTimeModel(
        date:              now,
        hijriDate:         hijri,
        locationLabel:     config.locationLabel,
        latitude:          config.latitude,
        longitude:         config.longitude,
        entries:           entries,
        daySegment:        daySegment,
        nextPrayer:        nextEntry,
        calculationMethod: config.method.labelEn,
      );
    } catch (e) {
      errorMessage = e.toString();
    }
  }

  // ── adhan param builder — adapter pattern ──────────────────────────────────

  adhan.CalculationParameters _buildParams() {
    adhan.CalculationParameters params;
    switch (config.method) {
      case CalculationMethodEnum.ummAlQura:
        params = adhan.CalculationMethod.umm_al_qura.getParameters();
        break;
      case CalculationMethodEnum.egyptian:
        params = adhan.CalculationMethod.egyptian.getParameters();
        break;
      case CalculationMethodEnum.mwl:
        params = adhan.CalculationMethod.muslim_world_league.getParameters();
        break;
      case CalculationMethodEnum.isna:
        params = adhan.CalculationMethod.north_america.getParameters();
        break;
      case CalculationMethodEnum.karachi:
        params = adhan.CalculationMethod.karachi.getParameters();
        break;
    }
    // Apply Madhab for Asr timing
    params.madhab = config.madhab == MadhabEnum.hanafi
        ? adhan.Madhab.hanafi
        : adhan.Madhab.shafi;
    return params;
  }

  // ── Map adhan.PrayerTimes → List<PrayerTimeEntry> ─────────────────────────

  List<PrayerTimeEntry> _toEntries(adhan.PrayerTimes times) {
    final notif = config.notifications;
    final offsets = config.prayerOffsets;

    DateTime adjust(DateTime original, String key) {
      final offsetMins = offsets[key] ?? 0;
      return original.add(Duration(minutes: offsetMins));
    }

    return [
      PrayerTimeEntry(
        prayer:    PrayerName.fajr,
        time:      adjust(times.fajr, 'fajr'),
        alertMode: notif.fajrEnabled
            ? PrayerAlertMode.notification
            : PrayerAlertMode.silent,
      ),
      PrayerTimeEntry(
        prayer:    PrayerName.sunrise,
        time:      adjust(times.sunrise, 'sunrise'),
        alertMode: notif.sunriseEnabled
            ? PrayerAlertMode.notification
            : PrayerAlertMode.silent,
      ),
      PrayerTimeEntry(
        prayer:    PrayerName.dhuhr,
        time:      adjust(times.dhuhr, 'dhuhr'),
        alertMode: notif.dhuhrEnabled
            ? PrayerAlertMode.notification
            : PrayerAlertMode.silent,
      ),
      PrayerTimeEntry(
        prayer:    PrayerName.asr,
        time:      adjust(times.asr, 'asr'),
        alertMode: notif.asrEnabled
            ? PrayerAlertMode.notification
            : PrayerAlertMode.silent,
      ),
      PrayerTimeEntry(
        prayer:    PrayerName.maghrib,
        time:      adjust(times.maghrib, 'maghrib'),
        alertMode: notif.maghribEnabled
            ? PrayerAlertMode.notification
            : PrayerAlertMode.silent,
      ),
      PrayerTimeEntry(
        prayer:    PrayerName.isha,
        time:      adjust(times.isha, 'isha'),
        alertMode: notif.ishaEnabled
            ? PrayerAlertMode.notification
            : PrayerAlertMode.silent,
      ),
    ];
  }

  // ── Day segment derivation ─────────────────────────────────────────────────

  DaySegment _computeSegment(adhan.PrayerTimes times, DateTime now) {
    if (now.isBefore(times.fajr))    return DaySegment.lastThirdNight;
    if (now.isBefore(times.sunrise)) return DaySegment.fajr;
    if (now.isBefore(times.dhuhr))   return DaySegment.morning;
    if (now.isBefore(times.asr))     return DaySegment.afternoon;
    if (now.isBefore(times.maghrib)) return DaySegment.evening;
    if (now.isBefore(times.isha))    return DaySegment.night;
    return DaySegment.lateNight;
  }

  // ── Next prayer ────────────────────────────────────────────────────────────

  PrayerTimeEntry _findNextPrayer(List<PrayerTimeEntry> entries, DateTime now) {
    for (final e in entries) {
      if (e.time.isAfter(now)) return e;
    }
    // All prayers passed — next is tomorrow's Fajr.
    return entries.first.copyWith(
      time: entries.first.time.add(const Duration(days: 1)),
    );
  }

  // ── Hijri conversion — uses the hijri package ─────────────────────────────
  //
  // HijriCalendar.fromDate() is the authoritative source; we honour the user's
  // hijriOffset (days) stored in PrayerConfig so the whole app stays in sync.

  HijriDate _toHijri(DateTime gregorian) {
    final adjusted = gregorian.add(Duration(days: config.hijriOffset));
    final hc = HijriCalendar.fromDate(adjusted);

    return HijriDate(
      year:        hc.hYear,
      month:       hc.hMonth,
      day:         hc.hDay,
      monthNameAr: _hijriMonthAr[(hc.hMonth - 1).clamp(0, 11)],
      monthNameEn: _hijriMonthEn[(hc.hMonth - 1).clamp(0, 11)],
    );
  }

  static const _hijriMonthAr = [
    'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر',
    'جمادى الأولى', 'جمادى الآخرة', 'رجب', 'شعبان',
    'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة',
  ];
  static const _hijriMonthEn = [
    'Muharram', 'Safar', "Rabi' al-Awwal", "Rabi' al-Thani",
    'Jumada al-Ula', 'Jumada al-Akhira', 'Rajab', "Sha'ban",
    'Ramadan', 'Shawwal', "Dhu al-Qi'dah", 'Dhu al-Hijjah',
  ];

  // ── Smart Defaults Helpers ──────────────────────────────────────────────────

  CalculationMethodEnum _detectMethod(double latitude, double longitude, String? countryCode) {
    final cc = (countryCode ?? ui.PlatformDispatcher.instance.locale.countryCode ?? '').toUpperCase();
    
    // SA or Gulf (AE, QA, OM, BH, KW)
    if (cc == 'SA' || cc == 'AE' || cc == 'QA' || cc == 'OM' || cc == 'BH' || cc == 'KW') {
      return CalculationMethodEnum.ummAlQura;
    }
    // EG, ET (Ethiopia), SD, or East Africa (KE, UG, TZ, SO, DJ, ER)
    if (cc == 'EG' || cc == 'ET' || cc == 'SD' || cc == 'KE' || cc == 'UG' || cc == 'TZ' || cc == 'SO' || cc == 'DJ' || cc == 'ER') {
      return CalculationMethodEnum.egyptian;
    }
    
    // Geographic heuristics fallback
    if (latitude >= 12.0 && latitude <= 32.0 && longitude >= 34.0 && longitude <= 60.0) {
      return CalculationMethodEnum.ummAlQura;
    }
    if (latitude >= -5.0 && latitude <= 31.5 && longitude >= 22.0 && longitude <= 52.0) {
      return CalculationMethodEnum.egyptian;
    }

    return CalculationMethodEnum.mwl;
  }

  void _applySmartDefaults(double lat, double lng, String? countryCode) {
    var method = config.method;
    var madhab = config.madhab;

    if (!config.hasManualMethodOverride) {
      method = _detectMethod(lat, lng, countryCode);
    }
    if (!config.hasManualMadhabOverride) {
      madhab = MadhabEnum.shafi; // Zero-config global default
    }

    config = config.copyWith(
      method: method,
      madhab: madhab,
    );
  }


  // ── Live countdown timer ───────────────────────────────────────────────────

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tickCountdown();
    });
  }

  void _tickCountdown() {
    if (model == null) return;
    final remaining = model!.nextPrayer.time.difference(DateTime.now());
    if (remaining.isNegative) {
      // Time has passed — recompute for next prayer.
      _compute();
      _scheduleNotifications();
      notifyListeners(); // Notify full model change
    } else {
      final h = remaining.inHours.toString().padLeft(2, '0');
      final m = (remaining.inMinutes % 60).toString().padLeft(2, '0');
      final s = (remaining.inSeconds % 60).toString().padLeft(2, '0');
      countdownNotifier.value = '$h:$m:$s';
    }
  }

  // ── Public mutation methods ────────────────────────────────────────────────

  /// Change calculation method, persist, recompute and reschedule alerts.
  Future<void> changeMethod(CalculationMethodEnum method) async {
    config = config.copyWith(
      method: method,
      hasManualMethodOverride: true,
    );
    await _saveConfig();
    _compute();
    _scheduleNotifications();
    notifyListeners();
  }

  /// Change Madhab (Asr timing), persist, recompute.
  Future<void> changeMadhab(MadhabEnum madhab) async {
    config = config.copyWith(
      madhab: madhab,
      hasManualMadhabOverride: true,
    );
    await _saveConfig();
    _compute();
    _scheduleNotifications();
    notifyListeners();
  }

  /// Toggle notification for one of the 6 prayer slots.
  Future<void> toggleNotification(PrayerName prayer) async {
    final n = config.notifications;
    PrayerNotifConfig updated;
    switch (prayer) {
      case PrayerName.fajr:
        updated = n.copyWith(fajrEnabled:    !n.fajrEnabled);
        break;
      case PrayerName.sunrise:
        updated = n.copyWith(sunriseEnabled: !n.sunriseEnabled);
        break;
      case PrayerName.dhuhr:
        updated = n.copyWith(dhuhrEnabled:   !n.dhuhrEnabled);
        break;
      case PrayerName.asr:
        updated = n.copyWith(asrEnabled:     !n.asrEnabled);
        break;
      case PrayerName.maghrib:
        updated = n.copyWith(maghribEnabled: !n.maghribEnabled);
        break;
      case PrayerName.isha:
        updated = n.copyWith(ishaEnabled:    !n.ishaEnabled);
        break;
      default:
        return; // tahajjud / duha — not in scope
    }
    config = config.copyWith(notifications: updated);
    await _saveConfig();
    _compute();      // re-map alertMode flags onto entries
    _scheduleNotifications();
    notifyListeners();
  }

  /// Re-trigger GPS and recompute times.
  Future<void> syncLocation() async {
    isLoading = true;
    notifyListeners();
    await _resolveLocation();
    _compute();
    _scheduleNotifications();
    isLoading = false;
    notifyListeners();
  }

  /// General-purpose config setter — persists to SharedPreferences, recomputes,
  /// and notifies listeners.  Used by Settings Sheet for is24HourFormat,
  /// hijriOffset, prayerOffsets and any other config fields.
  Future<void> updateConfig(PrayerConfig newConfig) async {
    config = newConfig;
    await _saveConfig();
    _compute();
    _scheduleNotifications();
    notifyListeners();
  }

  /// Returns whether notifications are enabled for the given prayer.
  bool isNotifEnabled(PrayerName prayer) {
    final n = config.notifications;
    switch (prayer) {
      case PrayerName.fajr:    return n.fajrEnabled;
      case PrayerName.sunrise: return n.sunriseEnabled;
      case PrayerName.dhuhr:   return n.dhuhrEnabled;
      case PrayerName.asr:     return n.asrEnabled;
      case PrayerName.maghrib: return n.maghribEnabled;
      case PrayerName.isha:    return n.ishaEnabled;
      default:                 return false;
    }
  }

  // ── Notification scheduling ────────────────────────────────────────────────

  void _scheduleNotifications() {
    if (model == null) return;
    try {
      final now = DateTime.now();
      final coordinates = adhan.Coordinates(config.latitude, config.longitude);
      final params = _buildParams();

      final todayDate = adhan.DateComponents.from(now);
      final todayTimes = adhan.PrayerTimes(coordinates, todayDate, params);
      final todayEntries = _toEntries(todayTimes);

      final tomorrowDate = adhan.DateComponents.from(now.add(const Duration(days: 1)));
      final tomorrowTimes = adhan.PrayerTimes(coordinates, tomorrowDate, params);
      final tomorrowEntries = _toEntries(tomorrowTimes);

      final upcomingEntries = [...todayEntries, ...tomorrowEntries];

      NotificationService().cancelAdhanNotifications();
      BackgroundEngine().scheduleAllAlarms(upcomingEntries, config);
    } catch (_) {
      // Silently ignore on platforms where notifications are unavailable.
    }
  }
}


