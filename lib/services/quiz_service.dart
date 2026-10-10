import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/database_helper.dart';
import '../models/quiz_models.dart';
import '../data/quiz_question_bank.dart';

class QuizService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static const String _leaderboardKey = 'quiz_leaderboard';
  static const String _careerStatsKey = 'quiz_player_career_stats';
  static const String _soundEnabledKey = 'quiz_sound_enabled';
  static const String _vibrationEnabledKey = 'quiz_vibration_enabled';

  /// Fetches a randomized pool of questions blending curated bank & SQLite database
  Future<List<QuizQuestion>> getQuestions({
    int limit = 15,
    String category = 'all',
    int? difficulty,
  }) async {
    // 1. Get questions from the verified curated bank
    final verified = QuizQuestionBank.getQuestions(
      category: category,
      difficulty: difficulty,
      limit: limit,
    );

    // If a specific faculty category was requested, return verified curated items
    if (category != 'all' && verified.length >= limit) {
      return verified.sublist(0, limit);
    }

    // 2. Fetch supplementary questions from SQLite if needed
    List<QuizQuestion> dbQuestions = [];
    try {
      final db = await _dbHelper.database;
      String query =
          'SELECT id, question, answerCorrect, wrong1, wrong2, wrong3, difficulty '
          'FROM quizQuestions WHERE isActive = 1 ';
      List<dynamic> args = [];

      if (difficulty != null) {
        query += 'AND difficulty = ? ';
        args.add(difficulty);
      }

      query += 'ORDER BY RANDOM() LIMIT ?';
      args.add(limit * 2);

      final rows = await db.rawQuery(query, args);
      dbQuestions = rows
          .map((e) => QuizQuestion.fromMap(e))
          .where((q) =>
              q.question.isNotEmpty &&
              q.answerCorrect.isNotEmpty &&
              q.wrong1.isNotEmpty)
          .toList();
    } catch (_) {
      // Fallback gracefully to curated pool if database is busy
    }

    // 3. Blend verified curated questions with SQLite questions
    final blended = <QuizQuestion>[...verified];
    final existingIds = verified.map((q) => q.id).toSet();

    for (final q in dbQuestions) {
      if (!existingIds.contains(q.id)) {
        blended.add(q);
        existingIds.add(q.id);
      }
    }

    blended.shuffle();
    if (blended.length > limit) {
      return blended.sublist(0, limit);
    }
    return blended;
  }

  /// Backward-compatible random questions method
  Future<List<QuizQuestion>> getRandomQuestions({int limit = 10}) async {
    return getQuestions(limit: limit);
  }

  /// Backward-compatible difficulty-based question loader
  Future<List<QuizQuestion>> getQuestionsByDifficulty(
    int difficulty, {
    int limit = 15,
    String category = 'all',
  }) async {
    return getQuestions(
      limit: limit,
      difficulty: difficulty,
      category: category,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Player Career Stats
  // ─────────────────────────────────────────────────────────────────────────

  Future<PlayerCareerStats> getCareerStats() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_careerStatsKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return PlayerCareerStats();
    }
    try {
      return PlayerCareerStats.fromJson(jsonStr);
    } catch (_) {
      return PlayerCareerStats();
    }
  }

  Future<void> updateCareerStats({
    required int score,
    required int streak,
    String? playerName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getCareerStats();

    final updated = PlayerCareerStats(
      totalGames: current.totalGames + 1,
      totalScore: current.totalScore + score,
      bestScore: score > current.bestScore ? score : current.bestScore,
      bestStreak: streak > current.bestStreak ? streak : current.bestStreak,
      playerName: (playerName != null && playerName.trim().isNotEmpty)
          ? playerName.trim()
          : current.playerName,
    );

    await prefs.setString(_careerStatsKey, updated.toJson());
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Sound & Vibration Preferences
  // ─────────────────────────────────────────────────────────────────────────

  Future<bool> isSoundEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_soundEnabledKey) ?? true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundEnabledKey, enabled);
  }

  Future<bool> isVibrationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_vibrationEnabledKey) ?? true;
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationEnabledKey, enabled);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Leaderboard Management
  // ─────────────────────────────────────────────────────────────────────────

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedList = prefs.getStringList(_leaderboardKey) ?? [];

    final entries = savedList.map((e) {
      try {
        return LeaderboardEntry.fromJson(e);
      } catch (_) {
        return null;
      }
    }).whereType<LeaderboardEntry>().toList();

    // Sort descending by score, then by timestamp
    entries.sort((a, b) {
      if (a.score != b.score) {
        return b.score.compareTo(a.score);
      }
      return b.timestamp.compareTo(a.timestamp);
    });

    return entries;
  }

  Future<void> saveToLeaderboard(LeaderboardEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedList = prefs.getStringList(_leaderboardKey) ?? [];

    savedList.add(entry.toJson());
    await prefs.setStringList(_leaderboardKey, savedList);

    // Also update career stats
    await updateCareerStats(
      score: entry.score,
      streak: 0,
      playerName: entry.playerName,
    );
  }
}
