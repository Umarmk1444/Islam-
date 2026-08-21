import 'package:flutter/material.dart';
import '../theme_notifier.dart';
import '../services/library_service.dart';
import '../models/roqua_item.dart';
import 'story_reading_screen.dart';
import '../widgets/liquid_pressable.dart';

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
    final bgColor = isDark ? const Color(0xFF090E11) : const Color(0xFFFAF7F0);
    final cardBg = isDark ? const Color(0xFF131C1A) : const Color(0xFFFFFDF9);
    final textColor = isDark ? const Color(0xFFF0F4F0) : const Color(0xFF0D3B2E);
    const accentPink = Color(0xFFED64A6);

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
          title: Text(
            'الرقية الشرعية',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              fontFamily: 'Amiri',
            ),
          ),
          centerTitle: true,
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
                    colors: [Color(0xFF702459), Color(0xFF97266D)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentPink.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? const Color(0xFF8A9995) : const Color(0xFF657B74),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, fontFamily: 'Amiri'),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, fontFamily: 'Amiri'),
                dividerColor: Colors.transparent,
                tabs: _stages.map((stage) => Tab(text: stage)).toList(),
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: _stages.map((stage) => _RuqyahListTab(stage: stage)).toList(),
        ),
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
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StoryReadingScreen(roquaItem: item)),
    );
  }

  void _showBenefitDialog(RoquaItem item) {
    if (item.info.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد فوائد مسجلة لهذه الآية/الدعاء', textAlign: TextAlign.center),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final theme = AppTheme.notifier.value;
    final isDark = theme == QuranTheme.dark;
    final bgColor = isDark ? const Color(0xFF131C1A) : Colors.white;
    final textColor = isDark ? const Color(0xFFF0F4F0) : const Color(0xFF0D3B2E);

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
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
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFFED64A6), size: 24),
                  const SizedBox(width: 10),
                  Text(
                    'فوائد وتوجيهات الرقية',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Amiri',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    item.info,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15.5,
                      height: 1.8,
                      fontFamily: 'Amiri',
                    ),
                    textAlign: TextAlign.center,
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
    final cardBg = isDark ? const Color(0xFF131C1A) : const Color(0xFFFFFDF9);
    final textColor = isDark ? const Color(0xFFF0F4F0) : const Color(0xFF0D3B2E);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE8DFC8);

    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFED64A6)),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(
          'لا توجد عناصر مسجلة في هذه المرحلة',
          style: TextStyle(
            color: isDark ? const Color(0xFF8A9995) : const Color(0xFF5A726A),
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];

        return LiquidPressable(
          onTap: () => _openItem(item),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14.0),
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
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFED64A6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.healing_rounded,
                    color: Color(0xFFED64A6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.5,
                      fontFamily: 'Amiri',
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.info.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFFED64A6)),
                    tooltip: 'عرض الفوائد',
                    onPressed: () => _showBenefitDialog(item),
                  )
                else
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black26),
              ],
            ),
          ),
        );
      },
    );
  }
}
