import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../theme_notifier.dart';
import '../services/library_service.dart';
import '../models/roqua_item.dart';
import 'story_reading_screen.dart';

class RuqyahScreen extends StatefulWidget {
  const RuqyahScreen({super.key});

  @override
  State<RuqyahScreen> createState() => _RuqyahScreenState();
}

class _RuqyahScreenState extends State<RuqyahScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _stages = [
    'المرحلة الأولى',
    'المرحلة الثانية',
    'المرحلة الثالثة',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _stages.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.notifier.value;
    final isDark = theme == QuranTheme.dark;

    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimary : AppColors.emeraldDeep;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'الرقية الشرعية',
          style: TextStyle(
              color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: AppColors.emeraldLight,
          labelColor: AppColors.emeraldLight,
          unselectedLabelColor:
              isDark ? AppColors.textSecondary : AppColors.textMuted,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: _stages.map((stage) => Tab(text: stage)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _stages.map((stage) => _RuqyahListTab(stage: stage)).toList(),
      ),
    );
  }
}

class _RuqyahListTab extends StatefulWidget {
  final String stage;
  const _RuqyahListTab({required this.stage});

  @override
  State<_RuqyahListTab> createState() => _RuqyahListTabState();
}

class _RuqyahListTabState extends State<_RuqyahListTab> {
  final LibraryService _libraryService = LibraryService();
  List<RoquaItem> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _libraryService.getRoquaItems(widget.stage);
    if (mounted) {
      setState(() {
        _items = items;
        _isLoading = false;
      });
    }
  }

  void _openItem(RoquaItem item) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => StoryReadingScreen(roquaItem: item)));
  }

  void _showBenefitDialog(RoquaItem item) {
    if (item.info.isEmpty) {
      final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
      String noInfo = 'لا توجد فوائد مسجلة';
      if (locale == 'en') noInfo = 'No benefits recorded';
      if (locale == 'am') noInfo = 'ምንም የተመዘገቡ ጥቅሞች የሉም';
      if (locale == 'om') noInfo = 'Faayidaan galmaa\'e hin jiru';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(noInfo),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final theme = AppTheme.notifier.value;
    final isDark = theme == QuranTheme.dark;
    final bgColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimary : AppColors.emeraldDeep;
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';

    String titleText = 'الفوائد';
    if (locale == 'en') titleText = 'Benefits';
    if (locale == 'am') titleText = 'ጥቅሞች';
    if (locale == 'om') titleText = 'Faayidaa';

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: AppColors.emeraldLight, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    titleText,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    item.info,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.textMuted,
                      fontSize: 16,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.notifier.value;
    final isDark = theme == QuranTheme.dark;
    final cardBg = isDark ? AppColors.surfaceCard : AppColors.surfaceCardLight;
    final textColor = isDark ? AppColors.textPrimary : AppColors.emeraldDeep;

    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.emeraldLight));
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'No items found.',
          style: TextStyle(
              color: isDark ? AppColors.textSecondary : AppColors.emeraldDeep),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];

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
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _openItem(item),
              onLongPress: () => _showBenefitDialog(item),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.emeraldLight.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.healing_rounded,
                        color: AppColors.emeraldLight,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item.title,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: TextDirection.rtl,
                      ),
                    ),
                    if (item.info.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _showBenefitDialog(item),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.info_outline_rounded,
                              color: isDark
                                  ? AppColors.textSecondary
                                  : AppColors.textMuted,
                              size: 22,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
