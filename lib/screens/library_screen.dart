import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme_notifier.dart';
import '../services/library_service.dart';
import '../models/library_item.dart';
import 'library_category_screen.dart';
import 'library_content_list_screen.dart';
import 'story_reading_screen.dart';
import 'ruqyah_screen.dart';
import 'fiqh_and_fatawa_screen.dart';
import 'quiz_intro_screen.dart';
import '../widgets/liquid_pressable.dart';
import '../widgets/custom_banner_ad.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Domain Configuration with Curated Luxury Islamic Palettes & Localization
// ─────────────────────────────────────────────────────────────────────────────
class _DomainInfo {
  final String part;
  final Map<String, String> titles;
  final Map<String, String> subtitles;
  final IconData icon;
  final List<Color> gradient;
  final Color accentColor;

  const _DomainInfo({
    required this.part,
    required this.titles,
    required this.subtitles,
    required this.icon,
    required this.gradient,
    required this.accentColor,
  });

  String title(String locale) => titles[locale] ?? titles['ar'] ?? titles['en']!;
  String subtitle(String locale) => subtitles[locale] ?? subtitles['ar'] ?? subtitles['en']!;
}

const List<_DomainInfo> _kDomainList = [
  _DomainInfo(
    part: 'المكتبة',
    titles: {
      'ar': 'المكتبة الإسلامية',
      'en': 'Islamic Library',
      'am': 'ኢስላማዊ ቤተ-መጽሐፍት',
      'om': 'Mana Kitaaba Islaamaa',
    },
    subtitles: {
      'ar': 'كتب، كتيبات، ومطويات دعوية',
      'en': 'Books, booklets & pamphlets',
      'am': 'መጽሐፍት እና የዳዕዋ ጽሑፎች',
      'om': 'Kitaabota fi barruulee da\'waa',
    },
    icon: Icons.local_library_rounded,
    gradient: [Color(0xFF0F5A47), Color(0xFF1B8A6B)],
    accentColor: Color(0xFF2ECC9A),
  ),
  _DomainInfo(
    part: 'صحيح البخارى',
    titles: {
      'ar': 'صحيح البخاري',
      'en': 'Sahih Al-Bukhari',
      'am': 'ሶሂህ አል-ቡኻሪ',
      'om': 'Sahiih Al-Bukhaarii',
    },
    subtitles: {
      'ar': 'الجامع الصحيح المسند',
      'en': 'Authentic Hadith collection',
      'am': 'ትክክለኛ የሐዲስ ስብስብ',
      'om': 'Kilaasika hadiisota sahiiha',
    },
    icon: Icons.menu_book_rounded,
    gradient: [Color(0xFF8D5B18), Color(0xFFC68A2E)],
    accentColor: Color(0xFFE5A93C),
  ),
  _DomainInfo(
    part: 'فقه وفتاوى',
    titles: {
      'ar': 'فقه وفتاوى',
      'en': 'Fiqh & Fatawa',
      'am': 'ፊቅህ እና ፈትዋ',
      'om': 'Fiqhii fi Fatwaa',
    },
    subtitles: {
      'ar': 'أحكام العبادات والمعاملات',
      'en': 'Islamic rulings & guidance',
      'am': 'የኢባዳ እና የሙዓመላት ህጎች',
      'om': 'Murteewwan amantii fi seera',
    },
    icon: Icons.balance_rounded,
    gradient: [Color(0xFF4A154B), Color(0xFF7A257C)],
    accentColor: Color(0xFFAB47BC),
  ),
  _DomainInfo(
    part: 'تفسير أحلام',
    titles: {
      'ar': 'تفسير الأحلام',
      'en': 'Dream Interpretation',
      'am': 'የሕልም ፍቺ',
      'om': 'Hiika Abjuu',
    },
    subtitles: {
      'ar': 'جامع تفاسير الرؤى والأحلام',
      'en': 'Meanings of dreams & visions',
      'am': 'የሕልሞች እና ራእዮች ማብራሪያ',
      'om': 'Hiikkaa abjuu fi mul\'ataa',
    },
    icon: Icons.nightlight_round,
    gradient: [Color(0xFF1A365D), Color(0xFF2B6CB0)],
    accentColor: Color(0xFF4299E1),
  ),
  _DomainInfo(
    part: 'الرقية الشرعية',
    titles: {
      'ar': 'الرقية الشرعية',
      'en': 'Ruqyah Shariyyah',
      'am': 'ሩቅያህ ሸርዒያህ',
      'om': 'Ruqiyaa Shar\'iyyaa',
    },
    subtitles: {
      'ar': 'تحصينات وأدعية الشفاء',
      'en': 'Healing & spiritual protection',
      'am': 'የፈውስ እና የጥበቃ ዱዓዎች',
      'om': 'Dawaa fi du\'aa\'ii eegumsaa',
    },
    icon: Icons.healing_rounded,
    gradient: [Color(0xFF702459), Color(0xFF97266D)],
    accentColor: Color(0xFFED64A6),
  ),
  _DomainInfo(
    part: 'مسابقات',
    titles: {
      'ar': 'المسابقات الإسلامية',
      'en': 'Islamic Quizzes',
      'am': 'ኢስላማዊ ውድድሮች',
      'om': 'Dorgommii Islaamaa',
    },
    subtitles: {
      'ar': 'اختبر معلوماتك وثقافتك',
      'en': 'Test knowledge & culture',
      'am': 'እውቀትዎን ይፈትሹ',
      'om': 'Beekumsa kee qori',
    },
    icon: Icons.emoji_events_rounded,
    gradient: [Color(0xFF744210), Color(0xFFB7791F)],
    accentColor: Color(0xFFECC94B),
  ),
];

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final LibraryService _libraryService = LibraryService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  List<LibraryItem> _searchResults = [];
  bool _isSearching = false;
  int _favCount = 0;

  List<LibraryItem> _featuredPamphlets = [];
  bool _isLoadingPamphlets = true;

  @override
  void initState() {
    super.initState();
    _loadFavCount();
    _loadFeaturedPamphlets();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavCount() async {
    final favs = await _libraryService.getFavorites();
    if (mounted) {
      setState(() {
        _favCount = favs.length;
      });
    }
  }

  Future<void> _loadFeaturedPamphlets() async {
    final pamphlets = await _libraryService.getFeaturedPamphlets();
    if (mounted) {
      setState(() {
        _featuredPamphlets = pamphlets;
        _isLoadingPamphlets = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }
    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 250), () async {
      final results = await _libraryService.searchLibrary(trimmed);
      if (mounted && _isSearching) {
        setState(() {
          _searchResults = results;
        });
      }
    });
  }

  void _navigateToFavorites() async {
    final l10n = AppLocalizations.of(context);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LibraryContentListScreen(
          part: 'favorites',
          categoryId: 'favorites',
          categoryTitle: l10n?.libraryFavorites ?? 'المفضلة',
        ),
      ),
    );
    _loadFavCount();
  }

  void _navigateToDomain(_DomainInfo domain) {
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    if (domain.part == 'الرقية الشرعية') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const RuqyahScreen()));
      return;
    }
    if (domain.part == 'فقه وفتاوى') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FiqhAndFatawaScreen()));
      return;
    }
    if (domain.part == 'مسابقات') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const QuizIntroScreen()));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LibraryCategoryScreen(
          domainPart: domain.part,
          domainTitle: domain.title(locale),
        ),
      ),
    );
  }

  void _openStory(LibraryItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoryReadingScreen(item: item)),
    );
    _loadFavCount();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';

    final String secTitleMain = {
      'ar': 'أقسام المكتبة الرئيسية',
      'en': 'Main Library Categories',
      'am': 'ዋና ዋና የቤተ-መጽሐፍት ክፍሎች',
      'om': 'Kutaa Mana Kitaabaa Ijoo',
    }[locale] ?? 'أقسام المكتبة الرئيسية';

    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, currentTheme, _) {
        final bool isDark = currentTheme == QuranTheme.dark;
        final bool isCream = currentTheme == QuranTheme.cream;

        final Color textColor = isDark
            ? const Color(0xFFF0F4F0)
            : (isCream ? const Color(0xFF2C1C11) : const Color(0xFF0F382C));

        final Color cardBg = isDark
            ? const Color(0xFF121B19)
            : (isCream ? const Color(0xFFFFFDF8) : Colors.white);

        final Color borderColor = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : (isCream ? const Color(0xFFE2D5BE) : const Color(0xFFE2EBE7));

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            bottom: false,
            child: ValueListenableBuilder<bool>(
              valueListenable: kAdVisibleNotifier,
              builder: (context, isAdVisible, _) {
                return Column(
                  children: [
                    _buildHeader(isDark, isCream, textColor, cardBg, borderColor, l10n, locale),
                    _buildSearchBar(isDark, isCream, textColor, cardBg, borderColor, locale),
                    Expanded(
                      child: _isSearching
                          ? _buildSearchResults(isDark, isCream, textColor, cardBg, borderColor, isAdVisible)
                          : CustomScrollView(
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                SliverToBoxAdapter(
                                  child: _buildFeaturedPamphletsSection(
                                    isDark,
                                    isCream,
                                    textColor,
                                    cardBg,
                                    borderColor,
                                    isAdVisible,
                                    locale,
                                  ),
                                ),
                                SliverToBoxAdapter(
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 18,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF2ECC9A),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          secTitleMain,
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16.5,
                                            fontFamily: locale == 'ar' ? 'Amiri' : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                _buildDomainGrid(isDark, isCream, cardBg, borderColor, isAdVisible, locale),
                                 SliverToBoxAdapter(
                                   child: SizedBox(height: isAdVisible ? 90 : 80),
                                 ),
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    bool isDark,
    bool isCream,
    Color textColor,
    Color cardBg,
    Color borderColor,
    AppLocalizations? l10n,
    String locale,
  ) {
    final String subtitleText = {
      'ar': 'كنوز المعرفة والعلوم الشرعية',
      'en': 'Treasures of Islamic Knowledge',
      'am': 'የእስልምና እውቀት ውድ ሀብቶች',
      'om': 'Qabeenya Beekumsa Islaamaa',
    }[locale] ?? 'كنوز المعرفة والعلوم الشرعية';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F5A47), Color(0xFF1B8A6B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B8A6B).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.navLibrary ?? 'المكتبة الإسلامية',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                      fontFamily: locale == 'ar' ? 'Amiri' : null,
                    ),
                  ),
                  Text(
                    subtitleText,
                    style: TextStyle(
                      color: isDark ? const Color(0xFF8A9995) : const Color(0xFF5A726A),
                      fontSize: 11.5,
                      fontFamily: locale == 'ar' ? 'Amiri' : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: _navigateToFavorites,
            tooltip: l10n?.libraryFavorites ?? 'المفضلة',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cardBg,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.bookmark_added_rounded, color: Color(0xFFD4AF37), size: 20),
                ),
                if (_favCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          '$_favCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
    bool isDark,
    bool isCream,
    Color textColor,
    Color cardBg,
    Color borderColor,
    String locale,
  ) {
    final String hint = {
      'ar': 'ابحث باللغة العربية (في الكتب، الأحاديث، والفتاوى)...',
      'en': 'Search in Arabic only (books, hadiths, fatawa)...',
      'am': 'በአረብኛ ብቻ ይፈልጉ (መጽሐፍት፣ ሐዲሶች፣ ፈትዋ)...',
      'om': 'Afaan Arabaatiin qofa barbaadi (kitaabota, hadiisota)...',
    }[locale] ?? 'ابحث باللغة العربية (في الكتب، الأحاديث، والفتاوى)...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: TextStyle(color: textColor, fontSize: 14.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? const Color(0xFF6C7C78) : const Color(0xFF9AA8A4),
              fontSize: 13,
            ),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1B8A6B), size: 22),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 13),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedPamphletsSection(
    bool isDark,
    bool isCream,
    Color textColor,
    Color cardBg,
    Color borderColor,
    bool isAdVisible,
    String locale,
  ) {
    if (_isLoadingPamphlets || _featuredPamphlets.isEmpty) {
      return const SizedBox.shrink();
    }

    final titleColor = isDark ? Colors.white : textColor;

    final String secTitleInspire = {
      'ar': 'قبسات وقراءات ملهمة',
      'en': 'Inspiring Quick Reads',
      'am': 'አነቃቂ አጫጭር ንባቦች',
      'om': 'Dubbisa Gabaabduu',
    }[locale] ?? 'قبسات وقراءات ملهمة';

    final String secSubtitleInspire = {
      'ar': 'قراءة سريعة متجددة',
      'en': 'Fresh daily insights',
      'am': 'ዕለታዊ ፈጣን ንባብ',
      'om': 'Beekumsa haarawaa',
    }[locale] ?? 'قراءة سريعة متجددة';

    final String readNowText = {
      'ar': 'اقرأ الآن ←',
      'en': 'Read now →',
      'am': 'አሁን ያንብቡ →',
      'om': 'Amma dubbisi →',
    }[locale] ?? 'اقرأ الآن ←';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    secTitleInspire,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF0F4F0) : textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16.5,
                      fontFamily: locale == 'ar' ? 'Amiri' : null,
                    ),
                  ),
                ],
              ),
              Text(
                secSubtitleInspire,
                style: TextStyle(
                  color: isDark ? const Color(0xFF8A9995) : const Color(0xFF6B8079),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _featuredPamphlets.length,
            itemBuilder: (context, idx) {
              final item = _featuredPamphlets[idx];
              final bool isBukhariItem = item.part == 'صحيح البخارى' || item.part == 'البخارى';
              final Color badgeColor = isBukhariItem ? const Color(0xFFC68A2E) : const Color(0xFF1B8A6B);
              final String badgeText = isBukhariItem
                  ? (locale == 'ar' ? 'صحيح البخاري' : 'Sahih Bukhari')
                  : (locale == 'ar' ? 'المكتبة الإسلامية' : 'Islamic Library');

              final String cleanTitle = item.title
                  .replaceAll('{', '')
                  .replaceAll('}', '')
                  .replaceAll(RegExp(r'\s+'), ' ')
                  .trim();

              return LiquidPressable(
                onTap: () => _openStory(item),
                child: Container(
                  width: 220,
                  margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(
                            isBukhariItem ? Icons.menu_book_rounded : Icons.auto_stories_rounded,
                            size: 15,
                            color: badgeColor,
                          ),
                        ],
                      ),
                      Text(
                        cleanTitle,
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          fontFamily: locale == 'ar' ? 'Amiri' : null,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          const Icon(Icons.remove_red_eye_rounded, size: 12, color: Color(0xFFD4AF37)),
                          const SizedBox(width: 4),
                          Text(
                            item.numReadings > 0
                                ? '${item.numReadings} ${locale == 'ar' ? 'قراءة' : 'reads'}'
                                : (locale == 'ar' ? 'مستحسن' : 'Featured'),
                            style: TextStyle(
                              color: isDark ? const Color(0xFF8A9995) : const Color(0xFF6B8079),
                              fontSize: 10.5,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            readNowText,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDomainGrid(
    bool isDark,
    bool isCream,
    Color cardBg,
    Color borderColor,
    bool isAdVisible,
    String locale,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final domain = _kDomainList[index];
            return _LuxuryDomainCard(
              domain: domain,
              isDark: isDark,
              cardBg: cardBg,
              borderColor: borderColor,
              locale: locale,
              onTap: () => _navigateToDomain(domain),
            );
          },
          childCount: _kDomainList.length,
        ),
      ),
    );
  }

  Widget _buildSearchResults(
    bool isDark,
    bool isCream,
    Color textColor,
    Color cardBg,
    Color borderColor,
    bool isAdVisible,
  ) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 54,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد نتائج بحث مطابقة',
              style: TextStyle(
                color: isDark ? const Color(0xFF8A9995) : const Color(0xFF6B8079),
                fontSize: 15,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 8, 16, isAdVisible ? 70 : 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, idx) {
        final item = _searchResults[idx];
        final cleanTitle = item.title
            .replaceAll('{', '')
            .replaceAll('}', '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        return LiquidPressable(
          onTap: () => _openStory(item),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B8A6B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Color(0xFF1B8A6B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleanTitle,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          fontFamily: 'Amiri',
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.part.isNotEmpty ? item.part : 'المكتبة الإسلامية',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF8A9995) : const Color(0xFF6B8079),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.black26,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LuxuryDomainCard extends StatelessWidget {
  final _DomainInfo domain;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final String locale;
  final VoidCallback onTap;

  const _LuxuryDomainCard({
    required this.domain,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF152A24);
    final title = domain.title(locale);
    final subtitle = domain.subtitle(locale);

    return LiquidPressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: domain.accentColor.withValues(alpha: isDark ? 0.12 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Positioned(
                top: -16,
                right: -16,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        domain.accentColor.withValues(alpha: isDark ? 0.18 : 0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: domain.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: domain.accentColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(domain.icon, color: Colors.white, size: 22),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            fontFamily: locale == 'ar' ? 'Amiri' : null,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF8A9995)
                                : const Color(0xFF657B74),
                            fontSize: 10.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
