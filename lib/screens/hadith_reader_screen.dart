import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import '../models/hadith_models.dart';
import '../services/hadith_service.dart';
import '../theme_notifier.dart';
import '../widgets/circular_theme_reveal.dart';
import 'story_reading_screen.dart' show ReadingTheme;

sealed class _ReaderListItem {}

class _ReaderBookHeaderItem extends _ReaderListItem {
  final HadithBook book;
  _ReaderBookHeaderItem(this.book);
}

class _ReaderChapterHeaderItem extends _ReaderListItem {
  final HadithChapter chapter;
  final int chapterIndex;
  _ReaderChapterHeaderItem(this.chapter, this.chapterIndex);
}

class _ReaderHadithEntryItem extends _ReaderListItem {
  final HadithItem hadith;
  final int hadithIndex;
  _ReaderHadithEntryItem(this.hadith, this.hadithIndex);
}

class HadithReaderScreen extends StatefulWidget {
  final HadithCollection collection;
  final HadithBook book;
  final HadithChapter? chapter;
  final int? initialHadithIndex;

  const HadithReaderScreen({
    super.key,
    required this.collection,
    required this.book,
    this.chapter,
    this.initialHadithIndex,
  });

  @override
  State<HadithReaderScreen> createState() => _HadithReaderScreenState();
}

class _HadithReaderScreenState extends State<HadithReaderScreen> {
  final HadithService _hadithService = HadithService();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final CircularThemeRevealController _themeRevealCtrl = CircularThemeRevealController();

  List<HadithItem> _hadiths = [];
  List<HadithChapter> _chapters = [];
  List<_ReaderListItem> _listItems = [];

  bool _isLoading = true;
  String? _errorMessage;
  double _fontSize = 20.0;
  bool _showIsnad = true;
  int _initialTargetIndex = 0;
  ReadingTheme _readingTheme = ReadingTheme.sepia;
  bool _showTopBar = true;
  double _accumulatedUpwardScroll = 0.0;
  double _accumulatedDownwardScroll = 0.0;

  @override
  void initState() {
    super.initState();
    final globalTheme = AppTheme.notifier.value;
    if (globalTheme == QuranTheme.white) {
      _readingTheme = ReadingTheme.light;
    } else if (globalTheme == QuranTheme.dark) {
      _readingTheme = ReadingTheme.dark;
    } else {
      _readingTheme = ReadingTheme.sepia;
    }
    _loadFontSize();
    _loadHadiths();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('hadith_reader_font_size') ?? 20.0;
      _showIsnad = prefs.getBool('hadith_reader_show_isnad') ?? true;
    });
  }

  Future<void> _saveFontSize(double size) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('hadith_reader_font_size', size);
  }

  Future<void> _saveShowIsnad(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hadith_reader_show_isnad', val);
  }

  String _arabicOrdinal(int n) {
    switch (n) {
      case 1:
        return 'الباب الأول';
      case 2:
        return 'الباب الثاني';
      case 3:
        return 'الباب الثالث';
      case 4:
        return 'الباب الرابع';
      case 5:
        return 'الباب الخامس';
      case 6:
        return 'الباب السادس';
      case 7:
        return 'الباب السابع';
      case 8:
        return 'الباب الثامن';
      case 9:
        return 'الباب التاسع';
      case 10:
        return 'الباب العاشر';
      case 11:
        return 'الباب الحادي عشر';
      case 12:
        return 'الباب الثاني عشر';
      case 13:
        return 'الباب الثالث عشر';
      case 14:
        return 'الباب الرابع عشر';
      case 15:
        return 'الباب الخامس عشر';
      case 16:
        return 'الباب السادس عشر';
      case 17:
        return 'الباب السابع عشر';
      case 18:
        return 'الباب الثامن عشر';
      case 19:
        return 'الباب التاسع عشر';
      case 20:
        return 'الباب العشرون';
      case 21:
        return 'الباب الحادي والعشرون';
      case 22:
        return 'الباب الثاني والعشرون';
      case 23:
        return 'الباب الثالث والعشرون';
      case 24:
        return 'الباب الرابع والعشرون';
      case 25:
        return 'الباب الخامس والعشرون';
      case 26:
        return 'الباب السادس والعشرون';
      case 27:
        return 'الباب السابع والعشرون';
      case 28:
        return 'الباب الثامن والعشرون';
      case 29:
        return 'الباب التاسع والعشرون';
      case 30:
        return 'الباب الثلاثون';
      case 31:
        return 'الباب الحادي والثلاثون';
      case 32:
        return 'الباب الثاني والثلاثون';
      case 33:
        return 'الباب الثالث والثلاثون';
      case 34:
        return 'الباب الرابع والثلاثون';
      case 35:
        return 'الباب الخامس والثلاثون';
      case 36:
        return 'الباب السادس والثلاثون';
      case 37:
        return 'الباب السابع والثلاثون';
      case 38:
        return 'الباب الثامن والثلاثون';
      case 39:
        return 'الباب التاسع والثلاثون';
      case 40:
        return 'الباب الأربعون';
      case 50:
        return 'الباب الخمسون';
      default:
        return 'الباب $n';
    }
  }

  String _formatChapterLabel(HadithChapter chapter, int displayIndex) {
    final num val = chapter.chapterNumber;
    if (val > 0) {
      if (val % 1 == 0) {
        final int n = val.toInt();
        return '${_arabicOrdinal(n)} ($n)';
      } else {
        return 'الباب $val';
      }
    }
    return '${_arabicOrdinal(displayIndex)} ($displayIndex)';
  }

  Future<void> _loadHadiths() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      // 1. Fetch all hadiths of the book in exact sequence
      final items = await _hadithService.getHadithsByBook(
        widget.collection.id,
        widget.book.id,
        limit: 5000,
      );

      // 2. Fetch all chapters of the book if collection supports chapters
      List<HadithChapter> chapters = [];
      if (widget.collection.hasChapters) {
        chapters = await _hadithService.getChapters(
          widget.collection.id,
          widget.book.id,
        );
      }

      final List<_ReaderListItem> flatItems = [];

      // Grand Book Header
      flatItems.add(_ReaderBookHeaderItem(widget.book));

      if (chapters.isNotEmpty) {
        final chapIds = chapters.map((c) => c.id).toList();
        int nextChapIdx = 0;

        for (int i = 0; i < items.length; i++) {
          final hadith = items[i];
          final chapId = hadith.chapterId;

          // If this hadith belongs to a chapter at or ahead of nextChapIdx, emit preceding chapters first!
          if (chapId != null && chapIds.contains(chapId)) {
            final targetIdx = chapIds.indexOf(chapId);
            if (targetIdx >= nextChapIdx) {
              while (nextChapIdx <= targetIdx) {
                final c = chapters[nextChapIdx];
                flatItems.add(_ReaderChapterHeaderItem(c, nextChapIdx + 1));
                nextChapIdx++;
              }
            }
          }

          flatItems.add(_ReaderHadithEntryItem(hadith, i));
        }

        // Emit any trailing chapters that may have no attached hadiths
        while (nextChapIdx < chapters.length) {
          final c = chapters[nextChapIdx];
          flatItems.add(_ReaderChapterHeaderItem(c, nextChapIdx + 1));
          nextChapIdx++;
        }
      } else {
        // If collection has no chapters (e.g. 40 Hadith Nawawi, Muwatta)
        for (int i = 0; i < items.length; i++) {
          flatItems.add(_ReaderHadithEntryItem(items[i], i));
        }
      }

      // Calculate initial scroll position
      int targetScrollIdx = 0;
      if (widget.chapter != null) {
        final idx = flatItems.indexWhere(
          (it) => it is _ReaderChapterHeaderItem && it.chapter.id == widget.chapter!.id,
        );
        if (idx >= 0) targetScrollIdx = idx;
      } else if (widget.initialHadithIndex != null && widget.initialHadithIndex! > 0) {
        final idx = flatItems.indexWhere(
          (it) => it is _ReaderHadithEntryItem && it.hadithIndex == widget.initialHadithIndex,
        );
        if (idx >= 0) targetScrollIdx = idx;
      }

      if (mounted) {
        setState(() {
          _hadiths = items;
          _chapters = chapters;
          _listItems = flatItems;
          _initialTargetIndex = targetScrollIdx;
          _isLoading = false;
        });

        // Record reading for first item
        if (items.isNotEmpty) {
          _hadithService.recordReading(items.first.id, widget.collection.id);
        }
      }
    } catch (e) {
      debugPrint('[HadithReaderScreen] Error loading hadiths: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _jumpToChapter(int chapterId) {
    final targetIndex = _listItems.indexWhere(
      (it) => it is _ReaderChapterHeaderItem && it.chapter.id == chapterId,
    );
    if (targetIndex >= 0 && _itemScrollController.isAttached) {
      _itemScrollController.scrollTo(
        index: targetIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _toggleFavorite(HadithItem item, int index) async {
    final newFav = !item.isFavorite;
    await _hadithService.toggleFavorite(item.id, item.collectionId, newFav);
    final updated = item.copyWith(isFavorite: newFav);
    setState(() {
      final hadithIdx = _hadiths.indexWhere((h) => h.id == item.id);
      if (hadithIdx >= 0) {
        _hadiths[hadithIdx] = updated;
      }
      final flatIdx = _listItems.indexWhere((it) => it is _ReaderHadithEntryItem && it.hadith.id == item.id);
      if (flatIdx >= 0) {
        _listItems[flatIdx] = _ReaderHadithEntryItem(updated, index);
      }
    });

    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newFav ? 'تمت إضافة الحديث إلى المفضلة' : 'تمت إزالة الحديث من المفضلة',
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 13),
          ),
          backgroundColor: newFav ? const Color(0xFF1B8A6B) : Colors.grey.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(milliseconds: 1400),
        ),
      );
    }
  }

  void _shareHadith(HadithItem item) {
    const playStoreUrl = 'https://play.google.com/store/apps/details?id=com.umer.quranzone';
    final hasSeparateIsnad = item.isnadAr != null &&
        item.isnadAr!.trim().isNotEmpty &&
        item.matnAr != null &&
        item.matnAr!.trim().isNotEmpty;

    final buffer = StringBuffer();
    buffer.writeln('📖 كتاب: ${widget.book.nameAr}');
    buffer.writeln('📚 من: ${widget.collection.nameAr}');
    buffer.writeln('🔢 حديث رقم: ${item.hadithNumber}');
    if (item.grade != null && item.grade!.trim().isNotEmpty) {
      buffer.writeln('⚖️ درجة الحديث: ${item.grade!.trim()}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    if (_showIsnad && hasSeparateIsnad) {
      buffer.writeln('${item.isnadAr!.trim()}\n');
    }
    buffer.writeln(hasSeparateIsnad ? item.matnAr!.trim() : item.arabicText.trim());
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📱 تم الإرسال عبر تطبيق Quran Zone (منطقة القرآن)');
    buffer.writeln('✨ اقرأ القرآن الكريم، الأحاديث النبوية، الأذكار، والكتب والمستندات الإسلامية بكل سهولة.');
    buffer.writeln('📥 حمّل تطبيق Quran Zone الآن مجاناً من متجر Google Play:');
    buffer.write(playStoreUrl);

    Share.share(
      buffer.toString(),
      subject: '${widget.collection.nameAr} - حديث رقم ${item.hadithNumber}',
    );
  }

  void _copyHadith(HadithItem item) {
    final hasSeparateIsnad = item.isnadAr != null &&
        item.isnadAr!.trim().isNotEmpty &&
        item.matnAr != null &&
        item.matnAr!.trim().isNotEmpty;

    final buffer = StringBuffer();
    if (_showIsnad && hasSeparateIsnad) {
      buffer.writeln('${item.isnadAr!.trim()}\n');
    }
    buffer.writeln(hasSeparateIsnad ? item.matnAr!.trim() : item.arabicText.trim());
    buffer.writeln('\n[${widget.collection.nameAr} - ${widget.book.nameAr} - حديث رقم ${item.hadithNumber}]');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم نسخ الحديث مع المصدر',
          style: TextStyle(fontFamily: 'Amiri', fontSize: 13),
        ),
        backgroundColor: const Color(0xFF1B8A6B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(milliseconds: 1400),
      ),
    );
  }

  void _cycleReadingThemeWithReveal(BuildContext btnContext) {
    if (_themeRevealCtrl.isRevealing) return;

    HapticFeedback.selectionClick();

    final nextReadingTheme = _readingTheme == ReadingTheme.sepia
        ? ReadingTheme.dark
        : (_readingTheme == ReadingTheme.dark
            ? ReadingTheme.light
            : ReadingTheme.sepia);

    final nextGlobalTheme = nextReadingTheme == ReadingTheme.dark
        ? QuranTheme.dark
        : (nextReadingTheme == ReadingTheme.sepia
            ? QuranTheme.cream
            : QuranTheme.white);

    final RenderBox? box = btnContext.findRenderObject() as RenderBox?;
    final Offset origin = box != null && box.hasSize
        ? box.localToGlobal(box.size.center(Offset.zero))
        : Offset(MediaQuery.of(context).size.width - 40, 45);

    final Color ringColor = nextReadingTheme == ReadingTheme.dark
        ? const Color(0xFFE8C77A)
        : (nextReadingTheme == ReadingTheme.sepia
            ? const Color(0xFFC9A84C)
            : const Color(0xFF10B981));

    final Color targetBgColor = nextReadingTheme == ReadingTheme.dark
        ? const Color(0xFF090E11)
        : (nextReadingTheme == ReadingTheme.sepia
            ? const Color(0xFFFBF6ED)
            : const Color(0xFFFAF8F5));

    _themeRevealCtrl.triggerReveal(
      origin: origin,
      ringColor: ringColor,
      targetBgColor: targetBgColor,
      onThemeChange: () {
        setState(() {
          _readingTheme = nextReadingTheme;
        });
        AppTheme.changeTheme(nextGlobalTheme);
      },
    );
  }

  void _openChaptersIndexSheet(
    BuildContext context,
    Color textColor,
    Color cardBg,
    Color sheetBg,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollCtrl) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      const Icon(Icons.format_list_bulleted_rounded, color: Color(0xFFC68A2E), size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'فهرس أبواب ${widget.book.nameAr} (${_chapters.length} باباً)',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    itemCount: _chapters.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final chap = _chapters[idx];
                      final chapterLabel = _formatChapterLabel(chap, idx + 1);

                      return Material(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.pop(ctx);
                            _jumpToChapter(chap.id);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1B8A6B).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    chapterLabel,
                                    style: const TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1B8A6B),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    chap.babAr,
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 14.5,
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDisplaySettingsSheet(
    BuildContext context,
    Color textColor,
    Color sheetBg,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'خيارات القراءة والعرض',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'حجم الخط (${_fontSize.toInt()})',
                        style: TextStyle(fontFamily: 'Amiri', fontSize: 15, color: textColor),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _fontSize > 16
                                ? () {
                                    setState(() => _fontSize -= 1.5);
                                    setSheetState(() {});
                                    _saveFontSize(_fontSize);
                                  }
                                : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: _fontSize < 32
                                ? () {
                                    setState(() => _fontSize += 1.5);
                                    setSheetState(() {});
                                    _saveFontSize(_fontSize);
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'إظهار سند الحديث (سلسلة الرواة)',
                      style: TextStyle(fontFamily: 'Amiri', fontSize: 15, color: textColor),
                    ),
                    value: _showIsnad,
                    activeThumbColor: const Color(0xFF1B8A6B),
                    onChanged: (val) {
                      setState(() => _showIsnad = val);
                      setSheetState(() {});
                      _saveShowIsnad(val);
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color pageBg;
    Color textColor;
    Color topBarColor;
    Color cardBg;
    Color accentColor;
    bool isDark;

    switch (_readingTheme) {
      case ReadingTheme.sepia: // Warm Cream / Parchment (Default)
        pageBg = const Color(0xFFFBF6ED);
        cardBg = const Color(0xFFF4ECE0);
        textColor = const Color(0xFF2B1D14);
        topBarColor = const Color(0xFFEFE4D2);
        accentColor = const Color(0xFF8B5319);
        isDark = false;
        break;
      case ReadingTheme.light:
        pageBg = const Color(0xFFFAF8F5);
        cardBg = Colors.white;
        textColor = const Color(0xFF1B2A26);
        topBarColor = const Color(0xFFEDE8DF);
        accentColor = const Color(0xFF0F5A47);
        isDark = false;
        break;
      case ReadingTheme.dark:
        pageBg = const Color(0xFF090E11);
        cardBg = const Color(0xFF131C1A);
        textColor = const Color(0xFFE8EFEB);
        topBarColor = const Color(0xFF131D1A);
        accentColor = const Color(0xFF2ECC9A);
        isDark = true;
        break;
    }

    return CircularThemeReveal(
      controller: _themeRevealCtrl,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: pageBg,
          body: SafeArea(
            top: _showTopBar,
            bottom: true,
            child: Stack(
              children: [
                Column(
                  children: [
                    // ── Animated Collapsing Header ──
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 240),
                      firstCurve: Curves.easeOutCubic,
                      secondCurve: Curves.easeOutCubic,
                      crossFadeState: _showTopBar ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                      firstChild: Container(
                        color: topBarColor,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.book.nameAr,
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    widget.collection.nameAr,
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 11.5,
                                      color: textColor.withValues(alpha: 0.7),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Builder(
                              builder: (btnContext) {
                                return IconButton(
                                  icon: Icon(
                                    _readingTheme == ReadingTheme.sepia
                                        ? Icons.palette_outlined
                                        : _readingTheme == ReadingTheme.light
                                            ? Icons.wb_sunny_outlined
                                            : Icons.dark_mode_outlined,
                                    color: accentColor,
                                    size: 21,
                                  ),
                                  tooltip: 'تغيير المظهر',
                                  onPressed: () => _cycleReadingThemeWithReveal(btnContext),
                                );
                              },
                            ),
                            if (_chapters.isNotEmpty)
                              IconButton(
                                icon: Icon(Icons.format_list_bulleted_rounded, color: textColor, size: 21),
                                tooltip: 'فهرس الأبواب',
                                onPressed: () => _openChaptersIndexSheet(context, textColor, cardBg, pageBg),
                              ),
                            IconButton(
                              icon: Icon(Icons.format_size_rounded, color: textColor, size: 21),
                              tooltip: 'إعدادات الخط',
                              onPressed: () => _showDisplaySettingsSheet(context, textColor, cardBg),
                            ),
                          ],
                        ),
                      ),
                      secondChild: const SizedBox(width: double.infinity, height: 0),
                    ),

                    // ── Reading Viewport ──
                    Expanded(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollUpdateNotification) {
                            final delta = notification.scrollDelta ?? 0.0;
                            final pixels = notification.metrics.pixels;

                            // Near top of document: always reveal smoothly
                            if (pixels <= 20) {
                              _accumulatedUpwardScroll = 0.0;
                              _accumulatedDownwardScroll = 0.0;
                              if (!_showTopBar) {
                                setState(() => _showTopBar = true);
                              }
                              return false;
                            }

                            if (delta > 0) {
                              // Scrolling down (reading deeper)
                              _accumulatedDownwardScroll += delta;
                              _accumulatedUpwardScroll = 0.0;
                              if (_accumulatedDownwardScroll >= 25.0 && _showTopBar) {
                                setState(() => _showTopBar = false);
                              }
                            } else if (delta < 0) {
                              // Scrolling up (returning backwards)
                              _accumulatedUpwardScroll += delta.abs();
                              _accumulatedDownwardScroll = 0.0;
                              // Require deliberate upward scroll of >= 45px
                              if (_accumulatedUpwardScroll >= 45.0 && !_showTopBar) {
                                setState(() => _showTopBar = true);
                              }
                            }
                          }
                          return false;
                        },
                        child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1B8A6B)),
                )
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Colors.orange, size: 42),
                            const SizedBox(height: 12),
                            Text(
                              'تعذر تحميل الأحاديث الشريفة',
                              style: TextStyle(fontFamily: 'Amiri', fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B8A6B),
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _loadHadiths,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Amiri')),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _listItems.isEmpty
                      ? _buildEmptyState(textColor)
                      : ScrollablePositionedList.builder(
                          itemScrollController: _itemScrollController,
                          itemPositionsListener: _itemPositionsListener,
                          initialScrollIndex: _initialTargetIndex,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          itemCount: _listItems.length,
                          itemBuilder: (context, index) {
                            final item = _listItems[index];
                            if (item is _ReaderBookHeaderItem) {
                              return _buildBookHeader(cardBg, textColor, isDark);
                            } else if (item is _ReaderChapterHeaderItem) {
                              return _buildChapterHeader(item.chapter, item.chapterIndex, cardBg, textColor, isDark);
                            } else if (item is _ReaderHadithEntryItem) {
                              return _buildHadithCard(item.hadith, item.hadithIndex, cardBg, textColor, isDark);
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Floating Restore Pill when Top Bar is Hidden ──
                if (!_showTopBar)
                  Positioned(
                    top: 6,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _showTopBar = true);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: topBarColor.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.35),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.18),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: accentColor),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.book.nameAr} • ${widget.collection.nameAr}',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Amiri',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookHeader(Color cardBg, Color textColor, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0F382A), Color(0xFF1B5E46)]
              : const [Color(0xFF104A3A), Color(0xFF1B8A6B)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B8A6B).withValues(alpha: 0.22),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_rounded, color: Color(0xFFF3D27C), size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.book.nameAr,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 18.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      widget.collection.nameAr,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _buildBookStatPill('${_hadiths.length} حديثاً'),
              if (_chapters.isNotEmpty)
                _buildBookStatPill('${_chapters.length} باباً'),
            ],
          ),
          if (widget.book.introAr != null && widget.book.introAr!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              widget.book.introAr!,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookStatPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Amiri',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildChapterHeader(
    HadithChapter chapter,
    int chapterDisplayIndex,
    Color cardBg,
    Color textColor,
    bool isDark,
  ) {
    final chapterLabel = _formatChapterLabel(chapter, chapterDisplayIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (chapterDisplayIndex > 1) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Divider(
                    color: const Color(0xFFC9A84C).withValues(alpha: 0.35),
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Icon(
                    Icons.auto_stories_rounded,
                    size: 16,
                    color: const Color(0xFFC9A84C).withValues(alpha: 0.7),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: const Color(0xFFC9A84C).withValues(alpha: 0.35),
                    thickness: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
        Container(
          margin: const EdgeInsets.only(top: 4, bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF132B20) : const Color(0xFFF3EFE0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFC9A84C).withValues(alpha: 0.45),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC9A84C),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      chapterLabel,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      chapter.babAr,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
              if (chapter.introAr != null && chapter.introAr!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(10),
                    border: const Border(
                      right: BorderSide(color: Color(0xFF1B8A6B), width: 3.5),
                    ),
                  ),
                  child: Text(
                    chapter.introAr!,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: _fontSize - 2,
                      fontStyle: FontStyle.italic,
                      height: 1.6,
                      color: textColor.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHadithCard(
    HadithItem item,
    int index,
    Color cardBg,
    Color textColor,
    bool isDark,
  ) {
    final hasSeparateIsnad = item.isnadAr != null &&
        item.isnadAr!.trim().isNotEmpty &&
        item.matnAr != null &&
        item.matnAr!.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Meta Bar: Hadith Number & Grade
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B8A6B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'حديث رقم ${item.hadithNumber}',
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1B8A6B),
                        ),
                      ),
                    ),
                    if (item.grade != null && item.grade!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC68A2E).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.grade!,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC68A2E),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Quick Actions: Favorite & Copy & Share
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        item.isFavorite ? Icons.bookmark_added_rounded : Icons.bookmark_border_rounded,
                        color: item.isFavorite ? const Color(0xFFD4AF37) : textColor.withValues(alpha: 0.45),
                        size: 21,
                      ),
                      tooltip: item.isFavorite ? 'إزالة من المفضلة' : 'حفظ في المفضلة',
                      onPressed: () => _toggleFavorite(item, index),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.copy_rounded,
                        color: textColor.withValues(alpha: 0.45),
                        size: 18,
                      ),
                      tooltip: 'نسخ الحديث',
                      onPressed: () => _copyHadith(item),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.share_rounded,
                        color: textColor.withValues(alpha: 0.45),
                        size: 18,
                      ),
                      tooltip: 'مشاركة الحديث',
                      onPressed: () => _shareHadith(item),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),

            // Isnād (Chain of Narrators)
            if (_showIsnad && hasSeparateIsnad) ...[
              Text(
                item.isnadAr!,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: _fontSize - 3,
                  color: textColor.withValues(alpha: 0.65),
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Matn (Actual Hadith Text)
            SelectableText(
              hasSeparateIsnad ? item.matnAr! : item.arabicText,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: _fontSize,
                fontWeight: FontWeight.w600,
                color: textColor,
                height: 1.8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Text(
        'لا توجد أحاديث في هذا الكتاب',
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 16,
          color: textColor.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
