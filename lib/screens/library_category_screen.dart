import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../theme_notifier.dart';
import '../services/library_service.dart';
import 'library_content_list_screen.dart';

class LibraryCategoryScreen extends StatefulWidget {
  final String domainPart; // e.g. 'المكتبة', 'فتاوى'
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
    if (query.isEmpty) {
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
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => LibraryContentListScreen(
        part: widget.domainPart,
        categoryId: category['id']!,
        categoryTitle: category['title']!,
      )
    ));
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
          widget.domainTitle,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
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
                hintText: 'Search categories...',
                hintStyle: TextStyle(color: isDark ? AppColors.textSecondary : AppColors.textMuted),
                prefixIcon: Icon(Icons.search, color: isDark ? AppColors.textSecondary : AppColors.emeraldDeep),
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
                ? const Center(child: CircularProgressIndicator(color: AppColors.emeraldLight))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredCategories.length,
                    itemBuilder: (context, index) {
                      final cat = _filteredCategories[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.divider : Colors.grey.shade200,
                            width: 0.5,
                          ),
                        ),
                        child: ListTile(
                          title: Text(
                            cat['title']!,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16, color: isDark ? AppColors.textSecondary : AppColors.textMuted),
                          onTap: () => _navigateToCategory(cat),
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
