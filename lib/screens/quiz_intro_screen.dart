import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../theme_notifier.dart';
import '../models/quiz_models.dart';
import '../services/quiz_service.dart';
import 'active_quiz_screen.dart';

class QuizIntroScreen extends StatefulWidget {
  const QuizIntroScreen({super.key});

  @override
  State<QuizIntroScreen> createState() => _QuizIntroScreenState();
}

class _QuizIntroScreenState extends State<QuizIntroScreen> {
  final QuizService _quizService = QuizService();
  List<LeaderboardEntry> _leaderboard = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
    final entries = await _quizService.getLeaderboard();
    if (mounted) {
      setState(() {
        _leaderboard = entries;
        _isLoading = false;
      });
    }
  }

  void _startQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ActiveQuizScreen()),
    ).then((_) {
      // Reload leaderboard when coming back from quiz
      _loadLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.notifier.value;
    final isDark = theme == QuranTheme.dark;

    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimary : AppColors.emeraldDeep;
    final cardBg = isDark ? AppColors.surfaceCard : AppColors.surfaceCardLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'تحدي المعرفة',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),
          // Start Quiz Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: InkWell(
              onTap: _startQuiz,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.emeraldLight, AppColors.emeraldDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.emeraldDeep.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  children: [
                    Icon(Icons.emoji_events_rounded,
                        color: Colors.white, size: 48),
                    SizedBox(height: 16),
                    Text(
                      'ابدأ التحدي',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'اختبر معلوماتك الإسلامية',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Hall of Fame Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
              const SizedBox(width: 8),
              Text(
                'لوحة الشرف',
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 28),
            ],
          ),
          const SizedBox(height: 16),

          // Leaderboard List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.emeraldLight))
                : _leaderboard.isEmpty
                    ? Center(
                        child: Text(
                          'كن أول من يسجل اسمه في لوحة الشرف!',
                          style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.textMuted),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 8),
                        itemCount: _leaderboard.length,
                        itemBuilder: (context, index) {
                          final entry = _leaderboard[index];

                          // Crown icon for top 3
                          Widget? crown;
                          if (index == 0) {
                            crown = const Icon(Icons.workspace_premium,
                                color: Colors.amber, size: 28);
                          } else if (index == 1) {
                            crown = Icon(Icons.workspace_premium,
                                color: Colors.grey.shade400, size: 28);
                          } else if (index == 2) {
                            crown = const Icon(Icons.workspace_premium,
                                color: Colors.deepOrangeAccent, size: 28);
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: index < 3
                                    ? Colors.amber.withValues(alpha: 0.5)
                                    : (isDark
                                        ? AppColors.divider
                                        : Colors.grey.shade200),
                                width: index < 3 ? 1.5 : 0.5,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: isDark
                                    ? AppColors.surfaceDark
                                    : AppColors.surfaceLight,
                                child: Text(
                                  '#${index + 1}',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    entry.playerName,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (crown != null) ...[
                                    const SizedBox(width: 8),
                                    crown,
                                  ]
                                ],
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${entry.score}/${entry.totalQuestions}',
                                    style: const TextStyle(
                                      color: AppColors.emeraldLight,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  Text(
                                    'نقطة',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppColors.textSecondary
                                          : AppColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
