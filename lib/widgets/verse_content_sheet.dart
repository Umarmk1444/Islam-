import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../theme_notifier.dart';
import '../services/quran_api_service.dart';
import '../core/database/database_helper.dart';
import '../screens/quran_screen.dart';

class VerseContentSheet extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final String verseText;
  final String surahName;
  final bool initialIsTafsir;

  const VerseContentSheet({
    Key? key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.verseText,
    required this.surahName,
    required this.initialIsTafsir,
  }) : super(key: key);

  @override
  State<VerseContentSheet> createState() => _VerseContentSheetState();
}

class _VerseContentSheetState extends State<VerseContentSheet> {
  late bool _isTafsir;
  late dynamic _selectedResourceId; // String for tafsir (column name), int for translation (API ID)
  int? _currentAbsoluteIndex;
  PageController? _pageController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _isTafsir = widget.initialIsTafsir;
    _initAbsoluteIndex(widget.surahNumber, widget.ayahNumber);

    QuranScreen.selectedVerseNotifier.addListener(_onGlobalVerseSelectionChanged);
  }

  Future<void> _initAbsoluteIndex(int surah, int ayah) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery(
      'SELECT id_quran_ayat FROM quran WHERE sura_num = ? AND aya_num = ?',
      [surah, ayah]
    );
    if (res.isNotEmpty && mounted) {
      final id = res.first['id_quran_ayat'] as int;
      final newIndex = id - 1;
      
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final locale = Localizations.localeOf(context).languageCode;
      _selectedResourceId = _getDefaultResourceId(_isTafsir, locale);
      _initialized = true;
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

  dynamic _getDefaultResourceId(bool isTafsir, String locale) {
    if (isTafsir) {
      return 'tafsir_moysar'; // الميسر (default Arabic tafsir)
    } else {
      if (locale == 'am') return 87; // Sadiq & Sani (AM)
      if (locale == 'om') return 111; // Ghali Ababor (OM)
      return 20; // Saheeh Int (default English)
    }
  }

  List<Map<String, dynamic>> _getAvailableResources() {
    if (_isTafsir) {
      // Local DB column names as IDs
      return const [
        {'id': 'tafsir_moysar', 'name': 'الميسر'},
        {'id': 'tafsir_saadi', 'name': 'السعدي'},
        {'id': 'tafsir_baghawi', 'name': 'البغوي'},
      ];
    } else {
      // API resource IDs for translations
      return const [
        {'id': 20, 'name': 'Saheeh Int'},
        {'id': 87, 'name': 'Sadiq & Sani (AM)'},
        {'id': 111, 'name': 'Ghali Ababor (OM)'},
      ];
    }
  }

  void _onPageChanged(int index) async {
    if (index >= 6236) return;
    setState(() {
      _currentAbsoluteIndex = index;
    });

    final id = index + 1;
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('SELECT sura_num, aya_num, page_aya FROM quran WHERE id_quran_ayat = ?', [id]);
    if (res.isNotEmpty) {
      final row = res.first;
      QuranScreen.selectedVerseNotifier.value = {
        'surahNumber': row['sura_num'],
        'ayahNumber': row['aya_num'],
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

        final resources = _getAvailableResources();
        
        // As a fallback header while scrolling, use the widget's initial surah/ayah.
        // True updating titles per page can be done within the VerseContentPage itself, 
        // but for a smooth experience we'll keep the static generic title or hide it, 
        // because each page renders its own Ayah text anyway.
        final titleSurahName = widget.surahName;
        final titleAyahNumber = widget.ayahNumber;

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
                    children: resources.map((res) {
                      final isSelected = _selectedResourceId == res['id'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(
                            res['name'] as String,
                            style: TextStyle(
                              fontFamily: _isTafsir ? 'Amiri' : null,
                              fontSize: _isTafsir ? 14 : 12,
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
                                _selectedResourceId = res['id'];
                              });
                            }
                          },
                        ),
                      );
                    }).toList(),
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
                          onPageChanged: _onPageChanged,
                          itemBuilder: (context, index) {
                            final idQuranAyat = index + 1;
                            return Directionality(
                              textDirection: globalDirectionality,
                              child: VerseContentPage(
                                idQuranAyat: idQuranAyat,
                                resourceId: _selectedResourceId,
                                isTafsir: _isTafsir,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Content view page loaded dynamically inside the PageView
// ─────────────────────────────────────────────────────────────────────────────

class VerseContentPage extends StatefulWidget {
  final int idQuranAyat;
  final dynamic resourceId; // String for tafsir, int for translation
  final bool isTafsir;
  final QuranTheme theme;
  final Color bg;
  final Color border;
  final Color gold;
  final Color text;

  const VerseContentPage({
    Key? key,
    required this.idQuranAyat,
    required this.resourceId,
    required this.isTafsir,
    required this.theme,
    required this.bg,
    required this.border,
    required this.gold,
    required this.text,
  }) : super(key: key);

  @override
  State<VerseContentPage> createState() => _VerseContentPageState();
}

class _VerseContentPageState extends State<VerseContentPage> {
  bool _isLoading = true;
  String _content = '';
  String? _error;

  String _verseText = '';
  int _surahNum = 0;
  int _ayahNum = 0;

  @override
  void initState() {
    super.initState();
    _fetchContent();
  }

  @override
  void didUpdateWidget(covariant VerseContentPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resourceId != widget.resourceId ||
        oldWidget.idQuranAyat != widget.idQuranAyat ||
        oldWidget.isTafsir != widget.isTafsir) {
      _fetchContent();
    }
  }

  Future<void> _fetchContent() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
      _content = '';
    });

    try {
      final db = await DatabaseHelper.instance.database;
      final rowRes = await db.rawQuery('SELECT sura_num, aya_num, aya FROM quran WHERE id_quran_ayat = ?', [widget.idQuranAyat]);
      if (rowRes.isEmpty) throw Exception('Verse not found in Database');
      
      final row = rowRes.first;
      final surahNum = row['sura_num'] as int;
      final ayahNum = row['aya_num'] as int;
      final text = row['aya'] as String;

      _surahNum = surahNum;
      _ayahNum = ayahNum;
      _verseText = text;

      String resText;
      if (widget.isTafsir) {
        final String column = widget.resourceId as String;
        resText = await DatabaseHelper.instance.fetchTafsir(
          surahNumber: surahNum,
          ayahNumber: ayahNum,
          tafsirColumn: column,
        );
      } else {
        resText = await QuranApiService.fetchTranslationByResourceId(
          surahNum, ayahNum, widget.resourceId as int,
        );
      }
      
      if (mounted) {
        setState(() {
          _content = resText;
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
    final text = 'الآية: $_verseText\n\n'
        '$_content';
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = widget.isTafsir || widget.resourceId == 16 || widget.resourceId == 91 || widget.resourceId == 94 || widget.resourceId == 93;
    final isDark = widget.theme == QuranTheme.dark;
    final cardBg = isDark ? Colors.black.withValues(alpha: 0.28) : Colors.black.withValues(alpha: 0.03);
    final actionsBg = isDark ? Colors.black.withValues(alpha: 0.28) : Colors.black.withValues(alpha: 0.03);

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Arabic Ayah text container at the top
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
                Divider(color: widget.border.withValues(alpha: 0.25)),
                const SizedBox(height: 12),

                // Loaded Tafsir/Translation content underneath it
                if (_isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Center(child: CircularProgressIndicator(color: widget.gold)),
                  )
                else if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        const Text(
                          'خطأ في جلب البيانات',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
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
                  )
                else if (_content.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'لا توجد بيانات متاحة لهذا المورد.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: widget.text.withValues(alpha: 0.6)),
                    ),
                  )
                else
                  Text(
                    _content.trim(),
                    textAlign: isArabic ? TextAlign.right : TextAlign.justify,
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    style: TextStyle(
                      fontFamily: isArabic ? 'Amiri' : null,
                      fontSize: isArabic ? 17 : 14,
                      height: isArabic ? 1.8 : 1.6,
                      color: widget.text.withValues(alpha: 0.85),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Copy and Share Actions panel at the bottom
        if (!_isLoading && _error == null && _content.isNotEmpty)
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
                      onPressed: () => _copyToClipboard(_content),
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
}
