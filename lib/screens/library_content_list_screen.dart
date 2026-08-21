import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import '../services/library_service.dart';
import '../models/library_item.dart';
import '../models/fatwa_item.dart';
import '../models/roqua_item.dart';
import 'story_reading_screen.dart';
import '../widgets/liquid_pressable.dart';

class LibraryContentListScreen extends StatefulWidget {
  final String part; // e.g., 'المكتبة', 'فتاوى', 'favorites', 'الرقية الشرعية'
  final String categoryId;
  final String categoryTitle;

  const LibraryContentListScreen({
    super.key,
    required this.part,
    required this.categoryId,
    required this.categoryTitle,
  });

  @override
  State<LibraryContentListScreen> createState() =>
      _LibraryContentListScreenState();
}

class _LibraryContentListScreenState extends State<LibraryContentListScreen> {
  final LibraryService _libraryService = LibraryService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems({String query = ''}) async {
    setState(() => _isLoading = true);
    List<dynamic> items;

    if (widget.part == 'favorites') {
      items = await _libraryService.getFavorites();
      if (query.trim().isNotEmpty) {
        items = items
            .where((item) => (item as LibraryItem)
                .title
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    } else if (widget.part == 'فتاوى') {
      items = await _libraryService.getFatawyItems(widget.categoryId,
          searchQuery: query.trim());
    } else if (widget.part == 'الرقية الشرعية') {
      items = await _libraryService.getRoquaItems(widget.categoryId,
          searchQuery: query.trim());
    } else {
      items = await _libraryService.getLibraryItems(
          widget.part, widget.categoryId,
          searchQuery: query.trim());
    }

    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    _loadItems(query: query);
  }

  void _openItem(dynamic item, int index) async {
    final bool isBukhari = widget.part == 'صحيح البخارى' || widget.part == 'البخارى';
    await Navigator.push(context, MaterialPageRoute(builder: (_) {
      if (isBukhari) {
        return StoryReadingScreen(
          items: _items,
          initialIndex: index,
          categoryTitle: widget.categoryTitle,
        );
      } else if (item is FatwaItem) {
        return StoryReadingScreen(
          fatwaItem: item,
          categoryTitle: widget.categoryTitle,
        );
      } else if (item is RoquaItem) {
        return StoryReadingScreen(
          roquaItem: item,
          categoryTitle: widget.categoryTitle,
        );
      } else {
        return StoryReadingScreen(
          item: item as LibraryItem,
          categoryTitle: widget.part == 'favorites' ? null : widget.categoryTitle,
        );
      }
    }));
    if (widget.part == 'favorites') {
      _loadItems(query: _searchController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, currentTheme, _) {
        final isDark = currentTheme == QuranTheme.dark;
        final isCream = currentTheme == QuranTheme.cream;

        final bgColor = isDark
            ? const Color(0xFF090E11)
            : (isCream ? const Color(0xFFF6F0E2) : const Color(0xFFF3F7F5));
        final cardBg = isDark
            ? const Color(0xFF131C1A)
            : (isCream ? const Color(0xFFFFFDF8) : Colors.white);
        final textColor = isDark
            ? const Color(0xFFF0F4F0)
            : (isCream ? const Color(0xFF2C1C11) : const Color(0xFF0F382C));
        final borderColor = isDark
            ? Colors.white.withValues(alpha: 0.08)
            : (isCream ? const Color(0xFFE2D5BE) : const Color(0xFFE2EBE7));

        return Scaffold(
          backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              widget.categoryTitle,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'Amiri',
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (!_isLoading && _items.isNotEmpty)
              Text(
                '${_items.length} مادة علمية',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF8A9995)
                      : const Color(0xFF5A726A),
                  fontSize: 11,
                ),
              ),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Search Input ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'ابحث في ${widget.categoryTitle}...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? const Color(0xFF6C7C78)
                        : const Color(0xFF9AA8A4),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: Color(0xFF1B8A6B), size: 20),
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),

          // ── Content Items List ─────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1B8A6B)),
                  )
                : _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.menu_book_outlined,
                              size: 54,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد محتويات متوفرة حالياً',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF8A9995)
                                    : const Color(0xFF5A726A),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final bool isFatwa = item is FatwaItem;
                          final bool isRoqua = item is RoquaItem;

                          final String rawTitle = isFatwa
                              ? item.question
                              : isRoqua
                                  ? item.title
                                  : (item as LibraryItem).title;
                          final String title = rawTitle
                              .replaceAll('{', '')
                              .replaceAll('}', '')
                              .replaceAll(RegExp(r'\s+'), ' ')
                              .trim();

                          final bool isFav = (isFatwa || isRoqua)
                              ? false
                              : (item as LibraryItem).isFav;
                          final int readings = (isFatwa || isRoqua)
                              ? 0
                              : (item as LibraryItem).numReadings;

                          final String typeTag = widget.part == 'favorites'
                              ? (item is LibraryItem
                                  ? (item.part.isNotEmpty ? item.part : 'المكتبة')
                                  : 'المفضلة')
                              : isFatwa
                                  ? (widget.categoryTitle.isNotEmpty
                                      ? widget.categoryTitle
                                      : 'فتوى')
                                  : isRoqua
                                      ? (widget.categoryTitle.isNotEmpty
                                          ? widget.categoryTitle
                                          : 'رقية شرعية')
                                      : (widget.categoryTitle.isNotEmpty &&
                                              int.tryParse(widget.categoryTitle) ==
                                                  null
                                          ? widget.categoryTitle
                                          : (int.tryParse((item as LibraryItem)
                                                          .type) ==
                                                      null &&
                                                  (item).type.isNotEmpty
                                              ? (item).type
                                              : (widget.categoryTitle.isNotEmpty
                                                  ? widget.categoryTitle
                                                  : 'مادة علمية')));

                          IconData getIcon() {
                            if (isFatwa) return Icons.live_help_rounded;
                            if (isRoqua) return Icons.healing_rounded;
                            return Icons.menu_book_rounded;
                          }

                          Color getIconColor() {
                            if (isFatwa) return const Color(0xFFAB47BC);
                            if (isRoqua) return const Color(0xFFED64A6);
                            return const Color(0xFF1B8A6B);
                          }

                          return LiquidPressable(
                            onTap: () => _openItem(item, index),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14.0),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    Border.all(color: borderColor, width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(alpha: isDark ? 0.2 : 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Icon Badge
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: getIconColor()
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      getIcon(),
                                      color: getIconColor(),
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Content Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          title,
                                          style: TextStyle(
                                            color: textColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            fontFamily: 'Amiri',
                                            height: 1.25,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 7,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: getIconColor()
                                                    .withValues(alpha: 0.10),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                typeTag,
                                                style: TextStyle(
                                                  color: getIconColor(),
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            if (!isFatwa &&
                                                !isRoqua &&
                                                readings > 0) ...[
                                              const SizedBox(width: 10),
                                              const Icon(
                                                Icons.remove_red_eye_rounded,
                                                size: 13,
                                                color: Color(0xFFD4AF37),
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '$readings قراءة',
                                                style: TextStyle(
                                                  color: isDark
                                                      ? const Color(0xFF8A9995)
                                                      : const Color(0xFF6B8079),
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  if (isFav)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 6.0),
                                      child: Icon(
                                        Icons.bookmark_added_rounded,
                                        color: Color(0xFFD4AF37),
                                        size: 22,
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
    );
      },
    );
  }
}
