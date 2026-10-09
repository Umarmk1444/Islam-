import 'package:flutter/material.dart';
import '../models/hadith_models.dart';
import '../services/hadith_service.dart';
import '../theme_notifier.dart';
import 'hadith_reader_screen.dart';

class HadithChaptersScreen extends StatefulWidget {
  final HadithCollection collection;
  final HadithBook book;

  const HadithChaptersScreen({
    super.key,
    required this.collection,
    required this.book,
  });

  @override
  State<HadithChaptersScreen> createState() => _HadithChaptersScreenState();
}

class _HadithChaptersScreenState extends State<HadithChaptersScreen> {
  final HadithService _hadithService = HadithService();
  final TextEditingController _searchController = TextEditingController();

  List<HadithChapter> _chapters = [];
  List<HadithChapter> _filteredChapters = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChapters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadChapters() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final chaps = await _hadithService.getChapters(widget.collection.id, widget.book.id);
      if (mounted) {
        setState(() {
          _chapters = chaps;
          _filteredChapters = chaps;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[HadithChaptersScreen] Error loading chapters: $e');
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
      setState(() => _filteredChapters = _chapters);
      return;
    }
    setState(() {
      _filteredChapters = _chapters.where((ch) {
        return ch.babAr.contains(trimmed) ||
            (ch.introAr != null && ch.introAr!.contains(trimmed));
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
                  widget.book.nameAr,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Text(
                  widget.collection.nameAr,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 12,
                    color: textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              // Search in chapters bar (only if chapters exist)
              if (_chapters.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearch,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontFamily: 'Amiri', fontSize: 14, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'البحث في أبواب هذا الكتاب...',
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

              // Chapters List or Friendly Direct Reading Action
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
                                    'تعذر تحميل الأبواب',
                                    style: TextStyle(fontFamily: 'Amiri', fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                  const SizedBox(height: 12),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1B8A6B),
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: _loadChapters,
                                    icon: const Icon(Icons.refresh_rounded, size: 18),
                                    label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Amiri')),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _chapters.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(18),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1B8A6B).withValues(alpha: 0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.menu_book_rounded,
                                          color: Color(0xFF1B8A6B),
                                          size: 46,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'هذا الكتاب لا يشتمل على تقسيم لأبواب فرعية',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Amiri',
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'أحاديث الكتاب (${widget.book.totalHadiths} حديثاً) متتالية ومسوقة مباشرة كما رتبها المصنف.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Amiri',
                                          fontSize: 13.5,
                                          color: textColor.withValues(alpha: 0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 22),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1B8A6B),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: () {
                                          Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => HadithReaderScreen(
                                                collection: widget.collection,
                                                book: widget.book,
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.auto_stories_rounded, size: 20),
                                        label: const Text(
                                          'قراءة أحاديث الكتاب',
                                          style: TextStyle(fontFamily: 'Amiri', fontSize: 15),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : _filteredChapters.isEmpty
                                ? Center(
                                    child: Text(
                                      'لا توجد أبواب مطابقة للبحث',
                                      style: TextStyle(fontFamily: 'Amiri', fontSize: 15, color: textColor.withValues(alpha: 0.6)),
                                    ),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    itemCount: _filteredChapters.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final chapter = _filteredChapters[index];
                                      return _buildChapterTile(chapter, cardBg, textColor, isDark);
                                    },
                                  ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChapterTile(
    HadithChapter chapter,
    Color cardBg,
    Color textColor,
    bool isDark,
  ) {
    final hasIntro = chapter.introAr != null && chapter.introAr!.trim().isNotEmpty;

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
                book: widget.book,
                chapter: chapter,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chapter Number badge
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFC9A84C).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFC9A84C).withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${chapter.chapterNumber.toInt()}',
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC68A2E),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title and Intro Preview
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      chapter.babAr,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        height: 1.45,
                        color: textColor,
                      ),
                    ),
                    if (hasIntro) ...[
                      const SizedBox(height: 6),
                      Text(
                        chapter.introAr!,
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 13,
                          height: 1.5,
                          fontStyle: FontStyle.italic,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(width: 8),
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
