import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:share_plus/share_plus.dart';
import '../models/library_item.dart';
import '../models/fatwa_item.dart';
import '../models/roqua_item.dart';
import '../services/library_service.dart';
import '../theme_notifier.dart';

enum ReadingTheme {
  light,
  sepia, // Cream / Warm Parchment (Default for all library reading)
  dark,
}

class StoryReadingScreen extends StatefulWidget {
  final List<dynamic>? items;
  final int initialIndex;
  final LibraryItem? item;
  final FatwaItem? fatwaItem;
  final RoquaItem? roquaItem;
  final String? categoryTitle;

  const StoryReadingScreen({
    super.key,
    this.items,
    this.initialIndex = 0,
    this.item,
    this.fatwaItem,
    this.roquaItem,
    this.categoryTitle,
  }) : assert(items != null || item != null || fatwaItem != null || roquaItem != null);

  @override
  State<StoryReadingScreen> createState() => _StoryReadingScreenState();
}

class _StoryReadingScreenState extends State<StoryReadingScreen> {
  final LibraryService _libraryService = LibraryService();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();

  late int _currentIndex;
  late List<dynamic> _itemList;
  late bool _isBukhariStream;

  final Map<int, String> _contentCache = {};
  final Map<int, bool> _favCache = {};

  double _fontSize = 20.0;
  ReadingTheme _readingTheme = ReadingTheme.sepia; // Warm Cream default everywhere
  String _chapterName = '';

  @override
  void initState() {
    super.initState();
    final globalTheme = AppTheme.notifier.value;
    if (globalTheme == QuranTheme.white) {
      _readingTheme = ReadingTheme.light;
    } else if (globalTheme == QuranTheme.dark) {
      _readingTheme = ReadingTheme.dark;
    } else {
      _readingTheme = ReadingTheme.sepia; // Default to Cream
    }

    if (widget.items != null && widget.items!.isNotEmpty) {
      _itemList = widget.items!;
      _currentIndex = widget.initialIndex.clamp(0, _itemList.length - 1);
      final first = _itemList.first;
      _isBukhariStream = first is LibraryItem &&
          (first.part == 'صحيح البخارى' || first.part == 'البخارى');
    } else {
      final singleItem = widget.item ?? widget.fatwaItem ?? widget.roquaItem;
      _itemList = [singleItem];
      _currentIndex = 0;
      _isBukhariStream = false;
    }

    _initChapterName();
    _loadContentForIndex(_currentIndex);

    if (_isBukhariStream) {
      _itemPositionsListener.itemPositions.addListener(() {
        final positions = _itemPositionsListener.itemPositions.value;
        if (positions.isNotEmpty) {
          final firstVisible = positions.first.index;
          if (firstVisible >= 0 &&
              firstVisible < _itemList.length &&
              firstVisible != _currentIndex) {
            setState(() {
              _currentIndex = firstVisible;
            });
            _loadContentForIndex(firstVisible);
          }
        }
      });
    }
  }

  Future<void> _initChapterName() async {
    if (widget.categoryTitle != null &&
        widget.categoryTitle!.trim().isNotEmpty &&
        widget.categoryTitle != 'المفضلة' &&
        int.tryParse(widget.categoryTitle!.trim()) == null) {
      _chapterName = widget.categoryTitle!.trim();
    } else {
      final current = _itemList.first;
      if (current is LibraryItem) {
        if (current.type.isNotEmpty && int.tryParse(current.type) == null) {
          _chapterName = current.type;
        } else {
          final fetched =
              await _libraryService.getCategoryTitleById(current.part, current.type);
          if (mounted) setState(() => _chapterName = fetched);
        }
      }
    }
  }

  Future<String> _loadContentForIndex(int index) async {
    if (index < 0 || index >= _itemList.length) return '';
    if (_contentCache.containsKey(index)) return _contentCache[index]!;

    final item = _itemList[index];
    String content = '';
    bool isFav = false;

    if (item is LibraryItem) {
      isFav = item.isFav;
      _libraryService.recordReading(item.id, item.numReadings);
      content = await _libraryService.getLibraryStory(item.id);
    } else if (item is FatwaItem) {
      content = await _libraryService.getFatwaAnswer(item.id);
    } else if (item is RoquaItem) {
      content = await _libraryService.getRoquaStory(item.id);
    }

    if (mounted) {
      setState(() {
        _contentCache[index] = content;
        _favCache[index] = isFav;
      });
    }
    return content;
  }

  Future<void> _toggleFav(int index) async {
    final item = _itemList[index];
    if (item is LibraryItem) {
      final currentFav = _favCache[index] ?? item.isFav;
      final newFav = !currentFav;
      await _libraryService.toggleFavorite(item.id, newFav);
      setState(() {
        _favCache[index] = newFav;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newFav ? 'تمت الإضافة إلى المفضلة' : 'تمت الإزالة من المفضلة',
              textAlign: TextAlign.center,
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _increaseFontSize() {
    setState(() {
      if (_fontSize < 36) _fontSize += 2.0;
    });
  }

  void _decreaseFontSize() {
    setState(() {
      if (_fontSize > 14) _fontSize -= 2.0;
    });
  }

  String _formatCitation(int index) {
    final item = _itemList[index];
    final content = _contentCache[index] ?? '';
    final buffer = StringBuffer();
    buffer.writeln('بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ\n');
    buffer.writeln(content.trim());
    buffer.writeln('\n────────────────────');

    if (item is LibraryItem) {
      final bookName = item.part.isNotEmpty ? item.part : 'المكتبة الإسلامية';
      buffer.writeln('📖 الكتاب: $bookName');
      if (_chapterName.isNotEmpty &&
          _chapterName != item.title &&
          _chapterName != 'المفضلة') {
        buffer.writeln('📑 الباب / القسم: $_chapterName');
      }
      if (_isBukhariStream && _itemList.length > 1) {
        buffer.writeln('🔢 رقم الحديث: ${index + 1}');
      }
    } else if (item is FatwaItem) {
      buffer.writeln('📖 المصدر: الفقه والفتاوى');
      if (item.fatwyType.isNotEmpty) {
        buffer.writeln('📑 التصنيف: ${item.fatwyType}');
      }
      if (item.moftyName.isNotEmpty) {
        buffer.writeln('👤 المفتي: ${item.moftyName}');
      }
      buffer.writeln('❓ السؤال: ${item.question}');
    } else if (item is RoquaItem) {
      buffer.writeln('📖 المصدر: الرقية الشرعية');
      if (item.level.isNotEmpty) {
        buffer.writeln('📑 المرحلة: ${item.level}');
      }
    }
    return buffer.toString();
  }

  void _copyContent(int index) {
    final textToCopy = _formatCitation(index);
    if (textToCopy.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: textToCopy));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم نسخ النص مع التوثيق والمصدر بنجاح',
            textAlign: TextAlign.center,
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _shareContent(int index) {
    final textToShare = _formatCitation(index);
    if (textToShare.isNotEmpty) {
      Share.share(
        textToShare,
        subject: _chapterName.isNotEmpty ? _chapterName : 'مادة من المكتبة الإسلامية',
      );
    }
  }

  void _cycleReadingTheme() {
    setState(() {
      if (_readingTheme == ReadingTheme.sepia) {
        _readingTheme = ReadingTheme.light;
      } else if (_readingTheme == ReadingTheme.light) {
        _readingTheme = ReadingTheme.dark;
      } else {
        _readingTheme = ReadingTheme.sepia;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // ── Warm Cream / Sepia Palette as Default ─────────────────────────────────
    Color pageBg;
    Color textColor;
    Color topBarColor;
    Color cardBg;
    Color accentColor;
    Color actionBtnBg;

    switch (_readingTheme) {
      case ReadingTheme.sepia: // Warm Cream / Parchment (Default)
        pageBg = const Color(0xFFFBF6ED);
        cardBg = const Color(0xFFF4ECE0);
        textColor = const Color(0xFF2B1D14);
        topBarColor = const Color(0xFFEFE4D2);
        accentColor = const Color(0xFF8B5319);
        actionBtnBg = const Color(0xFFE8DAC3);
        break;
      case ReadingTheme.light:
        pageBg = const Color(0xFFFAF8F5);
        cardBg = Colors.white;
        textColor = const Color(0xFF1B2A26);
        topBarColor = const Color(0xFFEDE8DF);
        accentColor = const Color(0xFF0F5A47);
        actionBtnBg = const Color(0xFFE8F1EC);
        break;
      case ReadingTheme.dark:
        pageBg = const Color(0xFF090E11);
        cardBg = const Color(0xFF131C1A);
        textColor = const Color(0xFFE8EFEB);
        topBarColor = const Color(0xFF131D1A);
        accentColor = const Color(0xFF2ECC9A);
        actionBtnBg = const Color(0xFF1E2C28);
        break;
    }

    final singleItem = _itemList.first;
    final String mainTitle = singleItem is LibraryItem
        ? singleItem.title
        : singleItem is FatwaItem
            ? singleItem.question
            : (singleItem as RoquaItem).title;

    final String displayTag = _chapterName.isNotEmpty
        ? _chapterName
        : (singleItem is LibraryItem
            ? (singleItem.part.isNotEmpty ? singleItem.part : 'المكتبة')
            : (singleItem is FatwaItem ? 'فتاوى' : 'رقية شرعية'));

    final bool isSingleFav = _favCache[0] ??
        (singleItem is LibraryItem ? singleItem.isFav : false);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: topBarColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            _isBukhariStream ? displayTag : mainTitle,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 16.5,
              fontFamily: 'Amiri',
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: true,
          actions: [
            // Theme Switcher
            IconButton(
              icon: Icon(
                _readingTheme == ReadingTheme.sepia
                    ? Icons.palette_outlined
                    : _readingTheme == ReadingTheme.light
                        ? Icons.wb_sunny_outlined
                        : Icons.dark_mode_outlined,
                color: accentColor,
                size: 21,
              ),
              tooltip: 'تغيير المظهر (كريمي / فاتح / داكن)',
              onPressed: _cycleReadingTheme,
            ),
            // Actions for single reading mode
            if (!_isBukhariStream) ...[
              IconButton(
                icon: Icon(Icons.copy_rounded, color: textColor, size: 20),
                tooltip: 'نسخ النص',
                onPressed: () => _copyContent(0),
              ),
              IconButton(
                icon: Icon(Icons.share_rounded, color: textColor, size: 20),
                tooltip: 'مشاركة',
                onPressed: () => _shareContent(0),
              ),
              if (singleItem is LibraryItem)
                IconButton(
                  icon: Icon(
                    isSingleFav
                        ? Icons.bookmark_added_rounded
                        : Icons.bookmark_border_rounded,
                    color: isSingleFav ? const Color(0xFFD4AF37) : textColor,
                    size: 22,
                  ),
                  tooltip: 'المفضلة',
                  onPressed: () => _toggleFav(0),
                ),
            ],
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            // ── Reading Control Bar (Displaying Chapter Name & Font Scaler) ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: topBarColor.withValues(alpha: 0.7),
                border: Border(
                  bottom: BorderSide(
                    color: textColor.withValues(alpha: 0.08),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Chapter Name Badge
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.menu_book_rounded,
                                  size: 14, color: accentColor),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _isBukhariStream
                                      ? '$displayTag (${_currentIndex + 1} من ${_itemList.length})'
                                      : displayTag,
                                  style: TextStyle(
                                    color: accentColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    fontFamily: 'Amiri',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Font Scaling Controls
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.text_decrease_rounded,
                            color: textColor, size: 20),
                        onPressed: _decreaseFontSize,
                        tooltip: 'تصغير الخط',
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '${_fontSize.toInt()}',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.text_increase_rounded,
                            color: textColor, size: 20),
                        onPressed: _increaseFontSize,
                        tooltip: 'تكبير الخط',
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Reading Viewport (Bukhari Stream vs Single Document) ────────
            Expanded(
              child: _isBukhariStream
                  ? ScrollablePositionedList.builder(
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                      initialScrollIndex: _currentIndex,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
                      itemCount: _itemList.length,
                      itemBuilder: (context, index) {
                        final isFirstItem = index == 0;
                        final item = _itemList[index];
                        final bool isFav = _favCache[index] ??
                            (item is LibraryItem ? item.isFav : false);

                        return FutureBuilder<String>(
                          future: _loadContentForIndex(index),
                          builder: (context, snapshot) {
                            final content =
                                snapshot.data ?? _contentCache[index] ?? '';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Bismillah Calligraphy ONLY at the very top of the chapter
                                if (isFirstItem) ...[
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                          top: 8, bottom: 20),
                                      child: Text(
                                        'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'Amiri',
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: accentColor,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                // Hadith Card
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: textColor.withValues(alpha: 0.08),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: _readingTheme ==
                                                  ReadingTheme.dark
                                              ? 0.25
                                              : 0.03,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Hadith Number Pill
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: accentColor
                                                  .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'حديث رقم ${index + 1}',
                                              style: TextStyle(
                                                color: accentColor,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Amiri',
                                              ),
                                            ),
                                          ),
                                          if (item is LibraryItem &&
                                              item.numReadings > 0)
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.remove_red_eye_rounded,
                                                  size: 13,
                                                  color: Color(0xFFD4AF37),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${item.numReadings} قراءة',
                                                  style: TextStyle(
                                                    color: textColor
                                                        .withValues(alpha: 0.55),
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),

                                      const SizedBox(height: 14),

                                      // Hadith Text Body
                                      if (content.isEmpty)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 20),
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              color: accentColor,
                                              strokeWidth: 2.5,
                                            ),
                                          ),
                                        )
                                      else
                                        SelectableText(
                                          content,
                                          style: TextStyle(
                                            fontFamily: 'Amiri',
                                            color: textColor,
                                            fontSize: _fontSize,
                                            height: 1.9,
                                            letterSpacing: 0.1,
                                          ),
                                          textAlign: TextAlign.justify,
                                        ),

                                      const SizedBox(height: 16),
                                      Divider(
                                        color:
                                            textColor.withValues(alpha: 0.08),
                                        height: 1,
                                      ),
                                      const SizedBox(height: 10),

                                      // Action Bar: Copy | Fav | Share
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          _buildActionBtn(
                                            icon: Icons.copy_rounded,
                                            label: 'نسخ',
                                            onTap: () => _copyContent(index),
                                            textColor: textColor,
                                            accentColor: accentColor,
                                            btnBg: actionBtnBg,
                                          ),
                                          if (item is LibraryItem)
                                            _buildActionBtn(
                                              icon: isFav
                                                  ? Icons.bookmark_added_rounded
                                                  : Icons.bookmark_border_rounded,
                                              label: isFav ? 'المفضلة' : 'حفظ',
                                              onTap: () => _toggleFav(index),
                                              textColor: isFav
                                                  ? const Color(0xFFB8860B)
                                                  : textColor,
                                              accentColor: isFav
                                                  ? const Color(0xFFD4AF37)
                                                  : accentColor,
                                              btnBg: actionBtnBg,
                                            ),
                                          _buildActionBtn(
                                            icon: Icons.share_rounded,
                                            label: 'مشاركة',
                                            onTap: () => _shareContent(index),
                                            textColor: textColor,
                                            accentColor: accentColor,
                                            btnBg: actionBtnBg,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                if (index < _itemList.length - 1)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Center(
                                      child: Text(
                                        '✦ ✦ ✦',
                                        style: TextStyle(
                                          color: accentColor
                                              .withValues(alpha: 0.4),
                                          fontSize: 13,
                                          letterSpacing: 4,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    )
                  : FutureBuilder<String>(
                      future: _loadContentForIndex(0),
                      builder: (context, snapshot) {
                        final content = snapshot.data ?? _contentCache[0] ?? '';

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 22, vertical: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Bismillah
                              Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 18, top: 4),
                                  child: Text(
                                    'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 21,
                                      fontWeight: FontWeight.bold,
                                      color: accentColor,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ),

                              // Article / Book Title
                              Text(
                                mainTitle,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: _fontSize + 3,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                  height: 1.35,
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Main Text Body
                              if (content.isEmpty)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 40),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: accentColor,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              else
                                SelectableText(
                                  content,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    color: textColor,
                                    fontSize: _fontSize,
                                    height: 1.9,
                                    letterSpacing: 0.1,
                                  ),
                                  textAlign: TextAlign.justify,
                                ),

                              const SizedBox(height: 30),

                              // Source Attribution Card
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: topBarColor.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: textColor.withValues(alpha: 0.07),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.auto_stories_rounded,
                                        size: 16, color: accentColor),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        displayTag,
                                        style: TextStyle(
                                          color: textColor
                                              .withValues(alpha: 0.75),
                                          fontSize: 13,
                                          fontFamily: 'Amiri',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              Center(
                                child: Text(
                                  '✦ ✦ ✦',
                                  style: TextStyle(
                                    color: accentColor.withValues(alpha: 0.5),
                                    fontSize: 16,
                                    letterSpacing: 6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color textColor,
    required Color accentColor,
    required Color btnBg,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: btnBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: accentColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                fontFamily: 'Amiri',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
