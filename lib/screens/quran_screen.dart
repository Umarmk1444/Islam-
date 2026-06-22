import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qcf_quran/qcf_quran.dart';
import '../theme_notifier.dart';
import '../widgets/islamic_border.dart';
import '../widgets/opening_pages_illumination.dart';
import '../widgets/strict_qcf_page.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({Key? key}) : super(key: key);

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  PageController? _pageController;
  int _currentPageIndex = 0;
  bool _isLoading = true;

  /// Core page data: pageNumber → list of verse maps
  Map<int, List<Map<String, dynamic>>> _pagesData = {};

  /// Full surah list for the navigation panel
  List<Map<String, dynamic>> _surahList = [];

  /// surahNumber → first page that contains this surah (built once at load)
  final Map<int, int> _surahFirstPage = {};

  /// juzNumber → first page that contains this juz (built once at load)
  final Map<int, int> _juzFirstPage = {};

  static const String _prefPageKey = 'last_quran_page';
  static const String _bookmarkPageKey = 'bookmark_page';
  static const String _bookmarkSurahKey = 'bookmark_surah';
  static const String _bookmarkAyahKey = 'bookmark_ayah';

  // ── Theme color getters matching global AppTheme ──────────────────────────

  QuranTheme get _selectedTheme => AppTheme.notifier.value;

  Color get _screenBgColor => AppTheme.getScreenBgColor(_selectedTheme);
  Color get _pageBgColor => AppTheme.getPageBgColor(_selectedTheme);
  Color get _borderColor => AppTheme.getBorderColor(_selectedTheme);
  Color get _goldTextColor => AppTheme.getGoldTextColor(_selectedTheme);
  Color get _mainTextColor => AppTheme.getMainTextColor(_selectedTheme);

  QcfThemeData get _qcfTheme {
    return QcfThemeData(
      verseTextColor: _mainTextColor,
      verseNumberColor: _goldTextColor,
      pageBackgroundColor: _screenBgColor,
      basmalaColor: _mainTextColor,
      headerTextColor: _goldTextColor,
      // Option to add verse highlights if needed.
    );
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadQuranData();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadQuranData() async {
    try {
      final String response = await rootBundle.loadString('assets/quran.json');
      final data = json.decode(response);

      final Map<int, List<Map<String, dynamic>>> tmpPages = {};
      final List<Map<String, dynamic>> tmpSurahs = [];
      final Map<int, int> tmpSurahFirst = {};
      final Map<int, int> tmpJuzFirst = {};

      if (data is List) {
        for (final surah in data) {
          if (surah is! Map<String, dynamic>) continue;

          final int surahNum = surah['id'] ?? 0;
          final String surahName = surah['name'] ?? '';
          final String surahTranslit = surah['transliteration'] ?? '';
          final int totalVerses = surah['total_verses'] ?? 0;

          tmpSurahs.add({
            'number': surahNum,
            'name': surahName,
            'transliteration': surahTranslit,
            'totalVerses': totalVerses,
          });

          final verses = surah['verses'];
          if (verses is! List) continue;

          for (final verse in verses) {
            if (verse is! Map<String, dynamic>) continue;

            final int pageNum = verse['page'] ?? 1;
            final int juzNum = verse['juz'] ?? 1;

            if (!tmpSurahFirst.containsKey(surahNum)) {
              tmpSurahFirst[surahNum] = pageNum;
            }

            if (!tmpJuzFirst.containsKey(juzNum)) {
              tmpJuzFirst[juzNum] = pageNum;
            }

            final Map<String, dynamic> verseData = {
              'surahNumber': surahNum,
              'surahName': surahName,
              'ayahNumber': verse['id'] ?? 0,
              'text': verse['text'] ?? '',
              'juz': juzNum,
              'page': pageNum,
            };

            tmpPages.putIfAbsent(pageNum, () => []).add(verseData);
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();
      int lastPage = prefs.getInt(_prefPageKey) ?? 1;
      if (lastPage < 1 || lastPage > 604) lastPage = 1;
      final int initialIndex = lastPage - 1;

      _pageController = PageController(initialPage: initialIndex);

      if (mounted) {
        setState(() {
          _pagesData = tmpPages;
          _surahList = tmpSurahs;
          _surahFirstPage.addAll(tmpSurahFirst);
          _juzFirstPage.addAll(tmpJuzFirst);
          _currentPageIndex = initialIndex;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading Quran: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Theme Changer ─────────────────────────────────────────────────────────

  void _changeTheme(QuranTheme theme) {
    AppTheme.changeTheme(theme);
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _pageBgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'اختر المظهر (Reading Theme)',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _mainTextColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ThemeOption(
                  label: 'Classic Cream',
                  bgColor: const Color(0xFFFDFBF0),
                  borderColor: const Color(0xFFC9A84C),
                  textColor: Colors.black,
                  isSelected: _selectedTheme == QuranTheme.cream,
                  onTap: () {
                    Navigator.pop(ctx);
                    _changeTheme(QuranTheme.cream);
                  },
                ),
                _ThemeOption(
                  label: 'Dark Mode',
                  bgColor: const Color(0xFF0D1F17),
                  borderColor: const Color(0xFFE8C77A),
                  textColor: Colors.white,
                  isSelected: _selectedTheme == QuranTheme.dark,
                  onTap: () {
                    Navigator.pop(ctx);
                    _changeTheme(QuranTheme.dark);
                  },
                ),
                _ThemeOption(
                  label: 'Crisp White',
                  bgColor: Colors.white,
                  borderColor: const Color(0xFFC9A84C),
                  textColor: Colors.black,
                  isSelected: _selectedTheme == QuranTheme.white,
                  onTap: () {
                    Navigator.pop(ctx);
                    _changeTheme(QuranTheme.white);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _onPageChanged(int index) async {
    setState(() => _currentPageIndex = index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefPageKey, index + 1);
  }

  void _jumpToPage(int pageNum) {
    if (pageNum < 1 || pageNum > 604) return;
    _pageController?.jumpToPage(pageNum - 1);
  }

  int _findPageForAyah(int surahNumber, int ayahNumber) {
    for (int p = 1; p <= 604; p++) {
      final verses = _pagesData[p];
      if (verses == null) continue;
      if (verses.any((v) =>
          v['surahNumber'] == surahNumber && v['ayahNumber'] == ayahNumber)) {
        return p;
      }
    }
    return _surahFirstPage[surahNumber] ?? 1;
  }

  // ── Ayah Interactive Actions ──────────────────────────────────────────────

  void _showAyahActionSheet(int surahNumber, int ayahNumber) {
    // Find the verse from our loaded data to get its text & page info.
    final page = _findPageForAyah(surahNumber, ayahNumber);
    final versesOnPage = _pagesData[page] ?? [];
    final verse = versesOnPage.firstWhere(
      (v) => v['surahNumber'] == surahNumber && v['ayahNumber'] == ayahNumber,
      orElse: () => {
        'surahName': 'سورة', // Fallback
        'text': '',
        'page': page,
        'surahNumber': surahNumber,
        'ayahNumber': ayahNumber,
      },
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: _pageBgColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: _borderColor, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'سورة ${verse['surahName']} - الآية ${verse['ayahNumber']}',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _goldTextColor,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.menu_book, color: _goldTextColor),
              title: Text('التفسير', style: TextStyle(color: _mainTextColor, fontFamily: 'Amiri', fontSize: 18)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('سيتم إضافة التفسير قريباً', style: TextStyle(fontFamily: 'Amiri')),
                    backgroundColor: _borderColor,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.copy, color: _goldTextColor),
              title: Text('نسخ الآية', style: TextStyle(color: _mainTextColor, fontFamily: 'Amiri', fontSize: 18)),
              onTap: () {
                Navigator.pop(ctx);
                final textToCopy = '${verse['text']} ﴿${_toArabicNumerals(verse['ayahNumber'])}﴾';
                Clipboard.setData(ClipboardData(text: textToCopy));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('تم نسخ الآية بنجاح', style: TextStyle(fontFamily: 'Amiri')),
                    backgroundColor: _borderColor,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.share, color: _goldTextColor),
              title: Text('مشاركة', style: TextStyle(color: _mainTextColor, fontFamily: 'Amiri', fontSize: 18)),
              onTap: () {
                Navigator.pop(ctx);
                final shareText = '﴿${verse['text']}﴾ [${verse['surahName']}: ${verse['ayahNumber']}]';
                Share.share(shareText);
              },
            ),
            ListTile(
              leading: Icon(Icons.bookmark_add, color: _goldTextColor),
              title: Text('حفظ العلامة', style: TextStyle(color: _mainTextColor, fontFamily: 'Amiri', fontSize: 18)),
              onTap: () async {
                Navigator.pop(ctx);
                final prefs = await SharedPreferences.getInstance();
                await prefs.setInt(_bookmarkPageKey, verse['page']);
                await prefs.setInt(_bookmarkSurahKey, verse['surahNumber']);
                await prefs.setInt(_bookmarkAyahKey, verse['ayahNumber']);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('تم حفظ العلامة', style: TextStyle(fontFamily: 'Amiri')),
                      backgroundColor: _borderColor,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _goToBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final page = prefs.getInt(_bookmarkPageKey);
    if (page != null) {
      _jumpToPage(page);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('لا توجد علامة محفوظة', style: TextStyle(fontFamily: 'Amiri')),
          backgroundColor: _borderColor,
        ),
      );
    }
  }

  // ── Text formatting ───────────────────────────────────────────────────────

  String _toArabicNumerals(int number) {
    const Map<String, String> digits = {
      '0': '٠', '1': '١', '2': '٢', '3': '٣', '4': '٤',
      '5': '٥', '6': '٦', '7': '٧', '8': '٨', '9': '٩',
    };
    return number.toString().split('').map((c) => digits[c] ?? c).join('');
  }

  // ── Navigation panel ──────────────────────────────────────────────────────

  void _openNavigationPanel() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _NavigationPanel(
        surahList: _surahList,
        juzFirstPage: _juzFirstPage,
        currentPage: _currentPageIndex + 1,
        pageBgColor: _pageBgColor,
        borderColor: _borderColor,
        goldTextColor: _goldTextColor,
        mainTextColor: _mainTextColor,
        onJumpToPage: (p) {
          Navigator.pop(ctx);
          _jumpToPage(p);
        },
        onJumpToAyah: (surahNum, ayahNum) {
          Navigator.pop(ctx);
          final page = _findPageForAyah(surahNum, ayahNum);
          _jumpToPage(page);
        },
      ),
    );
  }

  // ── Root build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        return Scaffold(
          backgroundColor: _screenBgColor,
          appBar: AppBar(
            title: Text(
              'المصحف الشريف',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
                color: AppTheme.getAppBarTextColor(theme),
              ),
            ),
            centerTitle: true,
            backgroundColor: AppTheme.getAppBarBgColor(theme),
            foregroundColor: AppTheme.getAppBarTextColor(theme),
            elevation: 1,
            leading: IconButton(
              icon: const Icon(Icons.bookmark),
              tooltip: 'الذهاب إلى العلامة',
              onPressed: _goToBookmark,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.palette_outlined),
                tooltip: 'تغيير المظهر',
                onPressed: _isLoading ? null : _showThemeSelector,
              ),
              IconButton(
                icon: const Icon(Icons.menu_book_rounded),
                tooltip: 'التنقل',
                onPressed: _isLoading ? null : _openNavigationPanel,
              ),
            ],
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: _borderColor))
              : PageView.builder(
                  controller: _pageController,
                  itemCount: 604,
                  physics: const BouncingScrollPhysics(),
                  reverse: true,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, index) {
                    final pageNum = index + 1;

                    // جلب بيانات الصفحة الحالية ديناميكياً (اسم السورة والجزء) لعرضها في الأعلى
                    final List<Map<String, dynamic>> versesOnPage = _pagesData[pageNum] ?? [];
                    String surahName = "";
                    String juzNumber = "";
                     
                    if (versesOnPage.isNotEmpty) {
                      surahName = versesOnPage.first['surahName'] ?? "";
                      juzNumber = _toArabicNumerals(versesOnPage.first['juz'] ?? 1);
                    }

                    // 1. Pages 1-2 (Al-Fatihah & Al-Baqarah) with unique dome layout
                    if (pageNum == 1 || pageNum == 2) {
                      return Center(
                        child: AspectRatio(
                          aspectRatio: 0.65,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: 500,
                              height: 770,
                              child: Stack(
                                children: [
                                  // Base Layer: Beautiful illumination border with blue dome
                                  OpeningPagesIllumination(
                                    isPageOne: pageNum == 1,
                                    primaryColor: _selectedTheme == QuranTheme.cream
                                        ? const Color(0xFF1B365D)
                                        : _selectedTheme == QuranTheme.dark
                                            ? const Color(0xFF0A180F)
                                            : const Color(0xFF1B4332),
                                    accentColor: _borderColor,
                                    backgroundColor: _pageBgColor,
                                    child: const SizedBox.expand(),
                                  ),

                                  // Headers Layer: Surah Name and Juz inside blue dome
                                  Positioned(
                                    top: 75,
                                    left: 0,
                                    right: 0,
                                    child: SizedBox(
                                      height: 50,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        textDirection: TextDirection.rtl,
                                        children: [
                                          Text(
                                            'سُورَةُ $surahName',
                                            style: TextStyle(
                                              fontFamily: 'Amiri',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: _goldTextColor,
                                            ),
                                          ),
                                          Text(
                                            'الجُزْءُ $juzNumber',
                                            style: TextStyle(
                                              fontFamily: 'Amiri',
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: _goldTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                    // Reminder Widget Layer: positioned before the main text layer
                                    QuranReminderWidget(
                                      pageNum: pageNum,
                                      languageCode: Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar',
                                    ),

                                  // Main Quranic Text Layer: positioned inside white text area
                                  Positioned(
                                    top: 230,
                                    bottom: 90,
                                    left: 65,
                                    right: 65,
                                    child: Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: StrictQcfPage(
                                        pageNumber: pageNum,
                                        theme: _qcfTheme.copyWith(
                                          pageBackgroundColor: Colors.transparent,
                                        ),
                                        onTap: _showAyahActionSheet,
                                      ),
                                    ),
                                  ),

                                  // Page Number Layer: centered at bottom
                                  Positioned(
                                    bottom: 45,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).scaffoldBackgroundColor,
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: _goldTextColor.withOpacity(0.5),
                                            width: 1.2,
                                          ),
                                        ),
                                        child: Text(
                                          _toArabicNumerals(pageNum),
                                          style: TextStyle(
                                            fontFamily: 'Amiri',
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: _mainTextColor,
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

                    // 2. Pages 3-604 with CustomPaint border and proper layer ordering
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return Center(
                          child: AspectRatio(
                            aspectRatio: 0.65,
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: MediaQuery(
                                data: MediaQuery.of(context).copyWith(
                                  size: const Size(500, 770),
                                  textScaler: TextScaler.noScaling,
                                ),
                                child: Container(
                                  width: 500,
                                  height: 770,
                                  color: Theme.of(context).scaffoldBackgroundColor,
                                  child: Stack(
                                    children: [
                                      // Layer 1 (Bottom): CustomPaint border drawn first
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: TezhibBorderPainter(
                                            thickness: 45.0,
                                            primaryColor: _selectedTheme == QuranTheme.cream
                                                ? const Color(0xFF14305E)
                                                : _selectedTheme == QuranTheme.dark
                                                    ? const Color(0xFF1F3A3A)
                                                    : const Color(0xFF1B4332),
                                            accentColor: _borderColor,
                                            tertiaryColor: _selectedTheme == QuranTheme.cream
                                                ? const Color(0xFF8B1C24)
                                                : _selectedTheme == QuranTheme.dark
                                                    ? const Color(0xFFE8C77A).withOpacity(0.8)
                                                    : const Color(0xFF8B1C24),
                                          ),
                                        ),
                                      ),

                                      // Layer 2 (Top): Text content positioned on top with safe padding
                                      Positioned.fill(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            top: 60.0,    // Safe top padding for headers
                                            bottom: 55.0, // Safe bottom padding for page number
                                            left: 55.0,
                                            right: 55.0,
                                          ),
                                          child: Column(
                                            children: [
                                              // Surah name and Juz header with individual styled containers
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  textDirection: TextDirection.rtl,
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).scaffoldBackgroundColor,
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(
                                                          color: _goldTextColor.withOpacity(0.5),
                                                          width: 1.2,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'سُورَةُ $surahName',
                                                        style: TextStyle(
                                                          fontFamily: 'Amiri',
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                          color: _goldTextColor,
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context).scaffoldBackgroundColor,
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(
                                                          color: _goldTextColor.withOpacity(0.5),
                                                          width: 1.2,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        'الجُزْءُ $juzNumber',
                                                        style: TextStyle(
                                                          fontFamily: 'Amiri',
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                          color: _goldTextColor,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Divider line
                                              Container(
                                                margin: const EdgeInsets.symmetric(vertical: 6),
                                                height: 0.8,
                                                color: _borderColor.withOpacity(0.3),
                                              ),

                                              // Quranic text content (main area)
                                              Expanded(
                                                child: Directionality(
                                                  textDirection: TextDirection.rtl,
                                                  child: StrictQcfPage(
                                                    pageNumber: pageNum,
                                                    theme: _qcfTheme,
                                                    onTap: _showAyahActionSheet,
                                                  ),
                                                ),
                                              ),

                                              // Divider line
                                              Container(
                                                margin: const EdgeInsets.symmetric(vertical: 6),
                                                height: 0.8,
                                                color: _borderColor.withOpacity(0.3),
                                              ),

                                              // Page number footer with background and border
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).scaffoldBackgroundColor,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: _goldTextColor.withOpacity(0.5),
                                                    width: 1.2,
                                                  ),
                                                ),
                                                child: Text(
                                                  _toArabicNumerals(pageNum),
                                                  style: TextStyle(
                                                    fontFamily: 'Amiri',
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: _mainTextColor,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small stateless sub-widgets (keep the main class clean)
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 65,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? borderColor : Colors.grey.withOpacity(0.3),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: borderColor.withOpacity(0.3), blurRadius: 6)]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Navigation Panel (Modal Bottom Sheet with 3 tabs)
// ─────────────────────────────────────────────────────────────────────────────

class _NavigationPanel extends StatefulWidget {
  const _NavigationPanel({
    required this.surahList,
    required this.juzFirstPage,
    required this.currentPage,
    required this.pageBgColor,
    required this.borderColor,
    required this.goldTextColor,
    required this.mainTextColor,
    required this.onJumpToPage,
    required this.onJumpToAyah,
  });

  final List<Map<String, dynamic>> surahList;
  final Map<int, int> juzFirstPage;
  final int currentPage;
  final Color pageBgColor;
  final Color borderColor;
  final Color goldTextColor;
  final Color mainTextColor;
  final void Function(int page) onJumpToPage;
  final void Function(int surahNum, int ayahNum) onJumpToAyah;

  @override
  State<_NavigationPanel> createState() => _NavigationPanelState();
}

class _NavigationPanelState extends State<_NavigationPanel>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.8,
      decoration: BoxDecoration(
        color: widget.pageBgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          TabBar(
            controller: _tabController,
            labelColor: widget.goldTextColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: widget.borderColor,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            tabs: const [
              Tab(text: 'السور والآيات'),
              Tab(text: 'الأجزاء'),
              Tab(text: 'الصفحات'),
            ],
          ),
          Divider(height: 1, color: widget.borderColor),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SurahAyahTab(
                  surahList: widget.surahList,
                  pageBgColor: widget.pageBgColor,
                  borderColor: widget.borderColor,
                  goldTextColor: widget.goldTextColor,
                  mainTextColor: widget.mainTextColor,
                  onJumpToAyah: widget.onJumpToAyah,
                ),
                _JuzTab(
                  juzFirstPage: widget.juzFirstPage,
                  borderColor: widget.borderColor,
                  goldTextColor: widget.goldTextColor,
                  onJumpToPage: widget.onJumpToPage,
                ),
                _PagesTab(
                  currentPage: widget.currentPage,
                  borderColor: widget.borderColor,
                  goldTextColor: widget.goldTextColor,
                  onJumpToPage: widget.onJumpToPage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: Surahs + Keyboard Ayah Picker ─────────────────────────────────────

class _SurahAyahTab extends StatefulWidget {
  const _SurahAyahTab({
    required this.surahList,
    required this.pageBgColor,
    required this.borderColor,
    required this.goldTextColor,
    required this.mainTextColor,
    required this.onJumpToAyah,
  });

  final List<Map<String, dynamic>> surahList;
  final Color pageBgColor;
  final Color borderColor;
  final Color goldTextColor;
  final Color mainTextColor;
  final void Function(int surahNum, int ayahNum) onJumpToAyah;

  @override
  State<_SurahAyahTab> createState() => _SurahAyahTabState();
}

class _SurahAyahTabState extends State<_SurahAyahTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.surahList;
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = widget.surahList.where((s) {
        final name = (s['name'] ?? '').toString().toLowerCase();
        final translit = (s['transliteration'] ?? '').toString().toLowerCase();
        return name.contains(q) || translit.contains(q);
      }).toList();
    });
  }

  void _showAyahPicker(Map<String, dynamic> surah) {
    final int surahNum = surah['number'];
    final int totalVerses = surah['totalVerses'] ?? 1;
    int selectedAyah = 1;
    final TextEditingController ayahCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          void updateFromTextField(String text) {
            final val = int.tryParse(text);
            if (val != null && val >= 1 && val <= totalVerses) {
              setDialogState(() {
                selectedAyah = val;
              });
            }
          }

          return AlertDialog(
            backgroundColor: widget.pageBgColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: widget.borderColor, width: 1.5),
            ),
            title: Text(
              'سورة ${surah['name']}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 22,
                color: widget.goldTextColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    surah['transliteration'] ?? '',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'اختر رقم الآية (أو اكتبه مباشرة)',
                    style: TextStyle(fontFamily: 'Amiri', fontSize: 16, color: widget.mainTextColor),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      controller: ayahCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: widget.mainTextColor),
                      decoration: InputDecoration(
                        hintText: 'الآية...',
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: widget.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: widget.goldTextColor, width: 1.8),
                        ),
                      ),
                      onChanged: updateFromTextField,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CircleButton(
                        icon: Icons.remove,
                        borderColor: widget.borderColor,
                        textColor: widget.goldTextColor,
                        onTap: () {
                          if (selectedAyah > 1) {
                            setDialogState(() {
                              selectedAyah--;
                              ayahCtrl.text = '$selectedAyah';
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'الآية: $selectedAyah',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.goldTextColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      _CircleButton(
                        icon: Icons.add,
                        borderColor: widget.borderColor,
                        textColor: widget.goldTextColor,
                        onTap: () {
                          if (selectedAyah < totalVerses) {
                            setDialogState(() {
                              selectedAyah++;
                              ayahCtrl.text = '$selectedAyah';
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'من $totalVerses آية',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.borderColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  final val = int.tryParse(ayahCtrl.text);
                  if (val != null && val >= 1 && val <= totalVerses) {
                    Navigator.pop(ctx);
                    widget.onJumpToAyah(surahNum, val);
                  } else {
                    Navigator.pop(ctx);
                    widget.onJumpToAyah(surahNum, selectedAyah);
                  }
                },
                child: const Text('انتقل', style: TextStyle(fontSize: 16)),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            textDirection: TextDirection.rtl,
            style: TextStyle(color: widget.mainTextColor),
            decoration: InputDecoration(
              hintText: 'ابحث عن سورة...',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: widget.borderColor),
              filled: true,
              fillColor: widget.borderColor.withOpacity(0.07),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: _filtered.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              indent: 16,
              endIndent: 16,
              color: widget.borderColor.withOpacity(0.3),
            ),
            itemBuilder: (context, i) {
              final surah = _filtered[i];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.borderColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.borderColor, width: 1),
                  ),
                  child: Text(
                    '${surah['number']}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: widget.goldTextColor,
                    ),
                  ),
                ),
                title: Text(
                  'سورة ${surah['name']}',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: widget.mainTextColor,
                  ),
                ),
                subtitle: Text(
                  surah['transliteration'] ?? '',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: widget.borderColor,
                ),
                onTap: () => _showAyahPicker(surah),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Tab 2: Juz Grid ──────────────────────────────────────────────────────────

class _JuzTab extends StatelessWidget {
  const _JuzTab({
    required this.juzFirstPage,
    required this.borderColor,
    required this.goldTextColor,
    required this.onJumpToPage,
  });

  final Map<int, int> juzFirstPage;
  final Color borderColor;
  final Color goldTextColor;
  final void Function(int page) onJumpToPage;

  static const List<String> _juzNames = [
    'الجزء الأول', 'الجزء الثاني', 'الجزء الثالث', 'الجزء الرابع', 'الجزء الخامس',
    'الجزء السادس', 'الجزء السابع', 'الجزء الثامن', 'الجزء التاسع', 'الجزء العاشر',
    'الجزء الحادي عشر', 'الجزء الثاني عشر', 'الجزء الثالث عشر', 'الجزء الرابع عشر',
    'الجزء الخامس عشر', 'الجزء السادس عشر', 'الجزء السابع عشر', 'الجزء الثامن عشر',
    'الجزء التاسع عشر', 'الجزء العشرون', 'الجزء الحادي والعشرون', 'الجزء الثاني والعشرون',
    'الجزء الثالث والعشرون', 'الجزء الرابع والعشرون', 'الجزء الخامس والعشرون',
    'الجزء السادس والعشرون', 'الجزء السابع والعشرون', 'الجزء الثامن والعشرون',
    'الجزء التاسع والعشرون', 'الجزء الثلاثون',
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.35,
      ),
      itemCount: 30,
      itemBuilder: (context, index) {
        final juzNum = index + 1;
        final firstPage = juzFirstPage[juzNum] ?? 1;

        return GestureDetector(
          onTap: () => onJumpToPage(firstPage),
          child: Container(
            decoration: BoxDecoration(
              color: borderColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$juzNum',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: goldTextColor,
                  ),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    _juzNames[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 11,
                      color: goldTextColor,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ص $firstPage',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Tab 3: Pages Grid ───────────────────────────────────────────────────────

class _PagesTab extends StatefulWidget {
  const _PagesTab({
    Key? key,
    required this.currentPage,
    required this.borderColor,
    required this.goldTextColor,
    required this.onJumpToPage,
  }) : super(key: key);

  final int currentPage;
  final Color borderColor;
  final Color goldTextColor;
  final void Function(int page) onJumpToPage;

  @override
  State<_PagesTab> createState() => _PagesTabState();
}

class _PagesTabState extends State<_PagesTab> {
  final TextEditingController _pageCtrl = TextEditingController();

  void _submitPage() {
    final val = int.tryParse(_pageCtrl.text);
    if (val != null && val >= 1 && val <= 604) {
      widget.onJumpToPage(val);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'الرجاء إدخال رقم صفحة صحيح بين 1 و 604',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: 'Amiri'),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            textDirection: TextDirection.rtl,
            children: [
              Expanded(
                child: TextField(
                  controller: _pageCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textDirection: TextDirection.rtl,
                  decoration: InputDecoration(
                    hintText: 'اكتب رقم الصفحة (1 - 604)...',
                    hintStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.find_in_page, color: widget.borderColor),
                    filled: true,
                    fillColor: widget.borderColor.withOpacity(0.07),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _submitPage(),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.borderColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onPressed: _submitPage,
                child: const Text(
                  'انتقل',
                  style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.0,
            ),
            itemCount: 604,
            itemBuilder: (context, index) {
              final pageNum = index + 1;
              final bool isCurrent = pageNum == widget.currentPage;

              return GestureDetector(
                onTap: () => widget.onJumpToPage(pageNum),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    color: isCurrent ? widget.borderColor : widget.borderColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCurrent ? widget.goldTextColor : widget.borderColor.withOpacity(0.4),
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$pageNum',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isCurrent ? Colors.white : widget.goldTextColor,
                    ),
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

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.borderColor,
    required this.textColor,
    required this.onTap,
  });

  final IconData icon;
  final Color borderColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: borderColor.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(color: borderColor),
        ),
        child: Icon(icon, color: textColor, size: 20),
      ),
    );
  }
}

/// مصفوفة البيانات الكاملة التي تحتوي على 50 عبارة تذكيرية مترجمة.
/// تم استثناء الأبيات الشعرية (العناصر من 9 إلى 13) من الترجمة والإبقاء عليها بالعربية لجميع اللغات.
final List<Map<String, String>> quranReminders = [
  // المجموعة 1: آيات وأحاديث ورفع القرآن
  {
    'ar': '⚠️ {أَلَمْ يَأْنِ لِلَّذِينَ آمَنُوا أَن تَخْشَعَ قُلُوبُهُمْ لِذِكْرِ اللَّهِ وَمَا نَزَلَ مِنَ الْحَقِّ}.. اقرأ بقلبٍ حاضر.',
    'en': '⚠️ {Has the time not come for those who have believed that their hearts should submit to the remembrance of Allah and what has come down of the truth...} Read with an attentive heart.',
    'am': '⚠️ {ካመኑት ወገኖች ልቦቻቸው ለአላህ ውሳኔና ከእውነት ለወረደው (ለቁርኣን) ሊሰበሩና ሊያጎነብሱ ጊዜው አልደረሰምን?}.. በልብህ ተገኝተህ አንብብ።',
    'om': '⚠️ {Yeroon warra amananiif qalbiiwwan isaanii zikrii Allaahifi dhugaa bu’eef akka laaftu hin geennee?...} Qalbii dammaqiinsaan dubbisi.',
  },
  {
    'ar': '🚨 سيأتي زمانٌ يُسرى على كتاب الله في ليلة فلا يبقى في الأرض منه آية، وتُغلق التوبة.. ماذا أنت فاعلٌ بمصحفك اليوم؟',
    'en': '🚨 A time will come when the Book of Allah will be taken away in a single night, leaving not a single verse on Earth, and repentance will be closed... What are you doing with your Mus-haf today?',
    'am': '🚨 የአላህ መጽሐፍ (ቁርኣን) በአንድ ሌሊት የሚነጠቅበትና በምድር ላይ አንዲትም አንቀጽ የማይቀርበት፣ ተውበትም የሚዘጋበት ጊዜ ይመጣል። ዛሬ ከቁርኣንህ ጋር ምን እያደረግክ ነው?',
    'om': "🚨 Yeroon Kitaabni Allaah halkan tokkotti ol fudhamuufi dachii irratti aayanni tokkollee hin hafne, tawbaanis cufamu ni dhufa... Har'a immoo ati qur'aana keetiin maal gochaa jirtaa?",
  },
  {
    'ar': '⏱️ فرصتك الآن بين يديك! اقرأ وتدبر بقلبك قبل أن يُرفع القرآن من الصدور والسطور.',
    'en': '⏱️ Your opportunity is now in your hands! Read and contemplate with your heart before the Qur\'an is lifted from hearts and pages.',
    'am': '⏱️ ዕድሉ አሁን በእጅህ ነው! ቁርኣን ከልቦችና ከገጾች ከመነሳቱ በፊት በልብህ አንብብና አሰላስል።',
    'om': "⏱️ Carraan kee amma harka kee jira! Qur'aanni onneefi barruu keessaa osoo hin fudaatamin dura qalbii keetiin dubbisi, xiinxali.",
  },
  {
    'ar': '📖 قال النبي ﷺ: «اقرؤوا القرآن فإنه يأتي يوم القيامة شفيعاً لأصحابه».. فضمن شفاعته الآن.',
    'en': '📖 The Prophet ﷺ said: "Read the Qur\'an, for it will come on the Day of Resurrection as an intercessor for its companions." Secure its intercession now.',
    'am': '📖 ነቢዩ ﷺ እንዲህ ብለዋል፡- «ቁርኣንን አንብቡ፤ በትንሳኤ ቀን ለጓደኞቹ አማላጅ ሆኖ ይመጣልና።» አሁኑኑ አማላጅነቱን አረጋግጥ።',
    'om': '📖 Nabiyyiin ﷺ jedhan: "Qur’aana dubbisaa, inni Guyyaa Qiyamaa saahiboota isaatiif shafaa’aa (mangaastuu) ta’ee ni dhufaa." Ammuma shafaa’ummaa isaa mirkaneeffadhu.',
  },
  {
    'ar': '💎 قال النبي ﷺ: «الماهر بالقرآن مع السفرة الكرام البررة».. جاهد لتكون معهم.',
    'en': '💎 The Prophet ﷺ said: "The one who is proficient in the Qur\'an will be with the noble and obedient scribes (angels)." Strive to be with them.',
    'am': '💎 ነቢዩ ﷺ እንዲህ ብለዋል፡- «በቁርኣን ጎበዝ የሆነው ከተከበሩትና ታዛዦች መላእክት ጋር ነው።» ከእነሱ ጋር ለመሆን ታገል።',
    'om': '💎 Nabiyyiin ﷺ jedhan: "Inni qur’aana ogummaan dubbisu malaykoota kabajamoo fi qajeeloo waliin ta\'a." Isaaniin waliin ta\'uuf qabsaa\'i.',
  },
  {
    'ar': '🔥 قال النبي ﷺ: «يؤتى بالقرآن يوم القيامة تقدمه سورة البقرة وآل عمران تحاجان عن صاحبهما».. لا تترك صاحبيك اليوم.',
    'en': '🔥 The Prophet ﷺ said: "The Qur\'an will be brought on the Day of Resurrection, preceded by Surah Al-Baqarah and Al-Imran, arguing on behalf of their companion." Do not abandon your two companions today.',
    'am': '🔥 ነቢዩ ﷺ እንዲህ ብለዋል፡- «ቁርኣን በትንሳኤ ቀን ይመጣል፤ ሱረቱ አል-በቀራህና አሊ-ዒምራን እየመሩት ለባለቤታቸው ይሟገታሉ።» ዛሬ ሁለቱን ጓደኞችህን أتተዋቸው።',
    'om': '🔥 Nabiyyiin ﷺ jedhan: "Qur’aanni Guyyaa Qiyamaa ni fidama, Suuraa Al-Baqaraafi Al-Imraan dursanii dhufeen saahiba isaaniitiif falmu." Har\'a saahiboota kee lamaan kana hin dhiisin.',
  },
  {
    'ar': '⚖️ قال النبي ﷺ: «القرآن حجة لك أو عليك».. فتأمل في آياتك؛ هل تقودك إلى الجنة أم تشهد عليك؟',
    'en': '⚖️ The Prophet ﷺ said: "The Qur\'an is a proof for you or against you." So reflect upon your verses; are they leading you to Paradise or testifying against you?',
    'am': '⚖️ ነቢዩ ﷺ እንዲህ ብለዋል፡- «ቁርኣን ለአንተ أو በአንተ ላይ ምስክር ነው።» ስለዚህ አንቀጾችህን አሰላስል፤ ወደ ጀነት እየመሩህ ነው ወይስ በአንተ ላይ እየመሰከሩብህ?',
    'om': '⚖️ Nabiyyiin ﷺ jedhan: "Qur’aanni siif ragaa ykn sitti ragaa dha." Sila aayatoota kee xiinxali; gara Jannataa si geessaa jiran moo sitti ragaa bahaa jiru?',
  },
  {
    'ar': '⚡ قال عمر بن الخطاب: «إن الله يرفع بهذا الكتاب أقواماً ويضع به آخرين».. فكن ممن رفعه الله بالقرآن.',
    'en': '⚡ Umar ibn al-Khattab said: "Indeed, Allah raises nations by this Book and degrades others by it." So be among those whom Allah raises with the Qur\'an.',
    'am': '⚡ ዑመር ቢን አል-ኸጧብ እንዲህ ብለዋል፡- «አላህ በዚህ መጽሐፍ ህዝቦችን ከፍ ያደርጋል، ሌሎችንም ዝቅ ያደርጋል።» አላህ በቁርኣን ከፍ ካደረጋቸው መካከል ሁን።',
    'om': '⚡ Umar bin Al-Khattaab jedhan: "Dhugumatti Allaah kitaaba kanaan uummata tokko ol kaasa, kaan immoo gadi qaba." Warra Allaah Qur\'aanaan ol kaase keessaa tokko ta\'i.',
  },

  // المجموعة 2: أبيات شعرية (مستثناة من الترجمة الإنجليزية والأمهرية والأورومية)
  {
    'ar': '«يا ليت شعري كيف حالي في غدٍ.. وبأيِّ وجهٍ ألتَقِي رَبِّي غَدَا\nأمَّا إلى جَنَّاتِ خُلْدٍ عَالِيَةْ.. أوْ هَاوِيَةْ تَصْلَى جَحِيمًا جَامِدَا!»\nاقرأ لِتَنْجُو.',
    'en': '«يا ليت شعري كيف حالي في غدٍ.. وبأيِّ وجهٍ ألتَقِي رَبِّي غَدَا\nأمَّا إلى جَنَّاتِ خُلْدٍ عَالِيَةْ.. أوْ هَاوِيَةْ تَصْلَى جَحِيمًا جَامِدَا!»\nاقرأ لِتَنْجُو.',
    'am': '«يا ليت شعري كيف حالي في غدٍ.. وبأيِّ وجهٍ ألتَقِي رَبِّي غَدَا\nأمَّا إلى جَنَّاتِ خُلْدٍ عَالِيَةْ.. أوْ هَاوِيَةْ تَصْلَى جَحِيمًا جَامِدَا!»\nاقرأ لِتَنْجُو.',
    'om': '«يا ليت شعري كيف حالي في غدٍ.. وبأيِّ وجهٍ ألتَقِي رَبِّي غَدَا\nأمَّا إلى جَنَّاتِ خُلْدٍ عَالِيَةْ.. أوْ هَاوِيَةْ تَصْلَى جَحِيمًا جَامِدَا!»\nاقرأ لِتَنْجُو.',
  },
  {
    'ar': '«وإذا خلوت بريبة في ظلمة.. والنفس داعية إلى الطغيان\nفاستحي من نظر الإله وقل لها.. إن الذي خلق الظلام يراني»\nطهّر قلبك بالقرآن.',
    'en': '«وإذا خلوت بريبة في ظلمة.. والنفس داعية إلى الطغيان\nفاستحي من نظر الإله وقل لها.. إن الذي خلق الظلام يراني»\nطهّر قلبك بالقرآن.',
    'am': '«وإذا خلوت بريبة في ظلمة.. والنفس داعية إلى الطغيان\nفاستحي من نظر الإله وقل لها.. إن الذي خلق الظلام يراني»\nطهّر قلبك بالقرآن.',
    'om': '«وإذا خلوت بريبة في ظلمة.. والنفس داعية إلى الطغيان\nفاستحي من نظر الإله وقل لها.. إن الذي خلق الظلام يراني»\nطهّر قلبك بالقرآن.',
  },
  {
    'ar': '«تنسى الموت وتلهو بالحياة.. وكأنك مخلدٌ فيها لا محالة\nوالقبر يناديك كل ليلة.. أنا بيت الغربة والظلمة والوحدة».. تدبر كلام ربك.',
    'en': '«تنسى الموت وتلهو بالحياة.. وكأنك مخلدٌ فيها لا محالة\nوالقبر يناديك كل ليلة.. أنا بيت الغربة والظلمة والوحدة».. تدبر كلام ربك.',
    'am': '«تنسى الموت وتلهو بالحياة.. وكأنك مخلدٌ فيها لا محالة\nوالقبر يناديك كل ليلة.. أنا بيت الغربة والظلمة والوحدة».. تدبر كلام ربك.',
    'om': '«تنسى الموت وتلهو بالحياة.. وكأنك مخلدٌ فيها لا محالة\nوالقبر يناديك كل ليلة.. أنا بيت الغربة والظلمة والوحدة».. تدبر كلام ربك.',
  },
  {
    'ar': '«أتنبت بالذنوب وأنت فانٍ.. وتنسى موقف العرض العظيم؟\nوتعرض عن كتاب الله لاهٍ.. كأنك قد ضمنت لظى الجحيم!»\nاستفق واقرأ بوجل.',
    'en': '«أتنبت بالذنوب وأنت فانٍ.. وتنسى موقف العرض العظيم؟\nوتعرض عن كتاب الله لاهٍ.. كأنك قد ضمنت لظى الجحيم!»\nاستفق واقرأ بوجل.',
    'am': '«أتنبت بالذنوب وأنت فانٍ.. وتنسى موقف العرض العظيم؟\nوتعرض عن كتاب الله لاهٍ.. كأنك قد ضمنت لظى الجحيم!»\nاستفق واقرأ بوجل.',
    'om': '«أتنبت بالذنوب وأنت فانٍ.. وتنسى موقف العرض العظيم؟\nوتعرض عن كتاب الله لاهٍ.. كأنك قد ضمنت لظى الجحيم!»\nاستفق واقرأ بوجل.',
  },
  {
    'ar': '«عمرك يمضي والأنفاس معدودة.. والمصحف يشكو الهجر في زاوية دارك\nفقم وتزود بآياتٍ تنير بها.. قبراً غداً ستحل فيه ضيفاً بجوارك».',
    'en': '«عمرك يمضي والأنفاس معدودة.. والمصحف يشكو الهجر في زاوية دارك\nفقم وتزود بآياتٍ تنير بها.. قبراً غداً ستحل فيه ضيفاً بجوارك».',
    'am': '«عمرك يمضي والأنفاس معدودة.. والمصحف يشكو الهجر في زاوية دارك\nفقم وتزود بآياتٍ تنير بها.. قبراً غداً ستحل فيه ضيفاً بجوارك».',
    'om': '«عمرك يمضي والأنفاس معدودة.. والمصحف يشكو الهجر في زاوية دارك\nفقم وتزود بآياتٍ تنير بها.. قبراً غداً ستحل فيه ضيفاً بجوارك».',
  },

  // المجموعة 3: أقوال الأئمة الأربعة وكبار السلف
  {
    'ar': 'قال الإمام عثمان بن عفان رضي الله عنه: «لو طهرت قلوبكم ما شبعت من كلام ربكم.»',
    'en': 'Imam Uthman ibn Affan (may Allah be pleased with him) said: "If your hearts were pure, they would never have enough of the speech of your Lord."',
    'am': 'ኢማም ዑስማን ቢን ዓፋን (ረዲየላሁ ዐንሁ) እንዲህ ብለዋል፡- «ልቦቻችሁ ቢጠሩ ኖሮ ከጌታችሁ ንግግር ባልጠገቡ ነበር።»',
    'om': 'Imaam Usmaan bin Affaan (R.A) jedhan: "Osoo onneen keessan qulqullooftee, jecha Rabbii keessanii hin quuftu turtte."',
  },
  {
    'ar': 'قال الإمام الشافعي رحمه الله: «من قرأ القرآن عظُمت قيمته.»',
    'en': 'Imam Al-Shafi\'i (may Allah have mercy on him) said: "Whoever reads the Qur\'an, their value becomes magnificent."',
    'am': 'ኢማም አሽ-ሻፊዒይ (ረሂመሁላህ) እንዲህ ብለዋል፡- «ቁርኣንን ያነበበ ሰው እሴቱ ታላቅ ይሆናል።»',
    'om': 'Imaam Al-Shaafi\'ii (R.H) jedhan: "Namni Qur’aana dubbise gatiin isaa guddata."',
  },
  {
    'ar': 'قيل للإمام أحمد: بمَ يتقرب المتقربون إلى الله؟ قال: «بِكَلَامِهِ». قيل: بفهمٍ أو بغير فهم؟ قال: «بِفَهْمٍ وَبِغَيْرِ فَهْمٍ».',
    'en': 'It was said to Imam Ahmad: "With what do those drawing close to Allah draw close?" He said: "With His Speech." It was asked: "With understanding or without understanding?" He said: "With understanding and without understanding."',
    'am': 'ለኢማም አሕመድ ተባለ፡ «ወደ አላህ ተቃራኒዎች በምን ይቃረባሉ?» እርሳቸውም «በቃሉ» አሉ። «በመረዳት ወይስ ያለመረዳት?» ተብለው ተጠየቁ። «በመረዳትም ያለመረዳትም» አሉ።',
    'om': 'Imaam Ahmadaniin jedhame: "Warri gara Allaah dhiyaatan maaliin dhiyaatu?" Innis: "Jecha Isaatiin" jedhe. "Hubannoodhaan moo hubannoo malee?" jedhamee gaafatame. Innis: "Hubannoodhaanis hubannoo malees" jedhe.',
  },
  {
    'ar': 'قال الإمام مالك رحمه الله: «ما من شيء من أعمال البر إلا وله حدٌّ ينتهي إليه، إلا ذكر الله وتلاوة كتابه.»',
    'en': 'Imam Malik (may Allah have mercy on him) said: "There is no righteous deed except that it has a limit where it ends, except the remembrance of Allah and the recitation of His Book."',
    'am': 'ኢማም ማሊክ (ረሂመሁላህ) እንዲህ ብለዋል፡- «ከመልካም ስራዎች ሁሉ የሚቆምበት ወሰን የሌለው የለም، አላህን ማውساتና መጽሐፉን ማንበብ ሲቀር።»',
    'om': 'Imaam Maalik (R.H) jedhan: "Hojiiwwan gaarii keessaa waan daangaa qabu malee hin jiru, zikrii Allaah fi Kitaaba Isaa dubbisuu malee."',
  },
  {
    'ar': 'قال الإمام عبد الله بن مسعود رضي الله عنه: «إن هذا القرآن مأدبة الله, فخذوا من مأدبته ما استطعتم.»',
    'en': 'Imam Abdullah ibn Mas\'ud (may Allah be pleased with him) said: "Indeed, this Qur\'an is the banquet of Allah, so take from His banquet as much as you can."',
    'am': 'ኢማም ዓብደላህ ቢን መስዑድ (ረዲየላሁ ዐንሁ) እንዲህ ብለዋል፡- «ይህ ቁርኣን የአላህ ግብዣ ነው፤ ስለዚህ ከግብዣው የቻላችሁትን ያህል ውሰዱ።»',
    'om': 'Imaam Abdullaah bin Mas’uud (R.A) jedhan: "Dhugumatti Qur’aanni kun maaddii (afeerraa) Allaahati, kanaaf maaddii Isaa irraa waan dandeessan fudhadhaa."',
  },
  {
    'ar': 'قال الإمام سفيان الثوري: «إذا أراد العبد أن يزداد مقاطعة للدنيا وإقبالاً على الآخرة، فلينظر في المصحف.»',
    'en': 'Imam Sufyan al-Thawri said: "If a servant wants to increase their detachment from this world and focus on the Hereafter, let them look into the Mus-haf."',
    'am': 'ኢማም ሱፍያን አጥ-ሰውሪ እንዲህ ብለዋል፡- «አንድ ባሪያ ከዱንያ መራቅና ወደ አኺራ መቃረብን መጨመር ከፈለገ ቁርኣንን ይመልከት።»',
    'om': 'Imaam Sufyaaan Al-Sawrii jedhan: "Yoo gabrichi addunyaa irraa fagaachuu fi gara aakhiraa deemuu dabaluu fedhe, Qur\'aana haa ilaalu."',
  },
  {
    'ar': 'قال الإمام الفضيل بن عياض: «حامل القرآن حامل راية الإسلام، لا ينبغي أن يلهو مع من يلهو.»',
    'en': 'Imam Al-Fudayl ibn Iyad said: "The bearer of the Qur\'an is the bearer of the banner of Islam, it is not fitting for him to idle with those who idle."',
    'am': 'ኢማም አል-ፉደይል ቢን ኢያድ እንዲህ ብለዋል፡- «የቁርኣን ተሸካሚ የእስልምናን ሰንደቅ አላማ ተሸካሚ ነው، ከሚጫወቱት ጋር ሊጫወት አይገባውም።»',
    'om': 'Imaam Fudayl bin Iyaad jedhan: "Baataan Qur’aanaa alaabaa Islaamaa baataadha, nama taphatu waliin taphachuun isaaf hin malu."',
  },
  {
    'ar': 'قال الإمام الحسن البصري: «تفقَّدوا الحلاوة في ثلاثة أشياء: في الصلاة، وفي الذكر، وفي قراءة القرآن.»',
    'en': 'Imam Al-Hasan al-Basri said: "Seek sweetness in three things: in prayer, in remembrance, and in the recitation of the Qur\'an."',
    'am': 'ኢማም አል-ሀሰን አል-በስሪ እንዲህ ብለዋል፡- «ጣፋጭነትን በሶስት ነገሮች ውስጥ ፈልጉ፡ በሶላት، በዚክር እና ቁርኣን በማንበብ ውስጥ።»',
    'om': 'Imaam Al-Hasan Al-Basrii jedhan: "Miyaawaa waan sadii keessatti barbaadaa: salaata keessatti, zikrii keessatti fi Qur’aana dubbisuu keessatti."',
  },
  {
    'ar': 'قال ابن القيم رحمه الله: «قراءة آية بتفكر وتدبر خير من قراءة ختمة بغير تدبر وفهم.»',
    'en': 'Ibn al-Qayyim (may Allah have mercy on him) said: "Reading a single verse with reflection and contemplation is better than completing the entire Qur\'an without contemplation and understanding."',
    'am': 'ኢብኑል ቀይም (ረሂመሁላህ) እንዲህ ብለዋል፡- «አንዲትን አንቀጽ በትኩረትና በማስተንተን ማንበብ ቁርኣንን ሙሉ በሙሉ ያለ ማስተንተንና መረዳት ከማንበብ ይበልጣል።»',
    'om': 'Ibn Al-Qayyim (R.H) jedhan: "Aayata tokko xiinxalaafi hubannoodhaan dubbisuun Qur’aana guutuu osoo hin xiinxalin dubbisuu irra caala."',
  },
  {
    'ar': 'قال الإمام ذو النون المصري: «القرآن دواء القلوب البالية، وصلاح الأنفس العاصية.»',
    'en': 'Imam Dhu\'n-Nun al-Misri said: "The Qur\'an is the cure for worn-out hearts and the righteousness of disobedient souls."',
    'am': 'ኢማም ዙን-ኑን አል-ሚስሪ እንዲህ ብለዋል፡- «ቁርኣን ለዛሉ ልቦች መድኃኒት، ለአመጸኞች ነፍሳትም ማስተካከያ ነው።»',
    'om': 'Imaam Dhu Al-Nuun Al-Misrii jedhan: "Qur’aanni qoricha onnee dhumteeti, fi qajeelfama lubbuu finciltuuti."',
  },

  // المجموعة 4: وعظ، مقارنة بالأموات، وشحن الهمة
  {
    'ar': '⚰️ الأموات في قبورهم يتمنون سجدة أو آية، وأنت كتاب الله بين يديك كاملاً.. اغتنم حياتك قبل حسرتك!',
    'en': '⚰️ The deceased in their graves wish for a single prostration or a single verse, while the Book of Allah is fully in your hands... Seize your life before your regret!',
    'am': '⚰️ ሙታን በመቃብራቸው ውስጥ ሆነው አንዲት ሱጁድ ወይም አንቀጽ ይመኛሉ፣ አንተ ግን የአላህ መጽሐፍ ሙሉ በሙሉ በእጅህ ነው... ከቆጨህ በፊት ሕይወትህን ተጠቀምባት!',
    'om': "⚰️ Warri du'an qabrii keessatti sujuuda tokko ykn aayata tokko hawwu, ati immoo Kitaabni Allaah guutuun harka kee jira... Osoo hin gaabin jireenya kee gorfadhu!",
  },
  {
    'ar': '🕯️ اقرأ بتمهل.. فرُبّ آيةٍ تتلوها وتتدبرها اليوم، تكون هي أنيسك والضياء الشافي لك في ظلمات قبرك.',
    'en': '🕯️ Read slowly... For perhaps a verse you recite and ponder today will be your companion and healing light in the darkness of your grave.',
    'am': '🕯️ ቀስ ብለህ አንብብ... ዛሬ የምታነባትና የምታስተነትናት አንቀጽ ነገ በመቃብርህ ጨለማ ውስጥ አጋዥህና ፈዋሽ ብርሃንህ ትሆን ይሆናል።',
    'om': "🕯️ Suuta jedhii dubbisi... Tarii aayanni ati har'a qaraatanii xiinxaltu, dukkana qabrii keetii keessatti hiriyaa keefi ibsaa si fayyisu ta'uu danda'a.",
  },
  {
    'ar': '🏰 كل آية تقرؤها وتعمل بها الآن هي لبنةٌ ودرجةٌ تبنيها في قصرك بالجنة.. اقرأ وارتقِ!',
    'en': '🏰 Every verse you read and act upon now is a brick and a step you build in your palace in Paradise... Read and rise!',
    'am': '🏰 አሁን የምታነባትና የምትሰራባት እያንዳንዱ አንቀጽ በጀነት ውስጥ ላለህ ቤተመንግስት የምትገነባው ጡብና ደረጃ ነው... አንብብና ከፍ በል!',
    'om': '🏰 Aayanni ati amma dubbistee hojiirra oolchitu hundi riqaa fi sadarkaa ati gamooma jannata keessatti ijaarrattudha... Dubbisi ol ka\'i!',
  },
  {
    'ar': '🪙 الحرف بعشر حسنات، والحسنات جبالٌ تثقل الميزان يوم القيامة.. ابدأ تجارتك الرابحة الآن مع الله.',
    'en': '🪙 A letter earns ten good deeds, and good deeds are mountains that weigh heavy on the Scale on the Day of Resurrection... Start your profitable trade with Allah now.',
    'am': '🪙 እያንዳንዱ ፊደل በአስር መልካም ስራዎች ነው، መልካም ስራዎች ደግሞ በትንساኤ ቀን ሚዛኑን የሚያከብዱ ተራሮች ናቸው... አሁኑኑ ከአላህ ጋር አتራፊ ንግድህን ጀምር።',
    'om': '🪙 Harfiin tokko tola kudhaniin, tolaa immoo gaarren Guyyaa Qiyamaa mizaana ulfeessanidha... Ammuma daldala kee kan bu\'aa qabu Allaah waliin jalqabi.',
  },
  {
    'ar': '❤️ القرآن لا يترك صاحبه أبداً؛ يرافقك في الدنيا، ويحميك في القبر، ويجادل عنك يوم القيامة حتى تدخل الجنة.',
    'en': '❤️ The Qur\'an never leaves its companion; it accompanies you in this world, protects you in the grave, and advocates for you on the Day of Resurrection until you enter Paradise.',
    'am': '❤️ ቁርኣን ባለቤቱን በፍጹም አይተውም፤ በዱንያ አብሮህ ይሆናል، በመቃብር ይጠብቅሃል، በትንሳኤ ቀንም ጀነት እስክትገባ ድረስ ይከራከርልሃል።',
    'om': '❤️ Qur’aanni saahiba isaa hin dhiisu; addunyaa keessatti si waliin ta\'a, qabrii keessatti si eega, Guyyaa Qiyamaas hamma Jannata seentutti siif falma.',
  },
  {
    'ar': '🌟 لا تجعل مصحفك مهجوراً؛ فالقلب الذي لا يقرأ القرآن كالبيت الخرب الذي لا يسكنه أحد.',
    'en': '🌟 Do not leave your Mus-haf abandoned; for the heart that does not read the Qur\'an is like a ruined house in which no one dwells.',
    'am': '🌟 ቁርኣንህን የተተወ አتاድርገው፤ ቁርኣን የማይነበብበት ልብ ማንም እንደማይኖርበት የፈረሰ ቤት ነውና።',
    'om': '🌟 Qur’aana kee gatamoo hin godhin; onneen Qur’aana hin dubbisne akka mana diigamee nama keessa hin jirreeti.',
  },
  {
    'ar': '🕊️ النجاة النجاة! غداً تُوضع الموازين وتنكشف الأستار، ولن ينفعك إلا ما قدمت من كتاب الله.',
    'en': '🕊️ Salvation, salvation! Tomorrow the scales will be set and secrets revealed, and nothing will benefit you except what you offered from the Book of Allah.',
    'am': '🕊️ መዳን، መዳን! ነገ ሚዛኖች ይቀመጣሉ، መጋረጃዎችም ይገለጣሉ، ከአላህ መጽሐፍ ካቀረብከው በስተቀር ምንም አይጠቅምህም።',
    'om': '🕊️ Fayyinna, fayyinna! Bor mizaanni ni kaa\'ama, haguuggiinis ni saaqama, waan ati Kitaaba Allaah irraa dabarsite malee maaltu si fayyada.',
  },
  {
    'ar': '💧 بكاء العين من خشية آية، يطفئ بحاراً من عذاب يوم القيامة.. تدبر حروفه.',
    'en': '💧 The weeping of the eye out of fear from a verse extinguishes oceans of torment on the Day of Resurrection... Ponder its letters.',
    'am': '💧 ከአንቀጽ ፍርሃት የተነሳ የአይን ማልቀስ የትንሳኤ ቀንን የስቃይ ባህሮች ያጠፋል... ፊደሎቹን አስተንትን።',
    'om': '💧 Imimmaan ijaa sodaa aayata tokkoo irraa ka\'e, galaana adaba Guyyaa Qiyamaa balleessa... Harfii isaa xiinxali.',
  },
  {
    'ar': '👑 يُقال لقارئ القرآن يوم القيامة: اقرأ وارتق ورتل كما كنت ترتل في الدنيا، فإن منزلتك عند آخر آية تقرؤها.',
    'en': '👑 It will be said to the companion of the Qur\'an on the Day of Resurrection: "Read and ascend, and recite smoothly as you used to recite in the world, for your status will be at the last verse you read."',
    'am': '👑 በትንሳኤ ቀን ለቁርኣን አንባቢ እንዲህ ይባላል፡- «አንብብና ከፍ በል፤ በዱንያ ላይ እንደምታነበው አሳምረህ አንብብ፤ ደረጃህ የመጨረሻዋ የምታነባት አንቀጽ ጋ ነውና።»',
    'om': '👑 Guyyaa Qiyamaa qaraataa Qur’aanaatiin ni jedhama: "Dubbisi ol ka\'i, akkuma addunyaa keessatti suuta dubbisaa turtetti suuta dubbisi, sadarkaan kee aayata dhumaa ati dubbistu biratti dha."',
  },
  {
    'ar': '🚨 لا تخرج من الدنيا صفر اليدين، والقرآن حجة لك أو عليك.. اجعله حجة لك.',
    'en': '🚨 Do not leave this world empty-handed, while the Qur\'an is a proof for you or against you... Make it a proof for you.',
    'am': '🚨 ከዱንያ ባዶ እጅህን አትውጣ، ቁርኣን ለአንته أو በአንተ ላይ ምስክር ነው... ለአንተ ምስክር አድርገው।',
    'om': '🚨 Harka duwwaa addunyaa irraa hin ba\'in, Qur’aanni siif ragaa ykn sitti ragaa dha... Ofiif ragaa godhadhu.',
  },
  {
    'ar': '🗺️ إذا تاهت بك السبل وضاق صدرك، فافتح مصحفك؛ ففيه نبأ من قبلكم، وخبر ما بعدكم، وحكم ما بينكم.',
    'en': '🗺️ If the ways confuse you and your chest feels tight, open your Mus-haf; for in it is the news of those before you, information of what is after you, and judgment for what is between you.',
    'am': '🗺️ መንገዶች ቢጠፉብህና ደረትህ ቢጠበብ ቁርኣንህን ክፈት፤ በእሱ ውስጥ የእናንተ በፊት የነበሩት ወሬ، ከእናንተ በኋላ የሚመጣው ዜና እና በመካከላችሁ ያለው ፍርድ አለና።',
    'om': '🗺️ Yoo karaaleen sitti badanii garaan kee dhiphate, Qur\'aana kee bani; isa keessa oduu warra isiniin duraa, oduu warra isiniin boodaa fi murtii gidduu keessanii jirutu jira.',
  },
  {
    'ar': '⚡ شعلة الحماس لا تنطفئ في قلبٍ أدمن تلاوة كلام ربه.. ابدأ قراءتك بهمة عالية.',
    'en': '⚡ The flame of enthusiasm does not die out in a heart addicted to reciting the speech of its Lord... Start your reading with high resolve.',
    'am': '⚡ የጌታውን ቃል ማንበብ በለመደ ልብ ውስጥ የንቃት እሳት አይጠፋም... ንባብህን በከፍተኛ ጉጉት ጀምር።',
    'om': '⚡ Labbiin fedhii onnee keessa jiru kan daddabalatee jecha Rabbii isaa dubbisuun adiktee ta\'e hin dhabamu... Dubbisa kee hamilee olaanaan jalqabi.',
  },
  {
    'ar': '🤝 ليكن القرآن صاحبك المفضل؛ فكل الأصحاب يفارقونك عند الموت، إلا القرآن يدخل معك قبرك.',
    'en': '🤝 Let the Qur\'an be your favorite companion; for all companions part with you at death, except the Qur\'an, which enters your grave with you.',
    'am': '🤝 ቁርኣን ተወዳጅ ጓደኛህ ይሁን፤ ጓደኞች ሁሉ ሲሞቱ ይለዩሃል، ቁርኣን ግን ካንተ ጋር ወደ መቃብርህ ይገባል።',
    'om': '🤝 Qur’aanni saahiba kee filatamaa haa ta’u; saahiboonni hundi yeroo du\'aa si biraa deemu, Qur’aana malee kan qabrii kee si waliin seenu.',
  },
  {
    'ar': '✨ استشعر الآن وأنت تفتح المصحف أن ملك الملوك يكلمك أنت مباشرة.. فاستمع وأنصت.',
    'en': '✨ Feel now as you open the Mus-haf that the King of kings is speaking to you directly... So listen and pay attention.',
    'am': '✨ አሁን ቁርኣኑን ስትከፍት የነገስታት ንጉስ በቀጥታ እያናገረህ እንደሆነ ይሰማህ... ስለዚህ አድምጥ، ጸጥም በል።',
    'om': '✨ Amma yeroo Qur\'aana bantu Mootiin moototaa kallattiin sitti dubbachaa akka jiru sitti haa dhaga\'amu... Kanaaf dhaggeeffadhu, cal\'isis.',
  },
  {
    'ar': '🛑 احذر الحرمان! أن يمر عليك يومك المكتظ بالمشاغل دون أن تفتح لقلبك نافذة نور من كلام ربك.',
    'en': '🛑 Beware of deprivation! That your day crowded with concerns passes by without opening a window of light for your heart from the speech of your Lord.',
    'am': '🛑 ከመነፈግ ተጠንቀቅ! በስራ የተጠመደው ቀንህ ለልብህ ከጌታህ ቃል የብርሃን መስኮት ሳትከፍት ማለፉ።',
    'om': '🛑 Akka hin dhabamne of eeggaddhu! Guyyaan kee kan hojiidhaan dhiphate osoo onnee keetiif foddaa ifaa jecha Rabbii keetii irraa hin banin akka hin dabarre.',
  },
  {
    'ar': '🥀 ما جفّت دماء القلوب ولا قست، إلا بعد أن هجرت تدبر المصحف الكريم.. رطّب قلبك بآياته.',
    'en': '🥀 The blood of the hearts did not dry up nor harden, except after they abandoned contemplating the Noble Mus-haf... Moisten your heart with its verses.',
    'am': '🥀 የልቦች ደም አልደረቀም ወይም አልጠነከረም، የተከበረውን ቁርኣን ማስተንተን ከተዉ በኋላ ቢሆን እንጂ... ልብህን በአንቀጾቹ አርጥብ።',
    'om': '🥀 Dhiigni onnee hin gogne, hin jabaannes, osoo xiinxala Qur\'aana kabajamaa dhiisanii booda malee... Onnee kee aayatoota isaatiin jiisi.',
  },
  {
    'ar': '🔍 تفكّر في عاقبتك.. لو قُبضت روحك الليلة، أيسرّك أن يكون آخر عهدك بالدنيا آية قرأتها أم تفاهة تصفحتها؟',
    'en': '🔍 Think about your end... If your soul were taken tonight, would it please you for your last moment in the world to be a verse you read, or triviality you scrolled through?',
    'am': '🔍 ስለ መጨረሻህ አስብ... ዛሬ ማታ ነፍስህ ብትወሰድ، በዱንያ ላይ የመጨረሻ ጊዜህ ያነበብከው አንቀጽ መሆኑ ወይስ የተመለከትከው ከንቱ ነገር መሆኑ ያስደስትሃል؟',
    'om': '🔍 Gara dhuma keetii xiinxali... Yoo lubbuun kee halkan kana fudhatamte, addunyaa irratti yeroon kee dhumaa aayata ati dubbifte ta\'u moo waan faayidaa hin qabne kan ati laaltee dabarsitedha kan si gammachiisu?',
  },
  {
    'ar': '🏹 آيات الوعيد كالسِّهام، تفلق صخور القلوب القاسية.. فقف عند وعيد الله خاشعاً منيباً.',
    'en': '🏹 The verses of warning are like arrows, splitting the rocks of hard hearts... So halt at the warning of Allah in humility and repentance.',
    'am': '🏹 የማسጠንቀቂያ አንቀጾች እንደ ቀስት ናቸው، የጠነከሩ ልቦችን ዓለቶች ይሰነጥቃሉ... ስለዚህ በአلاህ ማስጠንቀቂያ ላይ በትህትናና በመጸጸت ቁም።',
    'om': '🏹 Aayatoonni akeekkachiisaa akka xiyyaati, dhagaa onnee gantuu dhoosu... Kanaaf sodaa fi tawbaadhaan akeekkachiisa Allaah biratti dhaabbadhu.',
  },
  {
    'ar': '🌻 اقرأ بتلذذ، فهذه الدنيا ممر وساعات القراءة في المصحف هي روضة الجنة المعجّلة في الأرض.',
    'en': '🌻 Read with pleasure, for this world is a transit, and the hours of reading the Mus-haf are the hastened garden of Paradise on Earth.',
    'am': '🌻 በደስታ አንብብ، ይህች ዱንያ መሻገሪያ ነችና، በቁርኣን ውስጥ የምታነብባቸው ሰዓታት በምድር ላይ ያለችው የጀነት መናፈሻ ናቸው።',
    'om': '🌻 Mi’aa dubbisi, addunyaan tun karaa darbiinsati, sa\'aatiin ati Qur’aana keessatti dabarsitus jannata daddafte kan dachii irratti argamte dha.',
  },
  {
    'ar': '🌌 لو علم القارئ ما ينتظره من الإكرام عند منتهى سورة يرتلها، لسالت روحه شوقاً لتلاوة كتاب ربه.',
    'en': '🌌 If the reader knew what honor awaits them at the end of a Surah they recite, their soul would have flowed with longing to recite the Book of their Lord.',
    'am': '🌌 አንባቢው በሚያነበው ሱራ መጨረሻ ላይ ምን ዓይነት ክብር እንደሚጠبቀው ቢያውቅ ኖሮ، ነፍሱ የጌታውን መጽሐፍ ለማንበብ በጉጉት ትፈስ ነበር።',
    'om': '🌌 Osoo qaraataan kabaja dhuma suuraa inni qara\'u biratti isa eeggatu beekee, lubbuun isaa kitaaba Rabbii isaa qara\'uuf hawwiidhaan yaati turte.',
  },
  {
    'ar': '🚪 باب الإقبال على الله مفتوح الآن عبر هذه الشاشة.. ادخل بقلب منكسر خاشع عسى أن يُرحم.',
    'en': '🚪 The door of turning to Allah is open now through this screen... Enter with a broken, humble heart, so you may be shown mercy.',
    'am': '🚪 ወደ አላህ የመመለሻ በር አሁን በዚህ ስክሪን በኩል ክፍት ነው... ምሕረት ይደረግልህ ዘንድ በሰበረና በትሑት ልብ ግባ።',
    'om': '🚪 Balbalonni gara Allaah deebi\'u amma iskiriinii kanaan banameera... Qalbii cabduu fi gadi jedheen seeni, tarii rahmanni siif godhama.',
  },
  {
    'ar': '🍂 العمر ينقضي سريعاً والأيام تطوى.. ولا يبقى في صحيفتك غداً إلا ما وعاه قلبك من هذا التنزيل.',
    'en': '🍂 Life passes quickly and days fold... and nothing remains in your record tomorrow except what your heart preserved of this Revelation.',
    'am': '🍂 ዕድሜ በፍጥነት ያልፋል ቀናትም ይታጠፋሉ... ነገ በምዝግብ ማስታወሻህ ውስጥ ከዚህ መገለጥ ልብህ ከያዘው በስተቀር ምንም አይቀርም።',
    'om': '🍂 Umriin dafee dhumata, guyyoonnis ni dacha\'u... Bor galmee kee keessatti waan onneen kee bu\'iinsa kana irraa qabatte malee homtuu hin hafu.',
  },
  {
    'ar': '💡 القرآن نور البصيرة، من استضاء به هُدي إلى الصراط المستقيم ومن أعرض عنه عاش في ظلمة التيه.',
    'en': '💡 The Qur\'an is the light of insight, whoever seeks light from it is guided to the Straight Path, and whoever turns away from it lives in the darkness of wandering.',
    'am': '💡 ቁርኣን የእውቀት ብርሃን ነው، በእሱ የበራ ወደ ቀጥተኛው መንገድ ይመራል، ከእሱ የራቀ ግን በመጥፋት ጨለማ ውስጥ ይኖራል።',
    'om': '💡 Qur’aanni ifa ija qalbii ti, namni ifa isaan ibsate gara karaa qajeelaa qajeelfama, namni isarraa garagale immoo dukkana badinsaa keessa jiraata.',
  },
  {
    'ar': '🔔 تذكرة للمغترّ بطول الأمل: الموت يأتي بغتة، والقبر صندوق العمل.. فاجعل صندوقك مليئاً بالقرآن.',
    'en': '🔔 A reminder for the one deceived by long hopes: Death comes suddenly, and the grave is the chest of deeds... So make your chest full of the Qur\'an.',
    'am': '🔔 ረጅም ተስፋ ላለው ሰው ማስታወሻ፡ ሞት በድንገት ይመጣል، መቃብርም የስራ ሳጥን ነው... ስለዚህ ሳጥንህን በቁርኣን የተሞላ አድርገው።',
    'om': '🔔 Hawwii dheeraan kan gowwoomeef yaadachiisa: Duuti dingata dhufa, qabriin saanduqaa hojiiti... Kanaaf saanduqa kee Qur\'aanaan guuti.',
  },
  {
    'ar': '💎 القرآن لا يعطيك بعضه حتى تعطيه كلك.. فأعطِ مصحفك كليّة قلبك وانتباهك الآن.',
    'en': '💎 The Qur\'an does not give you some of it until you give it all of you... So give your Mus-haf the whole of your heart and your attention now.',
    'am': '💎 ቁርኣን ሙሉ ማንነትህን እስክትሰጠው ድረስ ከፊሉን አይሰጥህም... ስለዚህ አሁን ለቁርኣንህ ሙሉ ልብህንና ትኩረትህን ስጠው።',
    'om': '💎 Qur’aanni hamma ati guutuu kee kennitutti gartokkee isaa siif hin kennu... Kanaaf guutuu onnee keetii fi xiyyeeffannaa kee amma Qur\'aanaaf kenni.',
  },
  {
    'ar': '🌊 اغسل هموم صدرك الـمُتعبة بفيضان من آيات الطمأنينة.. أنصت لخطاب الله لك.',
    'en': '🌊 Wash away the tired worries of your chest with a flood of verses of tranquility... Listen to Allah\'s discourse to you.',
    'am': '🌊 የደረትህን የዛሉ ጭንቀቶች በእርጋታ አንቀጾች ጎርፍ እጠባቸው... አላህ ለአንተ የሚናገረውን ንግግር አድምጥ।',
    'om': '🌊 Yaaddoo garba dhiphina garaa keetii dambalii aayatoota tasgabbii kanaan dhuqi... Dubbii Allaah kan sitti dubbatu dhaggeeffadhu.',
  },
  {
    'ar': '🤲 اللهم اجعلنا ممن يقرأ القرآن فيرقى، ولا تجعلنا ممن يقرأه فيشقى.. ابدأ قراءتك مستعيناً بالله.',
    'en': '🤲 O Allah, make us of those who read the Qur\'an and ascend, and do not make us of those who read it and are miserable... Start your reading seeking help from Allah.',
    'am': '🤲 አላህ ሆይ! ቁርኣን አንብበው ከፍ ከሚሉት አድርገን، አንብበው ከሚቸገሩት አታድርገን... አላህን በመታገዝ ንባብህን ጀምር።',
    'om': '🤲 Ya Allaah! warra Qur’aana qara’ee ol ka’u nu taasisi, warra qara’ee hoonga’u nu hin taasisin... Gargaarsa Allaah barbaacha dubbisa kee jalqabi.',
  },
];

/// ودجت التذكير التفاعلي المحمي ضد تجاوز حدود المساحة الرأسية والأفقية.
class QuranReminderWidget extends StatefulWidget {
  final int pageNum;
  final String languageCode; // 'ar', 'en', 'am', 'om'

  const QuranReminderWidget({
    Key? key,
    required this.pageNum,
    required this.languageCode,
  }) : super(key: key);

  @override
  State<QuranReminderWidget> createState() => _QuranReminderWidgetState();
}

class _QuranReminderWidgetState extends State<QuranReminderWidget> {
  late int _randomIndex;

  @override
  void initState() {
    super.initState();
    // اختيار عشوائي للعبارة عند بدء بناء الصفحة لأول مرة
    _randomIndex = math.Random().nextInt(quranReminders.length);
  }

  @override
  Widget build(BuildContext context) {
    // يظهر الودجت فقط في الصفحتين 1 و 2 كما هو محدد بالشروط
    if (widget.pageNum != 1 && widget.pageNum != 2) {
      return const SizedBox.shrink();
    }

    final Map<String, String> selectedItem = quranReminders[_randomIndex];
    
    // جلب النص حسب لغة الجهاز وفي حال غيابها نعود للعربية كلغة افتراضية
    final String localizedText = selectedItem[widget.languageCode] ?? selectedItem['ar'] ?? '';

    return Positioned(
      top: 155,
      left: 45,
      right: 45,
      bottom: 650,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        alignment: Alignment.center,
        // برواز جمالي يحيط بالتذكير
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: const Color(0xFFD4AF37), // لون ذهبي هادئ يناسب مصحف القرآن
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ],
        ),
        // استخدام تخطيط القيود الصارمة (LayoutBuilder & FittedBox) لمنع تسرب النصوص الطويلة كالأورومية
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth,
                  maxHeight: constraints.maxHeight,
                ),
                child: Text(
                  localizedText,
                  textAlign: TextAlign.center,
                  maxLines: 4, // حد أقصى للحفاظ على شكل التنسيق
                  overflow: TextOverflow.ellipsis, // إلحاق النقاط (...) في حال عدم اتساع النص نهائياً بعد التصغير المسموح
                  style: const TextStyle(
                    fontSize: 18.0, // الحجم الافتراضي المفضل وسيتم تصغيره برمجياً تلقائياً إذا تطلب الأمر لضمان الحماية من الـ Overflow
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2C3E50),
                    height: 1.4,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}