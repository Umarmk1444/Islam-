import 'dart:async';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme_notifier.dart';
import '../services/library_service.dart';
import '../models/library_item.dart';
import '../models/user_pdf_book.dart';
import 'library_category_screen.dart';
import 'library_content_list_screen.dart';
import 'story_reading_screen.dart';
import 'ruqyah_screen.dart';
import 'fiqh_and_fatawa_screen.dart';
import 'quiz_intro_screen.dart';
import 'pdf_reader_screen.dart';
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

const _DomainInfo _kBukhariDomain = _DomainInfo(
  part: 'صحيح البخارى',
  titles: {
    'ar': 'صحيح البخاري',
    'en': 'Sahih Al-Bukhari',
    'am': 'ሶሂህ አል-ቡኻሪ',
    'om': 'Sahiih Al-Bukhaarii',
  },
  subtitles: {
    'ar': 'الجامع الصحيح المسند من أمور رسول الله ﷺ وسننه وأيامه',
    'en': 'Authentic Hadith collection of Prophet Muhammad ﷺ',
    'am': 'ትክክለኛ የነቢዩ ሙሐመድ ﷺ የሐዲስ ስብስብ',
    'om': 'Kilaasika hadiisota sahiiha Ergamaa Rabbii ﷺ',
  },
  icon: Icons.menu_book_rounded,
  gradient: [Color(0xFF8D5B18), Color(0xFFC68A2E)],
  accentColor: Color(0xFFE5A93C),
);

const _DomainInfo _kLibraryDomain = _DomainInfo(
  part: 'المكتبة',
  titles: {
    'ar': 'المكتبة الإسلامية',
    'en': 'Islamic Library',
    'am': 'ኢስላማዊ ቤተ-መጽሐፍት',
    'om': 'Mana Kitaaba Islaamaa',
  },
  subtitles: {
    'ar': 'موسوعة الكتب، الرسائل، والمطويات الدعوية المصنفة',
    'en': 'Books, treatises & Islamic guidance booklets',
    'am': 'መጽሐፍት እና የዳዕዋ ጽሑፎች ስብስብ',
    'om': 'Kitaabota fi barruulee da\'waa',
  },
  icon: Icons.local_library_rounded,
  gradient: [Color(0xFF0F5A47), Color(0xFF1B8A6B)],
  accentColor: Color(0xFF2ECC9A),
);

const List<_DomainInfo> _kSecondaryDomains = [
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
    part: 'الرقية الشرعية',
    titles: {
      'ar': 'الرقية الشرعية',
      'en': 'Ruqyah Shariyyah',
      'am': 'ሩቅያህ ሸርዒያህ',
      'om': 'Ruqiyaa Shar\'iyyaa',
    },
    subtitles: {
      'ar': 'تحصينات وأدعية الشفاء',
      'en': 'Healing & protection',
      'am': 'የፈውስ እና የጥበቃ ዱዓዎች',
      'om': 'Dawaa fi du\'aa\'ii eegumsaa',
    },
    icon: Icons.healing_rounded,
    gradient: [Color(0xFF702459), Color(0xFF97266D)],
    accentColor: Color(0xFFED64A6),
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
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;

  List<LibraryItem> _searchResults = [];
  bool _isSearching = false;
  int _favCount = 0;

  List<LibraryItem> _featuredPamphlets = [];
  bool _isLoadingPamphlets = true;

  // Local PDF Books & Resume Reading States
  List<UserPdfBook> _userPdfBooks = [];
  bool _isLoadingPdfBooks = true;
  bool _isImportingPdf = false;
  Map<String, dynamic>? _latestResumeItem;
  int _selectedFilterIndex = 0; // 0: All, 1: Bukhari, 2: Library, 3: Fiqh, 4: My Shelf

  @override
  void initState() {
    super.initState();
    _loadFavCount();
    _loadFeaturedPamphlets();
    _loadUserPdfBooks();
    _loadResumeItem();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
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

  Future<void> _loadUserPdfBooks() async {
    final books = await _libraryService.getUserPdfBooks();
    if (mounted) {
      setState(() {
        _userPdfBooks = books;
        _isLoadingPdfBooks = false;
      });
    }
  }

  Future<void> _loadResumeItem() async {
    final item = await _libraryService.getLatestResumeItem();
    if (mounted) {
      setState(() {
        _latestResumeItem = item;
      });
    }
  }

  Future<void> _importPdf() async {
    if (_isImportingPdf) return;
    setState(() => _isImportingPdf = true);

    try {
      final imported = await _libraryService.pickAndImportPdfBook();
      if (imported != null && mounted) {
        await _loadUserPdfBooks();
        await _loadResumeItem();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تمت إضافة "${imported.title}" إلى كتبي الخاصة بنجاح',
              style: const TextStyle(fontFamily: 'Amiri'),
            ),
            backgroundColor: const Color(0xFF1B8A6B),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'اقرأ الآن',
              textColor: const Color(0xFFECC94B),
              onPressed: () => _openPdfReader(imported),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر استيراد ملف PDF: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImportingPdf = false);
      }
    }
  }

  void _openPdfReader(UserPdfBook book) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfReaderScreen(book: book)),
    );
    _loadUserPdfBooks();
    _loadResumeItem();
  }

  void _confirmDeletePdfBook(UserPdfBook book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text(
              'حذف الكتاب',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من حذف "${book.title}" من مكتبتك الخاصة؟\nسيتم حذف الملف والتقدم المحفوظ نهائياً.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (book.id != null) {
                await _libraryService.deleteUserPdfBook(book.id!);
                await _loadUserPdfBooks();
                await _loadResumeItem();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حذف الكتاب بنجاح'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            child: const Text('حذف'),
          ),
        ],
      ),
    );
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
    _loadResumeItem();
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
    ).then((_) {
      _loadResumeItem();
    });
  }

  void _openStory(LibraryItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoryReadingScreen(item: item)),
    );
    _loadFavCount();
    _loadResumeItem();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';

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
                final double bottomClearance =
                    MediaQuery.paddingOf(context).bottom + (isAdVisible ? 120 : 100);

                return Column(
                  children: [
                    // Top Header Bar (Zero overflow guaranteed with Expanded)
                    _buildHeader(isDark, isCream, textColor, cardBg, borderColor, l10n, locale),

                    // Elegant Search Input Bar
                    _buildSearchBar(isDark, isCream, textColor, cardBg, borderColor, locale),

                    // Category & Shelf Filter Pills
                    _buildFilterChips(isDark, isCream, textColor, cardBg, borderColor, locale),

                    Expanded(
                      child: _isSearching
                          ? _buildSearchResults(isDark, isCream, textColor, cardBg, borderColor, bottomClearance)
                          : CustomScrollView(
                              controller: _scrollController,
                              physics: const BouncingScrollPhysics(),
                              slivers: [
                                // 1. Unified Bookshelf & Reading Hub (Compact & cohesive)
                                if (_selectedFilterIndex == 0 || _selectedFilterIndex == 4)
                                  SliverToBoxAdapter(
                                    child: _buildBookshelfSection(
                                      isDark,
                                      isCream,
                                      textColor,
                                      cardBg,
                                      borderColor,
                                      locale,
                                    ),
                                  ),

                                // 2. Main Master Categories (Bukhari, Islamic Library, and 2x2 Grid)
                                if (_selectedFilterIndex != 4) ...[
                                  SliverToBoxAdapter(
                                    child: _buildCategoriesHeader(textColor, locale),
                                  ),
                                  _buildMasterDomainGrid(
                                    isDark,
                                    isCream,
                                    textColor,
                                    cardBg,
                                    borderColor,
                                    locale,
                                  ),
                                ],

                                // 3. Streamlined Inspiring Quick Reads
                                if (_selectedFilterIndex == 0)
                                  SliverToBoxAdapter(
                                    child: _buildFeaturedPamphletsSection(
                                      isDark,
                                      isCream,
                                      textColor,
                                      cardBg,
                                      borderColor,
                                      locale,
                                    ),
                                  ),

                                // Bottom clearance so dock never obscures content
                                SliverToBoxAdapter(
                                  child: SizedBox(height: bottomClearance),
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

  // ───────────────────────────────────────────────────────────────────────────
  // 1. Header Bar (Overflow-Free)
  // ───────────────────────────────────────────────────────────────────────────
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
      'ar': 'كنوز المعرفة، كتب PDF والعلوم الشرعية',
      'en': 'Islamic Treasures, PDF Books & Sciences',
      'am': 'የእስልምና እውቀት ውድ ሀብቶች እና PDF መጽሐፍት',
      'om': 'Qabeenya Beekumsa Islaamaa fi Kitaabota PDF',
    }[locale] ?? 'كنوز المعرفة، كتب PDF والعلوم الشرعية';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          // Islamic Emblem Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F5A47), Color(0xFF1B8A6B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(13),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B8A6B).withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),

          // Title & Subtitle (Wrapped in Expanded to completely prevent horizontal overflow)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n?.navLibrary ?? 'المكتبة الإسلامية',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: locale == 'ar' ? 'Amiri' : null,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitleText,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF8A9995) : const Color(0xFF5A726A),
                    fontSize: 11,
                    fontFamily: locale == 'ar' ? 'Amiri' : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Favorites Action Button
          LiquidPressable(
            onTap: _navigateToFavorites,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: cardBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.bookmark_added_rounded, color: Color(0xFFD4AF37), size: 19),
                ),
                if (_favCount > 0)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE53935),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                      child: Center(
                        child: Text(
                          '$_favCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
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

  // ───────────────────────────────────────────────────────────────────────────
  // 2. Search Bar
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSearchBar(
    bool isDark,
    bool isCream,
    Color textColor,
    Color cardBg,
    Color borderColor,
    String locale,
  ) {
    final String hint = {
      'ar': 'ابحث في الكتب، الأحاديث، والفتاوى...',
      'en': 'Search in books, hadiths & fatawa...',
      'am': 'በመጽሐፍት፣ ሐዲሶች እና ፈትዋ ውስጥ ይፈልጉ...',
      'om': 'Kitaabota, hadiisota fi fatwaa keessatti barbaadi...',
    }[locale] ?? 'ابحث في الكتب، الأحاديث، والفتاوى...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          style: TextStyle(color: textColor, fontSize: 13.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? const Color(0xFF6C7C78) : const Color(0xFF9AA8A4),
              fontSize: 12.5,
            ),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1B8A6B), size: 20),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 17),
                    onPressed: () {
                      _searchController.clear();
                      _onSearchChanged('');
                    },
                  )
                : null,
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 3. Category Filter Chips
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFilterChips(
    bool isDark,
    bool isCream,
    Color textColor,
    Color cardBg,
    Color borderColor,
    String locale,
  ) {
    final List<Map<String, dynamic>> filters = [
      {
        'title': {'ar': 'الكل', 'en': 'All', 'am': 'ሁሉም', 'om': 'Hunda'}[locale] ?? 'الكل',
        'icon': Icons.apps_rounded,
      },
      {
        'title': {'ar': 'صحيح البخاري', 'en': 'Bukhari', 'am': 'ሶሂህ ቡኻሪ', 'om': 'Bukhaarii'}[locale] ?? 'صحيح البخاري',
        'icon': Icons.menu_book_rounded,
      },
      {
        'title': {'ar': 'المكتبة', 'en': 'Library', 'am': 'ቤተ-መጽሐፍት', 'om': 'Mana Kitaabaa'}[locale] ?? 'المكتبة',
        'icon': Icons.local_library_rounded,
      },
      {
        'title': {'ar': 'فقه وفتاوى', 'en': 'Fatawa', 'am': 'ፈትዋ', 'om': 'Fatwaa'}[locale] ?? 'فقه وفتاوى',
        'icon': Icons.balance_rounded,
      },
      {
        'title': {'ar': 'كتبي الخاصة', 'en': 'My Shelf', 'am': 'የእኔ መጽሐፍት', 'om': 'Kitaabota Koo'}[locale] ?? 'كتبي الخاصة',
        'icon': Icons.picture_as_pdf_rounded,
      },
    ];

    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (context, idx) {
          final isSelected = _selectedFilterIndex == idx;
          final item = filters[idx];
          return LiquidPressable(
            onTap: () {
              setState(() {
                _selectedFilterIndex = idx;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF0F5A47), Color(0xFF1B8A6B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : cardBg,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(
                  color: isSelected ? Colors.transparent : borderColor,
                  width: 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF1B8A6B).withValues(alpha: 0.28),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 14,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? const Color(0xFF8A9995) : const Color(0xFF5A726A)),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    item['title'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : textColor,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontFamily: locale == 'ar' ? 'Amiri' : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 4. Unified Bookshelf & Reading Hub (Resume Item + User PDF Books)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildBookshelfSection(
    bool isDark,
    bool isCream,
    Color textColor,
    Color cardBg,
    Color borderColor,
    String locale,
  ) {
    final bool hasResume = _latestResumeItem != null;
    final bool hasPdfs = _userPdfBooks.isNotEmpty;
    final bool hasContent = hasResume || hasPdfs;

    final String shelfTitle = {
      'ar': 'رف القراءة وكتبي',
      'en': 'Reading Shelf & Books',
      'am': 'የንባብ መደርደሪያ እና መጽሐፍት',
      'om': 'Kutaa Dubbisaa fi Kitaabota',
    }[locale] ?? 'رف القراءة وكتبي';

    final String addBtnText = {
      'ar': '+ كتاب PDF',
      'en': '+ Add PDF',
      'am': '+ PDF ጨምር',
      'om': '+ PDF Dabali',
    }[locale] ?? '+ كتاب PDF';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Shelf Header Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    shelfTitle,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: locale == 'ar' ? 'Amiri' : null,
                    ),
                  ),
                  if (hasPdfs) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B8A6B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_userPdfBooks.length}',
                        style: const TextStyle(
                          color: Color(0xFF1B8A6B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              LiquidPressable(
                onTap: _isImportingPdf ? () {} : _importPdf,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B8A6B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFF1B8A6B).withValues(alpha: 0.25),
                      width: 0.8,
                    ),
                  ),
                  child: _isImportingPdf
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.8, color: Color(0xFF1B8A6B)),
                        )
                      : Text(
                          addBtnText,
                          style: const TextStyle(
                            color: Color(0xFF1B8A6B),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),

        // Shelf Content (Horizontal Shelf vs Slim Empty State)
        if (_isLoadingPdfBooks)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B8A6B)),
            ),
          )
        else if (!hasContent)
          // Slim, elegant empty state banner (~62px height, no wasted vertical space)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            child: LiquidPressable(
              onTap: _importPdf,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.16 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_outlined,
                        color: Color(0xFFD32F2F),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locale == 'ar' ? 'استيراد كتب PDF شخصية' : 'Import Personal PDF Books',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              fontFamily: locale == 'ar' ? 'Amiri' : null,
                            ),
                          ),
                          Text(
                            locale == 'ar'
                                ? 'اقرأ كتبك مع حفظ الصفحة تلقائياً'
                                : 'Read with automatic page bookmarking',
                            style: TextStyle(
                              color: isDark ? const Color(0xFF8A9995) : const Color(0xFF657B74),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B8A6B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        locale == 'ar' ? 'استيراد' : 'Import',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          // Rich horizontal bookshelf containing Active Reading Card + User PDF Books + Add Slot
          SizedBox(
            height: 148,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: (hasResume ? 1 : 0) + _userPdfBooks.length + 1,
              itemBuilder: (context, idx) {
                // Slot 0: If there is a resume item, render the Active Reading Hero Card
                if (hasResume && idx == 0) {
                  return _ActiveResumeBookCard(
                    resumeItem: _latestResumeItem!,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    locale: locale,
                    onOpenPdf: _openPdfReader,
                    onOpenStory: _openStory,
                  );
                }

                final int bookIdx = hasResume ? idx - 1 : idx;

                // Last Slot: Sleek "+ Add PDF" Import Card
                if (bookIdx == _userPdfBooks.length) {
                  return LiquidPressable(
                    onTap: _isImportingPdf ? () {} : _importPdf,
                    child: Container(
                      width: 96,
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF1B8A6B).withValues(alpha: 0.3),
                          width: 1.1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B8A6B).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.note_add_rounded, color: Color(0xFF1B8A6B), size: 18),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            locale == 'ar' ? 'إضافة PDF' : 'Add PDF',
                            style: const TextStyle(
                              color: Color(0xFF1B8A6B),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Middle Slots: User's imported PDF Book Cards
                final book = _userPdfBooks[bookIdx];
                return _UserPdfBookCard(
                  book: book,
                  isDark: isDark,
                  cardBg: cardBg,
                  borderColor: borderColor,
                  locale: locale,
                  onTap: () => _openPdfReader(book),
                  onDelete: () => _confirmDeletePdfBook(book),
                );
              },
            ),
          ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // 5. Master Domain Categories Header & Grid
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCategoriesHeader(Color textColor, String locale) {
    final String secTitleMain = {
      'ar': 'أقسام العلوم والمكتبة',
      'en': 'Main Library Categories',
      'am': 'ዋና ዋና የቤተ-መጽሐፍት ክፍሎች',
      'om': 'Kutaa Mana Kitaabaa Ijoo',
    }[locale] ?? 'أقسام العلوم والمكتبة';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 16,
            decoration: BoxDecoration(
              color: const Color(0xFF1B8A6B),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            secTitleMain,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              fontFamily: locale == 'ar' ? 'Amiri' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterDomainGrid(
    bool isDark,
    bool isCream,
    Color textColor,
    Color cardBg,
    Color borderColor,
    String locale,
  ) {
    final bool showAll = _selectedFilterIndex == 0;
    final bool showBukhariOnly = _selectedFilterIndex == 1;
    final bool showLibOnly = _selectedFilterIndex == 2;
    final bool showFiqhOnly = _selectedFilterIndex == 3;

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildListDelegate(
          [
            // Pillar 1: Sahih Al-Bukhari (Luxury Gold Card - Calibrated spacing to prevent any bottom overflow)
            if (showAll || showBukhariOnly) ...[
              _buildBukhariCard(isDark, cardBg, borderColor, locale),
              const SizedBox(height: 10),
            ],

            // Pillar 2: Islamic Library (Luxury Emerald Card - Calibrated spacing)
            if (showAll || showLibOnly) ...[
              _buildIslamicLibraryCard(isDark, cardBg, borderColor, locale),
              const SizedBox(height: 10),
            ],

            // Secondary 2x2 Grid (Fiqh, Ruqyah, Dreams, Quizzes)
            if (showAll || showFiqhOnly)
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.22,
                ),
                itemCount: showFiqhOnly ? 1 : _kSecondaryDomains.length,
                itemBuilder: (context, idx) {
                  final domain = showFiqhOnly ? _kSecondaryDomains[0] : _kSecondaryDomains[idx];
                  return _CompactDomainCard(
                    domain: domain,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    locale: locale,
                    onTap: () => _navigateToDomain(domain),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // Pillar 1: Sahih Al-Bukhari (Overflow-free & Responsive)
  Widget _buildBukhariCard(
    bool isDark,
    Color cardBg,
    Color borderColor,
    String locale,
  ) {
    final title = _kBukhariDomain.title(locale);
    final subtitle = _kBukhariDomain.subtitle(locale);

    return LiquidPressable(
      onTap: () => _navigateToDomain(_kBukhariDomain),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFC68A2E).withValues(alpha: isDark ? 0.35 : 0.25),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC68A2E).withValues(alpha: isDark ? 0.12 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE5A93C).withValues(alpha: isDark ? 0.18 : 0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8D5B18), Color(0xFFC68A2E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC68A2E).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF152A24),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    fontFamily: locale == 'ar' ? 'Amiri' : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFC68A2E).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  locale == 'ar' ? 'أصح كتب الحديث' : 'Authentic',
                                  style: const TextStyle(
                                    color: Color(0xFFC68A2E),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: isDark ? const Color(0xFF8A9995) : const Color(0xFF657B74),
                              fontSize: 11,
                              fontFamily: locale == 'ar' ? 'Amiri' : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  locale == 'ar' ? '97 كتاباً • 7563 حديثاً' : '97 Books • 7563 Hadiths',
                                  style: const TextStyle(
                                    color: Color(0xFFC68A2E),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                locale == 'ar' ? 'تصفح الأبواب ←' : 'Browse Chapters →',
                                style: const TextStyle(
                                  color: Color(0xFFC68A2E),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  // Pillar 2: Islamic Library (Overflow-free & Responsive)
  Widget _buildIslamicLibraryCard(
    bool isDark,
    Color cardBg,
    Color borderColor,
    String locale,
  ) {
    final title = _kLibraryDomain.title(locale);
    final subtitle = _kLibraryDomain.subtitle(locale);

    return LiquidPressable(
      onTap: () => _navigateToDomain(_kLibraryDomain),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1B8A6B).withValues(alpha: isDark ? 0.35 : 0.25),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B8A6B).withValues(alpha: isDark ? 0.12 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF2ECC9A).withValues(alpha: isDark ? 0.18 : 0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F5A47), Color(0xFF1B8A6B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1B8A6B).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.local_library_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    color: isDark ? Colors.white : const Color(0xFF152A24),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    fontFamily: locale == 'ar' ? 'Amiri' : null,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1B8A6B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  locale == 'ar' ? 'تراث وعلوم' : 'Heritage',
                                  style: const TextStyle(
                                    color: Color(0xFF1B8A6B),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: isDark ? const Color(0xFF8A9995) : const Color(0xFF657B74),
                              fontSize: 11,
                              fontFamily: locale == 'ar' ? 'Amiri' : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  locale == 'ar' ? 'كتب ومطويات منوعة' : 'Classified Treatises',
                                  style: const TextStyle(
                                    color: Color(0xFF1B8A6B),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                locale == 'ar' ? 'تصفح الأقسام ←' : 'Browse Library →',
                                style: const TextStyle(
                                  color: Color(0xFF1B8A6B),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  // ───────────────────────────────────────────────────────────────────────────
  // 6. Inspiring Quick Reads ("قبسات وقراءات ملهمة")
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFeaturedPamphletsSection(
    bool isDark,
    bool isCream,
    Color textColor,
    Color cardBg,
    Color borderColor,
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
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    secTitleInspire,
                    style: TextStyle(
                      color: isDark ? const Color(0xFFF0F4F0) : textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: locale == 'ar' ? 'Amiri' : null,
                    ),
                  ),
                ],
              ),
              Text(
                secSubtitleInspire,
                style: TextStyle(
                  color: isDark ? const Color(0xFF8A9995) : const Color(0xFF6B8079),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 118,
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
                  width: 210,
                  margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(
                            isBukhariItem ? Icons.menu_book_rounded : Icons.auto_stories_rounded,
                            size: 14,
                            color: badgeColor,
                          ),
                        ],
                      ),
                      Text(
                        cleanTitle,
                        style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          fontFamily: locale == 'ar' ? 'Amiri' : null,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          const Icon(Icons.remove_red_eye_rounded, size: 11, color: Color(0xFFD4AF37)),
                          const SizedBox(width: 3),
                          Text(
                            item.numReadings > 0
                                ? '${item.numReadings} ${locale == 'ar' ? 'قراءة' : 'reads'}'
                                : (locale == 'ar' ? 'مستحسن' : 'Featured'),
                            style: TextStyle(
                              color: isDark ? const Color(0xFF8A9995) : const Color(0xFF6B8079),
                              fontSize: 9.5,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            readNowText,
                            style: TextStyle(
                              color: badgeColor,
                              fontSize: 10.5,
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

  // ───────────────────────────────────────────────────────────────────────────
  // 7. Search Results View
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSearchResults(
    bool isDark,
    bool isCream,
    Color textColor,
    Color cardBg,
    Color borderColor,
    double bottomClearance,
  ) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 50,
              color: isDark ? Colors.white24 : Colors.black26,
            ),
            const SizedBox(height: 10),
            Text(
              'لا توجد نتائج بحث مطابقة',
              style: TextStyle(
                color: isDark ? const Color(0xFF8A9995) : const Color(0xFF6B8079),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16, 6, 16, bottomClearance),
      itemCount: _searchResults.length,
      itemBuilder: (context, idx) {
        final item = _searchResults[idx];
        final cleanTitle = item.title
            .replaceAll('{', '')
            .replaceAll('}', '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

        final bool isBukhari = item.part == 'صحيح البخارى' || item.part == 'البخارى';
        final Color badgeColor = isBukhari ? const Color(0xFFC68A2E) : const Color(0xFF1B8A6B);

        return LiquidPressable(
          onTap: () => _openStory(item),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 3.5),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.025),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isBukhari ? Icons.menu_book_rounded : Icons.auto_stories_rounded,
                    color: badgeColor,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleanTitle,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFamily: 'Amiri',
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.part.isNotEmpty ? item.part : 'المكتبة الإسلامية',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF8A9995) : const Color(0xFF6B8079),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
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

// ─────────────────────────────────────────────────────────────────────────────
// Compact Active Reading Book Card (Horizontal Shelf Slot 0)
// ─────────────────────────────────────────────────────────────────────────────
class _ActiveResumeBookCard extends StatelessWidget {
  final Map<String, dynamic> resumeItem;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final String locale;
  final Function(UserPdfBook) onOpenPdf;
  final Function(LibraryItem) onOpenStory;

  const _ActiveResumeBookCard({
    required this.resumeItem,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.locale,
    required this.onOpenPdf,
    required this.onOpenStory,
  });

  @override
  Widget build(BuildContext context) {
    final type = resumeItem['type'] as String;
    final bool isPdf = type == 'pdf';

    String title = '';
    String subtitle = '';
    double progress = 0.5;
    VoidCallback onTapAction;
    IconData icon;
    Color accentColor;

    if (isPdf) {
      final book = resumeItem['pdfBook'] as UserPdfBook;
      title = book.title;
      subtitle = book.totalPages > 0
          ? '${locale == 'ar' ? 'صفحة' : 'Page'} ${book.lastPageRead} / ${book.totalPages}'
          : '${locale == 'ar' ? 'صفحة' : 'Page'} ${book.lastPageRead}';
      progress = book.progressPercent;
      icon = Icons.picture_as_pdf_rounded;
      accentColor = const Color(0xFFD32F2F);
      onTapAction = () => onOpenPdf(book);
    } else {
      final item = resumeItem['libraryItem'] as LibraryItem;
      title = item.title
          .replaceAll('{', '')
          .replaceAll('}', '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final bool isBukhari = item.part == 'صحيح البخارى' || item.part == 'البخارى';
      subtitle = isBukhari
          ? (locale == 'ar' ? 'صحيح البخاري' : 'Sahih Al-Bukhari')
          : (locale == 'ar' ? 'المكتبة الإسلامية' : 'Islamic Library');
      progress = 0.65;
      icon = isBukhari ? Icons.menu_book_rounded : Icons.auto_stories_rounded;
      accentColor = isBukhari ? const Color(0xFFC68A2E) : const Color(0xFF1B8A6B);
      onTapAction = () => onOpenStory(item);
    }

    final titleColor = isDark ? Colors.white : const Color(0xFF152A24);

    return LiquidPressable(
      onTap: onTapAction,
      child: Container(
        width: 170,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.4 : 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.14 : 0.06),
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        locale == 'ar' ? 'واصل القراءة' : 'Continue',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(icon, color: accentColor, size: 15),
              ],
            ),
            Text(
              title,
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                fontFamily: locale == 'ar' ? 'Amiri' : null,
                height: 1.18,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          color: isDark ? const Color(0xFF8A9995) : const Color(0xFF657B74),
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      locale == 'ar' ? 'تابع ←' : 'Read →',
                      style: TextStyle(
                        color: accentColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress > 0 ? progress : 0.1,
                    backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// User PDF Book Card Component (Horizontal Shelf)
// ─────────────────────────────────────────────────────────────────────────────
class _UserPdfBookCard extends StatelessWidget {
  final UserPdfBook book;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _UserPdfBookCard({
    required this.book,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.locale,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF152A24);

    return LiquidPressable(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
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
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFD32F2F), size: 11),
                      SizedBox(width: 2.5),
                      Text(
                        'PDF',
                        style: TextStyle(
                          color: Color(0xFFD32F2F),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 13,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              book.title,
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                fontFamily: locale == 'ar' ? 'Amiri' : null,
                height: 1.18,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      book.totalPages > 0
                          ? '${locale == 'ar' ? 'ص' : 'p.'} ${book.lastPageRead}/${book.totalPages}'
                          : '${locale == 'ar' ? 'ص' : 'p.'} ${book.lastPageRead}',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF8A9995) : const Color(0xFF657B74),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      book.formattedSize,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF6C7C78) : const Color(0xFF9AA8A4),
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: book.progressPercent,
                    backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B8A6B)),
                    minHeight: 3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Compact Secondary Domain Card (for 2x2 Grid)
// ─────────────────────────────────────────────────────────────────────────────
class _CompactDomainCard extends StatelessWidget {
  final _DomainInfo domain;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final String locale;
  final VoidCallback onTap;

  const _CompactDomainCard({
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
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: domain.accentColor.withValues(alpha: isDark ? 0.10 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            children: [
              Positioned(
                top: -14,
                right: -14,
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        domain.accentColor.withValues(alpha: isDark ? 0.16 : 0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(11.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: domain.gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: domain.accentColor.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(domain.icon, color: Colors.white, size: 18),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: titleColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
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
                            fontSize: 9.5,
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
