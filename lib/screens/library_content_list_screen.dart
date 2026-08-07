import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../theme_notifier.dart';
import '../services/library_service.dart';
import '../models/library_item.dart';
import '../models/fatwa_item.dart';
import '../models/roqua_item.dart';
import 'story_reading_screen.dart';

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
      if (query.isNotEmpty) {
        items = items
            .where((item) => (item as LibraryItem)
                .title
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    } else if (widget.part == 'فتاوى') {
      items = await _libraryService.getFatawyItems(widget.categoryId,
          searchQuery: query);
    } else if (widget.part == 'الرقية الشرعية') {
      items = await _libraryService.getRoquaItems(widget.categoryId,
          searchQuery: query);
    } else {
      items = await _libraryService
          .getLibraryItems(widget.part, widget.categoryId, searchQuery: query);
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

  void _openItem(dynamic item) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) {
      if (item is FatwaItem) {
        return StoryReadingScreen(fatwaItem: item);
      } else if (item is RoquaItem) {
        return StoryReadingScreen(roquaItem: item);
      } else {
        return StoryReadingScreen(item: item as LibraryItem);
      }
    }));
    if (widget.part == 'favorites') {
      _loadItems();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.notifier.value;
    final isDark = theme == QuranTheme.dark;

    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final cardBg = isDark ? AppColors.surfaceCard : AppColors.surfaceCardLight;
    final textColor = isDark ? AppColors.textPrimary : AppColors.emeraldDeep;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          widget.categoryTitle,
          style: TextStyle(
              color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: 'Search in ${widget.categoryTitle}...',
                hintStyle: TextStyle(
                    color:
                        isDark ? AppColors.textSecondary : AppColors.textMuted),
                prefixIcon: Icon(Icons.search,
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.emeraldDeep),
                filled: true,
                fillColor: cardBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.emeraldLight))
                : _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 64,
                                color:
                                    AppColors.textMuted.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(
                              'No items found.',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppColors.emeraldDeep,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Try adjusting your search query.',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final bool isFatwa = item is FatwaItem;
                          final bool isRoqua = item is RoquaItem;

                          final String title = isFatwa
                              ? item.question
                              : isRoqua
                                  ? item.title
                                  : (item as LibraryItem).title;

                          final bool isFav = (isFatwa || isRoqua)
                              ? false
                              : (item as LibraryItem).isFav;
                          final int readings = (isFatwa || isRoqua)
                              ? 0
                              : (item as LibraryItem).numReadings;

                          IconData getIcon() {
                            if (isFatwa) return Icons.question_answer_rounded;
                            if (isRoqua) return Icons.healing_rounded;
                            return Icons.menu_book_rounded;
                          }

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.divider
                                    : AppColors.textMuted
                                        .withValues(alpha: 0.2),
                                width: 0.5,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () => _openItem(item),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: AppColors.emeraldLight
                                              .withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          getIcon(),
                                          color: AppColors.emeraldLight,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
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
                                                  fontSize: 15),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (!isFatwa && !isRoqua) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                      Icons.visibility_rounded,
                                                      size: 14,
                                                      color: AppColors.goldMid),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Readings: $readings',
                                                    style: TextStyle(
                                                      color: isDark
                                                          ? AppColors
                                                              .textSecondary
                                                          : AppColors.textMuted,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ]
                                          ],
                                        ),
                                      ),
                                      if (isFav)
                                        const Padding(
                                          padding: EdgeInsets.only(left: 8.0),
                                          child: Icon(Icons.favorite_rounded,
                                              color: Colors.redAccent,
                                              size: 20),
                                        ),
                                    ],
                                  ),
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
  }
}
