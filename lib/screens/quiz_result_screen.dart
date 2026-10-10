import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../core/constants/quiz_theme_colors.dart';
import '../models/quiz_models.dart';
import '../services/quiz_service.dart';
import '../widgets/liquid_pressable.dart';
import 'active_quiz_screen.dart';

class QuizResultScreen extends StatefulWidget {
  final QuizSummary? summary;
  final int? score;
  final int? totalQuestions;

  const QuizResultScreen({
    super.key,
    this.summary,
    this.score,
    this.totalQuestions,
  });

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  final TextEditingController _nameController = TextEditingController();
  final QuizService _quizService = QuizService();

  late final QuizSummary _resolvedSummary;
  bool _isSaving = false;
  bool _hasSaved = false;
  bool _showReview = false;

  @override
  void initState() {
    super.initState();
    if (widget.summary != null) {
      _resolvedSummary = widget.summary!;
    } else {
      final s = widget.score ?? 0;
      final t = widget.totalQuestions ?? max(1, s);
      _resolvedSummary = QuizSummary(
        score: s,
        totalQuestions: t,
        maxStreak: 0,
        totalTimeSeconds: 0,
        records: const [],
        timestamp: DateTime.now(),
      );
    }

    _loadSavedName();
  }

  Future<void> _loadSavedName() async {
    final stats = await _quizService.getCareerStats();
    if (stats.playerName.isNotEmpty && mounted) {
      setState(() {
        _nameController.text = stats.playerName;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveScore() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء كتابة اسمك لتسجيل النتيجة في لوحة الشرف'),
          backgroundColor: Color(0xFFD4AF37),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final entry = LeaderboardEntry(
      playerName: name,
      score: _resolvedSummary.score,
      totalQuestions: _resolvedSummary.totalQuestions,
      timestamp: DateTime.now(),
      category: _resolvedSummary.category,
    );

    await _quizService.saveToLeaderboard(entry);

    if (mounted) {
      setState(() {
        _isSaving = false;
        _hasSaved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🏆 تم تخليد نتيجتك بنجاح في لوحة الشرف!'),
          backgroundColor: Color(0xFF1B8A6B),
        ),
      );
    }
  }

  void _shareResult() {
    final rank = _resolvedSummary.rankTitle;
    final acc = _resolvedSummary.accuracy.toStringAsFixed(1);
    final text = '🏆 حققت رتبة «$rank» في مسابقة المعرفة الإسلامية بنتيجة '
        '${_resolvedSummary.score} من ${_resolvedSummary.totalQuestions} (دقة $acc%)!\n'
        '✨ تطبيق الإسلام - موسوعة المعرفة والقرآن والسنة.';
    Share.share(text);
  }

  int max(int a, int b) => a > b ? a : b;

  @override
  Widget build(BuildContext context) {
    final qc = QuizColors.of(context);

    return Scaffold(
      backgroundColor: qc.screenBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: qc.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share_rounded, color: qc.goldAccent),
            tooltip: 'مشاركة النتيجة',
            onPressed: _shareResult,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          children: [
            // ── 1. Royal Coronation Card ──────────────────────────────────────
            _buildCoronationCard(qc),

            const SizedBox(height: 18),

            // ── 2. Performance Metrics Grid (4 Key stats) ─────────────────────
            _buildMetricsGrid(qc),

            const SizedBox(height: 20),

            // ── 3. Hall of Fame Save Card ─────────────────────────────────────
            _buildHallOfFameCard(qc),

            const SizedBox(height: 20),

            // ── 4. Question Review Accordion ──────────────────────────────────
            if (_resolvedSummary.records.isNotEmpty)
              _buildReviewSection(qc),

            const SizedBox(height: 24),

            // ── 5. Action Buttons (Play Again & Home) ─────────────────────────
            _buildActionButtons(qc),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Component Builders
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildCoronationCard(QuizColors qc) {
    final acc = _resolvedSummary.accuracy;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: qc.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: qc.goldBorder,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: qc.isDark ? 0.35 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Royal Medal Medallion
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: qc.isDark ? const Color(0xFF0A1411) : const Color(0xFFF9F5EB),
              border: Border.all(
                color: qc.goldAccent,
                width: 2.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: qc.goldAccent.withValues(alpha: qc.isDark ? 0.35 : 0.18),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              _resolvedSummary.rankBadge,
              style: const TextStyle(fontSize: 38),
            ),
          ),

          const SizedBox(height: 14),

          // Honorary Title (Calibrated bronze on light, radiant gold on dark!)
          Text(
            _resolvedSummary.rankTitle,
            style: TextStyle(
              color: qc.goldAccent,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Amiri',
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 6),

          // Score & Accuracy Subtitle
          Text(
            'حصدت ${_resolvedSummary.score} نقطة من أصل ${_resolvedSummary.totalQuestions} بنسبة دقة ${acc.toStringAsFixed(1)}%',
            style: TextStyle(
              color: qc.textSecondary,
              fontSize: 13,
              fontFamily: 'Amiri',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(QuizColors qc) {
    final incorrect =
        max(0, _resolvedSummary.totalQuestions - _resolvedSummary.score);

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            title: 'صحيحة',
            value: '${_resolvedSummary.score}',
            icon: Icons.check_circle_outline_rounded,
            color: const Color(0xFF2ECC71),
            qc: qc,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            title: 'أخطاء',
            value: '$incorrect',
            icon: Icons.highlight_off_rounded,
            color: const Color(0xFFE53935),
            qc: qc,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            title: 'أطول سلسلة',
            value: '🔥 ${_resolvedSummary.maxStreak}',
            icon: Icons.local_fire_department_rounded,
            color: const Color(0xFFFF9800),
            qc: qc,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            title: 'الزمن',
            value: '${_resolvedSummary.totalTimeSeconds}ث',
            icon: Icons.timer_outlined,
            color: const Color(0xFF42A5F5),
            qc: qc,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required QuizColors qc,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: qc.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: qc.isDark ? 0.35 : 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: qc.isDark ? 0.20 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: qc.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              color: qc.textMuted,
              fontSize: 10.5,
              fontFamily: 'Amiri',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHallOfFameCard(QuizColors qc) {
    if (_hasSaved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: qc.emeraldPillBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: qc.emeraldBorder, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stars_rounded, color: qc.goldAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              'تم حفظ نتيجتك في لوحة الشرف بنجاح! 🏆',
              style: TextStyle(
                color: qc.emeraldPrimary,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: qc.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: qc.goldBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: qc.isDark ? 0.20 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: qc.goldAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'تخليد الإنجاز في لوحة الشرف',
                style: TextStyle(
                  color: qc.goldAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: 'Amiri',
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'سجل اسمك ليظهر بين الأوائل على مستوى التطبيق:',
            style: TextStyle(
              color: qc.textSecondary,
              fontSize: 12,
              fontFamily: 'Amiri',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: qc.cardSubtleBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: qc.goldBorder),
                  ),
                  child: TextField(
                    controller: _nameController,
                    style: TextStyle(color: qc.textPrimary, fontSize: 14, fontFamily: 'Amiri'),
                    decoration: InputDecoration(
                      hintText: 'اكتب اسمك أو كنيتك هنا...',
                      hintStyle: TextStyle(color: qc.textMuted, fontSize: 12.5),
                      border: InputBorder.none,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B8A6B),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onPressed: _isSaving ? null : _saveScore,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'حفظ',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Amiri',
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(QuizColors qc) {
    return Container(
      decoration: BoxDecoration(
        color: qc.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: qc.goldBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: qc.isDark ? 0.20 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          LiquidPressable(
            onTap: () {
              setState(() => _showReview = !_showReview);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: qc.goldAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'مراجعة الأسئلة والفوائد الشرعية (${_resolvedSummary.records.length})',
                        style: TextStyle(
                          color: qc.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          fontFamily: 'Amiri',
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _showReview
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: qc.goldAccent,
                  ),
                ],
              ),
            ),
          ),
          if (_showReview) ...[
            Divider(height: 1, thickness: 0.8, color: qc.goldBorder),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(14),
              itemCount: _resolvedSummary.records.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final rec = _resolvedSummary.records[index];
                return _buildReviewTile(rec, index + 1, qc);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReviewTile(QuizAnswerRecord rec, int index, QuizColors qc) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: rec.isCorrect
            ? const Color(0xFF1B8A6B).withValues(alpha: qc.isDark ? 0.08 : 0.05)
            : const Color(0xFFB71C1C).withValues(alpha: qc.isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: rec.isCorrect
              ? const Color(0xFF1B8A6B).withValues(alpha: 0.3)
              : const Color(0xFFE53935).withValues(alpha: 0.3),
          width: 0.9,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                rec.isCorrect
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: rec.isCorrect
                    ? const Color(0xFF2ECC71)
                    : const Color(0xFFE53935),
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'س $index: ${rec.question.question}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Amiri',
                    color: qc.textPrimary,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (!rec.isCorrect) ...[
            Text(
              '❌ إجابتك: ${rec.selectedOption}',
              style: const TextStyle(
                color: Color(0xFFE53935),
                fontSize: 12.5,
                fontFamily: 'Amiri',
              ),
            ),
            const SizedBox(height: 2),
          ],
          Text(
            '✅ الإجابة الصحيحة: ${rec.question.answerCorrect}',
            style: const TextStyle(
              color: Color(0xFF1B8A6B),
              fontSize: 12.5,
              fontWeight: FontWeight.bold,
              fontFamily: 'Amiri',
            ),
          ),
          if (rec.question.explanation != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: qc.cardSubtleBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '💡 الفائدة والدليل: ${rec.question.explanation}',
                style: TextStyle(
                  color: qc.textSecondary,
                  fontSize: 11.5,
                  fontFamily: 'Amiri',
                ),
                textDirection: TextDirection.rtl,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(QuizColors qc) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B8A6B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => ActiveQuizScreen(
                    category: _resolvedSummary.category,
                    categoryTitle: _resolvedSummary.modeTitle,
                  ),
                ),
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.replay_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  'خوض تحدٍ جديد',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Amiri',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: qc.goldBorder, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              'العودة للمكتبة الإسلامية',
              style: TextStyle(
                color: qc.goldAccent,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
