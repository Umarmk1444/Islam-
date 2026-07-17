import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../theme_notifier.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MinbarTab — Tab 2 ("المنبر وصوتيات الدعوة")
// ─────────────────────────────────────────────────────────────────────────────
//
// Layout (bottom-up z-order):
//   Stack {
//     ① Scrollable body:
//       1. HaramainLiveFeed     — horizontal live-stream carousel
//       2. AudioLibrarySection  — reciters + language-filtered lectures
//       3. RecitationChecker    — AI mic input module
//       4. CommunityHub         — family/group challenge cards
//     ② PersistentAudioBar     — always-on-top bottom audio player bar
//   }
// ─────────────────────────────────────────────────────────────────────────────

class MinbarTab extends StatefulWidget {
  const MinbarTab({super.key});

  @override
  State<MinbarTab> createState() => _MinbarTabState();
}

class _MinbarTabState extends State<MinbarTab> {
  final ScrollController _scrollController = ScrollController();

  // ── Language filter for Da'wah Lectures
  static const _languages = ['All', 'العربية', 'English', 'አማርኛ', 'Oromoo'];
  int _selectedLangIndex = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.notifier.value == QuranTheme.dark;
    final bg     = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // ── Main scrollable content ───────────────────────────────────────
          SafeArea(
            bottom: false,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── AppBar ──────────────────────────────────────────────────
                SliverAppBar(
                  backgroundColor: bg,
                  elevation: 0,
                  floating: true,
                  snap: true,
                  pinned: false,
                  titleSpacing: 20,
                  title: Text(
                    'المنبر وصوتيات الدعوة',
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontFamily: 'Amiri',
                      color: isDark
                          ? AppColors.textPrimary
                          : AppColors.emeraldDeep,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  actions: [
                    IconButton(
                      icon: Icon(Icons.download_outlined,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.emeraldDeep),
                      onPressed: () {/* TODO: open cache manager */},
                      tooltip: 'Download Manager',
                    ),
                    const SizedBox(width: 8),
                  ],
                ),

                // ── Content ──────────────────────────────────────────────────
                SliverPadding(
                  // Extra bottom padding for the persistent audio bar
                  padding: const EdgeInsets.fromLTRB(0, 0, 0, 160),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // 1. Haramain Live Feed
                      const _SectionHeader(
                        title: 'Live — الحرمين',
                        subtitle: 'Makkah & Madinah 24/7',
                        icon: Icons.live_tv_rounded,
                        iconColor: AppColors.audioLive,
                      ),
                      const _HaramainLiveFeed(),
                      const SizedBox(height: 24),

                      // 2. Audio Library
                      const _SectionHeader(
                        title: 'Audio Library',
                        subtitle: 'Reciters & Scholars',
                        icon: Icons.library_music_rounded,
                        iconColor: AppColors.emeraldLight,
                      ),
                      const SizedBox(height: 12),
                      // Quran Reciters
                      _SubSectionLabel(label: 'Quran Reciters', isDark: isDark),
                      const _RecitersRow(),
                      const SizedBox(height: 16),
                      // Language filter chip row
                      _SubSectionLabel(label: "Da'wah Lectures", isDark: isDark),
                      const SizedBox(height: 8),
                      _LanguageFilterRow(
                        languages: _languages,
                        selectedIndex: _selectedLangIndex,
                        onSelected: (i) =>
                            setState(() => _selectedLangIndex = i),
                      ),
                      const SizedBox(height: 12),
                      const _LectureList(),
                      const SizedBox(height: 24),

                      // 3. AI Recitation Checker
                      const _SectionHeader(
                        title: 'AI Recitation Checker',
                        subtitle: 'Detect mistakes & track hifz',
                        icon: Icons.mic_rounded,
                        iconColor: Color(0xFF8B5CF6),
                      ),
                      const SizedBox(height: 12),
                      const _RecitationCheckerCard(),
                      const SizedBox(height: 24),

                      // 4. Community Hub
                      const _SectionHeader(
                        title: 'Ummah Community',
                        subtitle: 'Family & group challenges',
                        icon: Icons.people_rounded,
                        iconColor: AppColors.goldMid,
                      ),
                      const SizedBox(height: 12),
                      const _CommunityHubSection(),
                    ]),
                  ),
                ),
              ],
            ),
          ),

          // ② Persistent Audio Bar — always on top
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _PersistentAudioBar(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.headlineMedium),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubSectionLabel extends StatelessWidget {
  const _SubSectionLabel({required this.label, required this.isDark});

  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Text(
        label,
        style: AppTextStyles.labelLarge.copyWith(
          color: isDark ? AppColors.textSecondary : AppColors.emeraldDeep,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. HARAMAIN LIVE FEED
// ─────────────────────────────────────────────────────────────────────────────

class _HaramainLiveFeed extends StatelessWidget {
  const _HaramainLiveFeed();

  static const _feeds = [
    (title: 'Makkah Live', titleAr: 'قناة مكة المكرمة', city: 'Makkah', emoji: '🕋'),
    (title: 'Madinah Live', titleAr: 'قناة المدينة المنورة', city: 'Madinah', emoji: '🕌'),
    (title: 'Radio Quran', titleAr: 'إذاعة القرآن الكريم', city: 'Saudi Arabia', emoji: '📻'),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 172,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: _feeds.length,
        itemBuilder: (context, i) {
          final feed = _feeds[i];
          return _LiveStreamCard(feed: feed);
        },
      ),
    );
  }
}

class _LiveStreamCard extends StatelessWidget {
  const _LiveStreamCard({required this.feed});

  final ({String title, String titleAr, String city, String emoji}) feed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {/* TODO: start live stream */},
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D1B2A), Color(0xFF1A2A4A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.audioLive.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live dot + label
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.audioLive,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('LIVE', style: AppTextStyles.liveTag),
              ],
            ),
            const Spacer(),
            Text(feed.emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                feed.titleAr,
                style: AppTextStyles.arabicSmall
                    .copyWith(color: Colors.white, fontSize: 13, height: 1.3),
                textDirection: TextDirection.rtl,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Flexible(
              child: Text(
                feed.title,
                style: AppTextStyles.audioSubtitle
                    .copyWith(color: Colors.white70, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2a. RECITERS ROW
// ─────────────────────────────────────────────────────────────────────────────

class _RecitersRow extends StatelessWidget {
  const _RecitersRow();

  static const _reciters = [
    (name: 'Al-Minshawi', nameAr: 'المنشاوي', cached: true),
    (name: 'Al-Ghamdi', nameAr: 'الغامدي', cached: false),
    (name: 'Al-Ajmi', nameAr: 'العجمي', cached: false),
    (name: 'Mishary', nameAr: 'مشاري', cached: true),
    (name: 'Maher', nameAr: 'ماهر', cached: false),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.notifier.value == QuranTheme.dark;
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: _reciters.length,
        itemBuilder: (context, i) {
          final r = _reciters[i];
          return GestureDetector(
            onTap: () {/* TODO: open reciter's surah list */},
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.emeraldDeep.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.emeraldLight.withValues(alpha: 0.6),
                          width: 2,
                        ),
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: AppColors.emeraldLight, size: 28),
                    ),
                    if (r.cached)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.emeraldLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check,
                              color: Colors.white, size: 11),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  r.nameAr,
                  style: AppTextStyles.arabicLabel.copyWith(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.emeraldDeep,
                    fontSize: 11,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2b. LANGUAGE FILTER ROW
// ─────────────────────────────────────────────────────────────────────────────

class _LanguageFilterRow extends StatelessWidget {
  const _LanguageFilterRow({
    required this.languages,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> languages;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: languages.length,
        itemBuilder: (context, i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.emeraldLight
                    : AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? AppColors.emeraldLight
                      : AppColors.divider,
                  width: 1,
                ),
              ),
              child: Text(
                languages[i],
                style: AppTextStyles.labelLarge.copyWith(
                  color: selected ? Colors.white : AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2c. LECTURE LIST
// ─────────────────────────────────────────────────────────────────────────────

class _LectureList extends StatelessWidget {
  const _LectureList();

  static const _lectures = [
    (
      title: 'The Fundamentals of Aqeedah',
      scholar: 'Sheikh Ibn Uthaymeen',
      lang: 'Arabic',
      duration: '47:23',
      cached: false,
    ),
    (
      title: 'ጥቅሶቹ ሐዲሶች',
      scholar: 'Sheikh Abdurrahman',
      lang: 'Amharic',
      duration: '32:10',
      cached: true,
    ),
    (
      title: "Jireenya Muslim Tahilil Ramadaan'aa",
      scholar: 'Sheikh Ibrahim',
      lang: 'Oromo',
      duration: '28:55',
      cached: false,
    ),
    (
      title: 'Purification of the Soul',
      scholar: 'Sheikh Feiz Muhammad',
      lang: 'English',
      duration: '1:02:34',
      cached: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.notifier.value == QuranTheme.dark;
    return Column(
      children: _lectures.map((lec) {
        final cardBg = isDark ? AppColors.surfaceCard : AppColors.surfaceCardLight;
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.divider : Colors.grey.shade200,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              leading: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.emeraldMid.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.headphones_rounded,
                    color: AppColors.emeraldLight, size: 22),
              ),
              title: Text(lec.title,
                  style: AppTextStyles.audioTitle, maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              subtitle: Text(
                '${lec.scholar} · ${lec.lang}',
                style: AppTextStyles.audioSubtitle,
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(lec.duration,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      )),
                  const SizedBox(height: 4),
                  Icon(
                    lec.cached
                        ? Icons.offline_pin_rounded
                        : Icons.download_outlined,
                    color: lec.cached
                        ? AppColors.emeraldLight
                        : AppColors.textMuted,
                    size: 18,
                  ),
                ],
              ),
              onTap: () {/* TODO: play lecture */},
            ),
          ),
        );
      }).toList(),
    );

  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. AI RECITATION CHECKER
// ─────────────────────────────────────────────────────────────────────────────

class _RecitationCheckerCard extends StatefulWidget {
  const _RecitationCheckerCard();

  @override
  State<_RecitationCheckerCard> createState() => _RecitationCheckerCardState();
}

class _RecitationCheckerCardState extends State<_RecitationCheckerCard>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Stub results — replace with AudioRepository.analyseRecitation() response
  static const _stubScore    = 0.87;
  static const _stubFeedback = 'Excellent! Minor tajweed error on "الرَّحْمَٰنِ"';
  bool _showResult = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
      if (!_isRecording) {
        // Simulate result after stopping
        _showResult = true;
      } else {
        _showResult = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // isDark is available via AppTheme if needed for future theming
    // ignore: unused_local_variable
    final isDark = AppTheme.notifier.value == QuranTheme.dark;
    const micColor = Color(0xFF8B5CF6);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF3B0764).withValues(alpha: 0.9),
              const Color(0xFF1E1B4B).withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            // Target ayah row
            Row(
              children: [
                const Text('🎯', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Al-Fatiha 1:1 — بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white70),
                    textDirection: TextDirection.ltr,
                  ),
                ),
                GestureDetector(
                  onTap: () {/* TODO: pick ayah */},
                  child: Text(
                    'Change',
                    style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.goldLight),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Mic button with pulse
            GestureDetector(
              onTap: _toggleRecording,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _isRecording ? _pulseAnimation.value : 1.0,
                  child: child,
                ),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _isRecording
                        ? AppColors.audioLive
                        : micColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (_isRecording ? AppColors.audioLive : micColor)
                            .withValues(alpha: 0.45),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _isRecording ? 'Listening… tap to stop' : 'Tap mic to start',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white60),
            ),

            // Result block
            if (_showResult) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Score',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: Colors.white70)),
                        Text(
                          '${(_stubScore * 100).toStringAsFixed(0)}%',
                          style: AppTextStyles.statNumber.copyWith(
                            color: AppColors.emeraldLight,
                            fontSize: 22,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: _stubScore,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.emeraldLight),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _stubFeedback,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. COMMUNITY HUB
// ─────────────────────────────────────────────────────────────────────────────

class _CommunityHubSection extends StatelessWidget {
  const _CommunityHubSection();

  static const _rooms = [
    (
      name: 'Al-Firdaws Family',
      type: 'Family Khatma',
      progress: 0.72,
      members: 6,
      badge: '🥇',
    ),
    (
      name: 'Ramadan Squad 2026',
      type: 'Group Challenge',
      progress: 0.38,
      members: 24,
      badge: '🌙',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.notifier.value == QuranTheme.dark;
    final cardBg = isDark ? AppColors.surfaceCard : AppColors.surfaceCardLight;

    return Column(
      children: [
        ..._rooms.map((room) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.divider : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(room.badge,
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(room.name,
                                style: AppTextStyles.audioTitle),
                            Text(
                              '${room.type} · ${room.members} members',
                              style: AppTextStyles.audioSubtitle,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {/* TODO: open room */},
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.emeraldLight.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: AppColors.emeraldLight.withValues(alpha: 0.4)),
                          ),
                          child: Text('Join',
                              style: AppTextStyles.labelLarge.copyWith(
                                  color: AppColors.emeraldLight,
                                  fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: room.progress,
                      backgroundColor:
                          isDark ? AppColors.divider : Colors.grey.shade200,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.goldMid,
                      ),
                      minHeight: 7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${(room.progress * 100).toStringAsFixed(0)}% of group goal completed',
                    style: AppTextStyles.labelSmall,
                  ),
                ],
              ),
            ),
          );
        }),

        // "Create / Join" CTA
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: OutlinedButton.icon(
            onPressed: () {/* TODO: create group room */},
            icon: const Icon(Icons.add_circle_outline_rounded,
                color: AppColors.goldMid),
            label: Text(
              'Create or Join a Room',
              style: AppTextStyles.labelLarge
                  .copyWith(color: AppColors.goldMid),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.goldMid, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 48),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ② PERSISTENT AUDIO BAR
// ─────────────────────────────────────────────────────────────────────────────

class _PersistentAudioBar extends StatelessWidget {
  const _PersistentAudioBar();

  // Stub — wired to AudioPlayerController
  static const _trackAr     = 'سورة الملك';
  static const _scholar     = 'Mishary Rashid Al-Afasy';
  static const _progress    = 0.35;
  static const _isPlaying   = true;

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.notifier.value == QuranTheme.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0E1821) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.55 : 0.15),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.divider : Colors.grey.shade200,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thin seek bar
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: isDark ? AppColors.divider : Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.emeraldLight),
              minHeight: 2,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  // Cover art placeholder
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.emeraldDeep.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.graphic_eq_rounded,
                        color: AppColors.emeraldLight, size: 22),
                  ),
                  const SizedBox(width: 12),

                  // Track info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_trackAr,
                            style: AppTextStyles.arabicSmall.copyWith(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textPrimary
                                  : AppColors.emeraldDeep,
                            ),
                            textDirection: TextDirection.rtl),
                        const Text(_scholar,
                            style: AppTextStyles.audioSubtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),

                  // Controls
                  IconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    color: isDark ? AppColors.textSecondary : Colors.grey,
                    iconSize: 26,
                    onPressed: () {/* TODO */},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {/* TODO: play/pause */},
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.emeraldMid, AppColors.emeraldLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        _isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    color: isDark ? AppColors.textSecondary : Colors.grey,
                    iconSize: 26,
                    onPressed: () {/* TODO */},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.queue_music_rounded),
                    color: isDark ? AppColors.textMuted : Colors.grey,
                    iconSize: 22,
                    onPressed: () {/* TODO: open full player */},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
