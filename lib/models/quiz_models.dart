import 'dart:convert';

class QuizQuestion {
  final int id;
  final String question;
  final String answerCorrect;
  final String wrong1;
  final String wrong2;
  final String wrong3;
  final int difficulty;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.answerCorrect,
    required this.wrong1,
    required this.wrong2,
    required this.wrong3,
    required this.difficulty,
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
    );
  }
}

class LeaderboardEntry {
  final String playerName;
  final int score;
  final int totalQuestions;
  final DateTime timestamp;

  LeaderboardEntry({
    required this.playerName,
    required this.score,
    required this.totalQuestions,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'playerName': playerName,
      'score': score,
      'totalQuestions': totalQuestions,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      playerName: map['playerName'] ?? 'Anonymous',
      score: map['score'] ?? 0,
      totalQuestions: map['totalQuestions'] ?? 0,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }

  String toJson() => json.encode(toMap());

  factory LeaderboardEntry.fromJson(String source) => 
      LeaderboardEntry.fromMap(json.decode(source));
}
