// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

/// Interval granularity for analytics chart queries.
enum AnalyticsInterval { daily, weekly, monthly, yearly }

/// Goal type used to categorise user targets.
enum GoalType { khatma, pagesRead, readingTime, azkarCount, tahajjudDays }

// ─────────────────────────────────────────────────────────────────────────────
// WeeklyChartPoint — one bar/data-point in a chart
// ─────────────────────────────────────────────────────────────────────────────

/// A single data-point for charting — used across weekly and monthly views.
class ChartDataPoint {
  const ChartDataPoint({
    required this.label,   // e.g. "Mon", "W1", "Jan"
    required this.value,
    required this.goal,    // user's target for that period (for % bar overlay)
  });

  final String label;
  final double value;
  final double goal;

  double get completionRatio => goal > 0 ? (value / goal).clamp(0.0, 1.0) : 0.0;

  Map<String, dynamic> toJson() =>
      {'label': label, 'value': value, 'goal': goal};

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) => ChartDataPoint(
        label: json['label'] as String,
        value: (json['value'] as num).toDouble(),
        goal: (json['goal'] as num).toDouble(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// KhatmaRecord — a single completed or in-progress Quran reading cycle
// ─────────────────────────────────────────────────────────────────────────────

class KhatmaRecord {
  const KhatmaRecord({
    required this.id,
    required this.startDate,
    this.endDate,           // null if in-progress
    required this.totalDays,
    required this.pagesRead,
    this.isShared = false,  // part of a family/group challenge
    this.groupId,           // associated family/group ID if shared
  });

  final String id;
  final DateTime startDate;
  final DateTime? endDate;
  final int totalDays;
  final int pagesRead;
  final bool isShared;
  final String? groupId;

  bool get isCompleted => endDate != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'totalDays': totalDays,
        'pagesRead': pagesRead,
        'isShared': isShared,
        'groupId': groupId,
      };

  factory KhatmaRecord.fromJson(Map<String, dynamic> json) => KhatmaRecord(
        id: json['id'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : null,
        totalDays: json['totalDays'] as int? ?? 0,
        pagesRead: json['pagesRead'] as int? ?? 0,
        isShared: json['isShared'] as bool? ?? false,
        groupId: json['groupId'] as String?,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// FamilySyncMarker — lightweight pointer for family-account sync
// ─────────────────────────────────────────────────────────────────────────────

/// Indicates that this [UserAnalyticsModel] belongs to a family group.
class FamilySyncMarker {
  const FamilySyncMarker({
    required this.familyId,
    required this.memberRole,    // e.g. "admin", "member"
    required this.displayName,
    required this.lastSyncedAt,
  });

  final String familyId;
  final String memberRole;
  final String displayName;
  final DateTime lastSyncedAt;

  Map<String, dynamic> toJson() => {
        'familyId': familyId,
        'memberRole': memberRole,
        'displayName': displayName,
        'lastSyncedAt': lastSyncedAt.toIso8601String(),
      };

  factory FamilySyncMarker.fromJson(Map<String, dynamic> json) =>
      FamilySyncMarker(
        familyId: json['familyId'] as String,
        memberRole: json['memberRole'] as String? ?? 'member',
        displayName: json['displayName'] as String? ?? '',
        lastSyncedAt: DateTime.parse(json['lastSyncedAt'] as String),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// UserGoal — a declared target for a specific GoalType over an interval
// ─────────────────────────────────────────────────────────────────────────────

class UserGoal {
  const UserGoal({
    required this.type,
    required this.targetValue,
    required this.interval,
    required this.startDate,
  });

  final GoalType type;
  final double targetValue;  // pages, minutes, count, etc.
  final AnalyticsInterval interval;
  final DateTime startDate;

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'targetValue': targetValue,
        'interval': interval.name,
        'startDate': startDate.toIso8601String(),
      };

  factory UserGoal.fromJson(Map<String, dynamic> json) => UserGoal(
        type: GoalType.values.byName(json['type'] as String),
        targetValue: (json['targetValue'] as num).toDouble(),
        interval: AnalyticsInterval.values.byName(json['interval'] as String),
        startDate: DateTime.parse(json['startDate'] as String),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// UserAnalyticsModel — the full analytics state for a user
// ─────────────────────────────────────────────────────────────────────────────

/// Centralised analytics model holding all user activity data.
///
/// Used by:
/// - [StreakCard] — displays [currentStreakDays] and the flame index.
/// - [ResumeReadingCard] — uses [lastReadAyahId] / [lastReadJuz].
/// - [AnalyticsCenterCard] — renders [weeklyChartData] / [monthlyChartData].
/// - Family sync modules — checked via [familySyncMarker].
class UserAnalyticsModel {
  const UserAnalyticsModel({
    required this.userId,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.totalPagesRead,
    required this.totalReadingMinutes,
    required this.totalAzkarCount,
    required this.completedKhatmas,
    required this.activeKhatma,
    required this.weeklyChartData,
    required this.monthlyChartData,
    required this.activeGoals,
    required this.lastReadAyahId,
    required this.lastReadJuz,
    required this.lastReadSurahNumber,
    required this.lastReadPageNumber,
    required this.lastActivityAt,
    this.familySyncMarker,
    this.activeGroupId,
    this.ramadanBadgesEarned = 0,
  });

  final String userId;

  // ── Streak ─────────────────────────────────────────────────────────────────
  /// Number of consecutive days with at least one reading session.
  final int currentStreakDays;
  final int longestStreakDays;

  // ── Reading Totals ─────────────────────────────────────────────────────────
  final int totalPagesRead;
  final int totalReadingMinutes;
  final int totalAzkarCount;

  // ── Khatma ─────────────────────────────────────────────────────────────────
  final List<KhatmaRecord> completedKhatmas;

  /// The in-progress Khatma; null if the user has not started one.
  final KhatmaRecord? activeKhatma;

  // ── Charts ─────────────────────────────────────────────────────────────────
  /// 7 data points — one per day of the current week.
  final List<ChartDataPoint> weeklyChartData;

  /// 30 data points — one per day or one per week bucket of the current month.
  final List<ChartDataPoint> monthlyChartData;

  // ── Goals ──────────────────────────────────────────────────────────────────
  final List<UserGoal> activeGoals;

  // ── Last Read Position ────────────────────────────────────────────────────
  /// Unique ayah identifier (e.g. "2:255" for Ayat al-Kursi).
  final String lastReadAyahId;
  final int lastReadJuz;
  final int lastReadSurahNumber;
  final int lastReadPageNumber;

  // ── Meta ──────────────────────────────────────────────────────────────────
  final DateTime lastActivityAt;

  /// Null when the user is not linked to a family group.
  final FamilySyncMarker? familySyncMarker;

  /// ID of the active Ramadan/Khatma challenge group room.
  final String? activeGroupId;

  /// Badges earned during the current/last Ramadan season.
  final int ramadanBadgesEarned;

  // ── Derived Helpers ────────────────────────────────────────────────────────

  bool get hasActiveFamily => familySyncMarker != null;
  bool get hasActiveGroup  => activeGroupId != null;

  /// Total completed khatma count (quick stat display).
  int get khatmaCount => completedKhatmas.length;

  UserAnalyticsModel copyWith({
    String? userId,
    int? currentStreakDays,
    int? longestStreakDays,
    int? totalPagesRead,
    int? totalReadingMinutes,
    int? totalAzkarCount,
    List<KhatmaRecord>? completedKhatmas,
    KhatmaRecord? activeKhatma,
    List<ChartDataPoint>? weeklyChartData,
    List<ChartDataPoint>? monthlyChartData,
    List<UserGoal>? activeGoals,
    String? lastReadAyahId,
    int? lastReadJuz,
    int? lastReadSurahNumber,
    int? lastReadPageNumber,
    DateTime? lastActivityAt,
    FamilySyncMarker? familySyncMarker,
    String? activeGroupId,
    int? ramadanBadgesEarned,
  }) {
    return UserAnalyticsModel(
      userId: userId ?? this.userId,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      longestStreakDays: longestStreakDays ?? this.longestStreakDays,
      totalPagesRead: totalPagesRead ?? this.totalPagesRead,
      totalReadingMinutes: totalReadingMinutes ?? this.totalReadingMinutes,
      totalAzkarCount: totalAzkarCount ?? this.totalAzkarCount,
      completedKhatmas: completedKhatmas ?? this.completedKhatmas,
      activeKhatma: activeKhatma ?? this.activeKhatma,
      weeklyChartData: weeklyChartData ?? this.weeklyChartData,
      monthlyChartData: monthlyChartData ?? this.monthlyChartData,
      activeGoals: activeGoals ?? this.activeGoals,
      lastReadAyahId: lastReadAyahId ?? this.lastReadAyahId,
      lastReadJuz: lastReadJuz ?? this.lastReadJuz,
      lastReadSurahNumber: lastReadSurahNumber ?? this.lastReadSurahNumber,
      lastReadPageNumber: lastReadPageNumber ?? this.lastReadPageNumber,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      familySyncMarker: familySyncMarker ?? this.familySyncMarker,
      activeGroupId: activeGroupId ?? this.activeGroupId,
      ramadanBadgesEarned: ramadanBadgesEarned ?? this.ramadanBadgesEarned,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'currentStreakDays': currentStreakDays,
        'longestStreakDays': longestStreakDays,
        'totalPagesRead': totalPagesRead,
        'totalReadingMinutes': totalReadingMinutes,
        'totalAzkarCount': totalAzkarCount,
        'completedKhatmas': completedKhatmas.map((k) => k.toJson()).toList(),
        'activeKhatma': activeKhatma?.toJson(),
        'weeklyChartData': weeklyChartData.map((p) => p.toJson()).toList(),
        'monthlyChartData': monthlyChartData.map((p) => p.toJson()).toList(),
        'activeGoals': activeGoals.map((g) => g.toJson()).toList(),
        'lastReadAyahId': lastReadAyahId,
        'lastReadJuz': lastReadJuz,
        'lastReadSurahNumber': lastReadSurahNumber,
        'lastReadPageNumber': lastReadPageNumber,
        'lastActivityAt': lastActivityAt.toIso8601String(),
        'familySyncMarker': familySyncMarker?.toJson(),
        'activeGroupId': activeGroupId,
        'ramadanBadgesEarned': ramadanBadgesEarned,
      };

  factory UserAnalyticsModel.fromJson(Map<String, dynamic> json) {
    return UserAnalyticsModel(
      userId: json['userId'] as String,
      currentStreakDays: json['currentStreakDays'] as int? ?? 0,
      longestStreakDays: json['longestStreakDays'] as int? ?? 0,
      totalPagesRead: json['totalPagesRead'] as int? ?? 0,
      totalReadingMinutes: json['totalReadingMinutes'] as int? ?? 0,
      totalAzkarCount: json['totalAzkarCount'] as int? ?? 0,
      completedKhatmas: (json['completedKhatmas'] as List<dynamic>? ?? [])
          .map((e) => KhatmaRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeKhatma: json['activeKhatma'] != null
          ? KhatmaRecord.fromJson(
              json['activeKhatma'] as Map<String, dynamic>)
          : null,
      weeklyChartData: (json['weeklyChartData'] as List<dynamic>? ?? [])
          .map((e) => ChartDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      monthlyChartData: (json['monthlyChartData'] as List<dynamic>? ?? [])
          .map((e) => ChartDataPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeGoals: (json['activeGoals'] as List<dynamic>? ?? [])
          .map((e) => UserGoal.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastReadAyahId: json['lastReadAyahId'] as String? ?? '1:1',
      lastReadJuz: json['lastReadJuz'] as int? ?? 1,
      lastReadSurahNumber: json['lastReadSurahNumber'] as int? ?? 1,
      lastReadPageNumber: json['lastReadPageNumber'] as int? ?? 1,
      lastActivityAt: json['lastActivityAt'] != null
          ? DateTime.parse(json['lastActivityAt'] as String)
          : DateTime.now(),
      familySyncMarker: json['familySyncMarker'] != null
          ? FamilySyncMarker.fromJson(
              json['familySyncMarker'] as Map<String, dynamic>)
          : null,
      activeGroupId: json['activeGroupId'] as String?,
      ramadanBadgesEarned: json['ramadanBadgesEarned'] as int? ?? 0,
    );
  }

  /// Returns an empty baseline model for new users / first launch.
  factory UserAnalyticsModel.empty(String userId) => UserAnalyticsModel(
        userId: userId,
        currentStreakDays: 0,
        longestStreakDays: 0,
        totalPagesRead: 0,
        totalReadingMinutes: 0,
        totalAzkarCount: 0,
        completedKhatmas: const [],
        activeKhatma: null,
        weeklyChartData: const [],
        monthlyChartData: const [],
        activeGoals: const [],
        lastReadAyahId: '1:1',
        lastReadJuz: 1,
        lastReadSurahNumber: 1,
        lastReadPageNumber: 1,
        lastActivityAt: DateTime.now(),
      );
}
