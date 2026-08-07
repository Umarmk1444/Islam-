import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../theme_notifier.dart';
import '../widgets/persistent_audio_bar.dart';
import '../services/minbar_player.dart';
import '../models/minbar_models.dart';
import '../services/quran_radio_service.dart';

class LiveRadioScreen extends StatefulWidget {
  const LiveRadioScreen({super.key});

  @override
  State<LiveRadioScreen> createState() => _LiveRadioScreenState();
}

class _LiveRadioScreenState extends State<LiveRadioScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all'; // 'all', 'favorites', 'quran', 'tafsir', 'adhkar', 'ruqyah', 'varied'
  List<String> _favoriteIds = [];
  bool _isArabic = true;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _loadFavoritesAndLanguage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoritesAndLanguage() async {
    _prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _favoriteIds = _prefs?.getStringList('favorite_radio_ids') ?? [];
        _isArabic = _prefs?.getBool('radio_language_arabic') ?? true;
      });
    }
  }

  Future<void> _toggleFavorite(String id) async {
    if (_favoriteIds.contains(id)) {
      _favoriteIds.remove(id);
    } else {
      _favoriteIds.add(id);
    }
    await _prefs?.setStringList('favorite_radio_ids', _favoriteIds);
    setState(() {});
  }

  Future<void> _setLanguage(bool isArabic) async {
    await _prefs?.setBool('radio_language_arabic', isArabic);
    setState(() {
      _isArabic = isArabic;
    });
  }

  List<QuranRadioItem> _getFilteredStations() {
    return QuranRadioService.stations.where((station) {
      // 1. Filter by Search Query (match both Arabic and English names)
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = station.name.toLowerCase().contains(query);
        final matchesEnglishName = station.englishName.toLowerCase().contains(query);
        if (!matchesName && !matchesEnglishName) return false;
      }

      // 2. Filter by Category
      if (_selectedCategory == 'favorites') {
        return _favoriteIds.contains(station.id);
      } else if (_selectedCategory != 'all') {
        return station.category == _selectedCategory;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final isDark = theme == QuranTheme.dark;
        final bg = AppTheme.getScreenBgColor(theme);
        final textColor = AppTheme.getMainTextColor(theme);
        final cardBg = AppTheme.getCardBgColor(theme);
        final borderColor = theme == QuranTheme.cream
            ? const Color(0xFFC9A84C).withValues(alpha: 0.3)
            : (isDark
                ? Colors.white.withValues(alpha: 0.05)
                : AppColors.textMuted.withValues(alpha: 0.1));

        final filteredStations = _getFilteredStations();

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _isArabic ? 'الإذاعات الإسلامية المباشرة' : 'Islamic Live Radio',
              style: AppTextStyles.headlineMedium.copyWith(
                fontFamily: _isArabic ? 'Amiri' : null,
                fontSize: 20,
                color: theme == QuranTheme.cream
                    ? AppColors.emeraldDeep
                    : textColor,
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // ── Search Bar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? cardBg.withValues(alpha: 0.8) : cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val;
                      });
                    },
                    style: TextStyle(color: textColor, fontSize: 15),
                    textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
                    decoration: InputDecoration(
                      hintText: _isArabic ? 'ابحث عن إذاعة...' : 'Search stations...',
                      hintStyle: TextStyle(
                        color: textColor.withValues(alpha: 0.4),
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: textColor.withValues(alpha: 0.4),
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear_rounded,
                                color: textColor.withValues(alpha: 0.6),
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Category Selector (Chips) ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    _buildCategoryChip('all', _isArabic ? 'الكل' : 'All', Icons.radio_rounded, theme, textColor),
                    const SizedBox(width: 8),
                    _buildCategoryChip('favorites', _isArabic ? 'المفضلة' : 'Favorites', Icons.favorite_rounded, theme, textColor),
                    const SizedBox(width: 8),
                    _buildCategoryChip('quran', _isArabic ? 'قرآن كريم' : 'Holy Quran', Icons.menu_book_rounded, theme, textColor),
                    const SizedBox(width: 8),
                    _buildCategoryChip('tafsir', _isArabic ? 'تفسير' : 'Tafsir', Icons.auto_stories_rounded, theme, textColor),
                    const SizedBox(width: 8),
                    _buildCategoryChip('adhkar', _isArabic ? 'أذكار' : 'Adhkar', Icons.spa_rounded, theme, textColor),
                    const SizedBox(width: 8),
                    _buildCategoryChip('ruqyah', _isArabic ? 'الرقية الشرعية' : 'Ruqyah', Icons.clean_hands_rounded, theme, textColor),
                    const SizedBox(width: 8),
                    _buildCategoryChip('varied', _isArabic ? 'منوعات' : 'Varied', Icons.library_books_rounded, theme, textColor),
                  ],
                ),
              ),

              // ── List of Stations ──
              Expanded(
                child: filteredStations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedCategory == 'favorites'
                                  ? Icons.favorite_border_rounded
                                  : Icons.search_off_rounded,
                              size: 64,
                              color: textColor.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _selectedCategory == 'favorites'
                                  ? (_isArabic ? 'لا توجد إذاعات في المفضلة بعد' : 'No favorited stations yet')
                                  : (_isArabic ? 'لم يتم العثور على أي إذاعة' : 'No stations found'),
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.6),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        itemCount: filteredStations.length,
                        itemBuilder: (context, index) {
                          final station = filteredStations[index];
                          final isFav = _favoriteIds.contains(station.id);
                          return _buildRadioListTile(
                            context,
                            station,
                            isFav,
                            theme,
                            textColor,
                            cardBg,
                            borderColor,
                          );
                        },
                      ),
              ),

              // ── Language Toggle Bar (AR / EN) ──
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? cardBg.withValues(alpha: 0.4) : cardBg.withValues(alpha: 0.8),
                  border: Border(
                    top: BorderSide(
                      color: borderColor,
                      width: 1.0,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLanguageToggleButton(false, 'EN', theme, textColor),
                    const SizedBox(width: 16),
                    _buildLanguageToggleButton(true, 'عربي', theme, textColor),
                  ],
                ),
              ),

              // ── Persistent Audio Bar ──
              const PersistentAudioBar(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageToggleButton(
    bool isArabicButton,
    String label,
    QuranTheme theme,
    Color textColor,
  ) {
    final isSelected = _isArabic == isArabicButton;
    final isCream = theme == QuranTheme.cream;
    
    return GestureDetector(
      onTap: () => _setLanguage(isArabicButton),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isCream ? AppColors.emeraldDeep : AppColors.emeraldMid)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : textColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : textColor.withValues(alpha: 0.7),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    String categoryId,
    String label,
    IconData icon,
    QuranTheme theme,
    Color textColor,
  ) {
    final isSelected = _selectedCategory == categoryId;
    final isCream = theme == QuranTheme.cream;
    
    Color chipBg;
    Color chipText;
    Color iconColor;
    
    if (isSelected) {
      chipBg = isCream ? AppColors.emeraldDeep : AppColors.emeraldMid;
      chipText = Colors.white;
      iconColor = Colors.white;
    } else {
      chipBg = theme == QuranTheme.dark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.04);
      chipText = textColor.withValues(alpha: 0.8);
      iconColor = textColor.withValues(alpha: 0.5);
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedCategory = categoryId;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (theme == QuranTheme.cream
                    ? const Color(0xFFC9A84C).withValues(alpha: 0.2)
                    : Colors.transparent),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: chipText,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioListTile(
    BuildContext context,
    QuranRadioItem station,
    bool isFav,
    QuranTheme theme,
    Color textColor,
    Color cardBg,
    Color borderColor,
  ) {
    final radioId = 'radio_${station.id}';
    final isCream = theme == QuranTheme.cream;

    return ValueListenableBuilder<MinbarAudioItem?>(
      valueListenable: MinbarPlayer.currentItemNotifier,
      builder: (context, currentItem, _) {
        final isRadioActive = currentItem != null && currentItem.id == radioId;

        return StreamBuilder<bool>(
          stream: MinbarPlayer.player.playingStream,
          builder: (context, snapshot) {
            final isPlaying = isRadioActive && (snapshot.data ?? false);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: theme == QuranTheme.dark
                    ? cardBg.withValues(alpha: 0.8)
                    : cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPlaying
                      ? (isCream ? AppColors.emeraldDeep : AppColors.emeraldMid)
                      : borderColor,
                  width: isPlaying ? 1.8 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isPlaying
                        ? (isCream ? AppColors.emeraldDeep : AppColors.emeraldMid)
                            .withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: theme == QuranTheme.dark ? 0.15 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // Play/Pause button
                  GestureDetector(
                    onTap: () async {
                      if (isRadioActive) {
                        if (isPlaying) {
                          await MinbarPlayer.player.pause();
                        } else {
                          await MinbarPlayer.player.play();
                        }
                      } else {
                        final displayName = _isArabic ? station.name : station.englishName;
                        final audioItem = MinbarAudioItem(
                          id: radioId,
                          title: displayName,
                          url: station.url,
                          authorId: 'quran_radio',
                        );
                        await MinbarPlayer.playPlaylist([audioItem], 0, _isArabic ? 'إذاعة مباشرة' : 'Live Radio');
                        await MinbarPlayer.player.play();
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPlaying
                              ? [Colors.red.shade600, Colors.red.shade400]
                              : [AppColors.emeraldDeep, AppColors.emeraldMid],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isPlaying ? Colors.red : AppColors.emeraldDeep)
                                .withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and Subtitle Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: _isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                          textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
                          children: [
                            if (isPlaying) ...[
                              const _AnimatedEqualizer(),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Text(
                                _isArabic ? station.name : station.englishName,
                                textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
                                style: AppTextStyles.headlineMedium.copyWith(
                                  fontFamily: _isArabic ? 'Amiri' : null,
                                  fontSize: _isArabic ? 15 : 13,
                                  fontWeight: FontWeight.bold,
                                  color: isCream ? AppColors.emeraldDeep : textColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getCategoryDisplayName(station.category),
                          style: AppTextStyles.audioSubtitle.copyWith(
                            fontSize: 10,
                            color: textColor.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Favorite toggle
                  IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? Colors.red.shade500 : textColor.withValues(alpha: 0.3),
                      size: 20,
                    ),
                    onPressed: () => _toggleFavorite(station.id),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getCategoryDisplayName(String cat) {
    if (_isArabic) {
      switch (cat) {
        case 'quran':
          return 'قرآن كريم';
        case 'tafsir':
          return 'تفسير';
        case 'adhkar':
          return 'أذكار';
        case 'ruqyah':
          return 'الرقية الشرعية';
        case 'varied':
          return 'منوعات / سيرة';
        default:
          return 'إذاعة';
      }
    } else {
      switch (cat) {
        case 'quran':
          return 'Holy Quran';
        case 'tafsir':
          return 'Tafsir';
        case 'adhkar':
          return 'Adhkar';
        case 'ruqyah':
          return 'Ruqyah';
        case 'varied':
          return 'Varied / Seerah';
        default:
          return 'Radio';
      }
    }
  }
}

// ── Micro-Animated Equalizer Widget ──
class _AnimatedEqualizer extends StatefulWidget {
  const _AnimatedEqualizer();

  @override
  State<_AnimatedEqualizer> createState() => _AnimatedEqualizerState();
}

class _AnimatedEqualizerState extends State<_AnimatedEqualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _barHeights = [10.0, 15.0, 8.0];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..addListener(() {
        if (mounted) {
          setState(() {
            // Cycle heights smoothly
            _barHeights[0] = 6.0 + 8.0 * (1.0 + double.parse((_controller.value * 2.0).toStringAsFixed(2)) % 1.0);
            _barHeights[1] = 4.0 + 12.0 * (1.0 - _controller.value);
            _barHeights[2] = 5.0 + 10.0 * (0.3 + _controller.value);
          });
        }
      });
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(3, (index) {
        return Container(
          width: 3,
          height: _barHeights[index],
          margin: const EdgeInsets.only(right: 2.0),
          decoration: BoxDecoration(
            color: Colors.red.shade500,
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
      }),
    );
  }
}
