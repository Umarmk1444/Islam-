import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';
import '../theme_notifier.dart';
import '../models/quiz_models.dart';
import '../services/quiz_service.dart';

class QuizResultScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;

  const QuizResultScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  final TextEditingController _nameController = TextEditingController();
  final QuizService _quizService = QuizService();
  bool _isSaving = false;

  Future<void> _saveScore() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);

    final entry = LeaderboardEntry(
      playerName: name,
      score: widget.score,
      totalQuestions: widget.totalQuestions,
      timestamp: DateTime.now(),
    );

    await _quizService.saveToLeaderboard(entry);

    if (mounted) {
      Navigator.pop(context); // Go back to intro
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.notifier.value;
    final isDark = theme == QuranTheme.dark;

    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimary : AppColors.emeraldDeep;
    final cardBg = isDark ? AppColors.surfaceCard : AppColors.surfaceCardLight;

    final double percentage = widget.score / widget.totalQuestions;
    final bool isExcellent = percentage >= 0.8;
    final bool isGood = percentage >= 0.5 && percentage < 0.8;

    String titleMessage = 'محاولة جيدة!';
    if (isExcellent) {
      titleMessage = 'ما شاء الله! إنجاز رائع!';
    } else if (isGood) {
      titleMessage = 'أحسنت! أداء جيد!';
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            // Score Circle with glow
            Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bgColor,
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isExcellent ? Colors.amber : AppColors.emeraldLight)
                              .withValues(alpha: 0.4),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                  border: Border.all(
                    color: isExcellent ? Colors.amber : AppColors.emeraldLight,
                    width: 4,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${widget.score}',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 2,
                      color: isDark ? AppColors.divider : AppColors.textMuted.withValues(alpha: 0.2),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    Text(
                      '${widget.totalQuestions}',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textMuted,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
              )
                  .animate(
                      onPlay: (controller) => controller.repeat(reverse: true))
                  .scaleXY(
                      end: 1.05,
                      duration: 1500.ms,
                      curve: Curves.easeInOutSine),
            ),
            const SizedBox(height: 40),

            // Message
            Text(
              titleMessage,
              style: TextStyle(
                color: isExcellent ? Colors.amber : AppColors.emeraldLight,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ).animate().fade(duration: 800.ms).slideY(begin: 0.2, end: 0),

            const SizedBox(height: 48),

            // Name Input if score >= 10
            if (widget.score >= 10) ...[
              Text(
                'لقد حققت نتيجة رائعة وتجاوزت حاجز الـ 10 نقاط! أدخل اسمك لتخليده في لوحة الشرف.',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondary : AppColors.textMuted,
                  fontSize: 16,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ).animate().fade(delay: 500.ms, duration: 800.ms),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark ? AppColors.divider : AppColors.textMuted.withValues(alpha: 0.2)),
                ),
                child: TextField(
                  controller: _nameController,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: textColor, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'اسم اللاعب...',
                    hintStyle: TextStyle(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                  ),
                ),
              )
                  .animate()
                  .fade(delay: 800.ms, duration: 800.ms)
                  .slideY(begin: 0.2, end: 0),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveScore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'حفظ النتيجة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ).animate().fade(delay: 1000.ms, duration: 800.ms),
            ] else ...[
              // Score < 10 (Game Over)
              Text(
                'تحتاج إلى 10 نقاط على الأقل لدخول لوحة الشرف. حاول مرة أخرى!',
                style: TextStyle(
                  color: isDark ? AppColors.textSecondary : AppColors.textMuted,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ).animate().fade(delay: 500.ms, duration: 800.ms),
              const SizedBox(height: 32),

              // Try Again Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(
                        context); // Go back to Intro, user can start again
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.emeraldLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'حاول مجدداً',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ).animate().fade(delay: 800.ms, duration: 800.ms),
              const SizedBox(height: 16),

              // Main Menu Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: AppColors.emeraldLight, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'الرئيسية',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.emeraldLight,
                    ),
                  ),
                ),
              ).animate().fade(delay: 1000.ms, duration: 800.ms),
            ]
          ],
        ),
      ),
    );
  }
}
