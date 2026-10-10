import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import '../services/library_service.dart';
import 'library_content_list_screen.dart';
import '../widgets/liquid_pressable.dart';
import '../utils/category_translations.dart';

class LibraryCategoryScreen extends StatefulWidget {
  final String domainPart; // e.g. 'المكتبة', 'فتاوى', 'صحيح البخارى'
  final String domainTitle;
  final List<String>? filterCategories;
  final Widget? headerWidget;

  const LibraryCategoryScreen({
    super.key,
    required this.domainPart,
    required this.domainTitle,
    this.filterCategories,
    this.headerWidget,
  });

  @override
  State<LibraryCategoryScreen> createState() => _LibraryCategoryScreenState();
}

class _LibraryCategoryScreenState extends State<LibraryCategoryScreen> {
  final LibraryService _libraryService = LibraryService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, String>> _categories = [];
  List<Map<String, String>> _filteredCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      List<Map<String, String>> cats;
      if (widget.domainPart == 'فتاوى') {
        cats = await _libraryService.getFatawyCategories();
      } else {
        cats = await _libraryService.getLibraryCategories(widget.domainPart);
      }

      if (widget.filterCategories != null && widget.filterCategories!.isNotEmpty) {
        final orderList = widget.filterCategories!.map((s) => s.trim()).toList();
        final filterSet = orderList.toSet();
        cats = cats.where((c) {
          final id = c['id']?.trim() ?? '';
          final title = c['title']?.trim() ?? '';
          return filterSet.contains(id) || filterSet.contains(title);
        }).toList();

        // Preserve caller's custom ordering precisely
        cats.sort((a, b) {
          final aKey = a['id']?.trim() ?? a['title']?.trim() ?? '';
          final bKey = b['id']?.trim() ?? b['title']?.trim() ?? '';
          final aIdx = orderList.indexOf(aKey);
          final bIdx = orderList.indexOf(bKey);
          if (aIdx != -1 && bIdx != -1) return aIdx.compareTo(bIdx);
          if (aIdx != -1) return -1;
          if (bIdx != -1) return 1;
          return 0;
        });
      }

      if (mounted) {
        setState(() {
          _categories = cats;
          _filteredCategories = cats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[LibraryCategoryScreen] Error loading categories: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() => _filteredCategories = _categories);
      return;
    }
    final lowerQuery = query.toLowerCase();
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    setState(() {
      _filteredCategories = _categories.where((cat) {
        final raw = (cat['title'] ?? '').toLowerCase();
        final translated = CategoryTranslations.getTitle(cat['title'] ?? '', locale).toLowerCase();
        return raw.contains(lowerQuery) || translated.contains(lowerQuery);
      }).toList();
    });
  }

  void _navigateToCategory(Map<String, String> category) {
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final localizedTitle = CategoryTranslations.getTitle(category['title']!, locale);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LibraryContentListScreen(
          part: widget.domainPart,
          categoryId: category['id']!,
          categoryTitle: localizedTitle,
        ),
      ),
    );
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Builder(
          builder: (ctx) {
            final locale = Localizations.maybeLocaleOf(ctx)?.languageCode ?? 'ar';
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.domainTitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                    fontFamily: locale == 'ar' ? 'Amiri' : null,
                  ),
                ),
                if (!_isLoading && _categories.isNotEmpty)
                  Text(
                    locale == 'ar'
                        ? '${_categories.length} قسم وفهرس'
                        : '${_categories.length} ${locale == 'am' ? 'ክፍሎች' : (locale == 'om' ? 'Kutaa' : 'Categories')}',
                    style: TextStyle(
                      color: isDark ? const Color(0xFF8A9995) : const Color(0xFF5A726A),
                      fontSize: 11,
                      fontFamily: locale == 'ar' ? 'Amiri' : null,
                    ),
                  ),
              ],
            );
          },
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
              child: Builder(
                builder: (ctx) {
                  final locale = Localizations.maybeLocaleOf(ctx)?.languageCode ?? 'ar';
                  final String hint = locale == 'ar'
                      ? 'ابحث في أقسام ${widget.domainTitle}...'
                      : (locale == 'am'
                          ? 'በ${widget.domainTitle} ውስጥ ይፈልጉ...'
                          : (locale == 'om'
                              ? 'Keessatti barbaadi ${widget.domainTitle}...'
                              : 'Search within ${widget.domainTitle}...'));
                  return TextField(
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
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Categories List ────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1B8A6B)),
                  )
                : _filteredCategories.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_off_rounded,
                              size: 54,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'لا توجد أقسام مطابقة للبحث',
                              style: TextStyle(
                                color: isDark ? const Color(0xFF8A9995) : const Color(0xFF5A726A),
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
                        itemCount: _filteredCategories.length + (widget.headerWidget != null ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (widget.headerWidget != null && index == 0) {
                            return widget.headerWidget!;
                          }
                          final actualIndex = index - (widget.headerWidget != null ? 1 : 0);
                          final cat = _filteredCategories[actualIndex];
                          return LiquidPressable(
                            onTap: () => _navigateToCategory(cat),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                              child: Row(
                                children: [
                                  // Authentic Book Emblem
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1B8A6B).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.menu_book_rounded,
                                      color: Color(0xFF1B8A6B),
                                      size: 19,
                                    ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Category Title & Count
                                  Expanded(
                                    child: Builder(
                                      builder: (ctx) {
                                        final locale = Localizations.maybeLocaleOf(ctx)?.languageCode ?? 'ar';
                                        final rawTitle = cat['title'] ?? '';
                                        final displayTitle = CategoryTranslations.getTitle(rawTitle, locale);
                                        final isTranslated = locale != 'ar' && displayTitle != rawTitle;

                                        return Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              displayTitle,
                                              style: TextStyle(
                                                color: textColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: isTranslated ? 14.5 : 15.5,
                                                fontFamily: isTranslated ? null : 'Amiri',
                                                height: 1.25,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 3),
                                            Row(
                                              children: [
                                                if (cat['count'] != null && cat['count']!.isNotEmpty)
                                                  Text(
                                                    CategoryTranslations.getCountBadge(cat['count']!, widget.domainPart, locale),
                                                    style: TextStyle(
                                                      color: const Color(0xFF1B8A6B),
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      fontFamily: locale == 'ar' ? 'Amiri' : null,
                                                    ),
                                                  ),
                                                if (isTranslated) ...[
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      '•  $rawTitle',
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: isDark ? const Color(0xFF8A9995) : const Color(0xFF6B8079),
                                                        fontSize: 11,
                                                        fontFamily: 'Amiri',
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),

                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: Colors.black26,
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
