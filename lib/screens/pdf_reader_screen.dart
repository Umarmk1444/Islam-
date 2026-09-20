import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/user_pdf_book.dart';
import '../services/library_service.dart';
import '../services/pdf_annotation_service.dart';
import '../services/pdf_thumbnail_service.dart';
import '../theme_notifier.dart';

class PdfReaderScreen extends StatefulWidget {
  final UserPdfBook book;

  const PdfReaderScreen({super.key, required this.book});

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final LibraryService _libraryService = LibraryService();
  final PdfAnnotationService _annotationService = PdfAnnotationService();
  final PdfThumbnailService _thumbnailService = PdfThumbnailService();

  GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey<SfPdfViewerState>();
  OverlayEntry? _contextMenuOverlay;

  late PdfViewerController _pdfViewerController;
  late PdfTextSearchResult _searchResult;

  late int _currentPage;
  late int _totalPages;
  late final ValueNotifier<int> _pageNotifier;
  Timer? _saveProgressDebounce;

  // Vertical continuous scrolling by default as requested!
  bool _isSwipeHorizontal = false;

  // Default to Clean Mode: When opened, it displays a 100% clean page (tap anywhere to toggle controls!)
  bool _controlsVisible = false;
  String? _errorMessage;

  // Search State
  bool _isSearchActive = false;
  final TextEditingController _searchFieldController = TextEditingController();

  // Bookmarks State
  Set<int> _bookmarkedPages = {};
  String get _bookmarksPrefKey => 'pdf_bookmarks_${widget.book.id ?? widget.book.fileName.hashCode}';

  // Instant Theme State (Isolated to PDF Reader - 0ms instant GPU switch without global rebuild)
  late QuranTheme _currentTheme;

  // High-contrast inverted matrix for dark/night mode
  static const ColorFilter _kInvertColorFilter = ColorFilter.matrix([
    -1.0, 0.0, 0.0, 0.0, 255.0,
    0.0, -1.0, 0.0, 0.0, 255.0,
    0.0, 0.0, -1.0, 0.0, 255.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ]);

  // Rich, noticeable warm sepia/cream matrix for eye-comfort reading
  // Converts harsh white paper to warm, soothing antique parchment (#F2E3C7) while keeping black text sharp!
  static const ColorFilter _kCreamColorFilter = ColorFilter.matrix([
    0.95, 0.0,  0.0,  0.0, 0.0,
    0.0,  0.89, 0.0,  0.0, 0.0,
    0.0,  0.0,  0.78, 0.0, 0.0,
    0.0,  0.0,  0.0,  1.0, 0.0,
  ]);

  // Identity matrix for standard color rendering (ensures zero unmounting/rebuilding)
  static const ColorFilter _kIdentityColorFilter = ColorFilter.matrix([
    1.0, 0.0, 0.0, 0.0, 0.0,
    0.0, 1.0, 0.0, 0.0, 0.0,
    0.0, 0.0, 1.0, 0.0, 0.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
  ]);

  @override
  void initState() {
    super.initState();
    _currentPage = widget.book.lastPageRead > 0 ? widget.book.lastPageRead : 1;
    _totalPages = widget.book.totalPages;
    _pageNotifier = ValueNotifier<int>(_currentPage);
    _currentTheme = AppTheme.notifier.value;

    _loadSavedReaderTheme();
    _loadBookmarks();
    try {
      WakelockPlus.enable();
    } catch (e) {
      debugPrint('[PdfReaderScreen] Wakelock enable error: $e');
    }

    _pdfViewerController = PdfViewerController();
    _searchResult = PdfTextSearchResult();
  }

  Future<void> _loadSavedReaderTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('pdf_reader_theme_mode');
    if (saved != null && mounted) {
      setState(() {
        _currentTheme = QuranTheme.values.firstWhere(
          (t) => t.name == saved,
          orElse: () => _currentTheme,
        );
      });
    }
  }

  @override
  void dispose() {
    _hideContextMenu();
    _saveProgressDebounce?.cancel();
    _saveProgressImmediate();
    _pageNotifier.dispose();
    _searchFieldController.dispose();
    _searchResult.dispose();
    _pdfViewerController.dispose();
    try {
      WakelockPlus.disable();
    } catch (e) {
      debugPrint('[PdfReaderScreen] Wakelock disable error: $e');
    }
    super.dispose();
  }

  void _saveProgressThrottled() {
    _saveProgressDebounce?.cancel();
    _saveProgressDebounce = Timer(const Duration(milliseconds: 1200), () {
      _saveProgressImmediate();
    });
  }

  void _saveProgressImmediate() {
    if (widget.book.id != null) {
      _libraryService.updatePdfReadingProgress(
        widget.book.id!,
        _currentPage,
        totalPages: _totalPages > 0 ? _totalPages : null,
      );
      // Generate preview thumbnail for the exact page stopped at
      _thumbnailService.generateThumbnail(
        bookId: widget.book.id!,
        filePath: widget.book.filePath,
        pageNumber: _currentPage,
      );
    }
  }

  // ── Instant Theme Switching (Zero Delay, Isolated to PDF Reader Only) ───────
  void _cycleThemeInstantly() {
    HapticFeedback.selectionClick();

    QuranTheme nextTheme;
    if (_currentTheme == QuranTheme.dark) {
      nextTheme = QuranTheme.cream;
    } else if (_currentTheme == QuranTheme.cream) {
      nextTheme = QuranTheme.white;
    } else {
      nextTheme = QuranTheme.dark;
    }

    setState(() {
      _currentTheme = nextTheme;
    });

    // DO NOT call AppTheme.changeTheme()!
    // Keeping this local prevents MaterialApp from rebuilding the entire app and freezing the UI!
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('pdf_reader_theme_mode', nextTheme.name);
    });
  }

  // ── Swipe Direction Toggle ─────────────────────────────────────────────────
  void _toggleSwipeDirection() {
    _hideContextMenu();
    HapticFeedback.selectionClick();
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    setState(() {
      _isSwipeHorizontal = !_isSwipeHorizontal;
      _pdfViewerKey = GlobalKey<SfPdfViewerState>();
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isSwipeHorizontal
              ? (locale == 'ar' ? 'تم تفعيل التمرير الأفقي (صفحات)' : 'Horizontal Page Swipe Enabled')
              : (locale == 'ar' ? 'تم تفعيل التمرير الرأسي (مستمر)' : 'Vertical Continuous Scroll Enabled'),
          style: TextStyle(fontFamily: locale == 'ar' ? 'Amiri' : null, fontSize: 13),
        ),
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ── Share Book via share_plus ──────────────────────────────────────────────
  void _shareBook() {
    HapticFeedback.lightImpact();
    final file = File(widget.book.filePath);
    if (!file.existsSync()) return;

    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final isAr = locale == 'ar';
    const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.umer.quranzone';

    final String pageInfo = _totalPages > 0
        ? (isAr ? '📑 صفحة القراءة الحالية: $_currentPage من إجمالي $_totalPages\n' : '📑 Current Page: $_currentPage of $_totalPages\n')
        : '';

    final String shareText = isAr
        ? '📖 كتاب: ${widget.book.title}\n'
          '$pageInfo'
          '📂 مستند بصيغة (PDF)\n'
          '━━━━━━━━━━━━━━━━━━\n'
          '📱 تمت المشاركة عبر قارئ الكتب (PDF Reader)\n'
          '🕌 من تطبيق: Quran Zone (منطقة القرآن)\n'
          '✨ تصفح واقرأ القرآن الكريم، الأذكار، والكتب والمستندات الإسلامية بكل سهولة.\n'
          '📥 حمّل التطبيق الآن مجاناً من متجر Google Play:\n'
          '$playStoreUrl'
        : '📖 Book: ${widget.book.title}\n'
          '$pageInfo'
          '📂 PDF Document\n'
          '━━━━━━━━━━━━━━━━━━\n'
          '📱 Shared via PDF Book Reader\n'
          '🕌 App: Quran Zone\n'
          '✨ Read the Holy Quran, Adhkar, and Islamic books & documents effortlessly.\n'
          '📥 Download Quran Zone free from Google Play:\n'
          '$playStoreUrl';

    Share.shareXFiles(
      [XFile(widget.book.filePath)],
      text: shareText,
      subject: widget.book.title,
    );
  }

  // ── Jump to Page Dialog ────────────────────────────────────────────────────
  void _showJumpToPageDialog() {
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final textController = TextEditingController(text: '$_currentPage');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.find_in_page_rounded, color: Color(0xFF1B8A6B), size: 22),
              const SizedBox(width: 10),
              Text(
                locale == 'ar' ? 'انتقل إلى صفحة' : 'Jump to Page',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  fontFamily: locale == 'ar' ? 'Amiri' : null,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                locale == 'ar'
                    ? 'أدخل رقم الصفحة (من 1 إلى ${_totalPages > 0 ? _totalPages : "..."}):'
                    : 'Enter page number (1 to ${_totalPages > 0 ? _totalPages : "..."}):',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                keyboardType: TextInputType.number,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: locale == 'ar' ? 'رقم الصفحة' : 'Page number',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.bookmark_outline_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(locale == 'ar' ? 'إلغاء' : 'Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B8A6B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                final target = int.tryParse(textController.text.trim());
                if (target != null && target >= 1 && (_totalPages <= 0 || target <= _totalPages)) {
                  _currentPage = target;
                  _pageNotifier.value = target;
                  _pdfViewerController.jumpToPage(target);
                  _saveProgressThrottled();
                  Navigator.pop(ctx);
                }
              },
              child: Text(locale == 'ar' ? 'انتقال' : 'Jump'),
            ),
          ],
        );
      },
    );
  }

  // ── Bookmarks Management ───────────────────────────────────────────────────
  Future<void> _loadBookmarks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_bookmarksPrefKey) ?? [];
      if (mounted) {
        setState(() {
          _bookmarkedPages = list.map((e) => int.tryParse(e)).whereType<int>().toSet();
        });
      }
    } catch (e) {
      debugPrint('[PdfReaderScreen] Error loading bookmarks: $e');
    }
  }

  Future<void> _toggleBookmarkCurrentPage() async {
    HapticFeedback.lightImpact();
    final page = _currentPage;
    final bool wasBookmarked = _bookmarkedPages.contains(page);
    setState(() {
      if (wasBookmarked) {
        _bookmarkedPages.remove(page);
      } else {
        _bookmarkedPages.add(page);
      }
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _bookmarksPrefKey,
        _bookmarkedPages.map((e) => e.toString()).toList(),
      );
    } catch (e) {
      debugPrint('[PdfReaderScreen] Error saving bookmarks: $e');
    }

    if (!mounted) return;
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              wasBookmarked ? Icons.bookmark_remove_rounded : Icons.bookmark_added_rounded,
              color: const Color(0xFFECC94B),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              wasBookmarked
                  ? (locale == 'ar' ? 'تمت إزالة الإشارة المرجعية (صفحة $page)' : 'Bookmark removed (Page $page)')
                  : (locale == 'ar' ? 'تمت إضافة إشارة مرجعية (صفحة $page)' : 'Page $page bookmarked'),
              style: TextStyle(fontFamily: locale == 'ar' ? 'Amiri' : null, fontSize: 13),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 1400),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _removeBookmark(int page) async {
    HapticFeedback.lightImpact();
    setState(() {
      _bookmarkedPages.remove(page);
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _bookmarksPrefKey,
        _bookmarkedPages.map((e) => e.toString()).toList(),
      );
    } catch (e) {
      debugPrint('[PdfReaderScreen] Error removing bookmark: $e');
    }
  }

  void _showBookmarksListSheet() {
    HapticFeedback.lightImpact();
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final isDark = _currentTheme == QuranTheme.dark;
    final isCream = _currentTheme == QuranTheme.cream;
    final cardBg = isDark
        ? const Color(0xFF162320)
        : (isCream ? const Color(0xFFFFFDF8) : Colors.white);
    final textColor = isDark ? Colors.white : const Color(0xFF152A24);
    final primaryColor = AppTheme.getPrimaryColor(_currentTheme);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final sorted = _bookmarkedPages.toList()..sort();
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.bookmarks_rounded, color: Color(0xFFECC94B), size: 22),
                        const SizedBox(width: 8),
                        Text(
                          locale == 'ar' ? 'الإشارات المرجعية' : 'Bookmarks',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontFamily: 'Amiri',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECC94B).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${sorted.length}',
                            style: const TextStyle(
                              color: Color(0xFFECC94B),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: textColor.withValues(alpha: 0.6),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (sorted.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                        child: Column(
                          children: [
                            Icon(Icons.bookmark_border_rounded, size: 48, color: Colors.grey.withValues(alpha: 0.4)),
                            const SizedBox(height: 12),
                            Text(
                              locale == 'ar' ? 'لا توجد إشارات مرجعية محفوظة' : 'No bookmarks saved yet',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: textColor.withValues(alpha: 0.8),
                                fontFamily: 'Amiri',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              locale == 'ar'
                                  ? 'اضغط على أيقونة الإشارة المرجعية بأعلى الشاشة لحفظ أي صفحة والرجوع إليها بسرعة.'
                                  : 'Tap the bookmark icon in the top bar to bookmark any page for quick reference.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.5)),
                            ),
                          ],
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: sorted.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: isDark ? Colors.white10 : Colors.black12,
                          ),
                          itemBuilder: (context, index) {
                            final page = sorted[index];
                            final isCurrent = page == _currentPage;
                            final thumbPath = widget.book.id != null
                                ? _thumbnailService.getExistingThumbnailPathSync(widget.book.id!, page)
                                : null;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              leading: Container(
                                width: 42,
                                height: 52,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isCurrent ? primaryColor : Colors.grey.withValues(alpha: 0.3),
                                    width: isCurrent ? 1.8 : 1,
                                  ),
                                  color: isDark ? Colors.black26 : Colors.grey.shade100,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: thumbPath != null
                                    ? Image.file(File(thumbPath), fit: BoxFit.cover)
                                    : Center(
                                        child: Text(
                                          '$page',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                              ),
                              title: Row(
                                children: [
                                  Text(
                                    locale == 'ar' ? 'صفحة $page' : 'Page $page',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14.5,
                                      color: textColor,
                                      fontFamily: 'Amiri',
                                    ),
                                  ),
                                  if (isCurrent) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        locale == 'ar' ? 'الحالية' : 'Current',
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              subtitle: _totalPages > 0
                                  ? Text(
                                      locale == 'ar'
                                          ? 'من إجمالي $_totalPages صفحة'
                                          : 'of $_totalPages pages',
                                      style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.5)),
                                    )
                                  : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                tooltip: locale == 'ar' ? 'إزالة' : 'Remove',
                                onPressed: () {
                                  _removeBookmark(page);
                                  setSheetState(() {});
                                },
                              ),
                              onTap: () {
                                Navigator.pop(ctx);
                                _currentPage = page;
                                _pageNotifier.value = page;
                                _pdfViewerController.jumpToPage(page);
                                _saveProgressThrottled();
                              },
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Visual Page Grid Browser (تصفح جميع الصفحات) ──────────────────────────
  void _showPageGridBrowser() {
    HapticFeedback.lightImpact();
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final isDark = _currentTheme == QuranTheme.dark;
    final isCream = _currentTheme == QuranTheme.cream;
    final Color sheetBg = isDark
        ? const Color(0xFF141F1C)
        : (isCream ? const Color(0xFFF9F3E8) : Colors.white);
    final Color textColor = isDark ? Colors.white : const Color(0xFF152A24);
    final Color primaryColor = AppTheme.getPrimaryColor(_currentTheme);

    int selectedTab = 0; // 0: All pages, 1: Bookmarks only
    final scrollController = ScrollController();

    // Auto-scroll to current page after initial layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients && _currentPage > 3 && _totalPages > 0) {
        final row = (_currentPage - 1) ~/ 3;
        const estRowHeight = 150.0;
        final targetOffset = (row * estRowHeight).clamp(0.0, scrollController.position.maxScrollExtent);
        scrollController.jumpTo(targetOffset);
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setGridState) {
            final List<int> pagesToShow;
            if (selectedTab == 1) {
              pagesToShow = _bookmarkedPages.toList()..sort();
            } else {
              pagesToShow = List<int>.generate(_totalPages > 0 ? _totalPages : 1, (i) => i + 1);
            }

            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.88,
              child: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 42,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Header Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(Icons.grid_view_rounded, color: primaryColor, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            locale == 'ar' ? 'تصفح صفحات الكتاب' : 'Browse Pages',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontFamily: 'Amiri',
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.find_in_page_rounded, size: 22),
                            color: textColor.withValues(alpha: 0.8),
                            tooltip: locale == 'ar' ? 'انتقال لرقم صفحة' : 'Jump to Page',
                            onPressed: () {
                              Navigator.pop(ctx);
                              _showJumpToPageDialog();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 22),
                            color: textColor.withValues(alpha: 0.6),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                    ),

                    // Segment Toggle (All Pages vs Bookmarks)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : Colors.grey.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setGridState(() => selectedTab = 0),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selectedTab == 0
                                        ? (isDark ? const Color(0xFF223630) : Colors.white)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: selectedTab == 0
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.08),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.auto_stories_rounded,
                                        size: 15,
                                        color: selectedTab == 0 ? primaryColor : textColor.withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        locale == 'ar'
                                            ? 'جميع الصفحات (${_totalPages > 0 ? _totalPages : "..."})'
                                            : 'All (${_totalPages > 0 ? _totalPages : "..."})',
                                        style: TextStyle(
                                          fontWeight: selectedTab == 0 ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 12.5,
                                          color: selectedTab == 0 ? primaryColor : textColor.withValues(alpha: 0.7),
                                          fontFamily: 'Amiri',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setGridState(() => selectedTab = 1),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: selectedTab == 1
                                        ? (isDark ? const Color(0xFF223630) : Colors.white)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: selectedTab == 1
                                        ? [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.08),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.bookmark_rounded,
                                        size: 15,
                                        color: selectedTab == 1 ? const Color(0xFFECC94B) : textColor.withValues(alpha: 0.6),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        locale == 'ar'
                                            ? 'الإشارات المرجعية (${_bookmarkedPages.length})'
                                            : 'Bookmarks (${_bookmarkedPages.length})',
                                        style: TextStyle(
                                          fontWeight: selectedTab == 1 ? FontWeight.bold : FontWeight.normal,
                                          fontSize: 12.5,
                                          color: selectedTab == 1 ? const Color(0xFFECC94B) : textColor.withValues(alpha: 0.7),
                                          fontFamily: 'Amiri',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Grid of Pages
                    Expanded(
                      child: pagesToShow.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.bookmark_border_rounded,
                                      size: 48,
                                      color: Colors.grey.withValues(alpha: 0.4),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      locale == 'ar' ? 'لا توجد إشارات مرجعية' : 'No bookmarks found',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: textColor.withValues(alpha: 0.7),
                                        fontFamily: 'Amiri',
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      locale == 'ar'
                                          ? 'يمكنك حفظ إشارة مرجعية لأي صفحة عبر أيقونة العلامة في الشريط العلوي.'
                                          : 'You can bookmark any page using the bookmark icon in the top bar.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.5)),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : GridView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.70,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 12,
                              ),
                              itemCount: pagesToShow.length,
                              itemBuilder: (context, index) {
                                final pageNum = pagesToShow[index];
                                final isCurrent = pageNum == _currentPage;
                                final isBookmarked = _bookmarkedPages.contains(pageNum);
                                final thumbPath = widget.book.id != null
                                    ? _thumbnailService.getExistingThumbnailPathSync(widget.book.id!, pageNum)
                                    : null;

                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    Navigator.pop(ctx);
                                    _currentPage = pageNum;
                                    _pageNotifier.value = pageNum;
                                    _pdfViewerController.jumpToPage(pageNum);
                                    _saveProgressThrottled();
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isCurrent
                                            ? primaryColor
                                            : (isDark
                                                ? Colors.white.withValues(alpha: 0.12)
                                                : Colors.black.withValues(alpha: 0.1)),
                                        width: isCurrent ? 2.5 : 1.0,
                                      ),
                                      boxShadow: [
                                        if (isCurrent)
                                          BoxShadow(
                                            color: primaryColor.withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          )
                                        else
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                      ],
                                      color: isDark
                                          ? const Color(0xFF1B2A25)
                                          : (isCream ? const Color(0xFFFAF6EE) : Colors.white),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        if (thumbPath != null)
                                          Image.file(
                                            File(thumbPath),
                                            fit: BoxFit.cover,
                                          )
                                        else
                                          Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.menu_book_rounded,
                                                  size: 26,
                                                  color: isCurrent
                                                      ? primaryColor.withValues(alpha: 0.6)
                                                      : Colors.grey.withValues(alpha: 0.4),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  '$pageNum',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: isCurrent
                                                        ? primaryColor
                                                        : textColor.withValues(alpha: 0.6),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                        // Bookmark Badge (Top Right)
                                        if (isBookmarked)
                                          Positioned(
                                            top: 0,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.fromLTRB(4, 3, 4, 5),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFECC94B),
                                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withValues(alpha: 0.25),
                                                    blurRadius: 3,
                                                  ),
                                                ],
                                              ),
                                              child: const Icon(
                                                Icons.bookmark_rounded,
                                                color: Color(0xFF2C1C11),
                                                size: 13,
                                              ),
                                            ),
                                          ),

                                        // Current Page Indicator (Top Left)
                                        if (isCurrent)
                                          Positioned(
                                            top: 6,
                                            left: 6,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: primaryColor,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                locale == 'ar' ? 'الحالية' : 'Current',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),

                                        // Bottom Page Number Overlay
                                        Positioned(
                                          left: 0,
                                          right: 0,
                                          bottom: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                begin: Alignment.bottomCenter,
                                                end: Alignment.topCenter,
                                                colors: [
                                                  Colors.black.withValues(alpha: 0.75),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                            child: Text(
                                              '$pageNum',
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11,
                                                shadows: [
                                                  Shadow(
                                                    color: Colors.black,
                                                    blurRadius: 2,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Book Details & Actions Bottom Sheet ────────────────────────────────────
  void _showBookInfoSheet() {
    HapticFeedback.lightImpact();
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final isDark = _currentTheme == QuranTheme.dark;
    final cardBg = isDark ? const Color(0xFF162320) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF152A24);

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD32F2F).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFD32F2F), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.book.title,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: locale == 'ar' ? 'Amiri' : null,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${widget.book.formattedSize}  •  ${_totalPages > 0 ? "$_totalPages صفحة" : ""}',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.6),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // Info Rows
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      locale == 'ar' ? 'الصفحة الحالية' : 'Current Page',
                      style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13),
                    ),
                    Text(
                      '$_currentPage / ${_totalPages > 0 ? _totalPages : "..."}',
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      locale == 'ar' ? 'نسبة التقدم' : 'Reading Progress',
                      style: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 13),
                    ),
                    Text(
                      '${_totalPages > 0 ? ((_currentPage / _totalPages) * 100).toInt() : 0}%',
                      style: const TextStyle(
                        color: Color(0xFF1B8A6B),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: Text(locale == 'ar' ? 'نسخ العنوان' : 'Copy Title'),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.book.title));
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(locale == 'ar' ? 'تم نسخ العنوان' : 'Title copied'),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B8A6B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: Text(locale == 'ar' ? 'مشاركة الملف' : 'Share PDF'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _shareBook();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Build Main Screen with Syncfusion Engine ───────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool fileExists = File(widget.book.filePath).existsSync();
    final bool isDark = _currentTheme == QuranTheme.dark;
    final bool isCream = _currentTheme == QuranTheme.cream;

    final Color screenBg = isDark
        ? const Color(0xFF101614)
        : (isCream ? const Color(0xFFF2E3C7) : const Color(0xFFF5F5F5));

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _saveProgressDebounce?.cancel();
          _saveProgressImmediate();
        }
      },
      child: Scaffold(
        backgroundColor: screenBg,
        body: !fileExists
            ? _buildFileNotFoundView()
            : Stack(
                children: [
                  // 1. Core Syncfusion PDF Viewer Engine (Text Selection & Search Built-in)
                  Positioned.fill(
                    child: _buildPdfViewer(isDark, isCream),
                  ),

                  // 3. Error Overlay if any
                  if (_errorMessage != null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                            const SizedBox(height: 12),
                            const Text(
                              'تعذر فتح ملف PDF',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 4. In-App Search Bar (Appears below top bar when active)
                  if (_isSearchActive)
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 60,
                      left: 16,
                      right: 16,
                      child: _buildSearchToolbar(isDark, isCream),
                    ),

                  // 5. Top Bar (Smooth slide-in on tap)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    top: _controlsVisible ? 0 : -130,
                    left: 0,
                    right: 0,
                    child: _buildTopBar(_currentTheme),
                  ),

                  // 6. Bottom Bar (Smooth slide-in on tap with 60fps Scrub Slider)
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    bottom: _controlsVisible ? 0 : -150,
                    left: 0,
                    right: 0,
                    child: _buildBottomBar(_currentTheme),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Annotation Persistence & Context Menu ────────────────────────────────
  Future<void> _loadPersistentAnnotations() async {
    final bookId = widget.book.id;
    if (bookId == null) return;
    try {
      final savedAnnotations = await _annotationService.loadAnnotations(bookId);
      for (final ann in savedAnnotations) {
        _pdfViewerController.addAnnotation(ann);
      }
    } catch (e) {
      debugPrint('[PdfReaderScreen] Error loading annotations: $e');
    }
  }

  void _addHighlightAnnotation() async {
    final bookId = widget.book.id;
    if (bookId == null) return;

    final lines = _pdfViewerKey.currentState?.getSelectedTextLines() ?? [];
    if (lines.isEmpty) return;

    const color = Color(0x77ECC94B); // warm translucent gold/amber highlight
    final highlight = HighlightAnnotation(textBoundsCollection: lines);
    highlight.color = color;

    _pdfViewerController.clearSelection();
    _hideContextMenu();
    _pdfViewerController.addAnnotation(highlight);

    final id = await _annotationService.saveAnnotation(
      bookId: bookId,
      type: 'highlight',
      lines: lines,
      color: color,
    );
    highlight.subject = id;
    HapticFeedback.lightImpact();
  }

  void _addUnderlineAnnotation() async {
    final bookId = widget.book.id;
    if (bookId == null) return;

    final lines = _pdfViewerKey.currentState?.getSelectedTextLines() ?? [];
    if (lines.isEmpty) return;

    const color = Color(0xFF1B8A6B); // rich emerald green underline
    final underline = UnderlineAnnotation(textBoundsCollection: lines);
    underline.color = color;

    _pdfViewerController.clearSelection();
    _hideContextMenu();
    _pdfViewerController.addAnnotation(underline);

    final id = await _annotationService.saveAnnotation(
      bookId: bookId,
      type: 'underline',
      lines: lines,
      color: color,
    );
    underline.subject = id;
    HapticFeedback.lightImpact();
  }

  void _showAnnotationActionDialog(Annotation annotation) {
    final bookId = widget.book.id;
    if (bookId == null) return;

    final isDark = _currentTheme == QuranTheme.dark;
    final isCream = _currentTheme == QuranTheme.cream;
    final isHighlight = annotation is HighlightAnnotation;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cardBg = isDark ? const Color(0xFF162320) : (isCream ? const Color(0xFFFFFDF8) : Colors.white);
        final textColor = isDark ? Colors.white : const Color(0xFF152A24);

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: AppTheme.getBorderColor(_currentTheme).withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    isHighlight ? Icons.border_color_rounded : Icons.format_underlined_rounded,
                    color: isHighlight ? const Color(0xFFECC94B) : const Color(0xFF1B8A6B),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    isHighlight ? 'تظليل في الصفحة ${annotation.pageNumber}' : 'تسطير في الصفحة ${annotation.pageNumber}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor, fontFamily: 'Amiri'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('حذف هذا التحديد', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.redAccent.withValues(alpha: 0.08),
                onTap: () {
                  Navigator.pop(ctx);
                  _pdfViewerController.removeAnnotation(annotation);
                  _annotationService.removeAnnotation(bookId, annotation);
                  HapticFeedback.lightImpact();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _hideContextMenu() {
    _contextMenuOverlay?.remove();
    _contextMenuOverlay = null;
  }

  void _showFloatingContextMenu(PdfTextSelectionChangedDetails details) {
    _hideContextMenu();
    if (!mounted) return;

    final selectedText = details.selectedText;
    if (selectedText == null || selectedText.trim().isEmpty) return;

    final overlay = Overlay.of(context);
    final region = details.globalSelectedRegion;
    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final double menuWidth = (screenSize.width - 16.0).clamp(320.0, 440.0);
    const double menuHeight = 52.0;
    const double verticalOffset = 50.0; // 50px clearance from selected text as requested!

    double topPos;
    if (region != null) {
      // Responsive positioning: If text is near the top of the viewport, place popup 50px BELOW the text!
      final double topThreshold = topPadding + menuHeight + verticalOffset + 15.0;
      if (region.top < topThreshold) {
        topPos = region.bottom + verticalOffset; // Exactly 50px BELOW text and teardrop handles!
      } else {
        // Text is lower down: Position exactly 50px ABOVE the selected text!
        topPos = region.top - menuHeight - verticalOffset;
        // If it touches the status bar / top padding, flip below
        if (topPos < topPadding + 10.0) {
          topPos = region.bottom + verticalOffset;
        }
      }
    } else {
      topPos = (screenSize.height / 2) - menuHeight;
    }
    // Safeguard clamp so it never overflows top or bottom of screen
    topPos = topPos.clamp(topPadding + 10.0, screenSize.height - bottomPadding - menuHeight - 10.0);

    double leftPos;
    if (region != null) {
      // Follow the text horizontally: Center right over the selected text
      leftPos = region.center.dx - (menuWidth / 2);
    } else {
      leftPos = (screenSize.width - menuWidth) / 2;
    }
    // Clamp to screen edges so it never overflows
    leftPos = leftPos.clamp(8.0, screenSize.width - menuWidth - 8.0);

    _contextMenuOverlay = OverlayEntry(
      builder: (context) {
        final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
        final isDark = _currentTheme == QuranTheme.dark;
        final isCream = _currentTheme == QuranTheme.cream;
        final menuBg = isDark
            ? const Color(0xFF14201C).withValues(alpha: 0.96)
            : (isCream
                ? const Color(0xFFFFF8EC).withValues(alpha: 0.97)
                : Colors.white.withValues(alpha: 0.97));
        final textColor = isDark ? Colors.white : const Color(0xFF152A24);
        final borderColor = isDark ? const Color(0xFFECC94B) : const Color(0xFF1B8A6B);

        // Position dynamically following the text (below top text, above lower text)
        return Positioned(
          top: topPos,
          left: leftPos,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: menuWidth,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              decoration: BoxDecoration(
                color: menuBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor.withValues(alpha: 0.45), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildContextMenuItem(
                    icon: Icons.border_color_rounded,
                    label: locale == 'ar' ? 'تظليل' : 'Highlight',
                    color: const Color(0xFFECC94B),
                    onTap: _addHighlightAnnotation,
                  ),
                  _buildMenuDivider(isDark),
                  _buildContextMenuItem(
                    icon: Icons.format_underlined_rounded,
                    label: locale == 'ar' ? 'تسطير' : 'Underline',
                    color: const Color(0xFF1B8A6B),
                    onTap: _addUnderlineAnnotation,
                  ),
                  _buildMenuDivider(isDark),
                  _buildContextMenuItem(
                    icon: Icons.auto_awesome_rounded,
                    label: locale == 'ar' ? 'اسأل AI' : 'Ask AI',
                    color: const Color(0xFF9C27B0),
                    onTap: () {
                      _hideContextMenu();
                      _pdfViewerController.clearSelection();
                      _showAiBottomSheet(selectedText);
                    },
                  ),
                  _buildMenuDivider(isDark),
                  _buildContextMenuItem(
                    icon: Icons.g_translate_rounded,
                    label: locale == 'ar' ? 'ترجمة' : 'Translate',
                    color: const Color(0xFF2196F3),
                    onTap: () {
                      _handleTranslateTap(selectedText);
                    },
                  ),
                  _buildMenuDivider(isDark),
                  _buildContextMenuItem(
                    icon: Icons.travel_explore_rounded,
                    label: locale == 'ar' ? 'بحث Google' : 'Google',
                    color: const Color(0xFF4285F4),
                    onTap: () {
                      _hideContextMenu();
                      _pdfViewerController.clearSelection();
                      _launchWebSearch(selectedText);
                    },
                  ),
                  _buildMenuDivider(isDark),
                  _buildContextMenuItem(
                    icon: Icons.copy_rounded,
                    label: locale == 'ar' ? 'نسخ' : 'Copy',
                    color: textColor.withValues(alpha: 0.8),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: selectedText));
                      _hideContextMenu();
                      _pdfViewerController.clearSelection();
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                              const SizedBox(width: 8),
                              Text(locale == 'ar' ? 'تم نسخ النص إلى الحافظة' : 'Text copied to clipboard'),
                            ],
                          ),
                          backgroundColor: const Color(0xFF1B8A6B),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                  _buildMenuDivider(isDark),
                  _buildContextMenuItem(
                    icon: Icons.search_rounded,
                    label: locale == 'ar' ? 'في الكتاب' : 'Search In',
                    color: textColor.withValues(alpha: 0.8),
                    onTap: () {
                      _hideContextMenu();
                      _pdfViewerController.clearSelection();
                      _startSearchWithText(selectedText);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_contextMenuOverlay!);
  }

  Widget _buildContextMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.0, vertical: 3.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16.5, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8.8,
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontFamily: 'Amiri',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuDivider(bool isDark) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
    );
  }

  void _startSearchWithText(String text) {
    setState(() {
      _isSearchActive = true;
      _searchFieldController.text = text;
      _searchResult = _pdfViewerController.searchText(text);
    });
  }


  void _handleTranslateTap(String selectedText) async {
    _hideContextMenu();
    _pdfViewerController.clearSelection();

    // 1. Copy text to clipboard so it's always ready
    await Clipboard.setData(ClipboardData(text: selectedText));

    const String translatePackage = 'com.google.android.apps.translate';
    bool launchedTranslatePopup = false;

    // 2. Try native Android METHOD CHANNEL for ACTION_PROCESS_TEXT:
    // This launches Google Translate's native floating card popup from the top with text pre-filled!
    // (Exact same mechanism as Android system text selection and ReadEra!)
    try {
      const systemChannel = MethodChannel('com.umer.quranzone/system_actions');
      final res = await systemChannel.invokeMethod<bool>('launchProcessText', {
        'packageName': translatePackage,
        'text': selectedText,
      });
      if (res == true) launchedTranslatePopup = true;
    } catch (_) {}

    // 3. Fallback: Android ACTION_PROCESS_TEXT intent via url_launcher
    if (!launchedTranslatePopup) {
      try {
        final processIntentUri = Uri.parse(
          'intent:#Intent;action=android.intent.action.PROCESS_TEXT;type=text/plain;S.android.intent.extra.PROCESS_TEXT=${Uri.encodeQueryComponent(selectedText)};B.android.intent.extra.PROCESS_TEXT_READONLY=true;package=$translatePackage;end',
        );
        if (await canLaunchUrl(processIntentUri)) {
          launchedTranslatePopup = await launchUrl(processIntentUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }

    // 4. Fallback: ACTION_SEND intent with extra.TEXT
    if (!launchedTranslatePopup) {
      try {
        final sendIntentUri = Uri.parse(
          'intent:#Intent;action=android.intent.action.SEND;type=text/plain;S.android.intent.extra.TEXT=${Uri.encodeQueryComponent(selectedText)};package=$translatePackage;end',
        );
        if (await canLaunchUrl(sendIntentUri)) {
          launchedTranslatePopup = await launchUrl(sendIntentUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }

    // 5. Fallback: Custom URL scheme
    if (!launchedTranslatePopup) {
      try {
        final schemeUri = Uri.parse('googletranslate://');
        if (await canLaunchUrl(schemeUri)) {
          launchedTranslatePopup = await launchUrl(schemeUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }

    // If Google Translate floating window/activity launched, we are done!
    if (launchedTranslatePopup) {
      return;
    }

    // 6. If Google Translate app is NOT installed on the phone:
    // Seamlessly open our rich built-in in-app translation sheet!
    if (mounted) {
      _showTranslateBottomSheet(selectedText);
    }
  }

  void _launchWebSearch(String text) async {
    final query = text.trim();
    if (query.isEmpty) return;
    final url = Uri.parse('https://www.google.com/search?q=${Uri.encodeComponent(query)}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (_) {}
    }
  }

  // ── Multi-AI Assistant with App Discovery & Direct Text Input ──────────────
  void _showAiBottomSheet(String selectedText) {
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final isArabic = locale == 'ar';
    final isDark = _currentTheme == QuranTheme.dark;
    final isCream = _currentTheme == QuranTheme.cream;
    final cardBg = isDark ? const Color(0xFF14201C) : (isCream ? const Color(0xFFFFFDF7) : Colors.white);
    final textColor = isDark ? Colors.white : const Color(0xFF152A24);
    final borderColor = AppTheme.getBorderColor(_currentTheme);

    final List<Map<String, dynamic>> engines = [
      {
        'id': 'gemini',
        'name': 'Google Gemini',
        'icon': Icons.auto_awesome_rounded,
        'color': const Color(0xFF4285F4),
        'scheme': 'googleapp://',
        'package': 'com.google.android.googlequicksearchbox',
        'altPackage': 'com.google.android.apps.bard',
        'webUrl': 'https://gemini.google.com/app',
        'isDefault': true,
      },
      {
        'id': 'deepseek',
        'name': 'DeepSeek',
        'icon': Icons.explore_outlined,
        'color': const Color(0xFF1E88E5),
        'scheme': 'deepseek://',
        'package': 'com.deepseek.chat',
        'webUrl': 'https://chat.deepseek.com/',
      },
      {
        'id': 'chatgpt',
        'name': 'ChatGPT',
        'icon': Icons.chat_bubble_outline_rounded,
        'color': const Color(0xFF10A37F),
        'scheme': 'chatgpt://',
        'package': 'com.openai.chatgpt',
        'webUrl': 'https://chatgpt.com/?q=',
      },
      {
        'id': 'claude',
        'name': 'Claude AI',
        'icon': Icons.psychology_outlined,
        'color': const Color(0xFFD97706),
        'scheme': 'claude://',
        'package': 'com.anthropic.claude',
        'webUrl': 'https://claude.ai/new',
      },
      {
        'id': 'grok',
        'name': 'Grok (X)',
        'icon': Icons.flare_rounded,
        'color': const Color(0xFF1DA1F2),
        'scheme': 'twitter://',
        'package': 'com.x.android',
        'webUrl': 'https://x.com/i/grok',
      },
      {
        'id': 'kimi',
        'name': 'Kimi AI',
        'icon': Icons.bubble_chart_rounded,
        'color': const Color(0xFF673AB7),
        'scheme': 'kimi://',
        'package': 'com.moonshot.kimichat',
        'webUrl': 'https://kimi.moonshot.cn/',
      },
      {
        'id': 'copilot',
        'name': 'Copilot (Bing)',
        'icon': Icons.hub_outlined,
        'color': const Color(0xFF0078D4),
        'scheme': 'ms-copilot://',
        'package': 'com.microsoft.copilot',
        'altPackage': 'com.microsoft.bing',
        'webUrl': 'https://copilot.microsoft.com/?q=',
      },
      {
        'id': 'perplexity',
        'name': 'Perplexity',
        'icon': Icons.travel_explore_rounded,
        'color': const Color(0xFF20B2AA),
        'scheme': 'perplexity://',
        'package': 'ai.perplexity.app.android',
        'webUrl': 'https://www.perplexity.ai/search?q=',
      },
    ];

    final TextEditingController quoteController = TextEditingController(text: selectedText);
    String selectedEngineId = 'gemini';
    bool showAllEngines = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FutureBuilder<Map<String, bool>>(
              future: _detectInstalledAiApps(engines),
              builder: (context, snapshot) {
                final installedMap = snapshot.data ?? {};

                // Dynamic Discovery: Show only discovered installed AI apps + Gemini as default!
                final discoveredEngines = engines.where((e) {
                  final id = e['id'] as String;
                  if (id == 'gemini') return true; // Gemini always present
                  return installedMap[id] == true; // Only if installed on phone!
                }).toList();

                final visibleEngines = showAllEngines ? engines : discoveredEngines;

                // Ensure selection is valid
                if (!visibleEngines.any((e) => e['id'] == selectedEngineId)) {
                  selectedEngineId = visibleEngines.first['id'] as String;
                }

                return Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
                  padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border.all(color: borderColor.withValues(alpha: 0.35)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF9C27B0).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF9C27B0), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isArabic ? 'المساعد الذكي (AI Assistant)' : 'AI Smart Assistant',
                                    style: TextStyle(
                                      fontFamily: isArabic ? 'Amiri' : null,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.5,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    isArabic
                                        ? 'تم اكتشاف التطبيقات المثبتة على هاتفك تلقائياً'
                                        : 'Automatically discovered installed AI apps on your phone',
                                    style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.65)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Editable Excerpt Box
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isArabic ? 'النص المقتبس (يمكنك تعديله هنا):' : 'Selected Excerpt (editable):',
                              style: TextStyle(
                                fontFamily: isArabic ? 'Amiri' : null,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                color: textColor.withValues(alpha: 0.85),
                              ),
                            ),
                            if (quoteController.text.isNotEmpty)
                              InkWell(
                                onTap: () {
                                  setModalState(() {
                                    quoteController.clear();
                                  });
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Text(
                                    isArabic ? 'مسح النص' : 'Clear',
                                    style: const TextStyle(fontSize: 11, color: Colors.redAccent),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF7F5EE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor.withValues(alpha: 0.3)),
                          ),
                          child: TextField(
                            controller: quoteController,
                            maxLines: 4,
                            minLines: 2,
                            style: TextStyle(
                              fontFamily: isArabic ? 'Amiri' : null,
                              fontSize: 13,
                              color: textColor,
                              height: 1.35,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(12),
                              border: InputBorder.none,
                              hintText: isArabic ? 'اكتب أو عدل النص المقتبس هنا...' : 'Type or edit excerpt here...',
                              hintStyle: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.4)),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // AI Engine Selection Row (Discovered Engines)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isArabic ? 'التطبيقات المكتشفة على الهاتف:' : 'Discovered AI Apps on Phone:',
                              style: TextStyle(
                                fontFamily: isArabic ? 'Amiri' : null,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: textColor.withValues(alpha: 0.85),
                              ),
                            ),
                            if (engines.length > discoveredEngines.length)
                              InkWell(
                                onTap: () {
                                  setModalState(() {
                                    showAllEngines = !showAllEngines;
                                  });
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  child: Text(
                                    showAllEngines
                                        ? (isArabic ? 'المكتشفة فقط' : 'Discovered only')
                                        : (isArabic ? '+ المزيد (ويب)' : '+ More (Web)'),
                                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF2196F3), fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Discovered AI Cards Row
                        Row(
                          children: visibleEngines.map((eng) {
                            final bool isSelected = eng['id'] == selectedEngineId;
                            final bool isInstalled = installedMap[eng['id']] ?? false;
                            final Color brandColor = eng['color'] as Color;

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: InkWell(
                                  onTap: () {
                                    setModalState(() => selectedEngineId = eng['id'] as String);
                                    HapticFeedback.selectionClick();
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? brandColor.withValues(alpha: 0.16)
                                          : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? brandColor : (isDark ? Colors.white12 : Colors.black12),
                                        width: isSelected ? 1.8 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(eng['icon'] as IconData, size: 20, color: brandColor),
                                        const SizedBox(height: 4),
                                        Text(
                                          eng['name'] as String,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                            color: isSelected ? brandColor : textColor.withValues(alpha: 0.8),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: isInstalled
                                                ? const Color(0xFF1B8A6B).withValues(alpha: 0.15)
                                                : Colors.grey.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            isInstalled
                                                ? (isArabic ? 'مثبت' : 'Installed')
                                                : (isArabic ? 'ويب' : 'Web'),
                                            style: TextStyle(
                                              fontSize: 8,
                                              fontWeight: FontWeight.bold,
                                              color: isInstalled ? const Color(0xFF1B8A6B) : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 18),

                        // Prompt presets
                        Text(
                          isArabic ? 'اختر موضوع السؤال المطلوب:' : 'Select Question Type:',
                          style: TextStyle(
                            fontFamily: isArabic ? 'Amiri' : null,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: textColor.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 8),

                        _buildAiPromptTile(
                          icon: Icons.menu_book_rounded,
                          title: isArabic ? 'شرح وتفسير المعنى والمقاصد' : 'Explain Meaning & Key Concepts',
                          subtitle: isArabic ? 'بيان الدلالات الفقهية والمعنوية للنص' : 'Detailed analysis and practical takeaways',
                          isDark: isDark,
                          textColor: textColor,
                          onTap: () {
                            final currentQuote = quoteController.text.trim().isEmpty ? selectedText : quoteController.text.trim();
                            final question = isArabic
                                ? 'اشرح لي بالتفصيل المعنى والمقاصد والفوائد المستنبطة من هذا النص'
                                : 'Please explain in detail the meaning, context, and key takeaways of this excerpt';
                            _launchSelectedAi(selectedEngineId, engines, question, currentQuote, ctx, isArabic);
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildAiPromptTile(
                          icon: Icons.spellcheck_rounded,
                          title: isArabic ? 'معاني الألفاظ الغريبة والإعراب' : 'Vocabulary, Grammar & Eloquence',
                          subtitle: isArabic ? 'توضيح المفردات اللغوية والتركيب النحوي' : 'Linguistic definitions and grammatical breakdown',
                          isDark: isDark,
                          textColor: textColor,
                          onTap: () {
                            final currentQuote = quoteController.text.trim().isEmpty ? selectedText : quoteController.text.trim();
                            final question = isArabic
                                ? 'وضح لي معاني الكلمات الغريبة والتركيب البلاغي والإعرابي لهذا النص'
                                : 'Please explain difficult words, grammatical structure, and eloquence of this text';
                            _launchSelectedAi(selectedEngineId, engines, question, currentQuote, ctx, isArabic);
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildAiPromptTile(
                          icon: Icons.verified_outlined,
                          title: isArabic ? 'تخريج وتحقيق المسألة أو الحديث' : 'Authentication & Scholarly References',
                          subtitle: isArabic ? 'معرفة أصل الرواية والمصادر المعتمدة' : 'Sources, authenticity, and scholars opinions',
                          isDark: isDark,
                          textColor: textColor,
                          onTap: () {
                            final currentQuote = quoteController.text.trim().isEmpty ? selectedText : quoteController.text.trim();
                            final question = isArabic
                                ? 'خرج لي هذا النص واذكر مصادره وصحته وأقوال العلماء فيه'
                                : 'Please provide scholarly authentication, sources, and verified commentary for this text';
                            _launchSelectedAi(selectedEngineId, engines, question, currentQuote, ctx, isArabic);
                          },
                        ),

                        const SizedBox(height: 16),
                        // Direct Ask Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (engines.firstWhere((e) => e['id'] == selectedEngineId)['color'] as Color),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 18),
                          label: Text(
                            isArabic
                                ? 'إرسال إلى ${engines.firstWhere((e) => e['id'] == selectedEngineId)['name']} مباشرة ↗'
                                : 'Send to ${engines.firstWhere((e) => e['id'] == selectedEngineId)['name']} Now ↗',
                            style: TextStyle(
                              fontFamily: isArabic ? 'Amiri' : null,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          onPressed: () {
                            final currentQuote = quoteController.text.trim().isEmpty ? selectedText : quoteController.text.trim();
                            final question = isArabic
                                ? 'اشرح لي هذا النص من كتاب "${widget.book.title}" شرحاً وافياً وميسراً'
                                : 'Please explain this passage from the book "${widget.book.title}" thoroughly and clearly';
                            _launchSelectedAi(selectedEngineId, engines, question, currentQuote, ctx, isArabic);
                          },
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
    );
  }

  Future<Map<String, bool>> _detectInstalledAiApps(List<Map<String, dynamic>> engines) async {
    final Map<String, bool> result = {};

    // 1. Query native Android system for all PROCESS_TEXT apps and installed packages!
    List<dynamic> nativeProcessTextApps = [];
    try {
      const systemChannel = MethodChannel('com.umer.quranzone/system_actions');
      final list = await systemChannel.invokeMethod<List<dynamic>>('getProcessTextApps');
      if (list != null) nativeProcessTextApps = list;
    } catch (_) {}

    final Set<String> nativePackages = {};
    for (final item in nativeProcessTextApps) {
      if (item is Map) {
        final pkg = item['packageName']?.toString().toLowerCase() ?? '';
        if (pkg.isNotEmpty) nativePackages.add(pkg);
      }
    }

    for (final eng in engines) {
      final id = eng['id'] as String;
      final package = (eng['package'] ?? '') as String;
      final altPackage = (eng['altPackage'] ?? '') as String;
      final scheme = (eng['scheme'] ?? '') as String;
      bool isInstalled = false;

      // 1. Check native PROCESS_TEXT query from Android OS
      if (nativePackages.isNotEmpty) {
        if (package.isNotEmpty && nativePackages.contains(package.toLowerCase())) {
          isInstalled = true;
        } else if (altPackage.isNotEmpty && nativePackages.contains(altPackage.toLowerCase())) {
          isInstalled = true;
        }
      }

      // 2. Check native PackageManager isPackageInstalled
      if (!isInstalled && package.isNotEmpty) {
        try {
          const systemChannel = MethodChannel('com.umer.quranzone/system_actions');
          final isPkg = await systemChannel.invokeMethod<bool>('isPackageInstalled', {'packageName': package});
          if (isPkg == true) isInstalled = true;
        } catch (_) {}
      }
      if (!isInstalled && altPackage.isNotEmpty) {
        try {
          const systemChannel = MethodChannel('com.umer.quranzone/system_actions');
          final isPkg = await systemChannel.invokeMethod<bool>('isPackageInstalled', {'packageName': altPackage});
          if (isPkg == true) isInstalled = true;
        } catch (_) {}
      }

      // 3. Check ACTION_PROCESS_TEXT intent capability via url_launcher (Dart)
      if (!isInstalled && package.isNotEmpty) {
        try {
          final processTestUri = Uri.parse(
            'intent:#Intent;action=android.intent.action.PROCESS_TEXT;type=text/plain;package=$package;end',
          );
          if (await canLaunchUrl(processTestUri)) {
            isInstalled = true;
          }
        } catch (_) {}
      }

      // 4. Check ACTION_SEND intent capability via url_launcher (Dart)
      if (!isInstalled && package.isNotEmpty) {
        try {
          final sendTestUri = Uri.parse(
            'intent:#Intent;action=android.intent.action.SEND;type=text/plain;package=$package;end',
          );
          if (await canLaunchUrl(sendTestUri)) {
            isInstalled = true;
          }
        } catch (_) {}
      }

      // 5. Check native URL scheme
      if (!isInstalled && scheme.isNotEmpty) {
        try {
          if (await canLaunchUrl(Uri.parse(scheme))) {
            isInstalled = true;
          }
        } catch (_) {}
      }

      // Gemini is always available on all Android phones
      if (!isInstalled && id == 'gemini') {
        isInstalled = true;
      }

      result[id] = isInstalled;
    }
    return result;
  }

  void _launchSelectedAi(
    String engineId,
    List<Map<String, dynamic>> engines,
    String question,
    String quote,
    BuildContext sheetCtx,
    bool isArabic,
  ) async {
    Navigator.pop(sheetCtx);

    final fullPrompt = isArabic
        ? '$question\n\nالنص المقتبس من كتاب "${widget.book.title}":\n"$quote"'
        : '$question\n\nExcerpt from the book "${widget.book.title}":\n"$quote"';

    // 1. Always copy prompt to clipboard so user has a 100% backup
    await Clipboard.setData(ClipboardData(text: fullPrompt));

    final engine = engines.firstWhere((e) => e['id'] == engineId, orElse: () => engines.first);
    final String engineName = engine['name'] as String;
    final String webUrlTemplate = engine['webUrl'] as String;
    final String appScheme = (engine['scheme'] ?? '') as String;
    final String package = (engine['package'] ?? '') as String;
    final String altPackage = (engine['altPackage'] ?? '') as String;

    bool launched = false;

    // 2. Priority 1: Launch Android native ACTION_PROCESS_TEXT via system channel!
    // This injects the text directly into the AI prompt box (Gemini, DeepSeek, ChatGPT, Claude, Grok, Kimi)!
    if (package.isNotEmpty) {
      try {
        const systemChannel = MethodChannel('com.umer.quranzone/system_actions');
        final res = await systemChannel.invokeMethod<bool>('launchProcessText', {
          'packageName': package,
          'text': fullPrompt,
        });
        if (res == true) launched = true;
      } catch (_) {}

      // Try altPackage (e.g. Gemini bard vs quicksearchbox)
      if (!launched && altPackage.isNotEmpty) {
        try {
          const systemChannel = MethodChannel('com.umer.quranzone/system_actions');
          final res = await systemChannel.invokeMethod<bool>('launchProcessText', {
            'packageName': altPackage,
            'text': fullPrompt,
          });
          if (res == true) launched = true;
        } catch (_) {}
      }
    }

    // 3. Priority 2: Dart PROCESS_TEXT Intent via url_launcher
    if (!launched && package.isNotEmpty) {
      try {
        final processUri = Uri.parse(
          'intent:#Intent;action=android.intent.action.PROCESS_TEXT;type=text/plain;S.android.intent.extra.PROCESS_TEXT=${Uri.encodeQueryComponent(fullPrompt)};B.android.intent.extra.PROCESS_TEXT_READONLY=true;package=$package;end',
        );
        if (await canLaunchUrl(processUri)) {
          launched = await launchUrl(processUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }
    if (!launched && altPackage.isNotEmpty) {
      try {
        final processUri = Uri.parse(
          'intent:#Intent;action=android.intent.action.PROCESS_TEXT;type=text/plain;S.android.intent.extra.PROCESS_TEXT=${Uri.encodeQueryComponent(fullPrompt)};B.android.intent.extra.PROCESS_TEXT_READONLY=true;package=$altPackage;end',
        );
        if (await canLaunchUrl(processUri)) {
          launched = await launchUrl(processUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }

    // 4. Priority 3: Dart ACTION_SEND Intent via url_launcher
    if (!launched && package.isNotEmpty) {
      try {
        final encodedText = Uri.encodeQueryComponent(fullPrompt);
        final sendIntentUri = Uri.parse(
          'intent:#Intent;action=android.intent.action.SEND;type=text/plain;S.android.intent.extra.TEXT=$encodedText;package=$package;end',
        );
        if (await canLaunchUrl(sendIntentUri)) {
          launched = await launchUrl(sendIntentUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }

    // 5. Priority 4: Web URL with pre-filled query parameter (for ChatGPT, Copilot, Perplexity)
    if (!launched) {
      Uri? prefillUrl;
      if (engineId == 'chatgpt') {
        prefillUrl = Uri.parse('https://chatgpt.com/?q=${Uri.encodeComponent(fullPrompt)}');
      } else if (engineId == 'copilot') {
        prefillUrl = Uri.parse('https://copilot.microsoft.com/?q=${Uri.encodeComponent(fullPrompt)}');
      } else if (engineId == 'perplexity') {
        prefillUrl = Uri.parse('https://www.perplexity.ai/search?q=${Uri.encodeComponent(fullPrompt)}');
      }

      if (prefillUrl != null) {
        try {
          launched = await launchUrl(prefillUrl, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }
    }

    // 6. Priority 5: Native scheme fallback (e.g. chatgpt://, deepseek://)
    if (!launched && appScheme.isNotEmpty) {
      try {
        final schemeUri = Uri.parse(appScheme);
        if (await canLaunchUrl(schemeUri)) {
          launched = await launchUrl(schemeUri, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }

    // 7. Priority 6: Web fallback
    if (!launched) {
      final targetWebUrl = Uri.parse(webUrlTemplate.replaceAll('?q=', ''));
      try {
        launched = await launchUrl(targetWebUrl, mode: LaunchMode.externalApplication);
        if (!launched) {
          await launchUrl(targetWebUrl, mode: LaunchMode.platformDefault);
        }
      } catch (_) {}
    }

    if (mounted) {
      final String toastMsg;
      if (engineId == 'gemini') {
        toastMsg = isArabic
            ? 'تم فتح Gemini مع إدراج النص المقتبس'
            : 'Opened Gemini with prompt injected';
      } else {
        toastMsg = isArabic
            ? 'تم فتح $engineName مع إدراج النص المقتبس'
            : 'Opened $engineName with prompt ready';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  toastMsg,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1B8A6B),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Widget _buildAiPromptTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF9C27B0)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold, fontSize: 13.5, color: textColor)),
                  Text(subtitle, style: TextStyle(fontSize: 10.5, color: textColor.withValues(alpha: 0.6))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 12, color: textColor.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  // ── Multilingual Translation with Language Choice ─────────────────────────
  static const List<Map<String, String>> _kTranslationLanguages = [
    {'code': 'ar', 'nameAr': 'العربية', 'nameEn': 'Arabic', 'flag': '🇸🇦'},
    {'code': 'en', 'nameAr': 'الإنجليزية', 'nameEn': 'English', 'flag': '🇬🇧'},
    {'code': 'am', 'nameAr': 'الأمهرية', 'nameEn': 'Amharic', 'flag': '🇪🇹'},
    {'code': 'om', 'nameAr': 'الأورومية', 'nameEn': 'Oromo', 'flag': '🇪🇹'},
    {'code': 'fr', 'nameAr': 'الفرنسية', 'nameEn': 'French', 'flag': '🇫🇷'},
    {'code': 'tr', 'nameAr': 'التركية', 'nameEn': 'Turkish', 'flag': '🇹🇷'},
    {'code': 'ur', 'nameAr': 'الأوردية', 'nameEn': 'Urdu', 'flag': '🇵🇰'},
    {'code': 'id', 'nameAr': 'الإندونيسية', 'nameEn': 'Indonesian', 'flag': '🇮🇩'},
    {'code': 'de', 'nameAr': 'الألمانية', 'nameEn': 'German', 'flag': '🇩🇪'},
    {'code': 'es', 'nameAr': 'الإسبانية', 'nameEn': 'Spanish', 'flag': '🇪🇸'},
    {'code': 'ru', 'nameAr': 'الروسية', 'nameEn': 'Russian', 'flag': '🇷🇺'},
  ];

  void _showTranslateBottomSheet(String selectedText) {
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final isArabicUi = locale == 'ar';
    final isDark = _currentTheme == QuranTheme.dark;
    final isCream = _currentTheme == QuranTheme.cream;
    final cardBg = isDark ? const Color(0xFF14201C) : (isCream ? const Color(0xFFFFFDF7) : Colors.white);
    final textColor = isDark ? Colors.white : const Color(0xFF152A24);
    final borderColor = AppTheme.getBorderColor(_currentTheme);

    final TextEditingController sourceController = TextEditingController(text: selectedText);
    final bool isSourceArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(selectedText);
    String targetLang = isSourceArabic ? 'en' : 'ar';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentSource = sourceController.text.trim().isEmpty ? selectedText : sourceController.text.trim();

            return FutureBuilder<String>(
              future: _fetchTranslation(currentSource, targetLang),
              builder: (context, snapshot) {
                final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
                final String translation = snapshot.data ?? (snapshot.hasError ? (isArabicUi ? 'تعذر جلب الترجمة، تحقق من اتصال الإنترنت.' : 'Translation failed, check internet.') : '');

                return Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
                  padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    border: Border.all(color: borderColor.withValues(alpha: 0.35)),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2196F3).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.g_translate_rounded, color: Color(0xFF2196F3), size: 22),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isArabicUi ? 'الترجمة الفورية' : 'Instant Translation',
                                style: TextStyle(
                                  fontFamily: isArabicUi ? 'Amiri' : null,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.5,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Editable Source Text
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isArabicUi ? 'النص الأصلي (يمكنك تعديله هنا):' : 'Source Text (editable):',
                              style: TextStyle(
                                fontFamily: isArabicUi ? 'Amiri' : null,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                                color: textColor.withValues(alpha: 0.85),
                              ),
                            ),
                            Row(
                              children: [
                                if (sourceController.text.isNotEmpty)
                                  InkWell(
                                    onTap: () {
                                      setModalState(() {
                                        sourceController.clear();
                                      });
                                    },
                                    borderRadius: BorderRadius.circular(6),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      child: Text(
                                        isArabicUi ? 'مسح' : 'Clear',
                                        style: const TextStyle(fontSize: 11, color: Colors.redAccent),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    setModalState(() {});
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.refresh_rounded, size: 13, color: Color(0xFF2196F3)),
                                        const SizedBox(width: 2),
                                        Text(
                                          isArabicUi ? 'تحديث' : 'Refresh',
                                          style: const TextStyle(fontSize: 11, color: Color(0xFF2196F3), fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF7F5EE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor.withValues(alpha: 0.3)),
                          ),
                          child: TextField(
                            controller: sourceController,
                            maxLines: 4,
                            minLines: 2,
                            style: TextStyle(
                              fontFamily: isSourceArabic ? 'Amiri' : null,
                              fontSize: 13,
                              color: textColor,
                              height: 1.35,
                            ),
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.all(12),
                              border: InputBorder.none,
                              hintText: isArabicUi ? 'اكتب أو عدل النص هنا للترجمة...' : 'Type or edit text here to translate...',
                              hintStyle: TextStyle(fontSize: 12, color: textColor.withValues(alpha: 0.4)),
                            ),
                            onSubmitted: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Language Selection Row
                        Text(
                          isArabicUi ? 'اختر لغة الترجمة:' : 'Select Target Language:',
                          style: TextStyle(
                            fontFamily: isArabicUi ? 'Amiri' : null,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: textColor.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Dropdown Selector (Vertical selection instead of horizontal chips)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.4), width: 1.2),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: targetLang,
                              isExpanded: true,
                              dropdownColor: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              icon: const Icon(Icons.arrow_drop_down_circle_outlined, color: Color(0xFF2196F3), size: 20),
                              items: _kTranslationLanguages.map((lang) {
                                final isSelected = lang['code'] == targetLang;
                                return DropdownMenuItem<String>(
                                  value: lang['code'],
                                  child: Row(
                                    children: [
                                      Text(lang['flag']!, style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 10),
                                      Text(
                                        isArabicUi ? lang['nameAr']! : lang['nameEn']!,
                                        style: TextStyle(
                                          fontFamily: isArabicUi ? 'Amiri' : null,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          fontSize: 13.5,
                                          color: isSelected ? const Color(0xFF2196F3) : textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isArabicUi ? '(${lang['nameEn']})' : '(${lang['nameAr']})',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textColor.withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (newLang) {
                                if (newLang != null && newLang != targetLang) {
                                  setModalState(() {
                                    targetLang = newLang;
                                  });
                                  HapticFeedback.selectionClick();
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Translated Text Result Box
                        Container(
                          constraints: const BoxConstraints(minHeight: 80),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.25)),
                          ),
                          child: isLoading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(14.0),
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2196F3)),
                                    ),
                                  ),
                                )
                              : SelectableText(
                                  translation,
                                  style: TextStyle(
                                    fontFamily: (targetLang == 'ar' || targetLang == 'ur') ? 'Amiri' : null,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                    height: 1.45,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),

                        // Copy Translation Button
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.copy_rounded, size: 17),
                          label: Text(
                            isArabicUi ? 'نسخ الترجمة إلى الحافظة' : 'Copy Translation to Clipboard',
                            style: TextStyle(fontFamily: isArabicUi ? 'Amiri' : null, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          onPressed: translation.isEmpty || isLoading
                              ? null
                              : () {
                                  Clipboard.setData(ClipboardData(text: translation));
                                  Navigator.pop(ctx);
                                  HapticFeedback.lightImpact();
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text(isArabicUi ? 'تم نسخ الترجمة بنجاح' : 'Translation copied successfully'),
                                      backgroundColor: const Color(0xFF2196F3),
                                      behavior: SnackBarBehavior.floating,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                },
                        ),
                        const SizedBox(height: 8),

                        // Open in Google Translate App (Supports offline models)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2196F3),
                            side: const BorderSide(color: Color(0xFF2196F3), width: 1.2),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.open_in_new_rounded, size: 16),
                          label: Text(
                            isArabicUi ? 'فتح في تطبيق ترجمة Google ↗' : 'Open in Google Translate App ↗',
                            style: TextStyle(
                              fontFamily: isArabicUi ? 'Amiri' : null,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          onPressed: () async {
                            final currentText = sourceController.text.trim().isEmpty ? selectedText : sourceController.text.trim();
                            Navigator.pop(ctx);
                            const String translatePackage = 'com.google.android.apps.translate';
                            bool launched = false;
                            try {
                              final sendUri = Uri.parse(
                                'intent:#Intent;action=android.intent.action.SEND;type=text/plain;S.android.intent.extra.TEXT=${Uri.encodeQueryComponent(currentText)};package=$translatePackage;end',
                              );
                              if (await canLaunchUrl(sendUri)) {
                                launched = await launchUrl(sendUri, mode: LaunchMode.externalApplication);
                              }
                            } catch (_) {}

                            if (!launched) {
                              try {
                                final webUri = Uri.parse('https://translate.google.com/?sl=auto&tl=$targetLang&text=${Uri.encodeComponent(currentText)}');
                                await launchUrl(webUri, mode: LaunchMode.externalApplication);
                              } catch (_) {}
                            }
                          },
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
    );
  }

  Future<String> _fetchTranslation(String text, String targetLang) async {
    try {
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=$targetLang&dt=t&q=${Uri.encodeComponent(text)}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final List<dynamic> decoded = jsonDecode(response.body);
        if (decoded.isNotEmpty && decoded[0] is List) {
          final buffer = StringBuffer();
          for (final part in (decoded[0] as List)) {
            if (part is List && part.isNotEmpty && part[0] != null) {
              buffer.write(part[0].toString());
            }
          }
          return buffer.toString().trim();
        }
      }
      return 'تعذر إتمام الترجمة';
    } catch (e) {
      return 'خطأ في الاتصال بخدمة الترجمة';
    }
  }

  // ── Syncfusion PDF Viewer Widget ───────────────────────────────────────────
  Widget _buildPdfViewer(bool isDark, bool isCream) {
    final viewer = SfPdfViewer.file(
      File(widget.book.filePath),
      key: _pdfViewerKey,
      controller: _pdfViewerController,
      initialPageNumber: _currentPage > 0 ? _currentPage : 1, // Directly load the exact page stopped at on frame 1!
      canShowScrollHead: false, // Disabling heavy internal overlay avoids frame drops on 300+ pages
      canShowScrollStatus: false, // Replaced with smooth bottom scrubber matching Screenshot 3
      canShowPaginationDialog: false,
      canShowTextSelectionMenu: false, // Disable built-in Syncfusion menu to avoid overlapping
      enableTextSelection: true,
      pageSpacing: 4.0,
      // Tap anywhere on the page to toggle controls (Clean reading mode vs customization)
      onTap: (PdfGestureDetails details) {
        HapticFeedback.lightImpact();
        _hideContextMenu();
        setState(() {
          _controlsVisible = !_controlsVisible;
          if (!_controlsVisible && _isSearchActive) {
            _isSearchActive = false;
            _searchResult.clear();
            _searchFieldController.clear();
          }
        });
      },
      onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
        if (details.selectedText == null || details.selectedText!.trim().isEmpty) {
          _hideContextMenu();
        } else {
          _showFloatingContextMenu(details);
        }
      },
      onAnnotationSelected: (Annotation annotation) {
        _showAnnotationActionDialog(annotation);
      },
      pageLayoutMode: _isSwipeHorizontal ? PdfPageLayoutMode.single : PdfPageLayoutMode.continuous,
      scrollDirection: _isSwipeHorizontal ? PdfScrollDirection.horizontal : PdfScrollDirection.vertical,
      currentSearchTextHighlightColor: const Color(0xFFECC94B).withValues(alpha: 0.7),
      otherSearchTextHighlightColor: const Color(0xFFECC94B).withValues(alpha: 0.35),
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        if (mounted) {
          _totalPages = details.document.pages.count;
          _pageNotifier.value = _currentPage;
          _loadPersistentAnnotations();
          setState(() {});
        }
      },
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        if (mounted) {
          setState(() {
            _errorMessage = details.description;
          });
        }
      },
      onPageChanged: (PdfPageChangedDetails details) {
        _currentPage = details.newPageNumber;
        _pageNotifier.value = details.newPageNumber;
        _saveProgressThrottled();
      },
    );

    // Instant GPU-accelerated theme filter (0ms delay, zero unmounting/rebuilding)
    return ColorFiltered(
      colorFilter: isDark
          ? _kInvertColorFilter
          : (isCream ? _kCreamColorFilter : _kIdentityColorFilter),
      child: viewer,
    );
  }

  // ── In-App Search Toolbar ──────────────────────────────────────────────────
  Widget _buildSearchToolbar(bool isDark, bool isCream) {
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final cardBg = isDark ? const Color(0xFF162320) : (isCream ? const Color(0xFFFFFDF8) : Colors.white);
    final textColor = isDark ? Colors.white : const Color(0xFF152A24);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(_currentTheme).withValues(alpha: 0.4), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF1B8A6B), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchFieldController,
              autofocus: true,
              style: TextStyle(color: textColor, fontSize: 13.5),
              decoration: InputDecoration(
                hintText: locale == 'ar' ? 'بحث في نصوص الكتاب...' : 'Search in book text...',
                hintStyle: TextStyle(color: textColor.withValues(alpha: 0.45), fontSize: 12.5),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (query) {
                if (query.trim().isNotEmpty) {
                  _searchResult = _pdfViewerController.searchText(query.trim());
                  _searchResult.addListener(() {
                    if (mounted) setState(() {});
                  });
                }
              },
            ),
          ),

          // Matches Counter
          if (_searchResult.hasResult)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '${_searchResult.currentInstanceIndex}/${_searchResult.totalInstanceCount}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B8A6B),
                ),
              ),
            ),

          // Previous Match
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 20),
            color: textColor,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: _searchResult.hasResult ? () => _searchResult.previousInstance() : null,
          ),

          // Next Match
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            color: textColor,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: _searchResult.hasResult ? () => _searchResult.nextInstance() : null,
          ),

          // Close Search
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18),
            color: textColor.withValues(alpha: 0.6),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            onPressed: () {
              _searchResult.clear();
              _searchFieldController.clear();
              setState(() => _isSearchActive = false);
            },
          ),
        ],
      ),
    );
  }

  // ── Top App Bar ────────────────────────────────────────────────────────────
  Widget _buildTopBar(QuranTheme theme) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final bool isDark = theme == QuranTheme.dark;
    final bool isCream = theme == QuranTheme.cream;
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';

    final Color barBg = isDark
        ? const Color(0xFF121B19).withValues(alpha: 0.96)
        : (isCream ? const Color(0xFFFFFDF8).withValues(alpha: 0.96) : Colors.white.withValues(alpha: 0.96));

    final Color textColor = isDark
        ? const Color(0xFFF0F4F0)
        : (isCream ? const Color(0xFF2C1C11) : const Color(0xFF0F382C));

    final Color borderColor = AppTheme.getBorderColor(theme);
    final Color primaryColor = AppTheme.getPrimaryColor(theme);


    final String nextTooltip = isDark
        ? (locale == 'ar' ? 'التحويل للوضع الورقي الدافئ' : 'Switch to Warm Cream')
        : (isCream
            ? (locale == 'ar' ? 'التحويل للوضع الأبيض الناصع' : 'Switch to Crisp White')
            : (locale == 'ar' ? 'التحويل للوضع الليلي الداكن' : 'Switch to Night Mode'));

    // Distinct, prominent visual theme badge showing the exact theme color
    final Widget themeBadge;
    if (isDark) {
      themeBadge = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFF14201C),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFECC94B), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFECC94B).withValues(alpha: 0.35),
              blurRadius: 5,
            ),
          ],
        ),
        child: const Icon(Icons.dark_mode_rounded, color: Color(0xFFECC94B), size: 16),
      );
    } else if (isCream) {
      themeBadge = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFEADBBE), // Noticeable rich warm parchment cream!
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF9E782F), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC9A84C).withValues(alpha: 0.35),
              blurRadius: 5,
            ),
          ],
        ),
        child: const Icon(Icons.auto_stories_rounded, color: Color(0xFF6B4E1B), size: 16),
      );
    } else {
      themeBadge = Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF1B8A6B), width: 1.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 5,
            ),
          ],
        ),
        child: const Icon(Icons.light_mode_rounded, color: Color(0xFF1B8A6B), size: 16),
      );
    }

    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.fromLTRB(4, topPadding + 2, 8, 4),
        decoration: BoxDecoration(
          color: barBg,
          border: Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.3), width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Back Action
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 18),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 34),
              padding: EdgeInsets.zero,
              onPressed: () {
                _saveProgressDebounce?.cancel();
                _saveProgressImmediate();
                Navigator.pop(context);
              },
            ),

            // Book Title (Single compact line - Tapping opens book details)
            Expanded(
              child: InkWell(
                onTap: _showBookInfoSheet,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Text(
                    widget.book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ),
              ),
            ),

            // 1. Search in PDF Button
            IconButton(
              tooltip: locale == 'ar' ? 'بحث في نصوص الكتاب' : 'Search in Book',
              constraints: const BoxConstraints(minWidth: 30, minHeight: 34),
              padding: EdgeInsets.zero,
              icon: Icon(
                _isSearchActive ? Icons.search_off_rounded : Icons.search_rounded,
                color: _isSearchActive ? const Color(0xFFECC94B) : textColor.withValues(alpha: 0.85),
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isSearchActive = !_isSearchActive;
                  if (!_isSearchActive) {
                    _searchResult.clear();
                    _searchFieldController.clear();
                  }
                });
              },
            ),

            // 2. Visual Page Grid Navigator (تصفح جميع الصفحات)
            IconButton(
              tooltip: locale == 'ar' ? 'تصفح الصفحات' : 'Browse Pages',
              constraints: const BoxConstraints(minWidth: 30, minHeight: 34),
              padding: EdgeInsets.zero,
              icon: Icon(
                Icons.grid_view_rounded,
                color: textColor.withValues(alpha: 0.85),
                size: 19,
              ),
              onPressed: _showPageGridBrowser,
            ),

            // 3. Visual Bookmark Button (Live reactive to current page)
            ValueListenableBuilder<int>(
              valueListenable: _pageNotifier,
              builder: (context, page, _) {
                final isBookmarked = _bookmarkedPages.contains(page);
                return IconButton(
                  tooltip: isBookmarked
                      ? (locale == 'ar' ? 'إزالة الإشارة المرجعية' : 'Remove Bookmark')
                      : (locale == 'ar' ? 'إضافة إشارة مرجعية' : 'Add Bookmark'),
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 34),
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: isBookmarked ? const Color(0xFFECC94B) : textColor.withValues(alpha: 0.85),
                    size: 20,
                  ),
                  onPressed: _toggleBookmarkCurrentPage,
                );
              },
            ),

            // 4. Prominent Visual Theme Switcher (0ms instant GPU switch!)
            IconButton(
              tooltip: nextTooltip,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
              icon: themeBadge,
              onPressed: _cycleThemeInstantly,
            ),

            // 5. More Options Dropdown Menu (Scroll direction, Bookmarks, Share, Info)
            PopupMenuButton<String>(
              tooltip: locale == 'ar' ? 'خيارات إضافية' : 'More Options',
              icon: Icon(Icons.more_vert_rounded, color: textColor.withValues(alpha: 0.85), size: 20),
              color: barBg.withValues(alpha: 1.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 4,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 26, minHeight: 34),
              onSelected: (val) {
                if (val == 'direction') {
                  _toggleSwipeDirection();
                } else if (val == 'bookmarks') {
                  _showBookmarksListSheet();
                } else if (val == 'share') {
                  _shareBook();
                } else if (val == 'info') {
                  _showBookInfoSheet();
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'direction',
                  child: Row(
                    children: [
                      Icon(
                        _isSwipeHorizontal ? Icons.swap_vert_rounded : Icons.swap_horiz_rounded,
                        color: primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isSwipeHorizontal
                            ? (locale == 'ar' ? 'التحويل للتمرير الرأسي (مستمر)' : 'Switch to Vertical Continuous')
                            : (locale == 'ar' ? 'التحويل للتمرير الأفقي (صفحات)' : 'Switch to Horizontal Pages'),
                        style: TextStyle(
                          fontSize: 13.5,
                          color: textColor,
                          fontFamily: locale == 'ar' ? 'Amiri' : null,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'bookmarks',
                  child: Row(
                    children: [
                      const Icon(Icons.bookmarks_rounded, color: Color(0xFFECC94B), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        locale == 'ar' ? 'الإشارات المرجعية' : 'Bookmarks',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: textColor,
                          fontFamily: locale == 'ar' ? 'Amiri' : null,
                        ),
                      ),
                      if (_bookmarkedPages.isNotEmpty) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECC94B).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_bookmarkedPages.length}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFECC94B),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share_rounded, color: primaryColor, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        locale == 'ar' ? 'مشاركة الكتاب' : 'Share Book',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: textColor,
                          fontFamily: locale == 'ar' ? 'Amiri' : null,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'info',
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: textColor.withValues(alpha: 0.7), size: 18),
                      const SizedBox(width: 10),
                      Text(
                        locale == 'ar' ? 'معلومات الكتاب' : 'Book Info',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: textColor,
                          fontFamily: locale == 'ar' ? 'Amiri' : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Progress & Controls Bar (High Performance Scrubber Slider) ────
  Widget _buildBottomBar(QuranTheme theme) {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final bool isDark = theme == QuranTheme.dark;
    final bool isCream = theme == QuranTheme.cream;
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';

    final Color barBg = isDark
        ? const Color(0xFF121B19).withValues(alpha: 0.97)
        : (isCream ? const Color(0xFFFFFDF8).withValues(alpha: 0.97) : Colors.white.withValues(alpha: 0.97));

    final Color textColor = isDark
        ? const Color(0xFFF0F4F0)
        : (isCream ? const Color(0xFF2C1C11) : const Color(0xFF0F382C));

    final Color borderColor = AppTheme.getBorderColor(theme);
    final Color primaryColor = AppTheme.getPrimaryColor(theme);

    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 6, 16, bottomPadding + 6),
        decoration: BoxDecoration(
          color: barBg,
          border: Border(top: BorderSide(color: borderColor.withValues(alpha: 0.3), width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ValueListenableBuilder<int>(
          valueListenable: _pageNotifier,
          builder: (context, page, _) {
            final double maxP = (_totalPages > 0 ? _totalPages : 1).toDouble();
            final double currentVal = page.toDouble().clamp(1.0, maxP);
            final double progressPercent = _totalPages > 0 ? (page / _totalPages) : 0.0;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous Page Button
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 26),
                      color: textColor.withValues(alpha: page > 1 ? 0.9 : 0.25),
                      onPressed: page > 1
                          ? () {
                              final prev = page - 1;
                              _currentPage = prev;
                              _pageNotifier.value = prev;
                              _pdfViewerController.previousPage();
                              _saveProgressThrottled();
                            }
                          : null,
                    ),

                    // Page Indicator Pill (Tap to open Jump To Page Dialog) - Matches Screenshot 3 ("2 of 131")
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _showJumpToPageDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_bookmarkedPages.contains(page)) ...[
                              const Icon(Icons.bookmark_rounded, color: Color(0xFFECC94B), size: 14),
                              const SizedBox(width: 5),
                            ] else ...[
                              Icon(Icons.menu_book_rounded, color: primaryColor, size: 14),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              locale == 'ar'
                                  ? 'صفحة $page من ${_totalPages > 0 ? _totalPages : "..."}'
                                  : '$page of ${_totalPages > 0 ? _totalPages : "..."}',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Next Page Button
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 26),
                      color: textColor.withValues(alpha: (_totalPages <= 0 || page < _totalPages) ? 0.9 : 0.25),
                      onPressed: (_totalPages <= 0 || page < _totalPages)
                          ? () {
                              final nxt = page + 1;
                              _currentPage = nxt;
                              _pageNotifier.value = nxt;
                              _pdfViewerController.nextPage();
                              _saveProgressThrottled();
                            }
                          : null,
                    ),

                    // Percentage Text
                    Text(
                      '${(progressPercent * 100).toInt()}%',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.8),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                // Fast Scrub Slider (Scrub smoothly across 300+ pages like Screenshot 3!)
                if (_totalPages > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: primaryColor,
                        inactiveTrackColor: isDark ? Colors.white12 : Colors.black12,
                        thumbColor: primaryColor,
                        overlayColor: primaryColor.withValues(alpha: 0.15),
                        trackHeight: 3.5,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6.5),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                      ),
                      child: Slider(
                        value: currentVal,
                        min: 1.0,
                        max: maxP,
                        onChanged: (val) {
                          _pageNotifier.value = val.round();
                        },
                        onChangeEnd: (val) {
                          final target = val.round();
                          _currentPage = target;
                          _pdfViewerController.jumpToPage(target);
                          _saveProgressThrottled();
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── File Not Found View ────────────────────────────────────────────────────
  Widget _buildFileNotFoundView() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.file_copy_outlined, size: 54, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'الملف غير موجود في الذاكرة',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
              ),
              const SizedBox(height: 8),
              const Text(
                'قد يكون تم حذف الملف من الهاتف.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B8A6B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('رجوع'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
