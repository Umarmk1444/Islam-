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

  // Horizontal single-page paging by default for 60fps butter-smooth reading on 300+ page books!
  bool _isSwipeHorizontal = true;

  // Default to Clean Mode: When opened, it displays a 100% clean page (tap anywhere to toggle controls!)
  bool _controlsVisible = false;
  String? _errorMessage;

  // Search State
  bool _isSearchActive = false;
  final TextEditingController _searchFieldController = TextEditingController();

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

    double topPos = (region != null) ? (region.top - 62) : 120.0;
    if (topPos < topPadding + 60) {
      topPos = (region != null) ? (region.bottom + 12) : 140.0;
    }
    topPos = topPos.clamp(topPadding + 50, screenSize.height - 120);

    double leftPos = (region != null) ? (region.center.dx - 160) : (screenSize.width - 320) / 2;
    leftPos = leftPos.clamp(12.0, screenSize.width - 332);

    _contextMenuOverlay = OverlayEntry(
      builder: (context) {
        final isDark = _currentTheme == QuranTheme.dark;
        final isCream = _currentTheme == QuranTheme.cream;
        final menuBg = isDark
            ? const Color(0xFF14201C).withValues(alpha: 0.95)
            : (isCream
                ? const Color(0xFFFFF8EC).withValues(alpha: 0.96)
                : Colors.white.withValues(alpha: 0.96));
        final textColor = isDark ? Colors.white : const Color(0xFF152A24);
        final borderColor = isDark ? const Color(0xFFECC94B) : const Color(0xFF1B8A6B);

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _hideContextMenu();
                  _pdfViewerController.clearSelection();
                },
              ),
            ),
            Positioned(
              top: topPos,
              left: leftPos,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildContextMenuItem(
                        icon: Icons.border_color_rounded,
                        label: 'تظليل',
                        color: const Color(0xFFECC94B),
                        onTap: _addHighlightAnnotation,
                      ),
                      _buildMenuDivider(isDark),
                      _buildContextMenuItem(
                        icon: Icons.format_underlined_rounded,
                        label: 'تسطير',
                        color: const Color(0xFF1B8A6B),
                        onTap: _addUnderlineAnnotation,
                      ),
                      _buildMenuDivider(isDark),
                      _buildContextMenuItem(
                        icon: Icons.auto_awesome_rounded,
                        label: 'اسأل AI',
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
                        label: 'ترجمة',
                        color: const Color(0xFF2196F3),
                        onTap: () {
                          _hideContextMenu();
                          _pdfViewerController.clearSelection();
                          _showTranslateBottomSheet(selectedText);
                        },
                      ),
                      _buildMenuDivider(isDark),
                      _buildContextMenuItem(
                        icon: Icons.copy_rounded,
                        label: 'نسخ',
                        color: textColor.withValues(alpha: 0.8),
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: selectedText));
                          _hideContextMenu();
                          _pdfViewerController.clearSelection();
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                                  SizedBox(width: 8),
                                  Text('تم نسخ النص المحدد إلى الحافظة'),
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
                        label: 'بحث',
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
            ),
          ],
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
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.5, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: color,
                fontFamily: 'Amiri',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuDivider(bool isDark) {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 2),
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

  void _showAiBottomSheet(String selectedText) {
    final isDark = _currentTheme == QuranTheme.dark;
    final isCream = _currentTheme == QuranTheme.cream;
    final cardBg = isDark ? const Color(0xFF14201C) : (isCream ? const Color(0xFFFFFDF7) : Colors.white);
    final textColor = isDark ? Colors.white : const Color(0xFF152A24);
    final borderColor = AppTheme.getBorderColor(_currentTheme);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                const SizedBox(height: 16),
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
                            'المساعد الذكي (ChatGPT / AI)',
                            style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold, fontSize: 16.5, color: textColor),
                          ),
                          Text(
                            'تحليل وتفسير النص المقتبس من الكتاب',
                            style: TextStyle(fontSize: 11.5, color: textColor.withValues(alpha: 0.6)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF7F5EE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    '« $selectedText »',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13.5,
                      fontStyle: FontStyle.italic,
                      color: textColor.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'اختر موضوع السؤال المطلوب:',
                  style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold, fontSize: 13, color: textColor.withValues(alpha: 0.8)),
                ),
                const SizedBox(height: 10),
                _buildAiPromptTile(
                  icon: Icons.menu_book_rounded,
                  title: 'شرح وتفسير المعنى والمقاصد',
                  subtitle: 'بيان الدلالات الفقهية والمعنوية للنص',
                  isDark: isDark,
                  textColor: textColor,
                  onTap: () => _launchChatGptPrompt('اشرح لي بالتفصيل المعنى والمقاصد والفوائد المستنبطة من هذا النص', selectedText, ctx),
                ),
                const SizedBox(height: 8),
                _buildAiPromptTile(
                  icon: Icons.spellcheck_rounded,
                  title: 'معاني الألفاظ الغريبة والإعراب',
                  subtitle: 'توضيح المفردات اللغوية والتركيب النحوي',
                  isDark: isDark,
                  textColor: textColor,
                  onTap: () => _launchChatGptPrompt('وضح لي معاني الكلمات الغريبة والتركيب البلاغي والإعرابي لهذا النص', selectedText, ctx),
                ),
                const SizedBox(height: 8),
                _buildAiPromptTile(
                  icon: Icons.verified_outlined,
                  title: 'تخريج وتحقيق المسألة أو الحديث',
                  subtitle: 'معرفة أصل الرواية والمصادر المعتمدة',
                  isDark: isDark,
                  textColor: textColor,
                  onTap: () => _launchChatGptPrompt('خرج لي هذا النص واذكر مصادره وصحته وأقوال العلماء فيه', selectedText, ctx),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10A37F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                  label: const Text(
                    'فتح النص وسؤاله في ChatGPT مباشرة',
                    style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () => _launchChatGptPrompt('اشرح لي هذا النص من كتاب "${widget.book.title}" شرحاً وافياً وميسراً', selectedText, ctx),
                ),
              ],
            ),
          ),
        );
      },
    );
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

  void _launchChatGptPrompt(String question, String quote, BuildContext sheetCtx) async {
    Navigator.pop(sheetCtx);
    final fullPrompt = '$question\n\nالنص المقتبس من كتاب "${widget.book.title}":\n"$quote"';
    final url = Uri.parse('https://chatgpt.com/?q=${Uri.encodeComponent(fullPrompt)}');
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      Clipboard.setData(ClipboardData(text: fullPrompt));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر فتح المتصفح، تم نسخ السؤال إلى الحافظة'),
            backgroundColor: Color(0xFF1B8A6B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showTranslateBottomSheet(String selectedText) {
    final isDark = _currentTheme == QuranTheme.dark;
    final isCream = _currentTheme == QuranTheme.cream;
    final cardBg = isDark ? const Color(0xFF14201C) : (isCream ? const Color(0xFFFFFDF7) : Colors.white);
    final textColor = isDark ? Colors.white : const Color(0xFF152A24);
    final borderColor = AppTheme.getBorderColor(_currentTheme);

    final bool isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(selectedText);
    String targetLang = isArabic ? 'en' : 'ar';
    String langLabel = isArabic ? 'العربية ➔ English' : 'English ➔ العربية';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FutureBuilder<String>(
              future: _fetchTranslation(selectedText, targetLang),
              builder: (context, snapshot) {
                final bool isLoading = snapshot.connectionState == ConnectionState.waiting;
                final String translation = snapshot.data ?? (snapshot.hasError ? 'تعذر جلب الترجمة، تحقق من اتصال الإنترنت.' : '');

                return Container(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
                                Text(
                                  'الترجمة الفورية',
                                  style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold, fontSize: 16.5, color: textColor),
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () {
                                setModalState(() {
                                  targetLang = targetLang == 'en' ? 'ar' : 'en';
                                  langLabel = targetLang == 'en' ? 'العربية ➔ English' : 'English ➔ العربية';
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: const Color(0xFF2196F3).withValues(alpha: 0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(langLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF2196F3), fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.swap_horiz_rounded, size: 14, color: Color(0xFF2196F3)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF7F5EE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            selectedText,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: isArabic ? 'Amiri' : null,
                              fontSize: 13,
                              color: textColor.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
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
                                    padding: EdgeInsets.all(12.0),
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
                                    fontFamily: targetLang == 'ar' ? 'Amiri' : null,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                    height: 1.45,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.copy_rounded, size: 17),
                          label: const Text('نسخ الترجمة', style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold, fontSize: 14)),
                          onPressed: translation.isEmpty || isLoading
                              ? null
                              : () {
                                  Clipboard.setData(ClipboardData(text: translation));
                                  Navigator.pop(ctx);
                                  HapticFeedback.lightImpact();
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    const SnackBar(
                                      content: Text('تم نسخ الترجمة بنجاح'),
                                      backgroundColor: Color(0xFF2196F3),
                                      behavior: SnackBarBehavior.floating,
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
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
      canShowScrollHead: false, // Disabling heavy internal overlay avoids frame drops on 300+ pages
      canShowScrollStatus: false, // Replaced with smooth bottom scrubber matching Screenshot 3
      canShowPaginationDialog: false,
      enableTextSelection: true,
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
          if (_currentPage > 1 && _currentPage <= _totalPages) {
            _pdfViewerController.jumpToPage(_currentPage);
          }
          _saveProgressImmediate();
          _loadPersistentAnnotations();
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
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    children: [
                      Flexible(
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
                      const SizedBox(width: 4),
                      Icon(
                        Icons.info_outline_rounded,
                        size: 13,
                        color: textColor.withValues(alpha: 0.5),
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

            // 3. Prominent Visual Theme Switcher (0ms instant GPU switch!)
            IconButton(
              tooltip: nextTooltip,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
              icon: themeBadge,
              onPressed: _cycleThemeInstantly,
            ),

            // 4. Share Book Action
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
