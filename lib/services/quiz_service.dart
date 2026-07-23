import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/database_helper.dart';
import '../models/quiz_models.dart';

class QuizService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const String _leaderboardKey = 'quiz_leaderboard';

  Future<List<QuizQuestion>> getRandomQuestions({int limit = 10}) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT id, question, answerCorrect, wrong1, wrong2, wrong3, difficulty '
      'FROM quizQuestions WHERE isActive = 1 ORDER BY RANDOM() LIMIT ?',
      [limit],
    );
    return rows.map((e) => QuizQuestion.fromMap(e)).toList();
  }

  Future<List<QuizQuestion>> getQuestionsByDifficulty(int difficulty,
      {int limit = 20}) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT id, question, answerCorrect, wrong1, wrong2, wrong3, difficulty '
      'FROM quizQuestions WHERE isActive = 1 AND difficulty = ? ORDER BY RANDOM() LIMIT ?',
      [difficulty, limit],
    );
    return rows.map((e) => QuizQuestion.fromMap(e)).toList();
  }

  Future<List<LeaderboardEntry>> getLeaderboard() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> savedList = prefs.getStringList(_leaderboardKey) ?? [];

    final entries = savedList.map((e) => LeaderboardEntry.fromJson(e)).toList();
    // Sort by score descending, then by timestamp descending
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
  }
}
