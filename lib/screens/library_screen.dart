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
// Core Islamic Pillar Definition (Zen Bento Grid)
// ─────────────────────────────────────────────────────────────────────────────
class _IslamicPillar {
  final String id;
  final Map<String, String> titles;
  final Map<String, String> subtitles;
  final IconData icon;
  final List<Color> gradient;
  final Color accentColor;
  final VoidCallback Function(BuildContext context) onSelect;

  const _IslamicPillar({
    required this.id,
    required this.titles,
    required this.subtitles,
    required this.icon,
    required this.gradient,
    required this.accentColor,
    required this.onSelect,
  });

  String title(String locale) => titles[locale] ?? titles['ar'] ?? titles['en']!;
  String subtitle(String locale) => subtitles[locale] ?? subtitles['ar'] ?? subtitles['en']!;
}

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

  // Local PDF Books & Resume Reading States
  List<UserPdfBook> _userPdfBooks = [];
  bool _isLoadingPdfBooks = true;
  bool _isImportingPdf = false;
  Map<String, dynamic>? _latestResumeItem;

  // Zen 2-Tab Navigation:
  // 0: المكتبة الإسلامية (Islamic Heritage & 6 Reference Pillars)
  // 1: كتبي الخاصة (My Personal Bookshelf & PDF Reader)
  int _activeTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadFavCount();
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
        final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    locale == 'ar'
                        ? 'تمت إضافة "${imported.title}" إلى كتبي'
                        : 'Added "${imported.title}" to bookshelf',
                    style: const TextStyle(fontFamily: 'Amiri', fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1B8A6B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(milliseconds: 1800),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              locale == 'ar' ? 'تعذر استيراد ملف PDF' : 'Failed to import PDF file',
              style: const TextStyle(fontFamily: 'Amiri'),
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
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
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
            const SizedBox(width: 8),
            Text(
              locale == 'ar' ? 'حذف الكتاب' : 'Delete Book',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                fontFamily: locale == 'ar' ? 'Amiri' : null,
              ),
            ),
          ],
        ),
        content: Text(
          locale == 'ar'
              ? 'هل أنت متأكد من حذف "${book.title}" من رف كتبك؟\nسيتم حذف الملف والتقدم المحفوظ نهائياً.'
              : 'Are you sure you want to delete "${book.title}" from your bookshelf?\nThe file and reading progress will be permanently removed.',
          style: TextStyle(
            fontSize: 13.5,
            height: 1.45,
            fontFamily: locale == 'ar' ? 'Amiri' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(locale == 'ar' ? 'إلغاء' : 'Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              if (book.id != null) {
                await _libraryService.deleteUserPdfBook(book.id!);
                await _loadUserPdfBooks();
                await _loadResumeItem();
                if (mounted) {
                  final messenger = ScaffoldMessenger.of(context);
                  messenger.hideCurrentSnackBar();
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        locale == 'ar' ? 'تم حذف الكتاب بنجاح' : 'Book deleted successfully',
                        style: const TextStyle(fontFamily: 'Amiri'),
                      ),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      duration: const Duration(milliseconds: 1800),
                    ),
                  );
                }
              }
            },
            child: Text(locale == 'ar' ? 'حذف' : 'Delete'),
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

  void _openStory(LibraryItem item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoryReadingScreen(item: item)),
    );
    _loadFavCount();
    _loadResumeItem();
  }

  // 6 Core Islamic Reference Pillars
  List<_IslamicPillar> _getPillars(String locale) => [
        _IslamicPillar(
          id: 'bukhari',
          titles: {
            'ar': 'صحيح البخاري',
            'en': 'Sahih Al-Bukhari',
            'am': 'ሶሂህ አል-ቡኻሪ',
            'om': 'Sahiih Al-Bukhaarii',
          },
          subtitles: {
            'ar': 'الجامع المسند الصحيح',
            'en': 'Authentic Hadith collection',
            'am': 'ትክክለኛ የሐዲስ ስብስብ',
            'om': 'Kilaasika hadiisota sahiiha',
          },
          icon: Icons.menu_book_rounded,
          gradient: const [Color(0xFF8D5B18), Color(0xFFC68A2E)],
          accentColor: const Color(0xFFE5A93C),
          onSelect: (ctx) => () {
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => LibraryCategoryScreen(
                  domainPart: 'صحيح البخارى',
                  domainTitle: locale == 'ar' ? 'صحيح البخاري' : 'Sahih Al-Bukhari',
                ),
              ),
            ).then((_) => _loadResumeItem());
          },
        ),
        _IslamicPillar(
          id: 'library',
          titles: {
            'ar': 'المكتبة الإسلامية',
            'en': 'Islamic Library',
            'am': 'ኢስላማዊ ቤተ-መጽሐፍት',
            'om': 'Mana Kitaaba Islaamaa',
          },
          subtitles: {
            'ar': 'موسوعة الكتب والرسائل',
            'en': 'Books & Islamic treatises',
            'am': 'መጽሐፍት እና የዳዕዋ ጽሑፎች',
            'om': 'Kitaabota fi barruulee',
          },
          icon: Icons.local_library_rounded,
          gradient: const [Color(0xFF0F5A47), Color(0xFF1B8A6B)],
          accentColor: const Color(0xFF2ECC9A),
          onSelect: (ctx) => () {
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => LibraryCategoryScreen(
                  domainPart: 'المكتبة',
                  domainTitle: locale == 'ar' ? 'المكتبة الإسلامية' : 'Islamic Library',
                ),
              ),
            ).then((_) => _loadResumeItem());
          },
        ),
        _IslamicPillar(
          id: 'fiqh',
          titles: {
            'ar': 'فقه وفتاوى',
            'en': 'Fiqh & Fatawa',
            'am': 'ፊቅህ እና ፈትዋ',
            'om': 'Fiqhii fi Fatwaa',
          },
          subtitles: {
            'ar': 'أحكام العبادات والمعاملات',
            'en': 'Rulings & Islamic guidance',
            'am': 'የኢባዳ እና የሙዓመላት ህጎች',
            'om': 'Murteewwan amantii',
          },
          icon: Icons.balance_rounded,
          gradient: const [Color(0xFF4A154B), Color(0xFF7A257C)],
          accentColor: const Color(0xFFAB47BC),
          onSelect: (ctx) => () {
            Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const FiqhAndFatawaScreen()),
            );
          },
        ),
        _IslamicPillar(
          id: 'ruqyah',
          titles: {
            'ar': 'الرقية الشرعية',
            'en': 'Ruqyah Shariyyah',
            'am': 'ሩቅያህ ሸርዒያህ',
            'om': 'Ruqiyaa Shar\'iyyaa',
          },
          subtitles: {
            'ar': 'تحصينات وأدعية الشفاء',
            'en': 'Healing & protection prayers',
            'am': 'የፈውስ እና የጥበቃ ዱዓዎች',
            'om': 'Dawaa fi du\'aa\'ii eegumsaa',
          },
          icon: Icons.healing_rounded,
          gradient: const [Color(0xFF702459), Color(0xFF97266D)],
          accentColor: const Color(0xFFED64A6),
          onSelect: (ctx) => () {
            Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const RuqyahScreen()),
            );
          },
        ),
        _IslamicPillar(
          id: 'dreams',
          titles: {
            'ar': 'تفسير الأحلام',
            'en': 'Dream Interpretation',
            'am': 'የሕልም ፍቺ',
            'om': 'Hiika Abjuu',
          },
          subtitles: {
            'ar': 'جامع تفاسير الرؤى والأحلام',
            'en': 'Visions & dream meanings',
            'am': 'የሕልሞች እና ራእዮች ማብራሪያ',
            'om': 'Hiikkaa abjuu fi mul\'ataa',
          },
          icon: Icons.nightlight_round,
          gradient: const [Color(0xFF1A365D), Color(0xFF2B6CB0)],
          accentColor: const Color(0xFF4299E1),
          onSelect: (ctx) => () {
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => LibraryCategoryScreen(
                  domainPart: 'تفسير أحلام',
                  domainTitle: locale == 'ar' ? 'تفسير الأحلام' : 'Dream Interpretation',
                ),
              ),
            );
          },
        ),
        _IslamicPillar(
          id: 'quizzes',
          titles: {
            'ar': 'المسابقات الإسلامية',
            'en': 'Islamic Quizzes',
            'am': 'ኢስላማዊ ውድድሮች',
            'om': 'Dorgommii Islaamaa',
          },
          subtitles: {
            'ar': 'اختبر معلوماتك وثقافتك الدينية',
            'en': 'Test knowledge & Islamic facts',
            'am': 'እውቀትዎን ይፈትሹ',
            'om': 'Beekumsa kee qori',
          },
          icon: Icons.emoji_events_rounded,
          gradient: const [Color(0xFF744210), Color(0xFFB7791F)],
          accentColor: const Color(0xFFECC94B),
          onSelect: (ctx) => () {
            Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const QuizIntroScreen()),
            );
          },
        ),
      ];

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
                // Generous bottom clearance ensuring Samsung One UI dock & ad never obscure content
                final double bottomClearance =
                    MediaQuery.paddingOf(context).bottom + (isAdVisible ? 165 : 125);

                return Column(
                  children: [
                    // 1. Serene Header Bar
                    _buildHeader(isDark, isCream, textColor, cardBg, borderColor, l10n, locale),

                    // 2. Focused Search Bar
                    _buildSearchBar(isDark, isCream, textColor, cardBg, borderColor, locale),

                    // 3. Calm 2-Segment Zen Navigation (Islamic Library vs My Shelf)
                    _buildZenSegmentedNav(isDark, isCream, textColor, cardBg, borderColor, locale),

                    // 4. Content Area
                    Expanded(
                      child: _isSearching
                          ? _buildSearchResults(isDark, isCream, textColor, cardBg, borderColor, bottomClearance)
                          : AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: _activeTabIndex == 0
                                  ? _buildIslamicLibraryTab(
                                      isDark,
                                      isCream,
                                      textColor,
                                      cardBg,
                                      borderColor,
                                      locale,
                                      bottomClearance,
                                    )
                                  : _buildMyShelfTab(
                                      isDark,
                                      isCream,
                                      textColor,
                                      cardBg,
                                      borderColor,
                                      locale,
                                      bottomClearance,
                                    ),
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
  // 1. Serene Header Bar
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
      'ar': 'الموسوعة الإسلامية والمراجع العلمية',
      'en': 'Islamic Encyclopedia & Reference Works',
      'am': 'ኢስላማዊ ኢንሳይክሎፔዲያ እና ማጣቀሻዎች',
      'om': 'Insaayikilooppeediyaa fi Qorannoo',
    }[locale] ?? 'الموسوعة الإسلامية والمراجع العلمية';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
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
                  color: const Color(0xFF1B8A6B).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 12),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n?.navLibrary ?? (locale == 'ar' ? 'المكتبة' : 'Library'),
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: locale == 'ar' ? 'Amiri' : null,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  subtitleText,
                  style: TextStyle(
                    color: isDark ? const Color(0xFF8A9995) : const Color(0xFF6B8079),
                    fontSize: 11,
                    fontFamily: locale == 'ar' ? 'Amiri' : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Favorites Action Pill
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
                  child: const Icon(
                    Icons.bookmark_outline_rounded,
                    color: Color(0xFF1B8A6B),
                    size: 20,
                  ),
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

  // ───────────────────────────────────────────────────────────────────────────
  // 2. Focused Search Bar
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
      'ar': 'ابحث في المراجع، الأحاديث، والكتب...',
      'en': 'Search in references, hadiths & books...',
      'am': 'በማጣቀሻዎች፣ ሐዲሶች እና መጽሐፍት ውስጥ ይፈልጉ...',
      'om': 'Kitaabota fi hadiisota keessatti barbaadi...',
    }[locale] ?? 'ابحث في المراجع، الأحاديث، والكتب...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Container(
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
                    icon: const Icon(Icons.clear_rounded, size: 18),
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
  // 3. Calm 2-Segment Zen Navigation Capsule
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildZenSegmentedNav(
    bool isDark,
    bool isCream,
    Color textColor,
    Color cardBg,
    Color borderColor,
    String locale,
  ) {
    final List<Map<String, dynamic>> tabs = [
      {
        'title': {'ar': 'المكتبة الإسلامية', 'en': 'Islamic Heritage', 'am': 'ዋና ቤተ-መጽሐፍት', 'om': 'Mana Kitaabaa'}[locale] ?? 'المكتبة الإسلامية',
        'icon': Icons.menu_book_rounded,
        'badge': null,
      },
      {
        'title': {'ar': 'كتبي الخاصة', 'en': 'My Bookshelf', 'am': 'የእኔ መጽሐፍት', 'om': 'Kitaabota Koo'}[locale] ?? 'كتبي الخاصة',
        'icon': Icons.picture_as_pdf_rounded,
        'badge': _userPdfBooks.isNotEmpty ? '${_userPdfBooks.length}' : null,
      },
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Container(
        padding: const EdgeInsets.all(3.5),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0C1412) : const Color(0xFFF1F5F3),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Row(
          children: List.generate(tabs.length, (idx) {
            final isSelected = _activeTabIndex == idx;
            final tab = tabs[idx];
            final String? badgeText = tab['badge'] as String?;

            return Expanded(
              child: LiquidPressable(
                onTap: () {
                  if (_activeTabIndex != idx) {
                    setState(() {
                      _activeTabIndex = idx;
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.symmetric(vertical: 8.5),
                  decoration: BoxDecoration(
                    color: isSelected ? cardBg : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        tab['icon'] as IconData,
                        size: 16,
                        color: isSelected
                            ? const Color(0xFF1B8A6B)
                            : (isDark ? const Color(0xFF7A8B87) : const Color(0xFF6B8079)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tab['title'] as String,
                        style: TextStyle(
                          color: isSelected
                              ? textColor
                              : (isDark ? const Color(0xFF7A8B87) : const Color(0xFF6B8079)),
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          fontFamily: locale == 'ar' ? 'Amiri' : null,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1B8A6B).withValues(alpha: isSelected ? 0.15 : 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeText,
                            style: const TextStyle(
                              color: Color(0xFF1B8A6B),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Tab 0: Zen Islamic Heritage & 6 Reference Pillars (المكتبة الإسلامية)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildIslamicLibraryTab(
    bool isDark,
    bool isCream,
    Color textColor,
    Color cardBg,
    Color borderColor,
    String locale,
    double bottomClearance,
  ) {
    final pillars = _getPillars(locale);

    return CustomScrollView(
      key: const PageStorageKey<String>('zen_islamic_heritage_scroll'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        // A. Continue Reading Banner (Clean & Discrete)
        if (_latestResumeItem != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: _HeroResumeCard(
                resumeItem: _latestResumeItem!,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                locale: locale,
                onOpenPdf: _openPdfReader,
                onOpenStory: _openStory,
              ),
            ),
          ),

        // B. Section Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Container(
                  width: 3.5,
                  height: 15,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B8A6B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  locale == 'ar' ? 'أركان المعرفة الإسلامية' : 'Core Islamic References',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    fontFamily: locale == 'ar' ? 'Amiri' : null,
                  ),
                ),
              ],
            ),
          ),
        ),

        // C. Balanced 2x3 Bento Grid of Core Pillars
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.18,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, idx) {
                final pillar = pillars[idx];
                return _ZenPillarCard(
                  pillar: pillar,
                  isDark: isDark,
                  cardBg: cardBg,
                  borderColor: borderColor,
                  locale: locale,
                  onTap: pillar.onSelect(context),
                );
              },
              childCount: pillars.length,
            ),
          ),
        ),

        // Bottom clearance
        SliverToBoxAdapter(
          child: SizedBox(height: bottomClearance),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Tab 1: My Bookshelf & Personal PDFs (كتبي الخاصة)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildMyShelfTab(
    bool isDark,
    bool isCream,
    Color textColor,
    Color cardBg,
    Color borderColor,
    String locale,
    double bottomClearance,
  ) {
    final bool hasPdfs = _userPdfBooks.isNotEmpty;
    final bool isLastReadPdf = _latestResumeItem != null && _latestResumeItem!['type'] == 'pdf';

    return CustomScrollView(
      key: const PageStorageKey<String>('zen_myshelf_scroll'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        // A. Clean Header with Single "+ Add PDF" Action
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3.5,
                      height: 15,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      locale == 'ar' ? 'رف كتبي الشخصية' : 'Personal Bookshelf',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        fontFamily: locale == 'ar' ? 'Amiri' : null,
                      ),
                    ),
                    if (hasPdfs) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
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

                // Single Unified "+ Add PDF" Action Button
                LiquidPressable(
                  onTap: _isImportingPdf ? () {} : _importPdf,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F5A47), Color(0xFF1B8A6B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1B8A6B).withValues(alpha: 0.25),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _isImportingPdf
                        ? const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.note_add_rounded, color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                locale == 'ar' ? '+ استيراد PDF' : '+ Add PDF',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // B. Active Reading Hero Card (if currently reading a PDF)
        if (isLastReadPdf)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 8),
              child: _HeroResumeCard(
                resumeItem: _latestResumeItem!,
                isDark: isDark,
                cardBg: cardBg,
                borderColor: borderColor,
                locale: locale,
                onOpenPdf: _openPdfReader,
                onOpenStory: _openStory,
              ),
            ),
          ),

        // C. Content: Loading / Empty State / Grid of PDF Books
        if (_isLoadingPdfBooks)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1B8A6B)),
              ),
            ),
          )
        else if (!hasPdfs)
          // Zen Empty State
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_outlined,
                        color: Color(0xFFD32F2F),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      locale == 'ar' ? 'رف كتبك فارغ حالياً' : 'Your Bookshelf is Empty',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: locale == 'ar' ? 'Amiri' : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      locale == 'ar'
                          ? 'استورد كتبك ومذكراتك بصيغة PDF للقراءة وتحديد النصوص والبحث وحفظ التقدم تلقائياً'
                          : 'Import PDF books to read, highlight, search, and track reading progress.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF8A9995) : const Color(0xFF6B8079),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    LiquidPressable(
                      onTap: _importPdf,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B8A6B),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1B8A6B).withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          locale == 'ar' ? 'استيراد أول كتاب PDF الآن' : 'Import First PDF Book',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          // 2-Column Grid of User PDF Books
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, idx) {
                  final book = _userPdfBooks[idx];
                  return _GridPdfBookCard(
                    book: book,
                    isDark: isDark,
                    cardBg: cardBg,
                    borderColor: borderColor,
                    locale: locale,
                    onTap: () => _openPdfReader(book),
                    onDelete: () => _confirmDeletePdfBook(book),
                  );
                },
                childCount: _userPdfBooks.length,
              ),
            ),
          ),

        // Bottom clearance
        SliverToBoxAdapter(
          child: SizedBox(height: bottomClearance),
        ),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Search Results View
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
              size: 46,
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
              borderRadius: BorderRadius.circular(15),
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
// Zen Bento Pillar Card Component (Compact, Breathing, Elegant)
// ─────────────────────────────────────────────────────────────────────────────
class _ZenPillarCard extends StatelessWidget {
  final _IslamicPillar pillar;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final String locale;
  final VoidCallback onTap;

  const _ZenPillarCard({
    required this.pillar,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : const Color(0xFF152A24);

    return LiquidPressable(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: pillar.accentColor.withValues(alpha: isDark ? 0.3 : 0.18),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: pillar.accentColor.withValues(alpha: isDark ? 0.12 : 0.035),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Subtle background glow in corner
              Positioned(
                top: -16,
                right: -16,
                child: Container(
                  width: 65,
                  height: 65,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        pillar.accentColor.withValues(alpha: isDark ? 0.15 : 0.07),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Icon + Arrow Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: pillar.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: pillar.accentColor.withValues(alpha: 0.25),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(pillar.icon, color: Colors.white, size: 18),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: pillar.accentColor.withValues(alpha: 0.7),
                        ),
                      ],
                    ),

                    // Title & Subtitle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          pillar.title(locale),
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
                          pillar.subtitle(locale),
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8A9995) : const Color(0xFF6B8079),
                            fontSize: 9.5,
                            fontFamily: locale == 'ar' ? 'Amiri' : null,
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

// ─────────────────────────────────────────────────────────────────────────────
// Hero Continue Reading Card (Prominent & Eye-Catching)
// ─────────────────────────────────────────────────────────────────────────────
class _HeroResumeCard extends StatelessWidget {
  final Map<String, dynamic> resumeItem;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final String locale;
  final Function(UserPdfBook) onOpenPdf;
  final Function(LibraryItem) onOpenStory;

  const _HeroResumeCard({
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
          ? '${locale == 'ar' ? 'صفحة' : 'Page'} ${book.lastPageRead} / ${book.totalPages}  •  ${(book.progressPercent * 100).toInt()}%'
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
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withValues(alpha: isDark ? 0.45 : 0.3),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: isDark ? 0.16 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                        accentColor.withValues(alpha: isDark ? 0.18 : 0.10),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: accentColor, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    locale == 'ar' ? 'تابع القراءة' : 'Continue Reading',
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                locale == 'ar' ? 'اقرأ الآن ←' : 'Read now →',
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            title,
                            style: TextStyle(
                              color: titleColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              fontFamily: locale == 'ar' ? 'Amiri' : null,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
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

// ─────────────────────────────────────────────────────────────────────────────
// Grid PDF Book Card (for My Shelf 2-Column Grid)
// ─────────────────────────────────────────────────────────────────────────────
class _GridPdfBookCard extends StatelessWidget {
  final UserPdfBook book;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final String locale;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _GridPdfBookCard({
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 7,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: PDF Badge + Delete button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFD32F2F), size: 12),
                      SizedBox(width: 3),
                      Text(
                        'PDF',
                        style: TextStyle(
                          color: Color(0xFFD32F2F),
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
              ],
            ),

            // Book Title
            Text(
              book.title,
              style: TextStyle(
                color: titleColor,
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                fontFamily: locale == 'ar' ? 'Amiri' : null,
                height: 1.25,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Bottom Progress & Size
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
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      book.formattedSize,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF6C7C78) : const Color(0xFF9AA8A4),
                        fontSize: 9,
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
