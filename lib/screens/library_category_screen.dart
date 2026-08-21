import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import '../services/library_service.dart';
import 'library_content_list_screen.dart';
import '../widgets/liquid_pressable.dart';

class LibraryCategoryScreen extends StatefulWidget {
  final String domainPart; // e.g. 'المكتبة', 'فتاوى', 'صحيح البخارى'
  final String domainTitle;

  const LibraryCategoryScreen({
    super.key,
    required this.domainPart,
    required this.domainTitle,
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
    List<Map<String, String>> cats;
    if (widget.domainPart == 'فتاوى') {
      cats = await _libraryService.getFatawyCategories();
    } else {
      cats = await _libraryService.getLibraryCategories(widget.domainPart);
    }

    if (mounted) {
      setState(() {
        _categories = cats;
        _filteredCategories = cats;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() => _filteredCategories = _categories);
      return;
    }
    final lowerQuery = query.toLowerCase();
    setState(() {
      _filteredCategories = _categories
          .where((cat) => cat['title']!.toLowerCase().contains(lowerQuery))
          .toList();
    });
  }

  void _navigateToCategory(Map<String, String> category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LibraryContentListScreen(
          part: widget.domainPart,
          categoryId: category['id']!,
          categoryTitle: category['title']!,
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
        title: Column(
          children: [
            Text(
              widget.domainTitle,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 19,
                fontFamily: 'Amiri',
              ),
            ),
            if (!_isLoading && _categories.isNotEmpty)
              Text(
                '${_categories.length} قسم وفهرس',
                style: TextStyle(
                  color: isDark ? const Color(0xFF8A9995) : const Color(0xFF5A726A),
                  fontSize: 11.5,
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
                  hintText: 'ابحث في أقسام ${widget.domainTitle}...',
                  hintStyle: TextStyle(
                    color: isDark ? const Color(0xFF6C7C78) : const Color(0xFF9AA8A4),
                    fontSize: 13,
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
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
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
                        itemCount: _filteredCategories.length,
                        itemBuilder: (context, index) {
                          final cat = _filteredCategories[index];
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

                                  // Category Title
                                  Expanded(
                                    child: Text(
                                      cat['title']!,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15.5,
                                        fontFamily: 'Amiri',
                                        height: 1.2,
                                      ),
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
