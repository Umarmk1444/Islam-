import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../theme_notifier.dart';
import '../services/library_service.dart';
import '../models/library_item.dart';
import 'library_category_screen.dart';
import 'library_content_list_screen.dart';
import 'story_reading_screen.dart';
import 'ruqyah_screen.dart';
import '../widgets/liquid_pressable.dart';
import '../widgets/custom_banner_ad.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Per-domain accent palette
// ─────────────────────────────────────────────────────────────────────────────
const _kDomainPalette = [
  [Color(0xFF1DB97A), Color(0xFF0E7A4F)], // Islamic Library — emerald
  [Color(0xFF1E88E5), Color(0xFF0D47A1)], // Bukhari — azure blue
  [Color(0xFF8E24AA), Color(0xFF4A0072)], // Fiqh — violet
  [Color(0xFFFFB300), Color(0xFFE65100)], // Fatwas — amber→orange
  [Color(0xFF00ACC1), Color(0xFF006064)], // Dream Tafsir — cyan
  [Color(0xFFE91E8C), Color(0xFF880E4F)], // Ruqyah — hot pink
];

// ─────────────────────────────────────────────────────────────────────────────
// LibraryScreen
// ─────────────────────────────────────────────────────────────────────────────
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  final LibraryService _libraryService = LibraryService();
  final TextEditingController _searchController = TextEditingController();

  List<LibraryItem> _searchResults = [];
  bool _isSearching = false;

  // Shared smooth pulse: 0 → 1 → 0 with easeInOut
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  final List<Map<String, dynamic>> _domains = [
    {'part': 'المكتبة',        'title': 'المكتبة الإسلامية', 'icon': Icons.local_library_rounded},
    {'part': 'صحيح البخارى',   'title': 'صحيح البخاري',     'icon': Icons.menu_book_rounded},
    {'part': 'فقه',            'title': 'فقه',               'icon': Icons.balance_rounded},
    {'part': 'فتاوى',          'title': 'فتاوى',             'icon': Icons.question_answer_rounded},
    {'part': 'تفسير أحلام',    'title': 'تفسير الأحلام',     'icon': Icons.nights_stay_rounded},
    {'part': 'الرقية الشرعية', 'title': 'الرقية الشرعية',   'icon': Icons.healing_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true); // auto-reverses → perfect sine-like loop
    _pulseAnim = CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() { _searchResults = []; _isSearching = false; });
      return;
    }
    setState(() => _isSearching = true);
    final results = await _libraryService.searchLibrary(query);
    setState(() => _searchResults = results);
  }

  void _navigateToFavorites() {
    final l10n = AppLocalizations.of(context);
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => LibraryContentListScreen(
            part: 'favorites',
            categoryId: 'favorites',
            categoryTitle: l10n?.libraryFavorites ?? 'Favorites')));
  }

  void _navigateToDomain(Map<String, dynamic> domain) {
    if (domain['part'] == 'الرقية الشرعية') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RuqyahScreen()));
      return;
    }
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => LibraryCategoryScreen(
              domainPart: domain['part'],
              domainTitle: domain['title'],
            )));
  }

  void _openStory(LibraryItem item) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => StoryReadingScreen(item: item)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.notifier.value == QuranTheme.dark;
    final l10n   = AppLocalizations.of(context);
    final bgColor  = isDark ? AppColors.surfaceDark  : AppColors.surfaceLight;
    final cardBg   = isDark ? AppColors.surfaceCard  : AppColors.surfaceCardLight;
    final textColor = isDark ? AppColors.textPrimary : AppColors.emeraldDeep;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n?.navLibrary ?? 'Library',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Search library...',
                hintStyle: TextStyle(
                    color: isDark ? AppColors.textSecondary : AppColors.textMuted),
                prefixIcon: Icon(Icons.search,
                    color: isDark ? AppColors.textSecondary : AppColors.emeraldDeep),
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          Expanded(
            child: _searchController.text.isNotEmpty
                ? _buildSearchResults(textColor, cardBg, isDark)
                : CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: _buildFavoritesBanner(isDark, l10n),
                      ),
                      _buildDomainGrid(isDark),
                    ],
                  ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBannerAd(),
    );
  }

  // ── Favourites banner ───────────────────────────────────────────────────────
  Widget _buildFavoritesBanner(bool isDark, AppLocalizations? l10n) {
    return LiquidPressable(
      onTap: _navigateToFavorites,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF1A7A5E), const Color(0xFF0D3B2B)]
                : [AppColors.emeraldLight, AppColors.emeraldDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.emeraldDeep.withValues(alpha: isDark ? 0.4 : 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.25), blurRadius: 12, spreadRadius: 2)],
              ),
              child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n?.libraryFavorites ?? 'المفضلة',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 3),
                  Text('Your saved books, hadiths, and fatwas',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ── Domain grid ─────────────────────────────────────────────────────────────
  Widget _buildDomainGrid(bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 1.05,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final domain  = _domains[index];
            final palette = _kDomainPalette[index % _kDomainPalette.length];
            return _DomainCard(
              domain: domain,
              accent: palette[0],
              deep: palette[1],
              isDark: isDark,
              pulseAnim: _pulseAnim,
              phaseOffset: index * 0.15, // stagger the breathing phase for wave effect
              entranceDelay: Duration(milliseconds: index * 80),
              onTap: () => _navigateToDomain(domain),
            );
          },
          childCount: _domains.length,
        ),
      ),
    );
  }

  // ── Search results ──────────────────────────────────────────────────────────
  Widget _buildSearchResults(Color textColor, Color cardBg, bool isDark) {
    if (_isSearching && _searchResults.isEmpty) {
      return Center(
        child: Text('No results found.',
            style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.emeraldDeep)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return LiquidPressable(
          onTap: () => _openStory(item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: AppColors.emeraldLight.withValues(alpha: 0.14), shape: BoxShape.circle),
                  child: const Icon(Icons.book_rounded, color: AppColors.emeraldLight, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.title,
                          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      Text(item.type,
                          style: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: isDark ? AppColors.textMuted : Colors.black26, size: 14),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DomainCard — wave-phased breathing: scale + glow + color shift
// ─────────────────────────────────────────────────────────────────────────────
class _DomainCard extends StatefulWidget {
  const _DomainCard({
    required this.domain,
    required this.accent,
    required this.deep,
    required this.isDark,
    required this.pulseAnim,   // shared 0→1→0 animation
    required this.phaseOffset, // 0.0 – 1.0: each card starts at a different phase
    required this.entranceDelay,
    required this.onTap,
  });

  final Map<String, dynamic> domain;
  final Color accent;
  final Color deep;
  final bool isDark;
  final Animation<double> pulseAnim;
  final double phaseOffset;
  final Duration entranceDelay;
  final VoidCallback onTap;

  @override
  State<_DomainCard> createState() => _DomainCardState();
}

class _DomainCardState extends State<_DomainCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim  = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.22), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.entranceDelay, () {
      if (mounted) _entranceCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  /// Converts the shared 0→1 animation into a per-card phase-shifted
  /// smooth sine value (0.0 – 1.0) using easeInOut.
  double _phased(double raw) {
    final shifted = (raw + widget.phaseOffset) % 1.0;
    // fold [0,1] into [0,0.5,0] triangle then apply easeInOut
    final tri = shifted < 0.5 ? shifted * 2.0 : (1.0 - shifted) * 2.0;
    return Curves.easeInOut.transform(tri);
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accent;
    final deep   = widget.deep;
    final isDark = widget.isDark;

    // A brighter "lit" version of the accent for color interpolation
    final bright = Color.lerp(accent, Colors.white, 0.30)!;

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: LiquidPressable(
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: widget.pulseAnim,
            builder: (_, child) {
              final t = _phased(widget.pulseAnim.value);

              // ── Scale: 1.00 → 1.035 (clearly visible, non-jarring) ──────────
              final scale = 1.0 + 0.035 * t;

              // ── Glow: dim → vivid ────────────────────────────────────────────
              final glowAlpha  = isDark ? (0.10 + 0.45 * t) : (0.08 + 0.35 * t);
              final glowBlur   = 8.0 + 24.0 * t;
              final glowSpread = 0.5 + 3.0 * t;

              // ── Border: faint → bright ───────────────────────────────────────
              final borderAlpha = isDark ? (0.20 + 0.45 * t) : (0.12 + 0.35 * t);
              final borderWidth = 1.2 + 0.8 * t;

              // ── Fill gradient: shifts from subtle to richer ──────────────────
              final fillA = isDark ? (0.10 + 0.20 * t) : (0.05 + 0.12 * t);
              final fillB = isDark ? (0.04 + 0.12 * t) : (0.02 + 0.06 * t);

              // ── Current accent color lerps toward bright on peak ─────────────
              final currentAccent = Color.lerp(accent, bright, t * 0.6)!;

              return Transform.scale(
                scale: scale,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        currentAccent.withValues(alpha: fillA),
                        deep.withValues(alpha: fillB),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: currentAccent.withValues(alpha: borderAlpha),
                      width: borderWidth,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: currentAccent.withValues(alpha: glowAlpha),
                        blurRadius: glowBlur,
                        spreadRadius: glowSpread,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      children: [
                        // Accent color internal glowing orb
                        Positioned(
                          top: -30,
                          left: -30,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  currentAccent.withValues(alpha: isDark ? 0.35 * t : 0.28 * t),
                                  currentAccent.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Deep color internal glowing orb
                        Positioned(
                          bottom: -20,
                          right: -20,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  deep.withValues(alpha: isDark ? 0.28 * t : 0.20 * t),
                                  deep.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Main content centered correctly
                        Positioned.fill(child: child!),
                      ],
                    ),
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon circle — gradient shifts with accent
                  AnimatedBuilder(
                    animation: widget.pulseAnim,
                    builder: (_, __) {
                      final t = _phased(widget.pulseAnim.value);
                      final bright = Color.lerp(accent, Colors.white, 0.30)!;
                      final currentAccent = Color.lerp(accent, bright, t * 0.6)!;
                      return Container(
                        width: 64, height: 64,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [currentAccent, deep],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: currentAccent.withValues(alpha: 0.35 + 0.30 * t),
                              blurRadius: 10 + 14 * t,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(widget.domain['icon'] as IconData,
                            color: Colors.white, size: 30),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.domain['title'] as String,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      height: 1.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

