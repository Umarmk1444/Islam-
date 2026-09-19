import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:share_plus/share_plus.dart';
import '../models/user_pdf_book.dart';
import '../services/library_service.dart';
import '../theme_notifier.dart';

class PdfReaderScreen extends StatefulWidget {
  final UserPdfBook book;

  const PdfReaderScreen({super.key, required this.book});

  @override
  State<PdfReaderScreen> createState() => _PdfReaderScreenState();
}

class _PdfReaderScreenState extends State<PdfReaderScreen> {
  final LibraryService _libraryService = LibraryService();
  late PdfViewerController _pdfViewerController;
  late PdfTextSearchResult _searchResult;

  late int _currentPage;
  late int _totalPages;
  late final ValueNotifier<int> _pageNotifier;
  Timer? _saveProgressDebounce;

  // Horizontal single-page paging by default for 60fps butter-smooth reading on 300+ page books!
  bool _isSwipeHorizontal = true;

  // Default to Clean Mode: When opened, it displays a 100% clean page (tap anywhere to toggle controls!)
  bool _controlsVisible = false;
  String? _errorMessage;

  // Search State
  bool _isSearchActive = false;
  final TextEditingController _searchFieldController = TextEditingController();

  // Instant Theme State (NO SLOW ANIMATION - 0ms instant GPU switch)
  late QuranTheme _currentTheme;

  // High-contrast inverted matrix for dark/night mode
  static const ColorFilter _kInvertColorFilter = ColorFilter.matrix([
    -1.0, 0.0, 0.0, 0.0, 255.0,
    0.0, -1.0, 0.0, 0.0, 255.0,
    0.0, 0.0, -1.0, 0.0, 255.0,
    0.0, 0.0, 0.0, 1.0, 0.0,
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

    _pdfViewerController = PdfViewerController();
    _searchResult = PdfTextSearchResult();
  }

  @override
  void dispose() {
    _saveProgressDebounce?.cancel();
    _saveProgressImmediate();
    _pageNotifier.dispose();
    _searchFieldController.dispose();
    _searchResult.dispose();
    _pdfViewerController.dispose();
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
    }
  }

  // ── Instant Theme Switching (Zero Delay, No Animation) ──────────────────────
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

    AppTheme.changeTheme(nextTheme);
  }

  // ── Swipe Direction Toggle ─────────────────────────────────────────────────
  void _toggleSwipeDirection() {
    HapticFeedback.selectionClick();
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    setState(() {
      _isSwipeHorizontal = !_isSwipeHorizontal;
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
    if (file.existsSync()) {
      Share.shareXFiles(
        [XFile(widget.book.filePath)],
        text: 'كتاب: ${widget.book.title}\nعبر تطبيق Quran Zone',
      );
    }
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
        : (isCream ? const Color(0xFFF7F2DF) : const Color(0xFFF5F5F5));

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

                  // 2. Warm Parchment Tint Overlay for Cream Theme
                  if (isCream)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          color: const Color(0xFFC9A84C).withValues(alpha: 0.07),
                        ),
                      ),
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

  // ── Syncfusion PDF Viewer Widget ───────────────────────────────────────────
  Widget _buildPdfViewer(bool isDark, bool isCream) {
    final viewer = SfPdfViewer.file(
      File(widget.book.filePath),
      key: ValueKey('sf_pdf_${widget.book.id}_$_isSwipeHorizontal'),
      controller: _pdfViewerController,
      canShowScrollHead: false, // Disabling heavy internal overlay avoids frame drops on 300+ pages
      canShowScrollStatus: false, // Replaced with smooth bottom scrubber matching Screenshot 3
      canShowPaginationDialog: false,
      enableTextSelection: true,
      // Tap anywhere on the page to toggle controls (Clean reading mode vs customization)
      onTap: (PdfGestureDetails details) {
        HapticFeedback.lightImpact();
        setState(() {
          _controlsVisible = !_controlsVisible;
          if (!_controlsVisible && _isSearchActive) {
            _isSearchActive = false;
            _searchResult.clear();
            _searchFieldController.clear();
          }
        });
      },
      pageLayoutMode: _isSwipeHorizontal ? PdfPageLayoutMode.single : PdfPageLayoutMode.continuous,
      scrollDirection: _isSwipeHorizontal ? PdfScrollDirection.horizontal : PdfScrollDirection.vertical,
      currentSearchTextHighlightColor: const Color(0xFFECC94B).withValues(alpha: 0.7),
      otherSearchTextHighlightColor: const Color(0xFFECC94B).withValues(alpha: 0.35),
      onDocumentLoaded: (PdfDocumentLoadedDetails details) {
        if (mounted) {
          _totalPages = details.document.pages.count;
          _pageNotifier.value = _currentPage;
          if (_currentPage > 1 && _currentPage <= _totalPages) {
            _pdfViewerController.jumpToPage(_currentPage);
          }
          _saveProgressImmediate();
          if (mounted) setState(() {});
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
      colorFilter: isDark ? _kInvertColorFilter : _kIdentityColorFilter,
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

    // Current theme color & icon for the instant theme switcher
    final Color themeColor = isDark
        ? const Color(0xFFE8C77A)
        : (isCream ? const Color(0xFFC9A84C) : const Color(0xFF1B8A6B));

    final IconData themeIcon = isDark
        ? Icons.dark_mode_rounded
        : (isCream ? Icons.menu_book_rounded : Icons.light_mode_rounded);

    final String nextTooltip = isDark
        ? (locale == 'ar' ? 'التحويل للوضع الكريمي الدافئ' : 'Switch to Warm Cream')
        : (isCream
            ? (locale == 'ar' ? 'التحويل للوضع الأبيض الناصع' : 'Switch to Crisp White')
            : (locale == 'ar' ? 'التحويل للوضع الداكن' : 'Switch to Night Mode'));

    return GestureDetector(
      onTap: () {},
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.fromLTRB(8, topPadding + 6, 8, 10),
        decoration: BoxDecoration(
          color: barBg,
          border: Border(bottom: BorderSide(color: borderColor.withValues(alpha: 0.3), width: 1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Back Action
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 19),
              onPressed: () {
                _saveProgressDebounce?.cancel();
                _saveProgressImmediate();
                Navigator.pop(context);
              },
            ),

            // Book Title (Tapping opens book details)
            Expanded(
              child: InkWell(
                onTap: _showBookInfoSheet,
                borderRadius: BorderRadius.circular(10),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              widget.book.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                fontFamily: 'Amiri',
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                      Text(
                        '${widget.book.formattedSize}  •  ${_totalPages > 0 ? "$_totalPages صفحة" : ""}',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.6),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 1. Search in PDF Button
            IconButton(
              tooltip: locale == 'ar' ? 'بحث في نصوص الكتاب' : 'Search in Book',
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

            // 2. Scroll Direction Switcher (Vertical continuous vs Horizontal pages)
            IconButton(
              tooltip: _isSwipeHorizontal ? 'تمرير عمودي' : 'تمرير أفقي',
              icon: Container(
                padding: const EdgeInsets.all(5.5),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _isSwipeHorizontal ? Icons.swap_vert_rounded : Icons.swap_horiz_rounded,
                  color: primaryColor,
                  size: 18,
                ),
              ),
              onPressed: _toggleSwipeDirection,
            ),

            // 3. Instant Theme Switcher Button (NO ANIMATION, Instant 0ms switch!)
            IconButton(
              tooltip: nextTooltip,
              icon: Container(
                padding: const EdgeInsets.all(5.5),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: themeColor.withValues(alpha: 0.6), width: 1.2),
                ),
                child: Icon(themeIcon, color: themeColor, size: 18),
              ),
              onPressed: _cycleThemeInstantly,
            ),

            // 4. Fullscreen / Hide Controls Toggle
            IconButton(
              tooltip: locale == 'ar' ? 'ملء الشاشة' : 'Fullscreen',
              icon: Icon(
                Icons.fullscreen_rounded,
                color: textColor.withValues(alpha: 0.8),
                size: 22,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _controlsVisible = false);
              },
            ),

            // 5. Share Book Action
            IconButton(
              tooltip: 'مشاركة الكتاب',
              icon: Icon(Icons.share_rounded, color: textColor.withValues(alpha: 0.8), size: 19),
              onPressed: _shareBook,
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
                            Icon(Icons.menu_book_rounded, color: primaryColor, size: 14),
                            const SizedBox(width: 6),
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
