import 'dart:convert';

class QuizQuestion {
  final int id;
  final String question;
  final String answerCorrect;
  final String wrong1;
  final String wrong2;
  final String wrong3;
  final int difficulty; // 1: Easy, 2: Medium, 3: Hard
  final String category; // 'quran', 'seerah', 'aqeedah', 'fiqh', 'sahaba', 'prophets', 'adab', 'general'
  final String? explanation; // Educational note with daleel/source
  final String? categoryAr; // Arabic label for the faculty

  QuizQuestion({
    required this.id,
    required this.question,
    required this.answerCorrect,
    required this.wrong1,
    required this.wrong2,
    required this.wrong3,
    required this.difficulty,
    this.category = 'general',
    this.explanation,
    this.categoryAr,
  });

  factory QuizQuestion.fromMap(Map<String, dynamic> map) {
    return QuizQuestion(
      id: map['id'] as int? ?? 0,
      question: map['question']?.toString() ?? '',
      answerCorrect: map['answerCorrect']?.toString() ?? '',
      wrong1: map['wrong1']?.toString() ?? '',
      wrong2: map['wrong2']?.toString() ?? '',
      wrong3: map['wrong3']?.toString() ?? '',
      difficulty: map['difficulty'] as int? ?? 1,
      category: map['category']?.toString() ?? 'general',
      explanation: map['explanation']?.toString(),
      categoryAr: map['categoryAr']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'question': question,
      'answerCorrect': answerCorrect,
      'wrong1': wrong1,
      'wrong2': wrong2,
      'wrong3': wrong3,
      'difficulty': difficulty,
      'category': category,
      'explanation': explanation,
      'categoryAr': categoryAr,
    };
  }

  List<String> get allOptions {
    final list = [
      answerCorrect,
      if (wrong1.isNotEmpty) wrong1,
      if (wrong2.isNotEmpty) wrong2,
      if (wrong3.isNotEmpty) wrong3,
    ];
    return list;
  }
}

/// Tracks the user's answer for post-game review
class QuizAnswerRecord {
  final QuizQuestion question;
  final String selectedOption;
  final bool isCorrect;
  final int timeSpentSeconds;

  QuizAnswerRecord({
    required this.question,
    required this.selectedOption,
    required this.isCorrect,
    required this.timeSpentSeconds,
  });
}

/// Summary of a finished quiz session
class QuizSummary {
  final int score;
  final int totalQuestions;
  final int maxStreak;
  final int totalTimeSeconds;
  final List<QuizAnswerRecord> records;
  final String category;
  final String modeTitle;
  final DateTime timestamp;

  QuizSummary({
    required this.score,
    required this.totalQuestions,
    required this.maxStreak,
    required this.totalTimeSeconds,
    required this.records,
    this.category = 'all',
    this.modeTitle = 'تحدي شامل',
    required this.timestamp,
  });

  double get accuracy =>
      totalQuestions > 0 ? (score / totalQuestions) * 100 : 0.0;

  String get rankTitle {
    final acc = accuracy;
    if (score >= 20 || acc >= 90) {
      return 'علامة وباحث إسلامي متميز';
    } else if (score >= 12 || acc >= 75) {
      return 'حافظ متقن وراوٍ نجيب';
    } else if (score >= 6 || acc >= 50) {
      return 'طالب علم مجتهد';
    } else {
      return 'مبتدئ مبارك في مدارسة العلم';
    }
  }

  String get rankBadge {
    final acc = accuracy;
    if (score >= 20 || acc >= 90) return '👑';
    if (score >= 12 || acc >= 75) return '🌟';
    if (score >= 6 || acc >= 50) return '📜';
    return '🌱';
  }
}

/// Persistent player career stats
class PlayerCareerStats {
  final int totalGames;
  final int totalScore;
  final int bestScore;
  final int bestStreak;
  final String playerName;

  PlayerCareerStats({
    this.totalGames = 0,
    this.totalScore = 0,
    this.bestScore = 0,
    this.bestStreak = 0,
    this.playerName = '',
  });

  Map<String, dynamic> toMap() => {
        'totalGames': totalGames,
        'totalScore': totalScore,
        'bestScore': bestScore,
        'bestStreak': bestStreak,
        'playerName': playerName,
      };

  factory PlayerCareerStats.fromMap(Map<String, dynamic> map) =>
      PlayerCareerStats(
        totalGames: map['totalGames'] as int? ?? 0,
        totalScore: map['totalScore'] as int? ?? 0,
        bestScore: map['bestScore'] as int? ?? 0,
        bestStreak: map['bestStreak'] as int? ?? 0,
        playerName: map['playerName']?.toString() ?? '',
      );

  String toJson() => json.encode(toMap());

  factory PlayerCareerStats.fromJson(String source) =>
      PlayerCareerStats.fromMap(json.decode(source));
}

class LeaderboardEntry {
  final String playerName;
  final int score;
  final int totalQuestions;
  final DateTime timestamp;
  final String? category;

  LeaderboardEntry({
    required this.playerName,
    required this.score,
    required this.totalQuestions,
    required this.timestamp,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'playerName': playerName,
      'score': score,
      'totalQuestions': totalQuestions,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'category': category,
    };
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      playerName: map['playerName'] ?? 'Anonymous',
      score: map['score'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      category: map['category']?.toString(),
    );
  }

  String toJson() => json.encode(toMap());

  factory LeaderboardEntry.fromJson(String source) =>
      LeaderboardEntry.fromMap(json.decode(source));
}
