import '../../data/models/prayer_time_model.dart';

/// Abstract repository contract for prayer time data.
///
/// Implementations live in `data/repositories/prayer_time_repository_impl.dart`.
/// This interface ensures the domain layer has zero dependency on external
/// packages (aladhan API, geolocator, etc.).
abstract class PrayerTimeRepository {
  /// Fetch the full prayer schedule for [date] at the given coordinates.
  ///
  /// [calculationMethod] is a string key such as "MWL", "ISNA", or "Egypt".
  /// Returns [null] when the device is offline and no cached data exists.
  Future<PrayerTimeModel?> getPrayerTimes({
    required double latitude,
    required double longitude,
    required DateTime date,
    String calculationMethod = 'MWL',
  });

  /// Returns the locally cached schedule for today, or null if none exists.
  Future<PrayerTimeModel?> getCachedTodayPrayerTimes();

  /// Persists [model] to local storage (SharedPreferences / SQLite).
  Future<void> cachePrayerTimes(PrayerTimeModel model);

  /// Returns the user's saved per-prayer alert settings.
  Future<Map<PrayerName, PrayerAlertMode>> getPrayerAlertSettings();

  /// Persists a single prayer's alert mode preference.
  Future<void> setPrayerAlertMode(PrayerName prayer, PrayerAlertMode mode);

  /// Toggles the auto-silent feature for a specific prayer.
  Future<void> setAutoSilent({
    required PrayerName prayer,
    required bool enabled,
    int durationMinutes = 15,
  });

  /// Returns the saved Qibla direction (degrees) for the last known location,
  /// or null if not yet determined.
  Future<double?> getCachedQiblaDirection();

  /// Computes and caches the Qibla direction for the given coordinates.
  Future<double> computeQiblaDirection({
    required double latitude,
    required double longitude,
  });
}
