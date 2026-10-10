import 'package:flutter/material.dart';

import '../core/constants/quiz_theme_colors.dart';
import '../models/quiz_models.dart';
import '../services/quiz_service.dart';
import '../widgets/liquid_pressable.dart';
import 'active_quiz_screen.dart';

class QuizIntroScreen extends StatefulWidget {
  const QuizIntroScreen({super.key});

  @override
  State<QuizIntroScreen> createState() => _QuizIntroScreenState();
}

class _QuizIntroScreenState extends State<QuizIntroScreen> {
  final QuizService _quizService = QuizService();

  List<LeaderboardEntry> _leaderboard = [];
  PlayerCareerStats _careerStats = PlayerCareerStats();
  bool _isLoading = true;
  bool _soundEnabled = true;

  // Selected Category Mode
  String _selectedCategory = 'all';
  String _selectedCategoryTitle = 'التحدي المتدرج الشامل';
  bool _isBlitzMode = false;

  final List<Map<String, dynamic>> _modes = [
    {
      'id': 'all',
      'title': 'التحدي المتدرج',
      'subtitle': 'سهل ➔ متوسط ➔ متقدم',
      'icon': Icons.auto_awesome_rounded,
      'isBlitz': false,
    },
    {
      'id': 'quran',
      'title': 'القرآن الكريم',
      'subtitle': 'السور والآيات والفضائل',
      'icon': Icons.menu_book_rounded,
      'isBlitz': false,
    },
    {
      'id': 'seerah',
      'title': 'السيرة النبوية',
      'subtitle': 'سيرة المصطفى ﷺ والمغازي',
      'icon': Icons.stars_rounded,
      'isBlitz': false,
    },
    {
      'id': 'fiqh',
      'title': 'الفقه والعبادات',
      'subtitle': 'الصلاة، الزكاة، والصيام',
      'icon': Icons.balance_rounded,
      'isBlitz': false,
    },
    {
      'id': 'aqeedah',
      'title': 'العقيدة والإيمان',
      'subtitle': 'التوحيد وأركان الإيمان',
      'icon': Icons.light_mode_rounded,
      'isBlitz': false,
    },
    {
      'id': 'sahaba',
      'title': 'الصحابة والأنبياء',
      'subtitle': 'سير الأخيار والأنبياء',
      'icon': Icons.people_alt_rounded,
      'isBlitz': false,
    },
    {
      'id': 'adab_hadith',
      'title': 'الحديث والآداب',
      'subtitle': 'السنن والأخلاق الفاضلة',
      'icon': Icons.volunteer_activism_rounded,
      'isBlitz': false,
    },
    {
      'id': 'blitz',
      'title': 'تحدي السرعة ⏱️',
      'subtitle': '١٥ ثانية فقط لكل سؤال',
      'icon': Icons.bolt_rounded,
      'isBlitz': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final entries = await _quizService.getLeaderboard();
    final stats = await _quizService.getCareerStats();
    final sound = await _quizService.isSoundEnabled();

    if (mounted) {
      setState(() {
        _leaderboard = entries;
        _careerStats = stats;
        _soundEnabled = sound;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleSound() async {
    final newVal = !_soundEnabled;
    await _quizService.setSoundEnabled(newVal);
    setState(() => _soundEnabled = newVal);
  }

  void _startQuiz() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActiveQuizScreen(
          category: _isBlitzMode ? 'all' : _selectedCategory,
          categoryTitle: _selectedCategoryTitle,
          isBlitzMode: _isBlitzMode,
        ),
      ),
    ).then((_) {
      _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final qc = QuizColors.of(context);

    return Scaffold(
      backgroundColor: qc.screenBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: qc.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'تحدي المعرفة الإسلامية',
          style: TextStyle(
            color: qc.textPrimary,
            fontWeight: FontWeight.bold,
            fontFamily: 'Amiri',
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              color: qc.goldAccent,
              size: 22,
            ),
            tooltip: _soundEnabled ? 'كتم المؤثرات الصوتية' : 'تفعيل المؤثرات الصوتية',
            onPressed: _toggleSound,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: qc.goldAccent))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 1. Monumental Hero Start Banner ────────────────────────
                  _buildMonumentalHeroBanner(),

                  const SizedBox(height: 18),

                  // ── 2. Player Career Stats Bar ──────────────────────────────
                  _buildCareerStatsBar(qc),

                  const SizedBox(height: 20),

                  // ── 3. Category & Challenge Mode Selector ───────────────────
                  _buildModeSelector(qc),

                  const SizedBox(height: 24),

                  // ── 4. Hall of Fame (لوحة الشرف) with Top 3 Podium ───────────
                  _buildHallOfFameSection(qc),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI Builders
  // ─────────────────────────────────────────────────────────────────────────

  Widget _buildMonumentalHeroBanner() {
    return Container(
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.70),
          width: 1.4,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Authentic Masterpiece House of Wisdom Artwork
            Image.asset(
              'assets/images/faculty_quizzes.webp',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0F382A), Color(0xFF1B5E46)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // Rich Multi-Stop Scrim Gradient
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.40),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.68),
                    Colors.black.withValues(alpha: 0.94),
                  ],
                  stops: const [0.0, 0.35, 0.68, 1.0],
                ),
              ),
            ),

            // Inner Gilded Rim
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.18),
                    width: 0.8,
                  ),
                ),
              ),
            ),

            // Content Structure (inside dark scrim, ivory/gold text has perfect contrast)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Title & Category Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF091210).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.60),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded, color: Color(0xFFFFD54F), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              _selectedCategoryTitle,
                              style: const TextStyle(
                                color: Color(0xFFFFF6D6),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Amiri',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B8A6B).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '١,٥٠٠+ سؤال موثق',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Amiri',
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Middle Titles
                  const Column(
                    children: [
                      Text(
                        'ابدأ مدارسة العلم والتحدي',
                        style: TextStyle(
                          color: Color(0xFFFFFBF0),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Amiri',
                          shadows: [
                            Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
                          ],
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'اختبر معلوماتك في القرآن والسيرة والفقه بالدليل الشرعي',
                        style: TextStyle(
                          color: Color(0xFFDFD5C4),
                          fontSize: 11.5,
                          fontFamily: 'Amiri',
                          shadows: [
                            Shadow(color: Colors.black87, blurRadius: 3),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),

                  // Bottom Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B8A6B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      onPressed: _startQuiz,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 6),
                          Text(
                            'ابدأ التحدي الآن',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Amiri',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareerStatsBar(QuizColors qc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: qc.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: qc.goldBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: qc.isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            title: 'أعلى نتيجة',
            value: '${_careerStats.bestScore}',
            icon: Icons.emoji_events_rounded,
            iconColor: qc.goldAccent,
            qc: qc,
          ),
          Container(width: 1, height: 30, color: qc.isDark ? Colors.white12 : Colors.black12),
          _buildStatItem(
            title: 'أفضل سلسلة',
            value: '🔥 ${_careerStats.bestStreak}',
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFFF7043),
            qc: qc,
          ),
          Container(width: 1, height: 30, color: qc.isDark ? Colors.white12 : Colors.black12),
          _buildStatItem(
            title: 'الجولات المكتملة',
            value: '${_careerStats.totalGames}',
            icon: Icons.history_edu_rounded,
            iconColor: qc.isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2),
            qc: qc,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required QuizColors qc,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 5),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.5,
                color: qc.textPrimary,
              ),
            ),
          ],
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
    );
  }

  Widget _buildModeSelector(QuizColors qc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.tune_rounded, color: qc.goldAccent, size: 18),
            const SizedBox(width: 6),
            Text(
              'اختر مسار التحدي والتصنيف',
              style: TextStyle(
                fontSize: 15.5,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
                color: qc.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 2.2,
          ),
          itemCount: _modes.length,
          itemBuilder: (context, index) {
            final m = _modes[index];
            final isSelected = (_selectedCategory == m['id'] && _isBlitzMode == m['isBlitz']) ||
                (m['isBlitz'] == true && _isBlitzMode);

            // High contrast styles for selected vs unselected
            final chipBg = isSelected ? qc.emeraldPillBg : qc.cardBg;
            final chipBorder = isSelected ? qc.emeraldBorder : (qc.isDark ? Colors.white10 : Colors.black12);
            final iconColor = isSelected ? qc.emeraldPrimary : qc.textMuted;
            final titleColor = isSelected ? qc.emeraldPrimary : qc.textPrimary;
            final subtitleColor = isSelected ? qc.textSecondary : qc.textMuted;

            return LiquidPressable(
              onTap: () {
                setState(() {
                  _selectedCategory = m['id'];
                  _selectedCategoryTitle = m['title'];
                  _isBlitzMode = m['isBlitz'] as bool;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: chipBorder,
                    width: isSelected ? 1.4 : 1,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: qc.emeraldPrimary.withValues(alpha: qc.isDark ? 0.3 : 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? qc.emeraldPrimary.withValues(alpha: qc.isDark ? 0.2 : 0.12)
                            : (qc.isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.04)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        m['icon'] as IconData,
                        size: 16,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            m['title'] as String,
                            style: TextStyle(
                              color: titleColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Amiri',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            m['subtitle'] as String,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 9.5,
                              fontFamily: 'Amiri',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHallOfFameSection(QuizColors qc) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: qc.cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: qc.goldBorder,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: qc.isDark ? 0.25 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.workspace_premium_rounded, color: qc.goldAccent, size: 22),
              const SizedBox(width: 8),
              Text(
                'لوحة الشرف • حُفّاظ العلم',
                style: TextStyle(
                  color: qc.goldAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Amiri',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_leaderboard.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'كن أول من يسجل اسمه في لوحة الشرف بحصد النقاط!',
                  style: TextStyle(
                    color: qc.textMuted,
                    fontFamily: 'Amiri',
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else ...[
            // 3-Tier Royal Podium
            if (_leaderboard.isNotEmpty) _buildPodium(qc),

            const SizedBox(height: 14),

            // Ledger List for 4th and beyond
            if (_leaderboard.length > 3)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _leaderboard.length > 8 ? 8 : _leaderboard.length - 3,
                separatorBuilder: (_, __) => Divider(
                  height: 12,
                  thickness: 0.5,
                  color: qc.isDark ? Colors.white10 : Colors.black12,
                ),
                itemBuilder: (context, index) {
                  final entry = _leaderboard[index + 3];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            '#${index + 4}',
                            style: TextStyle(
                              color: qc.textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            entry.playerName,
                            style: TextStyle(
                              color: qc.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Amiri',
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: qc.emeraldPillBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${entry.score} نقطة',
                          style: TextStyle(
                            color: qc.emeraldPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPodium(QuizColors qc) {
    final first = _leaderboard.isNotEmpty ? _leaderboard[0] : null;
    final second = _leaderboard.length > 1 ? _leaderboard[1] : null;
    final third = _leaderboard.length > 2 ? _leaderboard[2] : null;

    final goldColor = qc.goldAccent;
    final silverColor = qc.isDark ? const Color(0xFFCFD8DC) : const Color(0xFF546E7A);
    final bronzeColor = qc.isDark ? const Color(0xFFD7CCC8) : const Color(0xFF8D6E63);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place (Silver)
        if (second != null)
          _buildPodiumPillar(
            entry: second,
            rank: 2,
            rankIcon: '🥈',
            medalColor: silverColor,
            height: 90,
            qc: qc,
          )
        else
          const SizedBox(width: 80),

        const SizedBox(width: 8),

        // 1st Place (Gold / Imperial Bronze)
        if (first != null)
          _buildPodiumPillar(
            entry: first,
            rank: 1,
            rankIcon: '🥇',
            medalColor: goldColor,
            height: 115,
            qc: qc,
          ),

        const SizedBox(width: 8),

        // 3rd Place (Bronze)
        if (third != null)
          _buildPodiumPillar(
            entry: third,
            rank: 3,
            rankIcon: '🥉',
            medalColor: bronzeColor,
            height: 75,
            qc: qc,
          )
        else
          const SizedBox(width: 80),
      ],
    );
  }

  Widget _buildPodiumPillar({
    required LeaderboardEntry entry,
    required int rank,
    required String rankIcon,
    required Color medalColor,
    required double height,
    required QuizColors qc,
  }) {
    return SizedBox(
      width: 86,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(rankIcon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 2),
          Text(
            entry.playerName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              fontFamily: 'Amiri',
              color: qc.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  medalColor.withValues(alpha: qc.isDark ? 0.35 : 0.16),
                  medalColor.withValues(alpha: qc.isDark ? 0.15 : 0.06),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(color: medalColor.withValues(alpha: 0.5), width: 1),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${entry.score}',
                  style: TextStyle(
                    color: medalColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
                Text(
                  'نقطة',
                  style: TextStyle(
                    color: qc.textMuted,
                    fontSize: 10,
                    fontFamily: 'Amiri',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
