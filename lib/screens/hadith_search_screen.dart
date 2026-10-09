import 'dart:async';
import 'package:flutter/material.dart';
import '../models/hadith_models.dart';
import '../services/hadith_service.dart';
import '../theme_notifier.dart';
import 'hadith_reader_screen.dart';

class HadithSearchScreen extends StatefulWidget {
  final int? initialCollectionId;
  final String? collectionTitle;

  const HadithSearchScreen({
    super.key,
    this.initialCollectionId,
    this.collectionTitle,
  });

  @override
  State<HadithSearchScreen> createState() => _HadithSearchScreenState();
}

class _HadithSearchScreenState extends State<HadithSearchScreen> {
  final HadithService _hadithService = HadithService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<HadithCollection> _collections = [];
  int? _selectedCollectionId;
  List<HadithItem> _results = [];
  bool _isSearching = false;
  String _searchedQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedCollectionId = widget.initialCollectionId;
    _loadCollections();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    try {
      final list = await _hadithService.getCollections();
      if (mounted) {
        setState(() => _collections = list);
      }
    } catch (e) {
      debugPrint('[HadithSearchScreen] Error loading collections: $e');
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _results = [];
        _isSearching = false;
        _searchedQuery = '';
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final res = await _hadithService.searchHadiths(
          trimmed,
          collectionId: _selectedCollectionId,
          limit: 60,
        );
        if (mounted) {
          setState(() {
            _results = res;
            _isSearching = false;
            _searchedQuery = trimmed;
          });
        }
      } catch (e) {
        debugPrint('[HadithSearchScreen] Error searching hadiths: $e');
        if (mounted) {
          setState(() {
            _results = [];
            _isSearching = false;
            _searchedQuery = trimmed;
          });
        }
      }
    });
  }

  Future<void> _openHadith(HadithItem item) async {
    final col = await _hadithService.getCollection(item.collectionId);
    final book = await _hadithService.getBook(item.bookId);
    HadithChapter? chapter;
    if (item.chapterId != null) {
      chapter = await _hadithService.getChapter(item.chapterId!);
    }

    if (mounted && col != null && book != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HadithReaderScreen(
            collection: col,
            book: book,
            chapter: chapter,
          ),
        ),
      );
    }
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
            title: Text(
              widget.collectionTitle != null
                  ? 'البحث في ${widget.collectionTitle}'
                  : 'البحث في الحديث الشريف',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ),
          body: Column(
            children: [
              // Search Input
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  textDirection: TextDirection.rtl,
                  autofocus: true,
                  style: TextStyle(fontFamily: 'Amiri', fontSize: 15, color: textColor),
                  decoration: InputDecoration(
                    hintText: 'ابحث بالكلمة أو العبارة (مع أو بدون تشكيل)...',
                    hintTextDirection: TextDirection.rtl,
                    hintStyle: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13.5,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1B8A6B)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: cardBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                ),
              ),

              // Collections Filter Chips (if not scoped to a single collection)
              if (widget.initialCollectionId == null && _collections.isNotEmpty) ...[
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: ChoiceChip(
                          label: const Text('جميع الكتب', style: TextStyle(fontFamily: 'Amiri', fontSize: 12)),
                          selected: _selectedCollectionId == null,
                          selectedColor: const Color(0xFF1B8A6B),
                          labelStyle: TextStyle(
                            color: _selectedCollectionId == null ? Colors.white : textColor,
                          ),
                          onSelected: (_) {
                            setState(() => _selectedCollectionId = null);
                            if (_searchController.text.isNotEmpty) {
                              _onSearchChanged(_searchController.text);
                            }
                          },
                        ),
                      ),
                      ..._collections.map((col) {
                        final isSel = _selectedCollectionId == col.id;
                        return Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: ChoiceChip(
                            label: Text(col.nameAr, style: const TextStyle(fontFamily: 'Amiri', fontSize: 12)),
                            selected: isSel,
                            selectedColor: const Color(0xFF1B8A6B),
                            labelStyle: TextStyle(
                              color: isSel ? Colors.white : textColor,
                            ),
                            onSelected: (_) {
                              setState(() => _selectedCollectionId = col.id);
                              if (_searchController.text.isNotEmpty) {
                                _onSearchChanged(_searchController.text);
                              }
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
              ],

              // Results Count / Loader
              if (_isSearching) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF1B8A6B))),
                ),
              ] else if (_searchedQuery.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Row(
                    children: [
                      Text(
                        'نتائج البحث: ${_results.length} حديثاً',
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 12.5,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Results List
              Expanded(
                child: _results.isEmpty && _searchedQuery.isNotEmpty && !_isSearching
                    ? Center(
                        child: Text(
                          'لا توجد نتائج مطابقة لـ "$_searchedQuery"',
                          style: TextStyle(fontFamily: 'Amiri', fontSize: 15, color: textColor.withValues(alpha: 0.6)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        itemCount: _results.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _results[index];
                          final colName = _collections
                              .firstWhere((c) => c.id == item.collectionId,
                                  orElse: () => HadithCollection(
                                        id: item.collectionId,
                                        sourceCollectionId: item.collectionId,
                                        slug: '',
                                        nameAr: 'الحديث الشريف',
                                        authorAr: '',
                                        numberingSource: '',
                                        totalBooks: 0,
                                        totalChapters: 0,
                                        totalHadiths: 0,
                                        hasChapters: true,
                                        sortOrder: 0,
                                      ))
                              .nameAr;

                          return Material(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(14),
                            elevation: 0.5,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => _openHadith(item),
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1B8A6B).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '$colName • حديث ${item.hadithNumber}',
                                            style: const TextStyle(
                                              fontFamily: 'Amiri',
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1B8A6B),
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        if (item.grade != null && item.grade!.trim().isNotEmpty) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFC68A2E).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              item.grade!,
                                              style: const TextStyle(
                                                fontFamily: 'Amiri',
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFFC68A2E),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item.arabicText,
                                      textDirection: TextDirection.rtl,
                                      maxLines: 4,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Amiri',
                                        fontSize: 15,
                                        height: 1.7,
                                        color: textColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
