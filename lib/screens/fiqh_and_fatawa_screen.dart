import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../theme_notifier.dart';
import '../services/library_service.dart';
import '../widgets/liquid_pressable.dart';
import 'library_content_list_screen.dart';

class FiqhAndFatawaScreen extends StatefulWidget {
  final int initialTabIndex;

  const FiqhAndFatawaScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<FiqhAndFatawaScreen> createState() => _FiqhAndFatawaScreenState();
}

class _FiqhAndFatawaScreenState extends State<FiqhAndFatawaScreen>
    with SingleTickerProviderStateMixin {
  final LibraryService _libraryService = LibraryService();
  late TabController _tabController;

  final TextEditingController _fiqhSearchCtrl = TextEditingController();
  final TextEditingController _fatawaSearchCtrl = TextEditingController();

  List<Map<String, String>> _fiqhCategories = [];
  List<Map<String, String>> _filteredFiqhCategories = [];
  bool _isFiqhLoading = true;

  List<Map<String, String>> _fatawaCategories = [];
  List<Map<String, String>> _filteredFatawaCategories = [];
  bool _isFatawaLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadFiqhCategories();
    _loadFatawaCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fiqhSearchCtrl.dispose();
    _fatawaSearchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFiqhCategories() async {
    final cats = await _libraryService.getLibraryCategories('فقه');
    if (mounted) {
      setState(() {
        _fiqhCategories = cats;
        _filteredFiqhCategories = cats;
        _isFiqhLoading = false;
      });
    }
  }

  Future<void> _loadFatawaCategories() async {
    final cats = await _libraryService.getFatawyCategories();
    if (mounted) {
      setState(() {
        _fatawaCategories = cats;
        _filteredFatawaCategories = cats;
        _isFatawaLoading = false;
      });
    }
  }

  void _onFiqhSearch(String query) {
    if (query.isEmpty) {
      setState(() => _filteredFiqhCategories = _fiqhCategories);
      return;
    }
    final lower = query.toLowerCase();
    setState(() {
      _filteredFiqhCategories = _fiqhCategories
          .where((cat) => cat['title']!.toLowerCase().contains(lower))
          .toList();
    });
  }

  void _onFatawaSearch(String query) {
    if (query.isEmpty) {
      setState(() => _filteredFatawaCategories = _fatawaCategories);
      return;
    }
    final lower = query.toLowerCase();
    setState(() {
      _filteredFatawaCategories = _fatawaCategories
          .where((cat) => cat['title']!.toLowerCase().contains(lower))
          .toList();
    });
  }

  void _navigateToCategory(String domainPart, Map<String, String> category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LibraryContentListScreen(
          part: domainPart,
          categoryId: category['id']!,
          categoryTitle: category['title']!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.notifier.value == QuranTheme.dark;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final cardBg = isDark ? AppColors.surfaceCard : AppColors.surfaceCardLight;
    final textColor = isDark ? AppColors.textPrimary : AppColors.emeraldDeep;
    const primaryAccent = Color(0xFF8E24AA); // Violet accent for Fiqh/Fatawa

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        centerTitle: true,
        title: Text(
          'الفقه والفتاوى',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF8E24AA), const Color(0xFF5E1078)]
                      : [const Color(0xFF9C27B0), const Color(0xFF7B1FA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryAccent.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor:
                  isDark ? AppColors.textSecondary : AppColors.textMuted,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(
                  iconMargin: EdgeInsets.only(bottom: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.balance_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('الفقه الإسلامي'),
                    ],
                  ),
                ),
                Tab(
                  iconMargin: EdgeInsets.only(bottom: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.question_answer_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('فتاوى وإرشادات'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Fiqh
          _buildCategoryTab(
            part: 'فقه',
            searchCtrl: _fiqhSearchCtrl,
            onSearch: _onFiqhSearch,
            isLoading: _isFiqhLoading,
            categories: _filteredFiqhCategories,
            searchHint: 'بحث في أبواب الفقه...',
            iconData: Icons.balance_rounded,
            iconGradient: const [Color(0xFF8E24AA), Color(0xFF4A0072)],
            textColor: textColor,
            cardBg: cardBg,
            isDark: isDark,
          ),
          // Tab 2: Fatawa
          _buildCategoryTab(
            part: 'فتاوى',
            searchCtrl: _fatawaSearchCtrl,
            onSearch: _onFatawaSearch,
            isLoading: _isFatawaLoading,
            categories: _filteredFatawaCategories,
            searchHint: 'بحث في تصنيفات الفتاوى...',
            iconData: Icons.question_answer_rounded,
            iconGradient: const [Color(0xFFFFB300), Color(0xFFE65100)],
            textColor: textColor,
            cardBg: cardBg,
            isDark: isDark,
          ),
        ],
      ),
    ),
  );
}

  Widget _buildCategoryTab({
    required String part,
    required TextEditingController searchCtrl,
    required ValueChanged<String> onSearch,
    required bool isLoading,
    required List<Map<String, String>> categories,
    required String searchHint,
    required IconData iconData,
    required List<Color> iconGradient,
    required Color textColor,
    required Color cardBg,
    required bool isDark,
  }) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: searchCtrl,
            onChanged: onSearch,
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: searchHint,
              hintStyle: TextStyle(
                color: isDark ? AppColors.textSecondary : AppColors.textMuted,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: isDark ? AppColors.textSecondary : AppColors.emeraldDeep,
              ),
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

        // Categories List
        Expanded(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.emeraldLight,
                  ),
                )
              : categories.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد نتائج',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textMuted,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        return LiquidPressable(
                          onTap: () => _navigateToCategory(part, cat),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.04,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: iconGradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: iconGradient.first
                                            .withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    iconData,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    cat['title']!,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 15,
                                  color: isDark
                                      ? AppColors.textMuted
                                      : Colors.black26,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
