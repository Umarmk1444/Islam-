import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qcf_quran/qcf_quran.dart';
import '../theme_notifier.dart';
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
                                child: SizedBox(
                                  width: 500,
                                  height: 770,
                                  child: StrictQcfPage(
                                    pageNumber: pageNum,
                                    theme: _qcfTheme,
                                    onTap: _showAyahActionSheet,
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