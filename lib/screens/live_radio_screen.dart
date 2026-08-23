import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme_notifier.dart';
import '../widgets/persistent_audio_bar.dart';
import '../widgets/liquid_pressable.dart';
import '../widgets/custom_banner_ad.dart';
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
  String _selectedCategory = 'all';
  List<String> _favoriteIds = [];
  SharedPreferences? _prefs;

  static const Map<String, Map<String, String>> _l10n = {
    'en': {
      'title': 'Islamic Live Radio',
      'search_hint': 'Search station or reciter (in Arabic/English)...',
      'featured_title': 'Popular Selections',
      'all': 'All',
      'favorites': 'Favorites',
      'quran': 'Holy Quran',
      'tafsir': 'Tafsir & Fiqh',
      'adhkar': 'Adhkar & Dua',
      'ruqyah': 'Ruqyah',
      'translations': 'Translations',
      'varied': 'Varied & Seerah',
      'no_fav': 'No favorite stations added yet',
      'no_results': 'No radio stations found',
      'live': 'LIVE',
    },
    'ar': {
      'title': 'الإذاعات الإسلامية المباشرة',
      'search_hint': 'ابحث عن إذاعة أو قارئ (بالعربية/الإنجليزية)...',
      'featured_title': 'مختارات شائعة ومحبوبة',
      'all': 'الكل',
      'favorites': 'المفضلة',
      'quran': 'قرآن كريم',
      'tafsir': 'تفسير وفتاوى',
      'adhkar': 'أذكار وأدعية',
      'ruqyah': 'الرقية الشرعية',
      'translations': 'الترجمات',
      'varied': 'منوعات وسيرة',
      'no_fav': 'لا توجد إذاعات في المفضلة بعد',
      'no_results': 'لم يتم العثور على أي إذاعة',
      'live': 'مباشر',
    },
    'am': {
      'title': 'ኢስላማዊ የቀጥታ ሬዲዮ',
      'search_hint': 'የሬዲዮ ጣቢያ ወይም ቃሪእ ይፈልጉ...',
      'featured_title': 'ተወዳጅ ምርጫዎች',
      'all': 'ሁሉም',
      'favorites': 'ተወዳጆች',
      'quran': 'ቁርአን',
      'tafsir': 'ተፍሲር',
      'adhkar': 'አዝካር',
      'ruqyah': 'ሩቅያህ',
      'translations': 'ትርጉሞች',
      'varied': 'የተለያዩ',
      'no_fav': 'ምንም የተወደዱ ጣቢያዎች የሉም',
      'no_results': 'ምንም ሬዲዮ አልተገኘም',
      'live': 'በቀጥታ',
    },
    'om': {
      'title': 'Raadiyoo Islaamaa Kallattii',
      'search_hint': 'Raadiyoo ykn qari\'a barbaadi...',
      'featured_title': 'Filatamaa',
      'all': 'Hunda',
      'favorites': 'Filannoo',
      'quran': 'Quraana',
      'tafsir': 'Tafsiira',
      'adhkar': 'Azkaara',
      'ruqyah': 'Ruqiyaa',
      'translations': 'Hiika Quraanaa',
      'varied': 'Makaa',
      'no_fav': 'Raadiyoon filatame hin jiru',
      'no_results': 'Raadiyoon hin argamne',
      'live': 'Kallattiin',
    },
  };

  String _tr(BuildContext context, String key) {
    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    return _l10n[lang]?[key] ?? _l10n['ar']?[key] ?? _l10n['en']![key]!;
  }

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    _prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _favoriteIds = _prefs?.getStringList('favorite_radio_ids') ?? [];
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

  List<QuranRadioItem> _getFilteredStations() {
    return QuranRadioService.stations.where((station) {
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = station.name.toLowerCase().contains(query);
        final matchesEnglishName = station.englishName.toLowerCase().contains(query);
        if (!matchesName && !matchesEnglishName) return false;
      }

      if (_selectedCategory == 'favorites') {
        return _favoriteIds.contains(station.id);
      } else if (_selectedCategory != 'all') {
        return station.category == _selectedCategory;
      }

      return true;
    }).toList();
  }

  List<QuranRadioItem> _getFeaturedStations() {
    return QuranRadioService.stations.where((s) => s.isFeatured).toList();
  }

  Future<void> _playRadio(List<QuranRadioItem> stationsList, int index, bool isArabic) async {
    if (stationsList.isEmpty || index < 0 || index >= stationsList.length) return;
    
    final audioItems = stationsList.map((station) {
      final radioId = 'radio_${station.id}';
      final displayName = isArabic ? station.name : station.englishName;
      return MinbarAudioItem(
        id: radioId,
        title: displayName,
        url: station.url,
        authorId: 'quran_radio',
      );
    }).toList();

    await MinbarPlayer.playPlaylist(audioItems, index, isArabic ? 'إذاعة مباشرة' : 'Live Radio');
    await MinbarPlayer.player.play();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final isArabic = locale == 'ar';
    final isFavView = _selectedCategory == 'favorites';

    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final isDark = theme == QuranTheme.dark;
        final isCream = theme == QuranTheme.cream;

        final Color bg = isDark
            ? const Color(0xFF090E11)
            : (isCream ? const Color(0xFFFBF8F0) : const Color(0xFFF4F7F5));

        final Color textColor = isDark
            ? const Color(0xFFF0F4F0)
            : (isCream ? const Color(0xFF2C1C11) : const Color(0xFF0D3D2E));

        final Color cardBg = isDark
            ? const Color(0xFF121B19)
            : (isCream ? const Color(0xFFFFFDF8) : Colors.white);

        final Color borderColor = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : (isCream ? const Color(0xFFE2D5BE) : const Color(0xFFE2EBE7));

        final Color primaryAccent = isDark
            ? const Color(0xFF2ECC9A)
            : (isCream ? const Color(0xFF8B5319) : const Color(0xFF1B8A6B));

        final filteredStations = _getFilteredStations();
        final featuredStations = _getFeaturedStations();

        return Scaffold(
          backgroundColor: bg,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              _tr(context, 'title'),
              style: TextStyle(
                fontFamily: isArabic ? 'Amiri' : null,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            centerTitle: true,
            actions: [
              // Top Right Favorites Shortcut Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: LiquidPressable(
                  onTap: () {
                    setState(() {
                      _selectedCategory = isFavView ? 'all' : 'favorites';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isFavView
                          ? const Color(0xFFE53935).withValues(alpha: 0.15)
                          : cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isFavView ? const Color(0xFFE53935) : borderColor,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isFavView ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: isFavView ? const Color(0xFFE53935) : textColor.withValues(alpha: 0.7),
                          size: 18,
                        ),
                        if (_favoriteIds.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text(
                            '${_favoriteIds.length}',
                            style: TextStyle(
                              color: isFavView ? const Color(0xFFE53935) : textColor.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: ValueListenableBuilder<bool>(
            valueListenable: kAdVisibleNotifier,
            builder: (context, isAdVisible, _) {
              return Column(
                children: [
                  // ── Search Bar ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) => setState(() => _searchQuery = val.trim()),
                        style: TextStyle(color: textColor, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: _tr(context, 'search_hint'),
                          hintStyle: TextStyle(
                            color: isDark ? const Color(0xFF6C7C78) : const Color(0xFF9AA8A4),
                            fontSize: 12.5,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: primaryAccent,
                            size: 20,
                          ),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                    ),
                  ),

                  // ── Category Chips ──
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                    child: Row(
                      children: [
                        _buildCategoryChip('all', _tr(context, 'all'), Icons.radio_rounded, isDark, isCream, textColor, primaryAccent),
                        const SizedBox(width: 8),
                        _buildCategoryChip('quran', _tr(context, 'quran'), Icons.menu_book_rounded, isDark, isCream, textColor, primaryAccent),
                        const SizedBox(width: 8),
                        _buildCategoryChip('tafsir', _tr(context, 'tafsir'), Icons.auto_stories_rounded, isDark, isCream, textColor, primaryAccent),
                        const SizedBox(width: 8),
                        _buildCategoryChip('adhkar', _tr(context, 'adhkar'), Icons.spa_rounded, isDark, isCream, textColor, primaryAccent),
                        const SizedBox(width: 8),
                        _buildCategoryChip('ruqyah', _tr(context, 'ruqyah'), Icons.healing_rounded, isDark, isCream, textColor, primaryAccent),
                        const SizedBox(width: 8),
                        _buildCategoryChip('translations', _tr(context, 'translations'), Icons.language_rounded, isDark, isCream, textColor, primaryAccent),
                        const SizedBox(width: 8),
                        _buildCategoryChip('varied', _tr(context, 'varied'), Icons.category_rounded, isDark, isCream, textColor, primaryAccent),
                      ],
                    ),
                  ),

                  // ── Main List & Featured Carousel ──
                  Expanded(
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Popular Selections Carousel (When viewing 'all' and not searching)
                        if (_selectedCategory == 'all' && _searchQuery.isEmpty)
                          SliverToBoxAdapter(
                            child: _buildFeaturedRadiosCarousel(
                              featuredStations,
                              isDark,
                              isCream,
                              cardBg,
                              borderColor,
                              textColor,
                              primaryAccent,
                              isArabic,
                            ),
                          ),

                        // Stations List
                        if (filteredStations.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isFavView
                                        ? Icons.favorite_border_rounded
                                        : Icons.search_off_rounded,
                                    size: 54,
                                    color: isDark ? Colors.white24 : Colors.black26,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    isFavView
                                        ? _tr(context, 'no_fav')
                                        : _tr(context, 'no_results'),
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF8A9995) : const Color(0xFF6B8079),
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: EdgeInsets.fromLTRB(16, 8, 16, isAdVisible ? 90 : 30),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final station = filteredStations[index];
                                  final isFav = _favoriteIds.contains(station.id);
                                  return _buildRadioListTile(
                                    context,
                                    station,
                                    index,
                                    filteredStations,
                                    isFav,
                                    isDark,
                                    isCream,
                                    textColor,
                                    cardBg,
                                    borderColor,
                                    primaryAccent,
                                    isArabic,
                                  );
                                },
                                childCount: filteredStations.length,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // ── Persistent Audio Bar ──
                  const PersistentAudioBar(),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ── Popular Selections Carousel ─────────────────────────────────────────────
  Widget _buildFeaturedRadiosCarousel(
    List<QuranRadioItem> featuredList,
    bool isDark,
    bool isCream,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color primaryAccent,
    bool isArabic,
  ) {
    if (featuredList.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
          child: Row(
            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4AF37),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _tr(context, 'featured_title'),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15.5,
                  fontFamily: isArabic ? 'Amiri' : null,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: featuredList.length,
            itemBuilder: (context, idx) {
              final station = featuredList[idx];
              final radioId = 'radio_${station.id}';
              final displayName = isArabic ? station.name : station.englishName;

              return ValueListenableBuilder<MinbarAudioItem?>(
                valueListenable: MinbarPlayer.currentItemNotifier,
                builder: (context, currentItem, _) {
                  final isRadioActive = currentItem != null && currentItem.id == radioId;

                  return StreamBuilder<bool>(
                    stream: MinbarPlayer.player.playingStream,
                    builder: (context, snapshot) {
                      final isPlaying = isRadioActive && (snapshot.data ?? false);

                      return LiquidPressable(
                        onTap: () => _playRadio(featuredList, idx, isArabic),
                        child: Container(
                          width: 200,
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isPlaying
                                  ? [const Color(0xFF0F5A47), const Color(0xFF1B8A6B)]
                                  : [cardBg, cardBg],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isPlaying ? const Color(0xFF2ECC9A) : borderColor,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: (isPlaying ? Colors.white : const Color(0xFFD4AF37))
                                          .withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: isPlaying ? Colors.redAccent : const Color(0xFFD4AF37),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _tr(context, 'live'),
                                          style: TextStyle(
                                            color: isPlaying ? Colors.white : const Color(0xFFD4AF37),
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                                    size: 26,
                                    color: isPlaying ? Colors.white : primaryAccent,
                                  ),
                                ],
                              ),
                              Text(
                                displayName,
                                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                style: TextStyle(
                                  color: isPlaying ? Colors.white : textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  fontFamily: isArabic ? 'Amiri' : null,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Category Chip ───────────────────────────────────────────────────────────
  Widget _buildCategoryChip(
    String categoryId,
    String label,
    IconData icon,
    bool isDark,
    bool isCream,
    Color textColor,
    Color primaryAccent,
  ) {
    final isSelected = _selectedCategory == categoryId;

    return LiquidPressable(
      onTap: () => setState(() => _selectedCategory = categoryId),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryAccent
              : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryAccent.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? Colors.white : textColor.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : textColor.withValues(alpha: 0.85),
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Station List Tile ───────────────────────────────────────────────────────
  Widget _buildRadioListTile(
    BuildContext context,
    QuranRadioItem station,
    int index,
    List<QuranRadioItem> stationsList,
    bool isFav,
    bool isDark,
    bool isCream,
    Color textColor,
    Color cardBg,
    Color borderColor,
    Color primaryAccent,
    bool isArabic,
  ) {
    final radioId = 'radio_${station.id}';
    final displayName = isArabic ? station.name : station.englishName;

    return ValueListenableBuilder<MinbarAudioItem?>(
      valueListenable: MinbarPlayer.currentItemNotifier,
      builder: (context, currentItem, _) {
        final isRadioActive = currentItem != null && currentItem.id == radioId;

        return StreamBuilder<bool>(
          stream: MinbarPlayer.player.playingStream,
          builder: (context, snapshot) {
            final isPlaying = isRadioActive && (snapshot.data ?? false);

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isPlaying ? primaryAccent : borderColor,
                  width: isPlaying ? 1.6 : 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isPlaying
                        ? primaryAccent.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: LiquidPressable(
                onTap: () => _playRadio(stationsList, index, isArabic),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isPlaying
                            ? [const Color(0xFFE53935), const Color(0xFFEF5350)]
                            : [primaryAccent, primaryAccent.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isPlaying ? Colors.red : primaryAccent).withValues(alpha: 0.3),
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
                  title: Row(
                    children: [
                      if (isPlaying) ...[
                        const _AnimatedEqualizer(),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: Text(
                          displayName,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontFamily: isArabic ? 'Amiri' : null,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    _tr(context, station.category),
                    style: TextStyle(
                      color: isDark ? const Color(0xFF8A9995) : const Color(0xFF6B8079),
                      fontSize: 11,
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isFav ? const Color(0xFFE53935) : textColor.withValues(alpha: 0.3),
                      size: 20,
                    ),
                    onPressed: () => _toggleFavorite(station.id),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Live Animated Equalizer Widget ───────────────────────────────────────────
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
            _barHeights[0] = 6.0 + 8.0 * ((_controller.value * 2.0) % 1.0);
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
            color: const Color(0xFFE53935),
            borderRadius: BorderRadius.circular(1.5),
          ),
        );
      }),
    );
  }
}
