import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme_notifier.dart';
import '../core/database/database_helper.dart';
import '../screens/quran_screen.dart';

class VerseMeaningsAndIrabSheet extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final String verseText;
  final String surahName;

  const VerseMeaningsAndIrabSheet({
    Key? key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.verseText,
    required this.surahName,
  }) : super(key: key);

  @override
  State<VerseMeaningsAndIrabSheet> createState() => _VerseMeaningsAndIrabSheetState();
}

class _VerseMeaningsAndIrabSheetState extends State<VerseMeaningsAndIrabSheet> {
  int? _currentAbsoluteIndex;
  PageController? _pageController;
  int _selectedMode = 0; // 0: Meanings, 1: Irab

  late int _currentAyahNumber;
  late String _currentSurahName;

  String _resolveSurahName(int surahNum, [String? initialName]) {
    if (initialName != null && initialName.trim().isNotEmpty) {
      return initialName;
    }
    if (surahNum >= 1 && surahNum <= DatabaseHelper.surahNamesArabicList.length) {
      return DatabaseHelper.surahNamesArabicList[surahNum - 1];
    }
    return '';
  }

  @override
  void initState() {
    super.initState();
    _currentAyahNumber = widget.ayahNumber;
    _currentSurahName = _resolveSurahName(widget.surahNumber, widget.surahName);
    _initAbsoluteIndex(widget.surahNumber, widget.ayahNumber);
    QuranScreen.selectedVerseNotifier.addListener(_onGlobalVerseSelectionChanged);
  }

  Future<void> _initAbsoluteIndex(int surah, int ayah) async {
    final surahName = _resolveSurahName(surah, (surah == widget.surahNumber) ? widget.surahName : null);
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery(
        'SELECT id_quran_ayat FROM quran WHERE sura_num = ? AND aya_num = ?',
        [surah, ayah]
    );
    if (res.isNotEmpty && mounted) {
      final id = res.first['id_quran_ayat'] as int;
      final newIndex = id - 1;

      setState(() {
        _currentAyahNumber = ayah;
        _currentSurahName = surahName;
      });

      if (_pageController == null) {
        setState(() {
          _currentAbsoluteIndex = newIndex;
          _pageController = PageController(initialPage: _currentAbsoluteIndex!);
        });
      } else if (_currentAbsoluteIndex != newIndex) {
        setState(() {
          _currentAbsoluteIndex = newIndex;
        });
        _pageController!.jumpToPage(newIndex);
      }
    }
  }

  @override
  void dispose() {
    QuranScreen.selectedVerseNotifier.removeListener(_onGlobalVerseSelectionChanged);
    _pageController?.dispose();
    super.dispose();
  }

  void _onGlobalVerseSelectionChanged() {
    final newSelection = QuranScreen.selectedVerseNotifier.value;
    if (newSelection != null) {
      final s = newSelection['surahNumber'] as int? ?? 1;
      final a = newSelection['ayahNumber'] as int? ?? 1;
      _initAbsoluteIndex(s, a);
    }
  }

  void _onPageChanged(int index) async {
    if (index >= 6236) return;
    setState(() {
      _currentAbsoluteIndex = index;
    });

    final id = index + 1;
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery(
        'SELECT sura_num, aya_num, page_aya FROM quran WHERE id_quran_ayat = ?',
        [id]
    );
    if (res.isNotEmpty && mounted) {
      final row = res.first;
      final surahNum = (row['sura_num'] as num).toInt();
      final ayahNum = (row['aya_num'] as num).toInt();
      final surahName = _resolveSurahName(surahNum);

      setState(() {
        _currentAyahNumber = ayahNum;
        _currentSurahName = surahName;
      });

      QuranScreen.selectedVerseNotifier.value = {
        'surahNumber': surahNum,
        'ayahNumber': ayahNum,
        'page': row['page_aya'],
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final globalDirectionality = Directionality.of(context);

    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final isDark = theme == QuranTheme.dark;
        final bg = AppTheme.getPageBgColor(theme);
        final border = AppTheme.getBorderColor(theme);
        final gold = AppTheme.getGoldTextColor(theme);
        final text = AppTheme.getMainTextColor(theme);
        final headerBg = isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.02);

        final titleSurahName = _currentSurahName;
        final titleAyahNumber = _currentAyahNumber;

        return Container(
          height: MediaQuery.of(context).size.height * 0.78,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: border.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Container(
                color: headerBg,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        'سورة $titleSurahName · الآية $titleAyahNumber',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: gold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: text, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),

              // Selection Tabs / Buttons at the top
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildChoiceChip('معاني الكلمات', 0, bg, text, gold, border, isDark),
                      const SizedBox(width: 16),
                      _buildChoiceChip('إعراب الآية', 1, bg, text, gold, border, isDark),
                    ],
                  ),
                ),
              ),

              Divider(color: border.withValues(alpha: 0.25), height: 1),

              // PageView Content
              Expanded(
                child: _currentAbsoluteIndex == null
                    ? Center(child: CircularProgressIndicator(color: gold))
                    : Directionality(
                        textDirection: TextDirection.ltr,
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: 6236,
                          reverse: true,
                          onPageChanged: _onPageChanged,
                          itemBuilder: (context, index) {
                            final idQuranAyat = index + 1;
                            return Directionality(
                              textDirection: globalDirectionality,
                              child: MeaningsAndIrabPage(
                                idQuranAyat: idQuranAyat,
                                selectedMode: _selectedMode,
                                theme: theme,
                                bg: bg,
                                border: border,
                                gold: gold,
                                text: text,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChoiceChip(String label, int modeIndex, Color bg, Color text, Color gold, Color border, bool isDark) {
    final isSelected = _selectedMode == modeIndex;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? bg : text,
        ),
      ),
      selected: isSelected,
      selectedColor: gold,
      backgroundColor: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
      checkmarkColor: bg,
      showCheckmark: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? gold : border.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedMode = modeIndex;
          });
        }
      },
    );
  }
}

class MeaningsAndIrabPage extends StatefulWidget {
  final int idQuranAyat;
  final int selectedMode;
  final QuranTheme theme;
  final Color bg;
  final Color border;
  final Color gold;
  final Color text;

  const MeaningsAndIrabPage({
    Key? key,
    required this.idQuranAyat,
    required this.selectedMode,
    required this.theme,
    required this.bg,
    required this.border,
    required this.gold,
    required this.text,
  }) : super(key: key);

  @override
  State<MeaningsAndIrabPage> createState() => _MeaningsAndIrabPageState();
}

class _MeaningsAndIrabPageState extends State<MeaningsAndIrabPage> {
  bool _isLoading = true;
  String _verseText = '';
  String _meanings = '';
  String _irab = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  @override
  void didUpdateWidget(covariant MeaningsAndIrabPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.idQuranAyat != widget.idQuranAyat) {
      _fetchContent();
    }
  }

  Future<void> _fetchContent() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _meanings = '';
      _irab = '';
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final rowRes = await db.rawQuery(
          'SELECT sura_num, aya_num, aya FROM quran WHERE id_quran_ayat = ?',
          [widget.idQuranAyat]
      );
      if (rowRes.isEmpty) throw Exception('Verse not found in Database');

      final row = rowRes.first;
      final surahNum = row['sura_num'] as int;
      final ayahNum = row['aya_num'] as int;
      final text = row['aya'] as String;

      _verseText = text.trim();

      final data = await DatabaseHelper.instance.fetchMeaningsAndIrab(
        surahNumber: surahNum,
        ayahNumber: ayahNum,
      );

      if (mounted) {
        setState(() {
          _meanings = data['meanings'] ?? '';
          _irab = data['irab'] ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم النسخ إلى الحافظة', style: TextStyle(fontFamily: 'Amiri')),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareContent() {
    final activeTabTitle = widget.selectedMode == 0 ? 'معاني الكلمات' : 'إعراب الآية';
    final activeContent = widget.selectedMode == 0 ? _meanings : _irab;
    final text = 'الآية: $_verseText\n\n'
        '$activeTabTitle:\n'
        '$activeContent';
    Share.share(text);
  }

  Widget _buildMeaningsList() {
    if (_meanings.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 48, color: widget.text.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text(
                'الآية لا تحتوي على غريب كلمات بحاجة لبيان معانيها.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16,
                  color: widget.text.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final lines = _meanings.split('\n');
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        final line = lines[index].trim();
        if (line.isEmpty) return const SizedBox.shrink();

        // Split word and meaning if separated by ':'
        final parts = line.split(':');
        final word = parts[0].trim();
        final meaning = parts.length > 1 ? parts.sublist(1).join(':').trim() : '';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.theme == QuranTheme.dark
                ? Colors.white.withValues(alpha: 0.03)
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.border.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RichText(
                  textDirection: TextDirection.rtl,
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      height: 1.6,
                      color: widget.text,
                    ),
                    children: [
                      TextSpan(
                        text: '$word: ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: widget.gold,
                        ),
                      ),
                      TextSpan(
                        text: meaning,
                        style: TextStyle(
                          color: widget.text.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIrabText() {
    if (_irab.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline, size: 48, color: widget.text.withValues(alpha: 0.3)),
              const SizedBox(height: 12),
              Text(
                'لا يوجد إعراب متوفر لهذه الآية الكريمة.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16,
                  color: widget.text.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Format quote markers nicely: e.g. replacing « and » with color highlights
    final paragraphs = _irab.split('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: paragraphs.map((para) {
        final content = para.trim();
        if (content.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            content,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 17,
              height: 1.8,
              color: widget.text.withValues(alpha: 0.85),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.theme == QuranTheme.dark;
    final cardBg = isDark ? Colors.black.withValues(alpha: 0.28) : Colors.black.withValues(alpha: 0.03);
    final actionsBg = isDark ? Colors.black.withValues(alpha: 0.28) : Colors.black.withValues(alpha: 0.03);

    return Column(
      children: [
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: widget.gold))
              : _error != null
                  ? _buildErrorWidget()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Verse text container
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: widget.border.withValues(alpha: 0.35)),
                            ),
                            child: Text(
                              _verseText,
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 22,
                                height: 1.8,
                                color: widget.text,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          widget.selectedMode == 0 ? _buildMeaningsList() : _buildIrabText(),
                        ],
                      ),
                    ),
        ),

        // Copy and Share Actions panel at the bottom
        if (!_isLoading && _error == null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: actionsBg,
              border: Border(top: BorderSide(color: widget.border.withValues(alpha: 0.25))),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final textToCopy = widget.selectedMode == 0 ? _meanings : _irab;
                        _copyToClipboard(textToCopy);
                      },
                      icon: Icon(Icons.copy, size: 16, color: widget.gold),
                      label: Text('نسخ النص', style: TextStyle(color: widget.text, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: widget.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareContent,
                      icon: Icon(Icons.share, size: 16, color: widget.gold),
                      label: Text('مشاركة', style: TextStyle(color: widget.text, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: widget.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'خطأ في جلب البيانات',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: widget.text.withValues(alpha: 0.6)),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchContent,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.gold,
                foregroundColor: widget.bg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
