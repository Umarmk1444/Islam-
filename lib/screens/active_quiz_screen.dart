import 'dart:async';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../theme_notifier.dart';
import '../models/quiz_models.dart';
import '../services/quiz_service.dart';
import 'quiz_result_screen.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'dart:math';

class ActiveQuizScreen extends StatefulWidget {
  const ActiveQuizScreen({super.key});

  @override
  State<ActiveQuizScreen> createState() => _ActiveQuizScreenState();
}

class _ActiveQuizScreenState extends State<ActiveQuizScreen>
    with SingleTickerProviderStateMixin {
  final QuizService _quizService = QuizService();
  final List<QuizQuestion> _questions = [];
  bool _isLoading = true;

  int _currentIndex = 0;
  int _score = 0;
  int _lives = 2;
  int _currentDifficulty = 1;

  // State for visual feedback
  bool _isAnswered = false;
  String _selectedOption = '';
  List<String> _currentOptions = [];

  // Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();

  // Timer
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _handleWrongAnswerOrTimeout();
      }
    });

    _loadMoreQuestions();
  }

  @override
  void dispose() {
    _timerController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadMoreQuestions() async {
    final newQuestions = await _quizService
        .getQuestionsByDifficulty(_currentDifficulty, limit: 15);

    if (mounted) {
      setState(() {
        _questions.addAll(newQuestions);
        _isLoading = false;
        if (_currentIndex == 0 && _questions.isNotEmpty) {
          _prepareQuestion();
        }
      });
    }
  }

  void _prepareQuestion() {
    if (_currentIndex >= _questions.length - 2) {
      // Pre-fetch more questions when nearing the end of the pool
      _checkAndUpgradeDifficulty();
      _loadMoreQuestions();
    }

    final q = _questions[_currentIndex];
    _currentOptions = [
      q.answerCorrect,
      if (q.wrong1.isNotEmpty) q.wrong1,
      if (q.wrong2.isNotEmpty) q.wrong2,
      if (q.wrong3.isNotEmpty) q.wrong3,
    ];
    // Shuffle options
    _currentOptions.shuffle();

    // Start timer
    _timerController.reset();
    _timerController.forward();
  }

  void _checkAndUpgradeDifficulty() {
    if (_score >= 25) {
      _currentDifficulty = 3;
    } else if (_score >= 10) {
      _currentDifficulty = 2;
    }
  }

  Future<void> _playSound(String assetPath) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setAudioSource(
        AudioSource.asset(
          assetPath,
          tag: MediaItem(
            id: assetPath,
            title: 'Quiz Sound',
          ),
        ),
      );
      _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  void _handleWrongAnswerOrTimeout({String? selectedOption}) {
    if (_isAnswered) return;

    _timerController.stop();

    _playSound('assets/audio/wrong_ans.mp3');

    setState(() {
      _isAnswered = true;
      _selectedOption = selectedOption ?? '';
    });

    if (_lives > 0) {
      _showLifelineDialog();
    } else {
      // Game Over immediately if no lives left
      _triggerGameOver();
    }
  }

  void _showLifelineDialog() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppTheme.notifier.value == QuranTheme.dark
              ? AppColors.surfaceCard
              : AppColors.surfaceCardLight,
          title: const Row(
            children: [
              Icon(Icons.favorite, color: Colors.redAccent, size: 28),
              SizedBox(width: 8),
              Text('استخدام مساعدة؟',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'لديك $_lives قلوب متبقية. هل تريد استخدام قلب واحد لمعرفة الإجابة الصحيحة والمتابعة؟',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _triggerGameOver();
              },
              child: const Text('استسلم',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emeraldLight),
              onPressed: () {
                Navigator.pop(ctx);
                _useLifeline();
              },
              child: const Text('استخدم المساعدة',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    });
  }

  void _useLifeline() {
    setState(() {
      _lives--;
      // Ensure the correct answer is highlighted, then move on
      _selectedOption = _questions[_currentIndex].answerCorrect;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      _moveToNextQuestion();
    });
  }

  void _onOptionSelected(String option) {
    if (_isAnswered) return;

    _timerController.stop();
    final isCorrect = option == _questions[_currentIndex].answerCorrect;

    if (isCorrect) {
      final soundNum = _random.nextBool() ? 1 : 2;
      _playSound('assets/audio/coreec_ans_$soundNum.mp3');

      setState(() {
        _isAnswered = true;
        _selectedOption = option;
        _score++;

        // Bonus life rule
        if (_score == 10) {
          _lives++;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 حصلت على قلب إضافي! (مكافأة 10 نقاط)'),
              backgroundColor: AppColors.emeraldLight,
              duration: Duration(seconds: 3),
            ),
          );
        }
      });

      Future.delayed(const Duration(milliseconds: 1200), () {
        _moveToNextQuestion();
      });
    } else {
      _handleWrongAnswerOrTimeout(selectedOption: option);
    }
  }

  void _moveToNextQuestion() {
    if (!mounted) return;
    setState(() {
      _currentIndex++;
      _isAnswered = false;
      _selectedOption = '';
      _prepareQuestion();
    });
  }

  void _triggerGameOver() {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => QuizResultScreen(
            score: _score,
            totalQuestions: _currentIndex + 1,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.notifier.value;
    final isDark = theme == QuranTheme.dark;

    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimary : AppColors.emeraldDeep;
    final cardBg = isDark ? AppColors.surfaceCard : AppColors.surfaceCardLight;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.emeraldLight)),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
        ),
        body: Center(
          child: Text(
            'لم يتم العثور على أسئلة.',
            style: TextStyle(color: textColor, fontSize: 18),
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.stars_rounded, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '$_score',
                  style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ],
            ),
            Text(
              'مستوى $_currentDifficulty',
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Row(
              children: List.generate(3, (index) {
                if (index < _lives) {
                  return const Icon(Icons.favorite,
                      color: Colors.redAccent, size: 20);
                } else if (index == 2 && _lives > 2) {
                  return Text('+$_lives',
                      style: TextStyle(
                          color: textColor)); // If they somehow get more
                } else {
                  return const Icon(Icons.favorite_border,
                      color: AppColors.textMuted, size: 20);
                }
              }).take(3).toList(),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timer Progress Bar
            AnimatedBuilder(
              animation: _timerController,
              builder: (context, child) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 1.0 - _timerController.value,
                    backgroundColor: AppColors.textMuted.withValues(alpha: 0.5),
                    color: _timerController.value > 0.7
                        ? Colors.redAccent
                        : AppColors.emeraldLight,
                    minHeight: 12,
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Question Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: isDark
                      ? AppColors.divider
                      : AppColors.textMuted.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                question.question,
                style: TextStyle(
                  color: textColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
              ),
            ),
            const SizedBox(height: 32),

            // Options
            Expanded(
              child: ListView.builder(
                itemCount: _currentOptions.length,
                itemBuilder: (context, index) {
                  final option = _currentOptions[index];

                  // Determine colors based on answered state
                  Color btnBgColor = cardBg;
                  Color btnBorderColor = isDark
                      ? AppColors.divider
                      : AppColors.textMuted.withValues(alpha: 0.2);
                  Color btnTextColor = textColor;

                  if (_isAnswered) {
                    if (option == question.answerCorrect) {
                      btnBgColor = Colors.green.shade600;
                      btnBorderColor = Colors.green.shade600;
                      btnTextColor = Colors.white;
                    } else if (option == _selectedOption) {
                      btnBgColor = Colors.red.shade600;
                      btnBorderColor = Colors.red.shade600;
                      btnTextColor = Colors.white;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InkWell(
                      onTap: () => _onOptionSelected(option),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 24),
                        decoration: BoxDecoration(
                          color: btnBgColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: btnBorderColor, width: 1.5),
                          boxShadow: [
                            if (_isAnswered &&
                                (option == question.answerCorrect ||
                                    option == _selectedOption))
                              BoxShadow(
                                color: btnBgColor.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Text(
                          option,
                          style: TextStyle(
                            color: btnTextColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
