import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
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
  PDFViewController? _pdfViewController;

  late int _currentPage;
  late int _totalPages;
  bool _isReady = false;
  bool _isNightMode = false;
  bool _isSwipeHorizontal = true;
  bool _controlsVisible = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.book.lastPageRead > 0 ? widget.book.lastPageRead : 1;
    _totalPages = widget.book.totalPages;

    // Default night mode according to active QuranTheme
    final currentTheme = AppTheme.notifier.value;
    _isNightMode = currentTheme == QuranTheme.dark;
  }

  void _saveProgress() {
    if (widget.book.id != null) {
      _libraryService.updatePdfReadingProgress(
        widget.book.id!,
        _currentPage,
        totalPages: _totalPages > 0 ? _totalPages : null,
      );
    }
  }

  void _showJumpToPageDialog() {
    final textController = TextEditingController(text: '$_currentPage');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.find_in_page_rounded, color: Color(0xFF1B8A6B)),
              SizedBox(width: 10),
              Text(
                'انتقل إلى صفحة',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أدخل رقم الصفحة (من 1 إلى ${_totalPages > 0 ? _totalPages : "..."}):',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                keyboardType: TextInputType.number,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: 'رقم الصفحة',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.bookmark_outline_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B8A6B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                final target = int.tryParse(textController.text.trim());
                if (target != null && target >= 1 && (_totalPages <= 0 || target <= _totalPages)) {
                  _pdfViewController?.setPage(target - 1);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('انتقال'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool fileExists = File(widget.book.filePath).existsSync();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _saveProgress();
        }
      },
      child: Scaffold(
        backgroundColor: _isNightMode ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
        body: !fileExists
            ? _buildFileNotFoundView()
            : GestureDetector(
                onTap: () {
                  setState(() {
                    _controlsVisible = !_controlsVisible;
                  });
                },
                child: Stack(
                  children: [
                    // ── Core PDF View ─────────────────────────────────────────
                    PDFView(
                      filePath: widget.book.filePath,
                      enableSwipe: true,
                      swipeHorizontal: _isSwipeHorizontal,
                      autoSpacing: true,
                      pageFling: true,
                      pageSnap: true,
                      defaultPage: (_currentPage - 1).clamp(0, 999999),
                      fitPolicy: FitPolicy.BOTH,
                      nightMode: _isNightMode,
                      onRender: (pages) {
                        if (mounted) {
                          setState(() {
                            _totalPages = pages ?? 0;
                            _isReady = true;
                          });
                          _saveProgress();
                        }
                      },
                      onError: (error) {
                        if (mounted) {
                          setState(() {
                            _errorMessage = error.toString();
                          });
                        }
                      },
                      onPageError: (page, error) {
                        debugPrint('PDF Page error $page: $error');
                      },
                      onViewCreated: (PDFViewController controller) {
                        _pdfViewController = controller;
                      },
                      onPageChanged: (int? page, int? total) {
                        if (page != null && mounted) {
                          final newPage = page + 1;
                          setState(() {
                            _currentPage = newPage;
                            if (total != null && total > 0) {
                              _totalPages = total;
                            }
                          });
                          _saveProgress();
                        }
                      },
                    ),

                    if (!_isReady && _errorMessage == null)
                      const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF1B8A6B),
                        ),
                      ),

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

                    // ── Animated Top App Bar ──────────────────────────────────
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      top: _controlsVisible ? 0 : -100,
                      left: 0,
                      right: 0,
                      child: _buildTopBar(),
                    ),

                    // ── Animated Bottom Progress Bar ──────────────────────────
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      bottom: _controlsVisible ? 0 : -80,
                      left: 0,
                      right: 0,
                      child: _buildBottomBar(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTopBar() {
    final double topPadding = MediaQuery.of(context).padding.top;
    final Color barBg = _isNightMode
        ? const Color(0xFF1E2421).withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.94);
    final Color textColor = _isNightMode ? Colors.white : const Color(0xFF1B2421);

    return Container(
      padding: EdgeInsets.fromLTRB(8, topPadding + 4, 8, 10),
      decoration: BoxDecoration(
        color: barBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
            onPressed: () {
              _saveProgress();
              Navigator.pop(context);
            },
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.5,
                  ),
                ),
                Text(
                  widget.book.formattedSize,
                  style: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Scroll Direction Switcher
          IconButton(
            tooltip: _isSwipeHorizontal ? 'تمرير عمودي' : 'تمرير أفقي',
            icon: Icon(
              _isSwipeHorizontal ? Icons.swap_horiz_rounded : Icons.swap_vert_rounded,
              color: textColor,
            ),
            onPressed: () {
              setState(() {
                _isSwipeHorizontal = !_isSwipeHorizontal;
              });
            },
          ),
          // Night Mode Toggle
          IconButton(
            tooltip: _isNightMode ? 'الوضع النهاري' : 'الوضع الليلي',
            icon: Icon(
              _isNightMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: _isNightMode ? const Color(0xFFECC94B) : textColor,
            ),
            onPressed: () {
              setState(() {
                _isNightMode = !_isNightMode;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final Color barBg = _isNightMode
        ? const Color(0xFF1E2421).withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.94);
    final Color textColor = _isNightMode ? Colors.white : const Color(0xFF1B2421);

    final double progressPercent = _totalPages > 0 ? (_currentPage / _totalPages) : 0.0;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPadding + 10),
      decoration: BoxDecoration(
        color: barBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Page Counter Pill
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: _showJumpToPageDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1B8A6B).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF1B8A6B).withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, color: Color(0xFF1B8A6B), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'صفحة $_currentPage من ${_totalPages > 0 ? _totalPages : "..."}',
                        style: const TextStyle(
                          color: Color(0xFF1B8A6B),
                          fontWeight: FontWeight.bold,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Percentage text
              Text(
                '${(progressPercent * 100).toInt()}%',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.8),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPercent.clamp(0.0, 1.0),
              backgroundColor: _isNightMode ? Colors.white12 : Colors.black12,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1B8A6B)),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileNotFoundView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.file_copy_outlined, size: 54, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'الملف غير موجود في الذاكرة',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
    );
  }
}
