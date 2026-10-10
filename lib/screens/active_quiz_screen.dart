import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../core/constants/quiz_theme_colors.dart';
import '../models/quiz_models.dart';
import '../services/quiz_service.dart';
import '../widgets/liquid_pressable.dart';
import 'quiz_result_screen.dart';

class ActiveQuizScreen extends StatefulWidget {
  final String category;
  final String categoryTitle;
  final int? fixedDifficulty;
  final bool isBlitzMode;

  const ActiveQuizScreen({
    super.key,
    this.category = 'all',
    this.categoryTitle = 'تحدي المعرفة الإسلامية',
    this.fixedDifficulty,
    this.isBlitzMode = false,
  });

  @override
  State<ActiveQuizScreen> createState() => _ActiveQuizScreenState();
}

class _ActiveQuizScreenState extends State<ActiveQuizScreen>
    with SingleTickerProviderStateMixin {
  final QuizService _quizService = QuizService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();

  List<QuizQuestion> _questions = [];
  bool _isLoading = true;

  int _currentIndex = 0;
  int _score = 0;
  int _lives = 3;
  int _currentDifficulty = 1;
  int _currentStreak = 0;
  int _maxStreak = 0;
  final Stopwatch _questionStopwatch = Stopwatch();
  int _totalSessionSeconds = 0;

  // Lifelines
  bool _usedFiftyFifty = false;
  bool _usedExtraTime = false;
  bool _usedHint = false;
  final Set<String> _eliminatedOptions = {};
  bool _showHint = false;

  // Answer tracking for post-game review
  final List<QuizAnswerRecord> _answerRecords = [];

  // Feedback states
  bool _isAnswered = false;
  String _selectedOption = '';
  List<String> _currentOptions = [];

  // Timer & Settings
  late AnimationController _timerController;
  bool _soundEnabled = true;

  @override
  void initState() {
    super.initState();
    _currentDifficulty = widget.fixedDifficulty ?? 1;

    final durationSeconds = widget.isBlitzMode ? 15 : 30;
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: durationSeconds),
    );

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _handleTimeout();
      }
    });

    _initQuiz();
  }

  @override
  void dispose() {
    _timerController.dispose();
    _audioPlayer.dispose();
    _questionStopwatch.stop();
    super.dispose();
  }

  Future<void> _initQuiz() async {
    _soundEnabled = await _quizService.isSoundEnabled();

    final fetched = await _quizService.getQuestions(
      limit: 20,
      category: widget.category,
      difficulty: widget.fixedDifficulty,
    );

    if (mounted) {
      setState(() {
        _questions = fetched;
        _isLoading = false;
        if (_questions.isNotEmpty) {
          _prepareQuestion();
        }
      });
    }
  }

  void _prepareQuestion() {
    if (_currentIndex >= _questions.length) {
      _triggerGameComplete();
      return;
    }

    final q = _questions[_currentIndex];

    _eliminatedOptions.clear();
    _showHint = false;
    _isAnswered = false;
    _selectedOption = '';

    _currentOptions = List<String>.from(q.allOptions);
    _currentOptions.shuffle(_random);

    if (widget.fixedDifficulty == null) {
      if (_score >= 20) {
        _currentDifficulty = 3;
      } else if (_score >= 8) {
        _currentDifficulty = 2;
      } else {
        _currentDifficulty = 1;
      }
    }

    _questionStopwatch.reset();
    _questionStopwatch.start();

    _timerController.reset();
    _timerController.forward();
  }

  Future<void> _playSound(String assetPath) async {
    if (!_soundEnabled) return;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setAudioSource(
        AudioSource.asset(
          assetPath,
          tag: MediaItem(id: assetPath, title: 'Quiz Sound'),
        ),
      );
      await _audioPlayer.play();
    } catch (_) {}
  }

  void _onOptionSelected(String option) {
    if (_isAnswered || _eliminatedOptions.contains(option)) return;

    _timerController.stop();
    _questionStopwatch.stop();
    final elapsedSec = max(1, _questionStopwatch.elapsed.inSeconds);
    _totalSessionSeconds += elapsedSec;

    final q = _questions[_currentIndex];
    final isCorrect = option == q.answerCorrect;

    _answerRecords.add(QuizAnswerRecord(
      question: q,
      selectedOption: option,
      isCorrect: isCorrect,
      timeSpentSeconds: elapsedSec,
    ));

    setState(() {
      _isAnswered = true;
      _selectedOption = option;

      if (isCorrect) {
        _score++;
        _currentStreak++;
        if (_currentStreak > _maxStreak) {
          _maxStreak = _currentStreak;
        }

        if (_currentStreak == 5 || _currentStreak == 10) {
          if (_lives < 3) {
            _lives++;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '🎉 مكافأة السلسلة المتتالية ($_currentStreak متتالية)! استعدت قلباً إضافياً ❤️',
                  style: const TextStyle(fontFamily: 'Amiri', fontSize: 13),
                ),
                backgroundColor: const Color(0xFF1B8A6B),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        _currentStreak = 0;
        _lives--;
      }
    });

    if (isCorrect) {
      HapticFeedback.lightImpact();
      final soundNum = _random.nextBool() ? 1 : 2;
      _playSound('assets/audio/coreec_ans_$soundNum.mp3');
    } else {
      HapticFeedback.heavyImpact();
      _playSound('assets/audio/wrong_ans.mp3');
    }
  }

  void _handleTimeout() {
    if (_isAnswered) return;

    _questionStopwatch.stop();
    final elapsedSec = widget.isBlitzMode ? 15 : 30;
    _totalSessionSeconds += elapsedSec;

    final q = _questions[_currentIndex];

    _answerRecords.add(QuizAnswerRecord(
      question: q,
      selectedOption: 'انتهى الوقت ولم تجب',
      isCorrect: false,
      timeSpentSeconds: elapsedSec,
    ));

    HapticFeedback.mediumImpact();
    _playSound('assets/audio/wrong_ans.mp3');

    setState(() {
      _isAnswered = true;
      _selectedOption = '';
      _currentStreak = 0;
      _lives--;
    });
  }

  void _proceedToNext() {
    if (_lives <= 0) {
      _triggerGameComplete();
    } else if (_currentIndex + 1 >= _questions.length) {
      _triggerGameComplete();
    } else {
      setState(() {
        _currentIndex++;
        _prepareQuestion();
      });
    }
  }

  void _useFiftyFifty() {
    if (_usedFiftyFifty || _isAnswered) return;
    HapticFeedback.selectionClick();

    final q = _questions[_currentIndex];
    final wrongs = _currentOptions.where((opt) => opt != q.answerCorrect).toList();
    wrongs.shuffle(_random);

    setState(() {
      _usedFiftyFifty = true;
      for (int i = 0; i < min(2, wrongs.length); i++) {
        _eliminatedOptions.add(wrongs[i]);
      }
    });
  }

  void _useExtraTime() {
    if (_usedExtraTime || _isAnswered) return;
    HapticFeedback.selectionClick();

    setState(() {
      _usedExtraTime = true;
      final remainingRatio = 1.0 - _timerController.value;
      final addedRatio = 15.0 / (widget.isBlitzMode ? 15.0 : 30.0);
      final newRatio = min(1.0, remainingRatio + addedRatio);
      _timerController.value = 1.0 - newRatio;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          '⏳ تم تمديد الوقت (+15 ثانية)',
          style: TextStyle(fontFamily: 'Amiri', fontSize: 13),
        ),
        backgroundColor: Color(0xFF1B8A6B),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _useHint() {
    if (_usedHint || _isAnswered) return;
    HapticFeedback.selectionClick();

    setState(() {
      _usedHint = true;
      _showHint = true;
    });
  }

  void _triggerGameComplete() {
    _questionStopwatch.stop();

    final summary = QuizSummary(
      score: _score,
      totalQuestions: _answerRecords.length,
      maxStreak: _maxStreak,
      totalTimeSeconds: _totalSessionSeconds,
      records: List.unmodifiable(_answerRecords),
      category: widget.category,
      modeTitle: widget.categoryTitle,
      timestamp: DateTime.now(),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultScreen(summary: summary),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_isAnswered && _lives <= 0) return true;

    final qc = QuizColors.of(context);

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: qc.cardBg,
        title: Row(
          children: [
            Icon(Icons.door_back_door_rounded, color: qc.goldAccent, size: 24),
            const SizedBox(width: 8),
            Text(
              'الخروج من التحدي؟',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
                color: qc.textPrimary,
              ),
            ),
          ],
        ),
        content: Text(
          'هل تريد إنهاء الجولة الحالية؟ سيتم حفظ نتيجتك الحالية في ملخص الجولة.',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 14,
            color: qc.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('متابعة اللعب', style: TextStyle(color: qc.emeraldPrimary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(ctx, true);
            },
            child: const Text('إنهاء وحفظ', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      _triggerGameComplete();
      return false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final qc = QuizColors.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: qc.screenBg,
        body: Center(
          child: CircularProgressIndicator(color: qc.goldAccent),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: qc.screenBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: qc.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Text(
            'لم يتم العثور على أسئلة.',
            style: TextStyle(color: qc.textPrimary, fontSize: 18, fontFamily: 'Amiri'),
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onWillPop();
      },
      child: Scaffold(
        backgroundColor: qc.screenBg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Royal Header Bar ───────────────────────────────────────────
              _buildRoyalHeader(qc),

              // ── Smooth Dynamic Timer Indicator ────────────────────────────
              _buildTimerProgress(),

              // ── Main Gameplay Body (Scrollable for Small Screens) ─────────
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Lifelines Dock
                      _buildLifelinesDock(qc),

                      const SizedBox(height: 12),

                      // Monumental Question Card
                      _buildQuestionCard(question, qc),

                      // Hint Box (if lifeline used)
                      if (_showHint) ...[
                        const SizedBox(height: 10),
                        _buildHintBox(question, qc),
                      ],

                      const SizedBox(height: 16),

                      // 4 Interactive Options (أ، ب، ج، د)
                      _buildOptionsList(question, qc),

                      const SizedBox(height: 16),

                      // Educational Insight Card (Revealed on Answer)
                      if (_isAnswered) _buildEducationalInsight(question, qc),
                    ],
                  ),
                ),
              ),

              // ── Bottom Action Proceed Button ───────────────────────────────
              if (_isAnswered) _buildBottomProceedButton(qc),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI Builder Components
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildRoyalHeader(QuizColors qc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: qc.cardBg,
        border: Border(
          bottom: BorderSide(
            color: qc.isDark ? Colors.white12 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 22),
            color: qc.textPrimary,
            onPressed: _onWillPop,
            tooltip: 'إنهاء التحدي',
          ),

          // Difficulty Badge (high-contrast across all modes)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: _currentDifficulty == 3
                  ? qc.diffHardBg
                  : (_currentDifficulty == 2 ? qc.diffMediumBg : qc.diffEasyBg),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _currentDifficulty == 3
                    ? qc.diffHardText.withValues(alpha: 0.5)
                    : (_currentDifficulty == 2
                        ? qc.diffMediumText.withValues(alpha: 0.5)
                        : qc.diffEasyText.withValues(alpha: 0.5)),
                width: 0.8,
              ),
            ),
            child: Text(
              _currentDifficulty == 3
                  ? 'مستوى متقدم'
                  : (_currentDifficulty == 2 ? 'مستوى متوسط' : 'مستوى سهل'),
              style: TextStyle(
                color: _currentDifficulty == 3
                    ? qc.diffHardText
                    : (_currentDifficulty == 2 ? qc.diffMediumText : qc.diffEasyText),
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
              ),
            ),
          ),

          // Score & Streak Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: qc.goldPillBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: qc.goldBorder,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars_rounded, color: qc.goldAccent, size: 18),
                const SizedBox(width: 5),
                Text(
                  '$_score',
                  style: TextStyle(
                    color: qc.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                if (_currentStreak >= 2) ...[
                  const SizedBox(width: 8),
                  Text(
                    '🔥 x$_currentStreak',
                    style: const TextStyle(
                      color: Color(0xFFFF7043),
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Hearts / Lives Gauge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              final isAlive = index < _lives;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  isAlive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: isAlive ? const Color(0xFFE53935) : (qc.isDark ? Colors.white24 : Colors.black26),
                  size: 20,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerProgress() {
    return AnimatedBuilder(
      animation: _timerController,
      builder: (context, child) {
        final progress = 1.0 - _timerController.value;
        Color timerColor = const Color(0xFF1B8A6B);
        if (progress < 0.25) {
          timerColor = const Color(0xFFE53935);
        } else if (progress < 0.50) {
          timerColor = const Color(0xFFFFA000);
        }

        return Container(
          height: 4.5,
          width: double.infinity,
          color: Colors.black12,
          child: Align(
            alignment: Alignment.centerRight,
            child: Container(
              height: 4.5,
              width: MediaQuery.of(context).size.width * progress,
              decoration: BoxDecoration(
                color: timerColor,
                boxShadow: [
                  BoxShadow(
                    color: timerColor.withValues(alpha: 0.6),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLifelinesDock(QuizColors qc) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLifelineButton(
          title: '50:50',
          subtitle: 'حذف خيارين',
          icon: Icons.filter_2_rounded,
          isUsed: _usedFiftyFifty,
          onTap: _useFiftyFifty,
          qc: qc,
        ),
        _buildLifelineButton(
          title: '+15 ثانية',
          subtitle: 'تمديد الوقت',
          icon: Icons.more_time_rounded,
          isUsed: _usedExtraTime,
          onTap: _useExtraTime,
          qc: qc,
        ),
        _buildLifelineButton(
          title: 'تلميح',
          subtitle: 'كشف فائدة',
          icon: Icons.lightbulb_outline_rounded,
          isUsed: _usedHint,
          onTap: _useHint,
          qc: qc,
        ),
      ],
    );
  }

  Widget _buildLifelineButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isUsed,
    required VoidCallback onTap,
    required QuizColors qc,
  }) {
    return LiquidPressable(
      onTap: isUsed ? () {} : onTap,
      child: Opacity(
        opacity: isUsed ? 0.35 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: qc.cardSubtleBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isUsed
                  ? (qc.isDark ? Colors.white12 : Colors.black12)
                  : qc.goldBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: qc.isDark ? 0.2 : 0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isUsed ? qc.textMuted : qc.goldAccent),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isUsed ? qc.textMuted : qc.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Amiri',
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: qc.textMuted,
                      fontSize: 9.5,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(QuizQuestion question, QuizColors qc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: qc.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: qc.goldBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: qc.isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Question Header Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: qc.emeraldPillBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'السؤال ${_currentIndex + 1} من ${_questions.length}',
                  style: TextStyle(
                    color: qc.emeraldPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                    fontFamily: 'Amiri',
                  ),
                ),
              ),
              if (question.categoryAr != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: qc.goldPillBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    question.categoryAr!,
                    style: TextStyle(
                      color: qc.goldAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Question Prompt in Classical Amiri Typography
          Text(
            question.question,
            style: TextStyle(
              color: qc.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Amiri',
              height: 1.45,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  Widget _buildHintBox(QuizQuestion question, QuizColors qc) {
    final hintText = question.explanation != null
        ? '💡 تلميح: فكر في سياق ${question.categoryAr ?? "المسألة الشرعية"}'
        : '💡 تلميح: استبعد الخيار الأبعد عن المنطق الشرعي';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: qc.goldPillBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: qc.goldBorder, width: 0.9),
      ),
      child: Text(
        hintText,
        style: TextStyle(
          color: qc.goldAccent,
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          fontFamily: 'Amiri',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildOptionsList(QuizQuestion question, QuizColors qc) {
    const letters = ['أ', 'ب', 'ج', 'د'];

    return Column(
      children: List.generate(_currentOptions.length, (index) {
        final option = _currentOptions[index];
        final isEliminated = _eliminatedOptions.contains(option);

        if (isEliminated) {
          return const SizedBox.shrink();
        }

        // Color and state determination
        Color btnBg = qc.cardBg;
        Color btnBorder = qc.isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.08);
        Color btnText = qc.textPrimary;
        Widget? trailingIcon;

        if (_isAnswered) {
          if (option == question.answerCorrect) {
            btnBg = const Color(0xFF1B8A6B);
            btnBorder = const Color(0xFF2ECC71);
            btnText = Colors.white;
            trailingIcon = const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20);
          } else if (option == _selectedOption) {
            btnBg = const Color(0xFFB71C1C);
            btnBorder = const Color(0xFFE53935);
            btnText = Colors.white;
            trailingIcon = const Icon(Icons.cancel_rounded, color: Colors.white, size: 20);
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 11),
          child: LiquidPressable(
            onTap: () => _onOptionSelected(option),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: btnBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: btnBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: qc.isDark ? 0.25 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Letter Badge (أ، ب، ج، د)
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isAnswered && (option == question.answerCorrect || option == _selectedOption)
                          ? Colors.white24
                          : qc.cardSubtleBg,
                      border: Border.all(
                        color: _isAnswered && (option == question.answerCorrect || option == _selectedOption)
                            ? Colors.white
                            : qc.goldBorder,
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      letters[index % letters.length],
                      style: TextStyle(
                        color: _isAnswered && (option == question.answerCorrect || option == _selectedOption)
                            ? Colors.white
                            : qc.goldAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Amiri',
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Option Text
                  Expanded(
                    child: Text(
                      option,
                      style: TextStyle(
                        color: btnText,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Amiri',
                        height: 1.3,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),

                  if (trailingIcon != null) trailingIcon,
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEducationalInsight(QuizQuestion question, QuizColors qc) {
    final explanation = question.explanation;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: qc.cardSubtleBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: qc.goldBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: qc.isDark ? 0.35 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, color: qc.goldAccent, size: 18),
              const SizedBox(width: 8),
              Text(
                'فائدة وتوضيح مع الدليل الشرعي',
                style: TextStyle(
                  color: qc.goldAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Amiri',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            explanation ??
                'الإجابة الصحيحة هي: «${question.answerCorrect}». مدارسة العلم الإسلامي من أعظم القربات إلى الله تعالى.',
            style: TextStyle(
              color: qc.textSecondary,
              fontSize: 13,
              fontFamily: 'Amiri',
              height: 1.45,
            ),
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomProceedButton(QuizColors qc) {
    final isLast = _currentIndex + 1 >= _questions.length || _lives <= 0;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
      decoration: BoxDecoration(
        color: qc.cardBg,
        border: Border(
          top: BorderSide(
            color: qc.isDark ? Colors.white12 : Colors.black12,
            width: 1,
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1B8A6B),
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onPressed: _proceedToNext,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLast ? 'عرض نتيجة الجولة' : 'السؤال التالي',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isLast ? Icons.emoji_events_rounded : Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
