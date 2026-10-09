import 'package:flutter/material.dart';
import '../models/hadith_models.dart';
import '../services/hadith_service.dart';
import '../theme_notifier.dart';
import 'hadith_chapters_screen.dart';
import 'hadith_reader_screen.dart';
import 'hadith_search_screen.dart';

class HadithBooksScreen extends StatefulWidget {
  final HadithCollection collection;

  const HadithBooksScreen({
    super.key,
    required this.collection,
  });

  @override
  State<HadithBooksScreen> createState() => _HadithBooksScreenState();
}

class _HadithBooksScreenState extends State<HadithBooksScreen> {
  final HadithService _hadithService = HadithService();
  final TextEditingController _searchController = TextEditingController();

  List<HadithBook> _books = [];
  List<HadithBook> _filteredBooks = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final books = await _hadithService.getBooks(widget.collection.id);
      if (mounted) {
        setState(() {
          _books = books;
          _filteredBooks = books;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[HadithBooksScreen] Error loading books: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onSearch(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() => _filteredBooks = _books);
      return;
    }
    setState(() {
      _filteredBooks = _books.where((b) {
        return b.nameAr.contains(trimmed) ||
            b.bookNumber.toString() == trimmed;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final screenBg = AppTheme.getScreenBgColor(theme);
        final cardBg = AppTheme.getPageBgColor(theme);
        final textColor = theme == QuranTheme.dark ? Colors.white : const Color(0xFF2C2416);
        final isDark = theme == QuranTheme.dark;

        return Scaffold(
          backgroundColor: screenBg,
          appBar: AppBar(
            backgroundColor: cardBg,
            elevation: 0.5,
            centerTitle: true,
            iconTheme: IconThemeData(color: textColor),
            title: Column(
              children: [
                Text(
                  widget.collection.nameAr,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  widget.collection.authorAr,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search_rounded),
                tooltip: 'البحث في هذه المجموعة',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HadithSearchScreen(
                        initialCollectionId: widget.collection.id,
                        collectionTitle: widget.collection.nameAr,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Search Books Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(fontFamily: 'Amiri', fontSize: 14, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'البحث عن كتاب في ${widget.collection.nameAr}...',
                    hintTextDirection: TextDirection.rtl,
                    hintStyle: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                    prefixIcon: Icon(Icons.search_rounded, color: textColor.withValues(alpha: 0.5)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: cardBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                ),
              ),

              // Books List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF1B8A6B)))
                    : _errorMessage != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline_rounded, color: Colors.orange, size: 42),
                                  const SizedBox(height: 12),
                                  Text(
                                    'تعذر تحميل الكتب',
                                    style: TextStyle(fontFamily: 'Amiri', fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1B8A6B),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: _loadBooks,
                                    icon: const Icon(Icons.refresh_rounded, size: 18),
                                    label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Amiri')),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _filteredBooks.isEmpty
                            ? Center(
                                child: Text(
                                  'لا توجد كتب مطابقة',
                                  style: TextStyle(fontFamily: 'Amiri', fontSize: 15, color: textColor.withValues(alpha: 0.6)),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                itemCount: _filteredBooks.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final book = _filteredBooks[index];
                                  return _buildBookTile(book, cardBg, textColor, isDark);
                                },
                              ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookTile(
    HadithBook book,
    Color cardBg,
    Color textColor,
    bool isDark,
  ) {
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      elevation: 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HadithReaderScreen(
                collection: widget.collection,
                book: book,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              // Book Number Badge
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B8A6B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF1B8A6B).withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  '${book.bookNumber}',
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1B8A6B),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Book Title & Hadith Range
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      book.nameAr,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        Text(
                          '${book.totalHadiths} حديثاً',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 12.5,
                            color: textColor.withValues(alpha: 0.6),
                          ),
                        ),
                        if (book.hasChapters && book.totalChapters > 0) ...[
                          Text(
                            '• ${book.totalChapters} باباً',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 12,
                              color: textColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                        if (book.firstHadithNum != null &&
                            book.lastHadithNum != null &&
                            book.firstHadithNum! > 0 &&
                            book.lastHadithNum! > 0) ...[
                          Text(
                            '• الأحاديث: ${book.firstHadithNum} - ${book.lastHadithNum}',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 12,
                              color: textColor.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              if (book.hasChapters)
                IconButton(
                  icon: const Icon(Icons.format_list_bulleted_rounded),
                  color: const Color(0xFFC68A2E),
                  iconSize: 20,
                  tooltip: 'فهرس الأبواب (${book.totalChapters})',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HadithChaptersScreen(
                          collection: widget.collection,
                          book: book,
                        ),
                      ),
                    );
                  },
                ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: textColor.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
