import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme_notifier.dart';
import '../services/library_service.dart';
import '../services/pdf_thumbnail_service.dart';
import '../models/library_item.dart';
import '../models/user_pdf_book.dart';
import 'library_category_screen.dart';
import 'library_content_list_screen.dart';
import 'story_reading_screen.dart';
import 'fiqh_and_fatawa_screen.dart';
import 'ruqyah_screen.dart';
import 'pdf_reader_screen.dart';
import 'hadith_collections_screen.dart';
import 'hadith_books_screen.dart';
import 'hadith_search_screen.dart';
import 'hadith_reader_screen.dart';
import '../core/database/hadith_database_helper.dart';
import '../services/hadith_service.dart';
import '../models/hadith_models.dart';
import '../widgets/liquid_pressable.dart';
import '../widgets/custom_banner_ad.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Canonical Hadith Collection Presets (10 Collections • 41,313 Hadiths)
// ─────────────────────────────────────────────────────────────────────────────
class _HadithCollectionPreset {
  final int id;
  final String title;
  final String author;
  final String hadithsCount;
  final List<Color> spineGradient;
  final Color goldAccent;
  final String badgeText;

  const _HadithCollectionPreset({
    required this.id,
    required this.title,
    required this.author,
    required this.hadithsCount,
    required this.spineGradient,
    required this.goldAccent,
    required this.badgeText,
  });
}

const List<_HadithCollectionPreset> _kHadithPresets = [
  _HadithCollectionPreset(
    id: 1,
    title: 'صحيح البخاري',
    author: 'الإمام البخاري',
    hadithsCount: '7,277',
    spineGradient: [Color(0xFF07271D), Color(0xFF104E3B)],
    goldAccent: Color(0xFFF0C85E),
    badgeText: 'أصح الكتب',
  ),
  _HadithCollectionPreset(
    id: 2,
    title: 'صحيح مسلم',
    author: 'الإمام مسلم',
    hadithsCount: '7,368',
    spineGradient: [Color(0xFF0C243B), Color(0xFF18456E)],
    goldAccent: Color(0xFFE2BC6A),
    badgeText: 'صحيح',
  ),
  _HadithCollectionPreset(
    id: 3,
    title: 'سنن النسائي',
    author: 'الإمام النسائي',
    hadithsCount: '5,768',
    spineGradient: [Color(0xFF380915), Color(0xFF6B182E)],
    goldAccent: Color(0xFFECC272),
    badgeText: 'السنن الصغرى',
  ),
  _HadithCollectionPreset(
    id: 4,
    title: 'سنن أبي داود',
    author: 'الإمام أبو داود',
    hadithsCount: '5,276',
    spineGradient: [Color(0xFF3D1E08), Color(0xFF703816)],
    goldAccent: Color(0xFFF3C765),
    badgeText: 'أحاديث الأحكام',
  ),
  _HadithCollectionPreset(
    id: 5,
    title: 'جامع الترمذي',
    author: 'الإمام الترمذي',
    hadithsCount: '4,053',
    spineGradient: [Color(0xFF2B0E3B), Color(0xFF552074)],
    goldAccent: Color(0xFFE7BE73),
    badgeText: 'الجامع الكبير',
  ),
  _HadithCollectionPreset(
    id: 6,
    title: 'سنن ابن ماجه',
    author: 'الإمام ابن ماجه',
    hadithsCount: '4,345',
    spineGradient: [Color(0xFF0A2B2D), Color(0xFF155355)],
    goldAccent: Color(0xFFDFBA68),
    badgeText: 'الكتب الستة',
  ),
  _HadithCollectionPreset(
    id: 7,
    title: 'موطأ مالك',
    author: 'الإمام مالك بن أنس',
    hadithsCount: '1,861',
    spineGradient: [Color(0xFF351F14), Color(0xFF5D3926)],
    goldAccent: Color(0xFFE6C16D),
    badgeText: 'إمام دار الهجرة',
  ),
  _HadithCollectionPreset(
    id: 8,
    title: 'رياض الصالحين',
    author: 'الإمام النووي',
    hadithsCount: '1,896',
    spineGradient: [Color(0xFF0F321F), Color(0xFF1D5A38)],
    goldAccent: Color(0xFFF3CD67),
    badgeText: 'تهذيب النفس',
  ),
  _HadithCollectionPreset(
    id: 9,
    title: 'الأدب المفرد',
    author: 'الإمام البخاري',
    hadithsCount: '1,326',
    spineGradient: [Color(0xFF181C3D), Color(0xFF2C3672)],
    goldAccent: Color(0xFFDFBA6A),
    badgeText: 'مكارم الأخلاق',
  ),
  _HadithCollectionPreset(
    id: 10,
    title: 'بلوغ المرام',
    author: 'الحافظ ابن حجر',
    hadithsCount: '1,767',
    spineGradient: [Color(0xFF380C15), Color(0xFF621727)],
    goldAccent: Color(0xFFE9C371),
    badgeText: 'أدلة الأحكام',
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Core Islamic Pillar Definition (Zen Bento Grid)
// ─────────────────────────────────────────────────────────────────────────────
class _IslamicPillar {
  final String id;
  final Map<String, String> titles;
  final Map<String, String> subtitles;
  final String countBadge;
  final IconData icon;
  final List<Color> gradient;
  final Color accentColor;
  final VoidCallback Function(BuildContext context) onSelect;

  const _IslamicPillar({
    required this.id,
    required this.titles,
    required this.subtitles,
    required this.countBadge,
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
    int hadithFavCount = 0;
    try {
      final hadithFavs = await HadithDatabaseHelper.instance.getFavorites();
      final existingLegacyIds = favs.map((f) => f.id).toSet();
      hadithFavCount = hadithFavs
          .where((h) => h.legacyBukhariId == null || !existingLegacyIds.contains(h.legacyBukhariId))
          .length;
    } catch (_) {}
    if (mounted) {
      setState(() {
        _favCount = favs.length + hadithFavCount;
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
    try {
      final isExtracted = await HadithDatabaseHelper.instance.isDatabaseExtracted();
      if (isExtracted) {
        final lastHadith = await HadithService().getLatestReadHadith();
        if (lastHadith != null && lastHadith.lastReadTimestamp != null) {
          final int hadithTimestamp = lastHadith.lastReadTimestamp!;
          int otherTimestamp = 0;
          if (item != null && item['isDefault'] != true) {
            if (item['type'] == 'pdf') {
              otherTimestamp = (item['pdfBook'] as UserPdfBook).lastReadTimestamp;
            } else if (item['type'] == 'library') {
              otherTimestamp = (item['libraryItem'] as LibraryItem).lastRead;
            }
          }
          if (hadithTimestamp > otherTimestamp) {
            if (mounted) {
              setState(() {
                _latestResumeItem = {
                  'type': 'hadith',
                  'hadithItem': lastHadith,
                };
              });
              return;
            }
          }
        }
      }
    } catch (_) {}

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
                        : 'Added "${imported.title}" to PDF Reader',
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
              : 'Are you sure you want to delete "${book.title}" from your PDF Reader?\nThe file and reading progress will be permanently removed.',
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

  void _openHadith(HadithItem hadith) async {
    final col = await HadithService().getCollection(hadith.collectionId);
    final book = await HadithService().getBook(hadith.bookId);
    if (col != null && book != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HadithReaderScreen(
            collection: col,
            book: book,
            initialHadithIndex: int.tryParse(hadith.hadithNumber) != null
                ? int.parse(hadith.hadithNumber) - 1
                : null,
          ),
        ),
      );
      _loadFavCount();
      _loadResumeItem();
    }
  }

  void _openHadithCollection(_HadithCollectionPreset preset) async {
    final isExtracted = await HadithDatabaseHelper.instance.isDatabaseExtracted();
    if (!isExtracted && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HadithCollectionsScreen()),
      ).then((_) => _loadResumeItem());
      return;
    }
    final col = await HadithService().getCollection(preset.id);
    if (col != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HadithBooksScreen(collection: col)),
      ).then((_) => _loadResumeItem());
    } else if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HadithCollectionsScreen()),
      ).then((_) => _loadResumeItem());
    }
  }

  Widget _buildRuqyahHeaderCard(BuildContext context) {
    return LiquidPressable(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RuqyahScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6B183E), Color(0xFF9E275E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9E275E).withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.healing_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'الرقية الشرعية المعتمدة',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'تحصينات وأدعية الشفاء من الكتاب والسنة (3 مراحل)',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 11.5,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 14),
          ],
        ),
      ),
    );
  }

  // 8 Core Islamic Reference Faculties (Comprehensive Preservation • 4,680 Topics)
  List<_IslamicPillar> _getPillars(String locale) => [
        _IslamicPillar(
          id: 'quran_sciences',
          titles: {
            'ar': 'علوم القرآن والتفسير',
            'en': 'Quranic Sciences & Exegesis',
            'am': 'የቁርኣን ሳይንስ እና ተፍሲር',
            'om': 'Saayinsii Qur\'aanaa fi Tafsiira',
          },
          subtitles: {
            'ar': 'الناسخ والمنسوخ، أوجه الإعجاز، وقصص التنزيل',
            'en': 'Abrogation, inimitability & revelation',
            'am': 'ናሲኽና መንሱኽ፣ የቁርኣን ተአምራት',
            'om': 'Naasikhii fi Mansuukhii, Ajaa\'iba',
          },
          countBadge: '174 موضوعاً',
          icon: Icons.menu_book_rounded,
          gradient: const [Color(0xFF21295C), Color(0xFF384699)],
          accentColor: const Color(0xFF667EEA),
          onSelect: (ctx) => () {
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => LibraryCategoryScreen(
                  domainPart: 'المكتبة',
                  domainTitle: locale == 'ar' ? 'علوم القرآن والتفسير' : 'Quranic Sciences',
                  filterCategories: const ['الناسخ والمنسوخ', 'إعجاز القرآن', 'قصص القرآن', 'القرآن الكريم'],
                ),
              ),
            ).then((_) => _loadResumeItem());
          },
        ),
        _IslamicPillar(
          id: 'seerah',
          titles: {
            'ar': 'السيرة النبوية والمغازي',
            'en': 'Prophetic Seerah & Battles',
            'am': 'የነቢዩ (ሰ.ዐ.ወ) ታሪክ',
            'om': 'Seenaa Nabiyyii (SAW)',
          },
          subtitles: {
            'ar': 'شمائل المصطفى ﷺ، غزواته، ووصاياه العطرة',
            'en': 'Shamail, battles & sacred counsels',
            'am': 'የነቢዩ ሸማኢል እና ዘመቻዎች',
            'om': 'Amala, waraana fi gorsa nabiyyii',
          },
          countBadge: '91 موضوعاً',
          icon: Icons.stars_rounded,
          gradient: const [Color(0xFF854F11), Color(0xFFC78422)],
          accentColor: const Color(0xFFE5A93C),
          onSelect: (ctx) => () {
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => LibraryCategoryScreen(
                  domainPart: 'المكتبة',
                  domainTitle: locale == 'ar' ? 'السيرة النبوية والمغازي' : 'Prophetic Seerah',
                  filterCategories: const ['من وصايا الرسول', 'غزوات الرسول', 'شمائل الرسول'],
                ),
              ),
            ).then((_) => _loadResumeItem());
          },
        ),
        _IslamicPillar(
          id: 'companions',
          titles: {
            'ar': 'سير الصحابة والتابعين',
            'en': 'Companions & Successors',
            'am': 'የሶሓቦች እና ታቢዒዮች ታሪክ',
            'om': 'Seenaa Sahaabotaa',
          },
          subtitles: {
            'ar': 'الصحابة، الصحابيات، التابعون، وقادة الإسلام',
            'en': 'Companions, Tabiun & Islamic leaders',
            'am': 'ሶሓቦች፣ ታቢዒዮች እና እስላማዊ መሪዎች',
            'om': 'Sahaabota, taabi\'oota fi hoggantoota',
          },
          countBadge: '252 ترجمة',
          icon: Icons.people_alt_rounded,
          gradient: const [Color(0xFF143B60), Color(0xFF2564A2)],
          accentColor: const Color(0xFF4299E1),
          onSelect: (ctx) => () {
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => LibraryCategoryScreen(
                  domainPart: 'المكتبة',
                  domainTitle: locale == 'ar' ? 'سير الصحابة والتابعين' : 'Companions & Successors',
                  filterCategories: const ['قصص الصحابة', 'خلفاء وقادة', 'قصص التابعين ', 'قصص الصحابيات'],
                ),
              ),
            ).then((_) => _loadResumeItem());
          },
        ),
        _IslamicPillar(
          id: 'prophets',
          titles: {
            'ar': 'قصص الأنبياء والعبر',
            'en': 'Prophets & Life Lessons',
            'am': 'የነቢያት ታሪኮች እና ትምህርቶች',
            'om': 'Seenaa Raajotaa fi Gorsa',
          },
          subtitles: {
            'ar': 'أخبار الأنبياء والمرسلين والقصص والعبر المستفادة',
            'en': 'Stories of Prophets, messengers & moral lessons',
            'am': 'የነቢያት ታሪክ እና ጠቃሚ ትምህርቶች',
            'om': 'Seenaa nabiyyootaa fi barnoota',
          },
          countBadge: '44 موضوعاً',
          icon: Icons.auto_stories_rounded,
          gradient: const [Color(0xFF0C503F), Color(0xFF19866A)],
          accentColor: const Color(0xFF2ECC9A),
          onSelect: (ctx) => () {
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => LibraryCategoryScreen(
                  domainPart: 'المكتبة',
                  domainTitle: locale == 'ar' ? 'قصص الأنبياء والعبر' : 'Prophets & Life Lessons',
                  filterCategories: const ['قصص الأنبياء', 'قصص وعبر'],
                ),
              ),
            ).then((_) => _loadResumeItem());
          },
        ),
        _IslamicPillar(
          id: 'fiqh_general',
          titles: {
            'ar': 'الفقه الإسلامي العام',
            'en': 'Islamic Jurisprudence (Fiqh)',
            'am': 'ኢስላማዊ ፊቅህ',
            'om': 'Fiqhii Islaamaa',
          },
          subtitles: {
            'ar': 'أحكام العبادات، المعاملات، الفرائض، والبيوع',
            'en': 'Worship, transactions & legal rulings',
            'am': 'የዒባዳ እና የሙዓመላት ህጎች',
            'om': 'Ibaadaa fi mu\'aamalaa',
          },
          countBadge: '996 موضوعاً',
          icon: Icons.balance_rounded,
          gradient: const [Color(0xFF4A154B), Color(0xFF7A257C)],
          accentColor: const Color(0xFFAB47BC),
          onSelect: (ctx) => () {
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => LibraryCategoryScreen(
                  domainPart: 'فقه',
                  domainTitle: locale == 'ar' ? 'الفقه الإسلامي وأحكام الشريعة' : 'Islamic Fiqh',
                ),
              ),
            ).then((_) => _loadResumeItem());
          },
        ),
        _IslamicPillar(
          id: 'fatawa',
          titles: {
            'ar': 'موسوعة الفتاوى الشرعية',
            'en': 'Encyclopedia of Fatawa',
            'am': 'የፈትዋ ኢንሳይክሎፔዲያ',
            'om': 'Fatwaa Hayyootaa',
          },
          subtitles: {
            'ar': '2,948 فتوى موثقة لكبار العلماء والأئمة',
            'en': '2,948 verified authoritative fatawa',
            'am': 'የታላላቅ ዑለሞች የተረጋገጡ ፈትዋዎች',
            'om': 'Fatwaa ulamaa\'ii',
          },
          countBadge: '2,948 فتوى',
          icon: Icons.gavel_rounded,
          gradient: const [Color(0xFF6E1822), Color(0xFFA62A39)],
          accentColor: const Color(0xFFE53E3E),
          onSelect: (ctx) => () {
            Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) => const FiqhAndFatawaScreen()),
            );
          },
        ),
        _IslamicPillar(
          id: 'aqeedah',
          titles: {
            'ar': 'العقيدة والإيمانيات والرقائق',
            'en': 'Creed & Spiritual Faith',
            'am': 'ዐቂዳህ እና እምነት',
            'om': 'Aqiidaa fi Iimaana',
          },
          subtitles: {
            'ar': 'معرفة الله، الملائكة، أشراط الساعة، والقدسيات',
            'en': 'Names of Allah, angels, signs of the Hour & Qudsi',
            'am': 'የአላህ ስሞች፣ መላእክት እና የቂያማ ምልክቶች',
            'om': 'Maqoota Rabbii, Malaaykoota',
          },
          countBadge: '30 موضوعاً',
          icon: Icons.light_mode_rounded,
          gradient: const [Color(0xFF0E434D), Color(0xFF1B7080)],
          accentColor: const Color(0xFF38B2AC),
          onSelect: (ctx) => () {
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => LibraryCategoryScreen(
                  domainPart: 'المكتبة',
                  domainTitle: locale == 'ar' ? 'العقيدة والإيمانيات والرقائق' : 'Islamic Creed & Faith',
                  filterCategories: const ['الله - عز وجل', 'الملائكة', 'علامات الساعة الكبرى', 'الأحاديث القدسية'],
                ),
              ),
            ).then((_) => _loadResumeItem());
          },
        ),
        _IslamicPillar(
          id: 'tibb',
          titles: {
            'ar': 'الطب النبوي والرقية',
            'en': 'Prophetic Medicine & Ruqyah',
            'am': 'የነቢዩ ህክምና እና ሩቅያህ',
            'om': 'Dawaa Nabiyyii fi Ruqiyaa',
          },
          subtitles: {
            'ar': 'هدي النبي ﷺ في التداوي والاستشفاء والرقية المعتمدة',
            'en': 'Healing guidance, medicine & protection',
            'am': 'የፈውስ እና የህክምና መመሪያዎች',
            'om': 'Dawaa fi du\'aa\'ii fayyinaa',
          },
          countBadge: '82 موضوعاً + الرقية',
          icon: Icons.healing_rounded,
          gradient: const [Color(0xFF6B183E), Color(0xFF9E275E)],
          accentColor: const Color(0xFFED64A6),
          onSelect: (ctx) => () {
            Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => LibraryCategoryScreen(
                  domainPart: 'المكتبة',
                  domainTitle: locale == 'ar' ? 'الطب النبوي والرقية الشرعية' : 'Prophetic Medicine & Healing',
                  filterCategories: const ['الطب النبوى', 'الطب البديل', 'باب المعرفة'],
                  headerWidget: _buildRuqyahHeaderCard(ctx),
                ),
              ),
            ).then((_) => _loadResumeItem());
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
      'ar': 'السنة النبوية • السيرة والعلوم الشرعية • المراجع',
      'en': 'Sunnah • Seerah • Fiqh & Islamic Heritage',
      'am': 'ሱናህ • ሲራህ • ፊቅህ እና እስላማዊ ማጣቀሻዎች',
      'om': 'Sunnah • Seenaa • Fiqhii fi Qorannoo',
    }[locale] ?? 'السنة النبوية • السيرة والعلوم الشرعية • المراجع';

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
                : IconButton(
                    icon: const Icon(Icons.manage_search_rounded, color: Color(0xFFC68A2E), size: 20),
                    tooltip: 'البحث في الحديث الشريف',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HadithSearchScreen()),
                      );
                    },
                  ),
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
        'title': {'ar': 'كتبي الخاصة', 'en': 'PDF Reader', 'am': 'PDF Reader', 'om': 'PDF Reader'}[locale] ?? 'كتبي الخاصة',
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
        // A. Continue Reading Banner (Clean & Discrete - Only shown for active reading)
        if (_latestResumeItem != null && _latestResumeItem!['isDefault'] != true)
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
                onOpenHadith: _openHadith,
              ),
            ),
          ),

        // A2. Dedicated Hadith Bookshelf Section (10 Authentic Leather-bound Books)
        SliverToBoxAdapter(
          child: _buildHadithBookshelfSection(
            isDark,
            isCream,
            textColor,
            cardBg,
            borderColor,
            locale,
          ),
        ),

        // B. Section Header for Islamic Heritage Faculties
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 3.5,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B8A6B),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      locale == 'ar' ? 'أقسام المكتبة والعلوم الشرعية' : 'Islamic Heritage & Faculties',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: locale == 'ar' ? 'Amiri' : null,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B8A6B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF1B8A6B).withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        locale == 'ar' ? '8 أقسام • 4,680 موضوعاً' : '8 Faculties • 4,680 Topics',
                        style: const TextStyle(
                          color: Color(0xFF1B8A6B),
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LibraryCategoryScreen(
                              domainPart: 'المكتبة',
                              domainTitle: locale == 'ar' ? 'الفهرس الشامل للمكتبة' : 'Comprehensive Library Index',
                            ),
                          ),
                        ).then((_) => _loadResumeItem());
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              locale == 'ar' ? 'الفهرس الشامل' : 'Full Index',
                              style: const TextStyle(
                                color: Color(0xFF1B8A6B),
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF1B8A6B), size: 9),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // C. Balanced 2-Column Bento Grid of Islamic Faculties
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.08,
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
  // Authentic Hadith Bookshelf Section (Horizontal Carousel of 10 Hardbacks)
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHadithBookshelfSection(
    bool isDark,
    bool isCream,
    Color textColor,
    Color cardBg,
    Color borderColor,
    String locale,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 15,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC68A2E),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    locale == 'ar' ? 'دواوين السنة النبوية' : 'Canonical Hadith Bookshelf',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: locale == 'ar' ? 'Amiri' : null,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC68A2E).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      locale == 'ar' ? '10 دواوين • 40,937 حديثاً' : '10 Books • 40,937 Hadiths',
                      style: const TextStyle(
                        color: Color(0xFFC68A2E),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  LiquidPressable(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HadithSearchScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFC68A2E).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: const Color(0xFFC68A2E).withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.manage_search_rounded, color: Color(0xFFC68A2E), size: 14),
                          const SizedBox(width: 3),
                          Text(
                            locale == 'ar' ? 'بحث' : 'Search',
                            style: const TextStyle(
                              color: Color(0xFFC68A2E),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HadithCollectionsScreen()),
                      ).then((_) => _loadResumeItem());
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            locale == 'ar' ? 'عرض الكل' : 'View All',
                            style: const TextStyle(
                              color: Color(0xFF1B8A6B),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF1B8A6B), size: 9),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Horizontal Bookshelf Row
        SizedBox(
          height: 196,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _kHadithPresets.length + 1,
            itemBuilder: (context, idx) {
              if (idx < _kHadithPresets.length) {
                final preset = _kHadithPresets[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _HadithBookShelfCard(
                    preset: preset,
                    isDark: isDark,
                    locale: locale,
                    onTap: () => _openHadithCollection(preset),
                  ),
                );
              } else {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _buildViewAllCollectionsCard(isDark, cardBg, borderColor, locale),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildViewAllCollectionsCard(
    bool isDark,
    Color cardBg,
    Color borderColor,
    String locale,
  ) {
    return LiquidPressable(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HadithCollectionsScreen()),
        ).then((_) => _loadResumeItem());
      },
      child: Container(
        width: 108,
        height: 194,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: const Color(0xFFC68A2E).withValues(alpha: isDark ? 0.35 : 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8D5B18), Color(0xFFC68A2E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFC68A2E).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.collections_bookmark_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              locale == 'ar' ? 'عرض جميع\nالدواوين' : 'View All\nCollections',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: locale == 'ar' ? 'Amiri' : null,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E3A30),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFC68A2E).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                locale == 'ar' ? '40,937 حديثاً' : '40,937 Hadiths',
                style: const TextStyle(
                  color: Color(0xFFC68A2E),
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Color(0xFFC68A2E),
              size: 16,
            ),
          ],
        ),
      ),
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
                      locale == 'ar' ? 'رف كتبي الشخصية' : 'PDF Reader',
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
                onOpenHadith: _openHadith,
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
                      locale == 'ar' ? 'رف كتبك فارغ حالياً' : 'Your PDF Reader is Empty',
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
                childAspectRatio: 0.68,
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
                    // Icon + Count Badge Pill
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: pillar.accentColor.withValues(alpha: isDark ? 0.16 : 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: pillar.accentColor.withValues(alpha: isDark ? 0.35 : 0.25),
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            pillar.countBadge,
                            style: TextStyle(
                              color: isDark ? pillar.accentColor : Color.lerp(pillar.accentColor, Colors.black, 0.25),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              fontFamily: locale == 'ar' ? 'Amiri' : null,
                            ),
                          ),
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
                            fontSize: 13.5,
                            fontFamily: locale == 'ar' ? 'Amiri' : null,
                            height: 1.15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2.5),
                        Text(
                          pillar.subtitle(locale),
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8A9995) : const Color(0xFF6B8079),
                            fontSize: 9.5,
                            fontFamily: locale == 'ar' ? 'Amiri' : null,
                            height: 1.25,
                          ),
                          maxLines: 2,
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
// ─────────────────────────────────────────────────────────────────────────────
// Authentic Hadith Hardback Book Card Component
// ─────────────────────────────────────────────────────────────────────────────
class _HadithBookShelfCard extends StatelessWidget {
  final _HadithCollectionPreset preset;
  final bool isDark;
  final String locale;
  final VoidCallback onTap;

  const _HadithBookShelfCard({
    required this.preset,
    required this.isDark,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isRtl = locale == 'ar';

    return LiquidPressable(
      onTap: onTap,
      child: Container(
        width: 122,
        height: 194,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: preset.spineGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: preset.goldAccent.withValues(alpha: 0.35),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.2),
              blurRadius: 9,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: preset.goldAccent.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Realistic Book Spine Shadow & Ribs (On the right for RTL, left for LTR)
              Positioned(
                top: 0,
                bottom: 0,
                right: isRtl ? 0 : null,
                left: isRtl ? null : 0,
                width: 13,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                      end: isRtl ? Alignment.centerLeft : Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.42),
                        Colors.black.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Realistic Paper Fore-Edge (opposite side to spine)
              Positioned(
                top: 5,
                bottom: 5,
                left: isRtl ? 0 : null,
                right: isRtl ? null : 0,
                width: 3.5,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(1),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFEADBBE),
                        Color(0xFFFAF3E0),
                        Color(0xFFD8C7A5),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Gold Filigree Ornamental Inner Frame
              Positioned.fill(
                child: Container(
                  margin: EdgeInsets.fromLTRB(
                    isRtl ? 6 : 14,
                    6,
                    isRtl ? 14 : 6,
                    6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: preset.goldAccent.withValues(alpha: 0.3),
                      width: 0.7,
                    ),
                  ),
                ),
              ),

              // 4. Book Content & Details
              Padding(
                padding: EdgeInsets.fromLTRB(
                  isRtl ? 9 : 17,
                  9,
                  isRtl ? 17 : 9,
                  8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top: Micro Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: preset.goldAccent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: preset.goldAccent.withValues(alpha: 0.35),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        preset.badgeText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: preset.goldAccent,
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Center: Book Title
                    Text(
                      preset.title,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.18,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Gold Filigree Divider
                    Container(
                      width: 32,
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            preset.goldAccent.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),

                    // Author Name
                    Text(
                      preset.author,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.8),
                        height: 1.15,
                      ),
                    ),
                    const Spacer(),

                    // Bottom: Hadith Count Gold Pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: preset.goldAccent.withValues(alpha: 0.4),
                          width: 0.6,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 9.5,
                            color: preset.goldAccent,
                          ),
                          const SizedBox(width: 3.5),
                          Text(
                            locale == 'ar' ? '${preset.hadithsCount} حديث' : '${preset.hadithsCount} hadiths',
                            style: TextStyle(
                              fontFamily: locale == 'ar' ? 'Amiri' : null,
                              color: preset.goldAccent,
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
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

class _HeroResumeCard extends StatelessWidget {
  final Map<String, dynamic> resumeItem;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final String locale;
  final Function(UserPdfBook) onOpenPdf;
  final Function(LibraryItem) onOpenStory;
  final Function(HadithItem) onOpenHadith;

  const _HeroResumeCard({
    required this.resumeItem,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.locale,
    required this.onOpenPdf,
    required this.onOpenStory,
    required this.onOpenHadith,
  });

  @override
  Widget build(BuildContext context) {
    final type = resumeItem['type'] as String;
    final bool isPdf = type == 'pdf';
    final bool isHadith = type == 'hadith';

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
    } else if (isHadith) {
      final hadith = resumeItem['hadithItem'] as HadithItem;
      title = (hadith.matnAr != null && hadith.matnAr!.isNotEmpty)
          ? hadith.matnAr!
          : hadith.arabicClean;
      final colPreset = _kHadithPresets.firstWhere(
        (p) => p.id == hadith.collectionId,
        orElse: () => _kHadithPresets.first,
      );
      subtitle = '${colPreset.title} • ${locale == 'ar' ? 'حديث رقم' : 'Hadith #'} ${hadith.hadithNumber}';
      progress = 0.75;
      icon = Icons.menu_book_rounded;
      accentColor = colPreset.goldAccent;
      onTapAction = () => onOpenHadith(hadith);
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
// ─────────────────────────────────────────────────────────────────────────────
// Grid PDF Book Card with Real Stopped-Page Preview (My Shelf)
// ─────────────────────────────────────────────────────────────────────────────
class _GridPdfBookCard extends StatefulWidget {
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
  State<_GridPdfBookCard> createState() => _GridPdfBookCardState();
}

class _GridPdfBookCardState extends State<_GridPdfBookCard> {
  final PdfThumbnailService _thumbnailService = PdfThumbnailService();
  String? _thumbnailPath;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadOrGenerateThumbnail();
  }

  @override
  void didUpdateWidget(covariant _GridPdfBookCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.id != widget.book.id ||
        oldWidget.book.lastPageRead != widget.book.lastPageRead) {
      _loadOrGenerateThumbnail();
    }
  }

  void _loadOrGenerateThumbnail() async {
    final bookId = widget.book.id;
    if (bookId == null) return;

    final targetPage = widget.book.lastPageRead > 0 ? widget.book.lastPageRead : 1;

    // Check synchronous cache first
    final existing = _thumbnailService.getExistingThumbnailPathSync(bookId, targetPage);
    if (existing != null) {
      if (mounted) {
        setState(() {
          _thumbnailPath = existing;
          _isGenerating = false;
        });
      }
      return;
    }

    // Check asynchronous storage
    final asyncPath = await _thumbnailService.getExistingThumbnailPath(bookId, targetPage);
    if (asyncPath != null) {
      if (mounted) {
        setState(() {
          _thumbnailPath = asyncPath;
          _isGenerating = false;
        });
      }
      return;
    }

    // If not generated, trigger generation
    if (mounted) setState(() => _isGenerating = true);

    final generatedPath = await _thumbnailService.generateThumbnail(
      bookId: bookId,
      filePath: widget.book.filePath,
      pageNumber: targetPage,
    );

    if (mounted && generatedPath != null) {
      setState(() {
        _thumbnailPath = generatedPath;
        _isGenerating = false;
      });
    } else if (mounted) {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = widget.locale == 'ar';
    final hasThumbnail = _thumbnailPath != null && File(_thumbnailPath!).existsSync();
    final pageNum = widget.book.lastPageRead > 0 ? widget.book.lastPageRead : 1;
    final isCover = pageNum <= 1;
    final pageBadgeText = isCover
        ? (isRtl ? 'الغلاف' : 'Cover')
        : (isRtl ? 'صفحة $pageNum' : 'Page $pageNum');

    return LiquidPressable(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: widget.borderColor.withValues(alpha: widget.isDark ? 0.35 : 0.5),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDark ? 0.35 : 0.1),
              blurRadius: 9,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Page Preview (Actual rendered image of the page user stopped at!)
              if (hasThumbnail)
                Image.file(
                  File(_thumbnailPath!),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => _buildFallbackPage(),
                )
              else
                _buildFallbackPage(),

              // 2. Realistic Book Spine Shadow Effect
              Positioned(
                top: 0,
                bottom: 0,
                right: isRtl ? 0 : null,
                left: isRtl ? null : 0,
                width: 10,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                      end: isRtl ? Alignment.centerLeft : Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Top Floating Header (Page Badge + Delete Action)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Stopped Page Indicator Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.68),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFECC94B).withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5.5,
                            height: 5.5,
                            decoration: const BoxDecoration(
                              color: Color(0xFFECC94B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            pageBadgeText,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Amiri',
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Circular Glassmorphic Delete Button
                    GestureDetector(
                      onTap: widget.onDelete,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 0.6,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          size: 13.5,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 4. Bottom Information Scrim (Title + Reading Progress)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 24, 10, 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                        Colors.black.withValues(alpha: 0.88),
                        Colors.black,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Book Title
                      Text(
                        widget.book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                          fontFamily: 'Amiri',
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 5),

                      // Progress Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            widget.book.totalPages > 0
                                ? '${widget.book.lastPageRead}/${widget.book.totalPages} ${isRtl ? 'صفحة' : 'p'}'
                                : '${isRtl ? 'صفحة' : 'p'} ${widget.book.lastPageRead}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${(widget.book.progressPercent * 100).toInt()}%',
                            style: const TextStyle(
                              color: Color(0xFFECC94B),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2.5),
                        child: LinearProgressIndicator(
                          value: widget.book.progressPercent,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFECC94B)),
                          minHeight: 2.8,
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
    );
  }

  // Authentic book page placeholder when thumbnail is generating
  Widget _buildFallbackPage() {
    final isDark = widget.isDark;
    return Container(
      color: isDark ? const Color(0xFF14201C) : const Color(0xFFFAF5EC),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 20),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFECC94B).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFECC94B).withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                color: Color(0xFFECC94B),
                size: 24,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              widget.book.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF3E3127),
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                height: 1.3,
              ),
            ),
            if (_isGenerating) ...[
              const SizedBox(height: 12),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  color: Color(0xFFECC94B),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
