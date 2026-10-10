import 'package:flutter/material.dart';
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
    if (query.trim().isEmpty) {
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
    if (query.trim().isEmpty) {
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
    final bgColor = isDark ? const Color(0xFF090E11) : const Color(0xFFFAF7F0);
    final cardBg = isDark ? const Color(0xFF131C1A) : const Color(0xFFFFFDF9);
    final textColor = isDark ? const Color(0xFFF0F4F0) : const Color(0xFF0D3B2E);
    const primaryAccent = Color(0xFFAB47BC);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Text(
            'الفقه والفتاوى',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              fontFamily: 'Amiri',
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4A154B), Color(0xFF7A257C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryAccent.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? const Color(0xFF8A9995) : const Color(0xFF657B74),
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  fontFamily: 'Amiri',
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: 'Amiri',
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.balance_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('الفقه الإسلامي'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.question_answer_rounded, size: 16),
                        SizedBox(width: 6),
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
              searchHint: (Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar') == 'ar'
                  ? 'ابحث بالعربية في أبواب الفقه الإسلامي...'
                  : 'Search in Arabic in Islamic Fiqh chapters...',
              iconData: Icons.balance_rounded,
              iconGradient: const [Color(0xFF4A154B), Color(0xFF7A257C)],
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
              searchHint: (Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar') == 'ar'
                  ? 'ابحث بالعربية في تصنيفات الفتاوى الشرعية...'
                  : 'Search in Arabic in Fatawa categories...',
              iconData: Icons.question_answer_rounded,
              iconGradient: const [Color(0xFF744210), Color(0xFFB7791F)],
              textColor: textColor,
              cardBg: cardBg,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFiqhHeroCard(bool isFiqh) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: 142,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.65),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Authentic Masterpiece Andalusian Fiqh Artwork
            Image.asset(
              'assets/images/faculty_fiqh.webp',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF4A154B), Color(0xFF7A257C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),

            // Rich Multi-Stop Scrim Gradient
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.40),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.68),
                    Colors.black.withValues(alpha: 0.94),
                  ],
                  stops: const [0.0, 0.35, 0.68, 1.0],
                ),
              ),
            ),

            // Inner Gilded Rim
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                    width: 0.8,
                  ),
                ),
              ),
            ),

            // Content Structure
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Sacred Medallion + Explanatory Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0A1411).withValues(alpha: 0.80),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.80),
                            width: 1.2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black54,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isFiqh ? Icons.balance_rounded : Icons.question_answer_rounded,
                          color: const Color(0xFFFFD54F),
                          size: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF091210).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: const Color(0xFFD4AF37).withValues(alpha: 0.55),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars_rounded, color: Color(0xFFFFD54F), size: 12),
                            const SizedBox(width: 5),
                            Text(
                              isFiqh ? 'أبواب الفقه الإسلامي • 15 باباً معتمداً' : 'فتاوى كبار العلماء • 3,929 فتوى',
                              style: const TextStyle(
                                color: Color(0xFFFFF6D6),
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Amiri',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Bottom Plate: Title & Subtitle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF07100D).withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isFiqh ? 'الفقه الإسلامي وأحكام الشريعة' : 'فتاوى وإرشادات كبار الأئمة والعلماء',
                          style: const TextStyle(
                            color: Color(0xFFFFFBF0),
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5,
                            fontFamily: 'Amiri',
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isFiqh
                              ? 'أحكام العبادات والمعاملات والأحوال الشخصية الميسرة'
                              : 'فتاوى شرعية موثوقة بالأدلة من الكتاب والسنة النبوية',
                          style: const TextStyle(
                            color: Color(0xFFDFD5C4),
                            fontSize: 10.5,
                            fontFamily: 'Amiri',
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05);

    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
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
              controller: searchCtrl,
              onChanged: onSearch,
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: searchHint,
                hintStyle: TextStyle(
                  color: isDark ? const Color(0xFF6C7C78) : const Color(0xFF9AA8A4),
                  fontSize: 13,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFAB47BC), size: 20),
                suffixIcon: searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          searchCtrl.clear();
                          onSearch('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // Categories List
        Expanded(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFAB47BC)),
                )
              : categories.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد نتائج مطابقة',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF8A9995) : const Color(0xFF5A726A),
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: categories.length + (searchCtrl.text.isEmpty ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (searchCtrl.text.isEmpty && index == 0) {
                          return _buildFiqhHeroCard(part == 'فقه');
                        }
                        final actualIndex = index - (searchCtrl.text.isEmpty ? 1 : 0);
                        final cat = categories[actualIndex];
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
                              border: Border.all(color: borderColor, width: 1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: isDark ? 0.2 : 0.03,
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
                                    borderRadius: BorderRadius.circular(10),
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
                                      fontSize: 15.5,
                                      fontFamily: 'Amiri',
                                      height: 1.25,
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
    );
  }
}
