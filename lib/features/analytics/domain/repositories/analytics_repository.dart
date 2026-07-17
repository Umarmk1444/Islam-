import '../../data/models/user_analytics_model.dart';

/// Abstract repository contract for user analytics and progress data.
///
/// Implementation in `data/repositories/analytics_repository_impl.dart`.
abstract class AnalyticsRepository {
  // ── Read ───────────────────────────────────────────────────────────────────

  /// Loads the full analytics model for [userId] from local storage.
  Future<UserAnalyticsModel> getAnalytics(String userId);

  /// Returns chart data aggregated by [interval] for the given [userId].
  /// [goalType] filters which metric's data points to return.
  Future<List<ChartDataPoint>> getChartData({
    required String userId,
    required GoalType goalType,
    required AnalyticsInterval interval,
  });

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Persists the full [model] to local storage.
  Future<void> saveAnalytics(UserAnalyticsModel model);

  /// Increments the page-read counter by [pagesCount] and updates streak.
  Future<void> recordReadingSession({
    required String userId,
    required int pagesCount,
    required int durationMinutes,
    required String lastAyahId,
    required int lastJuz,
    required int lastSurah,
    required int lastPage,
  });

  /// Increments the Azkar count by [count].
  Future<void> recordAzkarSession({
    required String userId,
    required int count,
  });

  /// Marks an active Khatma as completed and archives it.
  Future<void> completeKhatma({
    required String userId,
    required String khatmaId,
  });

  /// Creates a new active Khatma for [userId].
  Future<KhatmaRecord> startNewKhatma({
    required String userId,
    required bool isShared,
    String? groupId,
  });

  // ── Goals ──────────────────────────────────────────────────────────────────

  /// Saves or updates a [UserGoal] for [userId].
  Future<void> setGoal({
    required String userId,
    required UserGoal goal,
  });

  /// Removes a goal of the given [type] for [userId].
  Future<void> removeGoal({
    required String userId,
    required GoalType type,
  });

  // ── Family Sync ───────────────────────────────────────────────────────────

  /// Links this device's analytics to a family group identified by [familyId].
  Future<void> linkFamilyGroup({
    required String userId,
    required String familyId,
    required String displayName,
  });

  /// Removes the family sync link.
  Future<void> unlinkFamilyGroup(String userId);

  /// Fetches analytics summaries for all members in [familyId].
  /// Returns an empty list when offline or not linked.
  Future<List<UserAnalyticsModel>> getFamilyMembersAnalytics(String familyId);
}
