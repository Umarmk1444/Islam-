import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_text_styles.dart';
import '../models/minbar_models.dart';
import '../services/minbar_repository.dart';
import '../theme_notifier.dart';
import '../widgets/persistent_audio_bar.dart';
import '../widgets/liquid_pressable.dart';
import 'author_audio_screen.dart';

class AudioCategoriesScreen extends StatefulWidget {
  final int initialIndex;
  final bool onlyQuran;
  final bool excludeQuran;

  const AudioCategoriesScreen({
    super.key,
    this.initialIndex = 0,
    this.onlyQuran = false,
    this.excludeQuran = false,
  });

  @override
  State<AudioCategoriesScreen> createState() => _AudioCategoriesScreenState();
}

class _AudioCategoriesScreenState extends State<AudioCategoriesScreen> {
  final MinbarRepository _repository = MinbarRepository();
  late Future<List<MinbarCategory>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _repository.getCategories();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final isArabic = locale == 'ar';

    final String screenTitle = widget.onlyQuran
        ? (isArabic ? 'القرآن الكريم' : 'Holy Quran')
        : (isArabic ? 'صوتيات دعوية' : 'Islamic Audios');

    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final bg = AppTheme.getScreenBgColor(theme);
        final textColor = AppTheme.getMainTextColor(theme);
        final primaryColor = AppTheme.getPrimaryColor(theme);

        return FutureBuilder<List<MinbarCategory>>(
          future: _categoriesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Scaffold(
                backgroundColor: bg,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: IconThemeData(
                    color: theme == QuranTheme.cream
                        ? AppColors.emeraldDeep
                        : textColor,
                  ),
                  title: Text(
                    screenTitle,
                    style: TextStyle(
                      fontFamily: isArabic ? 'Amiri' : null,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme == QuranTheme.cream
                          ? AppColors.emeraldDeep
                          : textColor,
                    ),
                  ),
                  centerTitle: true,
                ),
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
              );
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return Scaffold(
                backgroundColor: bg,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: IconThemeData(
                    color: theme == QuranTheme.cream
                        ? AppColors.emeraldDeep
                        : textColor,
                  ),
                  title: Text(
                    screenTitle,
                    style: TextStyle(
                      fontFamily: isArabic ? 'Amiri' : null,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme == QuranTheme.cream
                          ? AppColors.emeraldDeep
                          : textColor,
                    ),
                  ),
                  centerTitle: true,
                ),
                body: Center(
                  child: Text(
                    isArabic ? 'خطأ في تحميل التصنيفات' : 'Error loading categories',
                    style: AppTextStyles.audioTitle.copyWith(color: textColor),
                  ),
                ),
              );
            }

            var categories = snapshot.data!;

            if (widget.onlyQuran) {
              categories = categories.where((c) => c.id == 'quran').toList();
            } else if (widget.excludeQuran) {
              categories = categories.where((c) => c.id != 'quran').toList();
            }

            return DefaultTabController(
              length: categories.length,
              initialIndex: widget.initialIndex,
              child: Scaffold(
                backgroundColor: bg,
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  iconTheme: IconThemeData(
                    color: theme == QuranTheme.cream
                        ? AppColors.emeraldDeep
                        : textColor,
                  ),
                  centerTitle: true,
                  title: Text(
                    screenTitle,
                    style: TextStyle(
                      fontFamily: isArabic ? 'Amiri' : null,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme == QuranTheme.cream
                          ? AppColors.emeraldDeep
                          : textColor,
                    ),
                  ),
                  bottom: TabBar(
                    isScrollable: true,
                    indicatorColor: theme == QuranTheme.cream
                        ? AppColors.emeraldDeep
                        : primaryColor,
                    labelColor: theme == QuranTheme.cream
                        ? AppColors.emeraldDeep
                        : primaryColor,
                    unselectedLabelColor: textColor.withValues(alpha: 0.5),
                    indicatorWeight: 3,
                    labelStyle: TextStyle(
                      fontFamily: isArabic ? 'Amiri' : null,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    tabs: categories.map((cat) {
                      String tabLabel = cat.name;
                      if (!isArabic) {
                        if (cat.id == 'quran') tabLabel = 'Holy Quran';
                        if (cat.id == 'khutbah') tabLabel = 'Khutbahs';
                        if (cat.id == 'lessons') tabLabel = 'Lessons';
                      }
                      return Tab(text: tabLabel);
                    }).toList(),
                  ),
                ),
                body: Column(
                  children: [
                    Expanded(
                      child: TabBarView(
                        children: categories.map((cat) {
                          return _CategoryAuthorsList(
                            categoryId: cat.id,
                            categoryName: cat.name,
                            theme: theme,
                            isSingleCategory: categories.length == 1,
                          );
                        }).toList(),
                      ),
                    ),
                    const PersistentAudioBar(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category Authors / Reciters Grid Widget
// ─────────────────────────────────────────────────────────────────────────────
class _CategoryAuthorsList extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final QuranTheme theme;
  final bool isSingleCategory;

  const _CategoryAuthorsList({
    required this.categoryId,
    required this.categoryName,
    required this.theme,
    this.isSingleCategory = false,
  });

  @override
  State<_CategoryAuthorsList> createState() => _CategoryAuthorsListState();
}

class _CategoryAuthorsListState extends State<_CategoryAuthorsList> {
  final MinbarRepository _repository = MinbarRepository();
  late Future<List<MinbarAuthor>> _authorsFuture;

  List<MinbarAuthor> _allAuthors = [];
  List<MinbarAuthor> _filteredAuthors = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _authorsFuture = _repository.getAuthorsForCategory(widget.categoryId);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredAuthors = _allAuthors;
      } else {
        _filteredAuthors = _allAuthors.where((author) {
          final nameLower = author.name.toLowerCase();
          final engNameLower = author.engName?.toLowerCase() ?? '';
          final englishNameLower = author.englishName?.toLowerCase() ?? '';

          final engNameCleaned = engNameLower.replaceAll('_', ' ').replaceAll('-', ' ');
          final englishNameCleaned = englishNameLower.replaceAll('_', ' ').replaceAll('-', ' ');

          return nameLower.contains(query) ||
              engNameLower.contains(query) ||
              englishNameLower.contains(query) ||
              engNameCleaned.contains(query) ||
              englishNameCleaned.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.theme == QuranTheme.dark;
    final cardBg = AppTheme.getCardBgColor(widget.theme);
    final textColor = AppTheme.getMainTextColor(widget.theme);
    final primaryColor = AppTheme.getPrimaryColor(widget.theme);
    final borderColor = widget.theme == QuranTheme.cream
        ? const Color(0xFFC9A84C).withValues(alpha: 0.3)
        : (isDark ? AppColors.divider : AppColors.textMuted.withValues(alpha: 0.2));

    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final isArabic = locale == 'ar';

    return Column(
      children: [
        // Elegant Local Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: 1.2,
              ),
            ),
            child: TextField(
              controller: _searchController,
              textAlign: isArabic ? TextAlign.right : TextAlign.left,
              style: TextStyle(fontSize: 14, color: textColor),
              decoration: InputDecoration(
                hintText: isArabic
                    ? 'البحث عن قارئ أو شيخ (بالعربية)...'
                    : 'Search reciter or scholar (in Arabic)...',
                hintStyle: TextStyle(
                  color: textColor.withValues(alpha: 0.4),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: widget.theme == QuranTheme.cream
                      ? AppColors.emeraldDeep
                      : primaryColor,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
        ),

        // Grid Content
        Expanded(
          child: FutureBuilder<List<MinbarAuthor>>(
            future: _authorsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      isArabic
                          ? 'خطأ في تحميل القائمة: ${snapshot.error}'
                          : 'Error loading list: ${snapshot.error}',
                      style: AppTextStyles.audioSubtitle
                          .copyWith(color: textColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              final authors = snapshot.data ?? [];
              if (authors.isEmpty) {
                return Center(
                  child: Text(
                    isArabic ? 'لا توجد نتائج متوفرة.' : 'No results found.',
                    style: AppTextStyles.audioTitle.copyWith(color: textColor),
                  ),
                );
              }

              if (_allAuthors.isEmpty) {
                _allAuthors = authors;
                _filteredAuthors = authors;
              }

              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                physics: const BouncingScrollPhysics(),
                itemCount: _filteredAuthors.length,
                itemBuilder: (context, index) {
                  final author = _filteredAuthors[index];
                  final letter = author.name.trim().isNotEmpty
                      ? author.name.trim().split(' ').last.substring(0, 1)
                      : 'م';

                  final avatarColor = widget.theme == QuranTheme.cream
                      ? AppColors.emeraldDeep
                      : primaryColor;

                  final riwayahTag = author.type != null && author.type!.trim().isNotEmpty
                      ? author.type!.trim()
                      : (widget.categoryId == 'quran' ? 'مصحف مرتل' : 'تسجيل صوتي');

                  return LiquidPressable(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AuthorAudioScreen(
                            categoryId: widget.categoryId,
                            authorId: author.id,
                            authorName: author.name,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: borderColor,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          // circular letter avatar
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  avatarColor.withValues(alpha: 0.9),
                                  avatarColor.withValues(alpha: 0.65),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: avatarColor.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                letter,
                                style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          // name & tag
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  author.name,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    color: widget.theme == QuranTheme.cream
                                        ? AppColors.emeraldDeep
                                        : textColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                                ),
                                const SizedBox(height: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: avatarColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: avatarColor.withValues(alpha: 0.2),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    riwayahTag,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: avatarColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.play_circle_fill_rounded,
                            color: avatarColor,
                            size: 30,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
