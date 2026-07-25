import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qcf_quran/qcf_quran.dart';
import '../theme_notifier.dart';
import '../widgets/strict_qcf_page.dart';
import '../widgets/quran_mini_player_bar.dart';
import '../widgets/ayah_action_bar.dart';
import '../controllers/quran_audio_controller.dart';
import '../core/database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../widgets/custom_banner_ad.dart'; // kQuranScreenActive

// Background processing removed in favor of True Lazy Loading directly from SQLite

class QuranPageContentWrapper extends StatelessWidget {
  const QuranPageContentWrapper({
    super.key,
    required this.hasOverlay,
    required this.child,
  });

  final bool hasOverlay;
  final Widget child;

  static const double overlayBottomInset = 120.0;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class QuranScreen extends StatefulWidget {
  final int? initialPage;
  const QuranScreen({Key? key, this.initialPage}) : super(key: key);

  static final ValueNotifier<Map<String, dynamic>?> selectedVerseNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  PageController? _pageController;
  int _currentPageIndex = 0;
  bool _isLoading = true;
  int _reminderIndex = 0;
  bool _reminderForceArabic = false;
  Timer? _sleepTimer;

  /// Selected Verse for Dashboard
  Map<String, dynamic>? _selectedVerseData;

  /// Page headers metadata: pageNumber → {surahName, juz}
  Map<int, Map<String, dynamic>> _pageHeaders = {};

  /// Full surah list for the navigation panel
  List<Map<String, dynamic>> _surahList = [];

  /// surahNumber → first page that contains this surah (built once at load)
  final Map<int, int> _surahFirstPage = {};

  /// juzNumber → first page that contains this juz (built once at load)
  final Map<int, int> _juzFirstPage = {};

  /// Juz → list of Hizb entries for the hierarchical navigation index
  /// Each entry: { 'hizb': int, 'surahName': String, 'surahNum': int, 'ayahNum': int, 'page': int }
  Map<int, List<Map<String, dynamic>>> _juzHizbData = {};

  int? _bookmarkedPage;
  int? _bookmarkedSurah;
  int? _bookmarkedAyah;

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
    );
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Signal to persistent banner: hide ads on the Holy Quran screen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      kQuranScreenActive.value = true;
    });
    _reminderIndex = math.Random().nextInt(quranReminders.length);
    _reminderForceArabic = math.Random().nextInt(100) < 35;
    _loadQuranData();
    QuranScreen.selectedVerseNotifier
        .addListener(_handleSelectedVerseNotifierChange);
  }

  @override
  void dispose() {
    // Signal to persistent banner: show ads again.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      kQuranScreenActive.value = false;
    });
    _sleepTimer?.cancel();
    QuranScreen.selectedVerseNotifier
        .removeListener(_handleSelectedVerseNotifierChange);
    _pageController?.dispose();
    super.dispose();
  }

  void _handleSelectedVerseNotifierChange() {
    if (mounted) {
      final newSelection = QuranScreen.selectedVerseNotifier.value;
      if (newSelection != _selectedVerseData) {
        setState(() {
          _selectedVerseData = newSelection;
        });
        if (newSelection != null) {
          final page = newSelection['page'] as int? ?? 1;
          if (_currentPageIndex + 1 != page) {
            _jumpToPage(page);
          }
        }
      }
    }
  }

  // ── Data loading ──────────────────────────────────────────────────────────

  Future<void> _loadQuranData() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Fetch Surah totals
      final surahRows = await db.rawQuery(
          'SELECT sura_num, COUNT(*) as totalVerses, MIN(page_aya) as minPage FROM quran GROUP BY sura_num');
      final Map<int, int> tmpSurahFirst = {};
      final List<Map<String, dynamic>> tmpSurahs = [];

      for (final row in surahRows) {
        final int surahNum = (row['sura_num'] as num?)?.toInt() ?? 0;
        final int totalV = (row['totalVerses'] as num?)?.toInt() ?? 0;
        final int minPage = (row['minPage'] as num?)?.toInt() ?? 1;
        if (surahNum > 0 && surahNum <= 114) {
          tmpSurahFirst[surahNum] = minPage;
          tmpSurahs.add({
            'number': surahNum,
            'name': DatabaseHelper.surahNamesArabicList[surahNum - 1],
            'transliteration':
                DatabaseHelper.surahTransliterations[surahNum - 1],
            'totalVerses': totalV,
          });
        }
      }

      // 2. Fetch Juz
      final juzRows = await db.rawQuery(
          'SELECT juz, MIN(page_aya) as minPage FROM quran GROUP BY juz');
      final Map<int, int> tmpJuzFirst = {};
      for (final row in juzRows) {
        final int juzNum = (row['juz'] as num?)?.toInt() ?? 1;
        final int minPage = (row['minPage'] as num?)?.toInt() ?? 1;
        tmpJuzFirst[juzNum] = minPage;
      }

      // 3. Fetch Hizb - OPTIMIZED (Very Fast!)
      final hizbRows = await db.rawQuery(
          'SELECT juz, hezb, MIN(sura_num) as sura_num, MIN(aya_num) as aya_num, MIN(page_aya) as page_aya FROM quran GROUP BY juz, hezb ORDER BY juz, hezb');

      final Map<int, List<Map<String, dynamic>>> tmpJuzHizb = {};
      for (final row in hizbRows) {
        final int juzNum = (row['juz'] as num?)?.toInt() ?? 1;
        final int hizbNum = (row['hezb'] as num?)?.toInt() ?? 1;
        final int surahNum = (row['sura_num'] as num?)?.toInt() ?? 0;
        final int ayaNum = (row['aya_num'] as num?)?.toInt() ?? 1;
        final int pageNum = (row['page_aya'] as num?)?.toInt() ?? 1;
        final surahName = surahNum > 0
            ? DatabaseHelper.surahNamesArabicList[surahNum - 1]
            : '';

        tmpJuzHizb.putIfAbsent(juzNum, () => []).add({
          'hizb': hizbNum,
          'surahName': surahName,
          'surahNum': surahNum,
          'ayahNum': ayaNum,
          'page': pageNum,
        });
      }

      // 4. Fetch Page Headers - OPTIMIZED (Very Fast!)
      final headerRows = await db.rawQuery(
          'SELECT page_aya, MIN(sura_num) as sura_num, MIN(juz) as juz FROM quran GROUP BY page_aya');
      final Map<int, Map<String, dynamic>> tmpPageHeaders = {};
      for (final row in headerRows) {
        final pageNum = (row['page_aya'] as num?)?.toInt() ?? 1;
        final surahNum = (row['sura_num'] as num?)?.toInt() ?? 1;
        final juzNum = (row['juz'] as num?)?.toInt() ?? 1;
        final surahName = surahNum > 0
            ? DatabaseHelper.surahNamesArabicList[surahNum - 1]
            : '';
        tmpPageHeaders[pageNum] = {'surahName': surahName, 'juz': juzNum};
      }

      final prefs = await SharedPreferences.getInstance();
      int lastPage = widget.initialPage ?? prefs.getInt(_prefPageKey) ?? 1;
      if (lastPage < 1 || lastPage > 604) lastPage = 1;
      final int initialIndex = lastPage - 1;

      final bookmarkedPage = prefs.getInt(_bookmarkPageKey);
      final bookmarkedSurah = prefs.getInt(_bookmarkSurahKey);
      final bookmarkedAyah = prefs.getInt(_bookmarkAyahKey);

      _pageController = PageController(initialPage: initialIndex);

      if (mounted) {
        setState(() {
          _pageHeaders = tmpPageHeaders;
          _surahList = tmpSurahs;
          _surahFirstPage.addAll(tmpSurahFirst);
          _juzFirstPage.addAll(tmpJuzFirst);
          _juzHizbData = tmpJuzHizb;
          _currentPageIndex = initialIndex;
          _bookmarkedPage = bookmarkedPage;
          _bookmarkedSurah = bookmarkedSurah;
          _bookmarkedAyah = bookmarkedAyah;
          _isLoading = false;
        });
      }
    } catch (e, st) {
      debugPrint('Error loading Quran: $e\n$st');
      _pageController ??= PageController(initialPage: 0);
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

  // ── Ayah Interactive Actions ──────────────────────────────────────────────

  void _onVerseSelected(int surahNumber, int ayahNumber, int pageNum) {
    if (QuranAudioController.instance.isActive) {
      QuranAudioController.instance.stopAndDismiss();
    }

    final verseData = {
      'surahName': DatabaseHelper.surahNamesArabicList[surahNumber - 1],
      'text': '', // Lazy loaded asynchronously in bottom sheet
      'page': pageNum,
      'surahNumber': surahNumber,
      'ayahNumber': ayahNumber,
    };

    setState(() {
      _selectedVerseData = verseData;
    });
    QuranScreen.selectedVerseNotifier.value = verseData;
  }

  void _startAudioForSelectedVerse() {
    if (_selectedVerseData == null) return;

    final surahNumber = _selectedVerseData!['surahNumber'] as int;
    final ayahNumber = _selectedVerseData!['ayahNumber'] as int;

    QuranAudioController.instance.startPlayback(
      surah: surahNumber,
      ayah: ayahNumber,
      surahList: _surahList,
      totalVerses: 6236,
      getVerseData: (s, a) {
        return {
          'surahName': DatabaseHelper.surahNamesArabicList[s - 1],
          'text': '',
        };
      },
      onAyahChanged: (s, a) async {
        final page = await DatabaseHelper.instance.getPageForAyah(s, a);
        if (_currentPageIndex + 1 != page) {
          _jumpToPage(page);
        }

        final newVerseData = {
          'surahName': DatabaseHelper.surahNamesArabicList[s - 1],
          'text': '',
          'page': page,
          'surahNumber': s,
          'ayahNumber': a,
        };

        if (mounted) {
          setState(() {
            _selectedVerseData = newVerseData;
          });
        }
      },
    );
  }

  Future<void> _downloadPageAudio(int pageNumber, QuranReciter reciter) async {
    // Reconstruct verses list for the page via SQLite dynamically for audio downloading
    final db = await DatabaseHelper.instance.database;
    final rows = await db.rawQuery(
        'SELECT sura_num, aya_num FROM quran WHERE page_aya = ? ORDER BY id_quran_ayat',
        [pageNumber]);
    final versesOnPage = rows
        .map((r) => {'surahNumber': r['sura_num'], 'ayahNumber': r['aya_num']})
        .toList();

    final ctrl = QuranAudioController.instance;
    ctrl.selectedReciter = reciter;
    ctrl.hasUserSelectedReciter = true;
    await ctrl.downloadPage(pageNumber, versesOnPage);
  }

  Future<void> _loadBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _bookmarkedPage = prefs.getInt(_bookmarkPageKey);
        _bookmarkedSurah = prefs.getInt(_bookmarkSurahKey);
        _bookmarkedAyah = prefs.getInt(_bookmarkAyahKey);
      });
    }
  }

  void _goToBookmark() {
    if (_bookmarkedPage != null) {
      _jumpToPage(_bookmarkedPage!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('لا توجد علامة محفوظة',
              style: TextStyle(fontFamily: 'Amiri')),
          backgroundColor: _borderColor,
        ),
      );
    }
  }

  void _showSleepTimerDialog() {
    final customTimeCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final themeVal = AppTheme.notifier.value;
        final txtColor = AppTheme.getMainTextColor(themeVal);
        final bg = AppTheme.getCardBgColor(themeVal);
        final primary = AppTheme.getPrimaryColor(themeVal);
        final l10n = AppLocalizations.of(context)!;

        void startTimer(int mins) {
          Navigator.pop(context);
          _sleepTimer?.cancel();
          _sleepTimer = Timer(Duration(minutes: mins), () {
            if (QuranAudioController.instance.isActive) {
              QuranAudioController.instance.pause();
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.stopAudioAfter} $mins ${l10n.minutesLabel}',
                  style: const TextStyle(fontFamily: 'Amiri', fontSize: 16),
                  textAlign: TextAlign.center),
              backgroundColor: primary,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.nights_stay_rounded,
                    size: 42, color: primary.withValues(alpha: 0.8)),
                const SizedBox(height: 12),
                Text(l10n.sleepTimer,
                    style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: txtColor)),
                const SizedBox(height: 4),
                Text(l10n.stopAudioAfter,
                    style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 16,
                        color: txtColor.withValues(alpha: 0.6))),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [15, 30, 45, 60]
                      .map((mins) => Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => startTimer(mins),
                              borderRadius: BorderRadius.circular(16),
                              child: Ink(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: primary.withValues(alpha: 0.1),
                                  border: Border.all(
                                      color: primary.withValues(alpha: 0.3),
                                      width: 1.5),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '$mins\n${l10n.minutesLabel}',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: primary,
                                      height: 1.2),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: txtColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: txtColor.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: customTimeCtrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: txtColor,
                              fontFamily: 'Inter',
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: l10n.customMinHint,
                            hintStyle: TextStyle(
                                color: txtColor.withValues(alpha: 0.4),
                                fontFamily: 'Amiri',
                                fontSize: 16,
                                fontWeight: FontWeight.normal),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      Container(
                          width: 1,
                          height: 24,
                          color: txtColor.withValues(alpha: 0.2)),
                      TextButton(
                        onPressed: () {
                          final mins = int.tryParse(customTimeCtrl.text);
                          if (mins != null && mins > 0) startTimer(mins);
                        },
                        child: Text(l10n.start,
                            style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: primary)),
                      )
                    ],
                  ),
                ),
                if (_sleepTimer != null && _sleepTimer!.isActive) ...[
                  const SizedBox(height: 24),
                  TextButton.icon(
                    onPressed: () {
                      _sleepTimer?.cancel();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.timerCanceled,
                              style: const TextStyle(
                                  fontFamily: 'Amiri', fontSize: 16),
                              textAlign: TextAlign.center),
                          backgroundColor: txtColor.withValues(alpha: 0.8),
                          behavior: SnackBarBehavior.floating,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.timer_off_outlined,
                        color: Colors.redAccent),
                    label: Text(l10n.cancelCurrentTimer,
                        style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16,
                            color: Colors.redAccent)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                    ),
                  )
                ]
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Text formatting ───────────────────────────────────────────────────────

  String _getCurrentSurahName() {
    final pageNum = _currentPageIndex + 1;
    final header = _pageHeaders[pageNum] ?? {};
    if (header.containsKey('surahName') && header['surahName'] != '') {
      return 'سورة ${header['surahName']}';
    }
    return 'المصحف الشريف';
  }

  String _toArabicNumerals(int number) {
    const Map<String, String> digits = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
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
        juzHizbData: _juzHizbData,
        currentPage: _currentPageIndex + 1,
        pageBgColor: _pageBgColor,
        borderColor: _borderColor,
        goldTextColor: _goldTextColor,
        mainTextColor: _mainTextColor,
        onJumpToPage: (p) {
          Navigator.pop(ctx);
          _jumpToPage(p);
        },
        onJumpToAyah: (surahNum, ayahNum) async {
          Navigator.pop(ctx);
          final page =
              await DatabaseHelper.instance.getPageForAyah(surahNum, ayahNum);
          _jumpToPage(page);
        },
      ),
    );
  }

  void _openQuranWordSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QuranWordSearchModal(
        theme: _selectedTheme,
        pageBgColor: _pageBgColor,
        borderColor: _borderColor,
        goldTextColor: _goldTextColor,
        mainTextColor: _mainTextColor,
        onJumpToAyah: (surahNum, ayahNum, pageNum) {
          _jumpToPage(pageNum);
          _onVerseSelected(surahNum, ayahNum, pageNum);
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
            title: GestureDetector(
              onTap: _openNavigationPanel,
              behavior: HitTestBehavior.opaque,
              child: Text(
                _getCurrentSurahName(),
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getAppBarTextColor(theme),
                ),
              ),
            ),
            centerTitle: true,
            backgroundColor: AppTheme.getAppBarBgColor(theme),
            foregroundColor: AppTheme.getAppBarTextColor(theme),
            elevation: 1,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: _openQuranWordSearch,
                tooltip: 'بحث',
              ),
              IconButton(
                icon: const Icon(Icons.format_list_bulleted),
                onPressed: _openNavigationPanel,
                tooltip: 'الفهرس',
              ),
            ],
          ),
          body: _isLoading
              ? Center(child: CircularProgressIndicator(color: _borderColor))
              : ListenableBuilder(
                  listenable: QuranAudioController.instance,
                  builder: (context, _) {
                    final hasOverlay = QuranAudioController.instance.isActive ||
                        _selectedVerseData != null;

                    return Stack(
                      children: [
                        QuranPageContentWrapper(
                          hasOverlay: hasOverlay,
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: PageView.builder(
                              controller: _pageController,
                              itemCount: 604,
                              physics: const BouncingScrollPhysics(),
                              reverse: true,
                              onPageChanged: _onPageChanged,
                              itemBuilder: (context, index) {
                                final pageNum = index + 1;
                                final header = _pageHeaders[pageNum] ?? {};
                                final surahName =
                                    header['surahName'] as String? ?? "";
                                final juzNumber = _toArabicNumerals(
                                    header['juz'] as int? ?? 1);

                                return Center(
                                  child: AspectRatio(
                                    aspectRatio: 0.58, // TALL RECTANGLE
                                    child: FittedBox(
                                      fit: BoxFit.contain,
                                      child: Container(
                                        width: 500,
                                        height: 860, // Taller height
                                        color: _screenBgColor,
                                        child: Stack(
                                          children: [
                                            // 1. The Border that hugs everything
                                            Positioned.fill(
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 20),
                                                decoration: BoxDecoration(
                                                  color: _pageBgColor,
                                                  border: Border.all(
                                                      color: _borderColor,
                                                      width: 2.0),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Column(
                                                  children: [
                                                    const SizedBox(height: 15),
                                                    // Surah and Juz Headers with container badges
                                                    Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 20),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          GestureDetector(
                                                            onTap:
                                                                _openNavigationPanel,
                                                            behavior:
                                                                HitTestBehavior
                                                                    .opaque,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10.0,
                                                                      vertical:
                                                                          2.0),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color:
                                                                    _screenBgColor,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            6),
                                                                border: Border.all(
                                                                    color: _goldTextColor
                                                                        .withValues(
                                                                            alpha:
                                                                                0.5),
                                                                    width: 1.2),
                                                              ),
                                                              child: Text(
                                                                'سُورَةُ $surahName',
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      'Amiri',
                                                                  fontSize: 13,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      _mainTextColor,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          GestureDetector(
                                                            onTap:
                                                                _openNavigationPanel,
                                                            behavior:
                                                                HitTestBehavior
                                                                    .opaque,
                                                            child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .symmetric(
                                                                      horizontal:
                                                                          10.0,
                                                                      vertical:
                                                                          2.0),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color:
                                                                    _screenBgColor,
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            6),
                                                                border: Border.all(
                                                                    color: _goldTextColor
                                                                        .withValues(
                                                                            alpha:
                                                                                0.5),
                                                                    width: 1.2),
                                                              ),
                                                              child: Text(
                                                                'الجُزْءُ $juzNumber',
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      'Amiri',
                                                                  fontSize: 13,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  color:
                                                                      _mainTextColor,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),

                                                    // Reminder ONLY on Pages 1 & 2 (Inside the border, above Surah Header graphic)
                                                    if (pageNum == 1 ||
                                                        pageNum == 2)
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 20,
                                                                vertical: 5),
                                                        child:
                                                            QuranReminderWidget(
                                                          pageNum: pageNum,
                                                          languageCode: Localizations
                                                                      .maybeLocaleOf(
                                                                          context)
                                                                  ?.languageCode ??
                                                              'ar',
                                                          textColor:
                                                              _mainTextColor,
                                                          reminderIndex:
                                                              _reminderIndex,
                                                          forceArabic:
                                                              _reminderForceArabic,
                                                        ),
                                                      ),

                                                    // The Quran Text (Expands to push page number to bottom)
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 10),
                                                        child: Directionality(
                                                          textDirection:
                                                              TextDirection.rtl,
                                                          child:
                                                              ListenableBuilder(
                                                            listenable:
                                                                QuranAudioController
                                                                    .instance,
                                                            builder:
                                                                (context, _) {
                                                              final ctrl =
                                                                  QuranAudioController
                                                                      .instance;
                                                              return StrictQcfPage(
                                                                pageNumber:
                                                                    pageNum,
                                                                theme: _qcfTheme.copyWith(
                                                                    pageBackgroundColor:
                                                                        Colors
                                                                            .transparent),
                                                                onTap: (s, a) =>
                                                                    _onVerseSelected(
                                                                        s,
                                                                        a,
                                                                        pageNum),
                                                                highlightedSurah:
                                                                    ctrl.isActive
                                                                        ? ctrl
                                                                            .currentSurah
                                                                        : null,
                                                                highlightedAyah:
                                                                    ctrl.isActive
                                                                        ? ctrl
                                                                            .currentAyah
                                                                        : null,
                                                                activeWordIndex:
                                                                    ctrl.isActive
                                                                        ? ctrl
                                                                            .activeWordPosition
                                                                        : null,
                                                                bookmarkedSurah:
                                                                    _bookmarkedSurah,
                                                                bookmarkedAyah:
                                                                    _bookmarkedAyah,
                                                              );
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                    // Page Number with container badge
                                                    Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              bottom: 10),
                                                      child: GestureDetector(
                                                        onTap:
                                                            _openNavigationPanel,
                                                        behavior:
                                                            HitTestBehavior
                                                                .opaque,
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      10.0,
                                                                  vertical:
                                                                      2.0),
                                                          decoration:
                                                              BoxDecoration(
                                                            color:
                                                                _screenBgColor,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        6),
                                                            border: Border.all(
                                                                color: _goldTextColor
                                                                    .withValues(
                                                                        alpha:
                                                                            0.5),
                                                                width: 1.2),
                                                          ),
                                                          child: Text(
                                                            _toArabicNumerals(
                                                                pageNum),
                                                            style: TextStyle(
                                                              fontFamily:
                                                                  'Amiri',
                                                              fontSize: 20,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  _mainTextColor,
                                                            ),
                                                          ),
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
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 14.0,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: ListenableBuilder(
                              listenable: QuranAudioController.instance,
                              builder: (context, _) {
                                if (QuranAudioController.instance.isActive) {
                                  return QuranMiniPlayerBar(
                                      onTimerTap: _showSleepTimerDialog);
                                }
                                if (_selectedVerseData != null) {
                                  final selSurah =
                                      _selectedVerseData!['surahNumber']
                                              as int? ??
                                          1;
                                  final selAyah =
                                      _selectedVerseData!['ayahNumber']
                                              as int? ??
                                          1;
                                  final isVerseBookmarked =
                                      _bookmarkedSurah == selSurah &&
                                          _bookmarkedAyah == selAyah;

                                  return AyahActionBar(
                                    verseData: _selectedVerseData!,
                                    onListen: _startAudioForSelectedVerse,
                                    onClose: () {
                                      setState(() {
                                        _selectedVerseData = null;
                                      });
                                      QuranScreen.selectedVerseNotifier.value =
                                          null;
                                    },
                                    isBookmarked: isVerseBookmarked,
                                    onBookmarkChanged: _loadBookmark,
                                    onGoToBookmark: _goToBookmark,
                                    onChangeTheme: _showThemeSelector,
                                    onOpenIndex: _openNavigationPanel,
                                    onOpenSearch: _openQuranWordSearch,
                                    onDownloadPage: _downloadPageAudio,
                                    onIsPageDownloaded: (pageNum) async {
                                      final db = await DatabaseHelper
                                          .instance.database;
                                      final rows = await db.rawQuery(
                                          'SELECT sura_num, aya_num FROM quran WHERE page_aya = ?',
                                          [pageNum]);
                                      if (rows.isEmpty) return false;
                                      for (final v in rows) {
                                        final s = v['sura_num'] as int? ?? 1;
                                        final a = v['aya_num'] as int? ?? 1;
                                        if (await QuranAudioController.instance
                                            .hasOfflineAudio(s, a)) {
                                          return true;
                                        }
                                      }
                                      return false;
                                    },
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                      ],
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
            color:
                isSelected ? borderColor : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: borderColor.withValues(alpha: 0.3), blurRadius: 6)
                ]
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
    required this.juzHizbData,
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
  final Map<int, List<Map<String, dynamic>>> juzHizbData;
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
              Tab(text: 'الأجزاء والأحزاب'),
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
                _JuzHizbTab(
                  juzHizbData: widget.juzHizbData,
                  pageBgColor: widget.pageBgColor,
                  borderColor: widget.borderColor,
                  goldTextColor: widget.goldTextColor,
                  mainTextColor: widget.mainTextColor,
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
                    style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 16,
                        color: widget.mainTextColor),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TextField(
                      controller: ayahCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.mainTextColor),
                      decoration: InputDecoration(
                        hintText: 'الآية...',
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: widget.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                              color: widget.goldTextColor, width: 1.8),
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
                child:
                    const Text('إلغاء', style: TextStyle(color: Colors.grey)),
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
              fillColor: widget.borderColor.withValues(alpha: 0.07),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
              color: widget.borderColor.withValues(alpha: 0.3),
            ),
            itemBuilder: (context, i) {
              final surah = _filtered[i];
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                leading: Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: widget.borderColor.withValues(alpha: 0.15),
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

// ── Tab 2: Juz / Hizb Hierarchical Index ──────────────────────────────────────────

class _JuzHizbTab extends StatefulWidget {
  const _JuzHizbTab({
    required this.juzHizbData,
    required this.pageBgColor,
    required this.borderColor,
    required this.goldTextColor,
    required this.mainTextColor,
    required this.onJumpToPage,
  });

  final Map<int, List<Map<String, dynamic>>> juzHizbData;
  final Color pageBgColor;
  final Color borderColor;
  final Color goldTextColor;
  final Color mainTextColor;
  final void Function(int page) onJumpToPage;

  @override
  State<_JuzHizbTab> createState() => _JuzHizbTabState();
}

class _JuzHizbTabState extends State<_JuzHizbTab> {
  /// Tracks which Juz sections are expanded (first Juz expanded by default)
  late final Set<int> _expandedJuz;

  static const List<String> _juzNames = [
    'الجزء الأول',
    'الجزء الثاني',
    'الجزء الثالث',
    'الجزء الرابع',
    'الجزء الخامس',
    'الجزء السادس',
    'الجزء السابع',
    'الجزء الثامن',
    'الجزء التاسع',
    'الجزء العاشر',
    'الجزء الحادي عشر',
    'الجزء الثاني عشر',
    'الجزء الثالث عشر',
    'الجزء الرابع عشر',
    'الجزء الخامس عشر',
    'الجزء السادس عشر',
    'الجزء السابع عشر',
    'الجزء الثامن عشر',
    'الجزء التاسع عشر',
    'الجزء العشرون',
    'الجزء الحادي والعشرون',
    'الجزء الثاني والعشرون',
    'الجزء الثالث والعشرون',
    'الجزء الرابع والعشرون',
    'الجزء الخامس والعشرون',
    'الجزء السادس والعشرون',
    'الجزء السابع والعشرون',
    'الجزء الثامن والعشرون',
    'الجزء التاسع والعشرون',
    'الجزء الثلاثون',
  ];

  @override
  void initState() {
    super.initState();
    _expandedJuz = {1}; // First juz expanded by default
  }

  String _toArabicNumerals(int number) {
    const Map<String, String> digits = {
      '0': '٠',
      '1': '١',
      '2': '٢',
      '3': '٣',
      '4': '٤',
      '5': '٥',
      '6': '٦',
      '7': '٧',
      '8': '٨',
      '9': '٩',
    };
    return number.toString().split('').map((c) => digits[c] ?? c).join('');
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 30,
      itemBuilder: (context, index) {
        final juzNum = index + 1;
        final hizbs = widget.juzHizbData[juzNum] ?? [];
        final isExpanded = _expandedJuz.contains(juzNum);
        final firstPage =
            hizbs.isNotEmpty ? (hizbs.first['page'] as int? ?? 1) : 1;

        return Column(
          children: [
            // ── Juz Header ──
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedJuz.remove(juzNum);
                  } else {
                    _expandedJuz.add(juzNum);
                  }
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: widget.borderColor.withValues(alpha: 0.08),
                  border: Border(
                    bottom: BorderSide(
                      color: widget.borderColor.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    // Juz number badge
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: widget.borderColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: widget.borderColor, width: 1.2),
                      ),
                      child: Text(
                        _toArabicNumerals(juzNum),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: widget.goldTextColor,
                          fontFamily: 'Amiri',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Juz name
                    Expanded(
                      child: Text(
                        _juzNames[index],
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.mainTextColor,
                        ),
                      ),
                    ),
                    // Page info
                    Text(
                      'ص ${_toArabicNumerals(firstPage)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.goldTextColor.withValues(alpha: 0.7),
                        fontFamily: 'Amiri',
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Expand/collapse icon
                    AnimatedRotation(
                      turns: isExpanded ? 0.25 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.chevron_left,
                        size: 20,
                        color: widget.borderColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Hizb Items (collapsed/expanded) ──
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: hizbs.map((hizb) {
                  final int hizbNum = (hizb['hizb'] as int?) ?? 1;
                  final String sName = (hizb['surahName'] as String?) ?? '';
                  final int ayahNum = (hizb['ayahNum'] as int?) ?? 1;
                  final int page = (hizb['page'] as int?) ?? 1;

                  return InkWell(
                    onTap: () => widget.onJumpToPage(page),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: widget.pageBgColor,
                        border: Border(
                          bottom: BorderSide(
                            color: widget.borderColor.withValues(alpha: 0.12),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          // Hizb connector icon
                          SizedBox(
                            width: 36,
                            child: Icon(
                              Icons.circle,
                              size: 8,
                              color: widget.borderColor.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Hizb info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'الحزب ${_toArabicNumerals(hizbNum)}',
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: widget.goldTextColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'سورة $sName · الآية ${_toArabicNumerals(ayahNum)}',
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 13,
                                    color: widget.mainTextColor
                                        .withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Page number
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.borderColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'ص ${_toArabicNumerals(page)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: widget.goldTextColor,
                                fontFamily: 'Amiri',
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 12,
                            color: widget.borderColor.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
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
                    prefixIcon:
                        Icon(Icons.find_in_page, color: widget.borderColor),
                    filled: true,
                    fillColor: widget.borderColor.withValues(alpha: 0.07),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onPressed: _submitPage,
                child: const Text(
                  'انتقل',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontFamily: 'Amiri'),
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
                    color: isCurrent
                        ? widget.borderColor
                        : widget.borderColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isCurrent
                          ? widget.goldTextColor
                          : widget.borderColor.withValues(alpha: 0.4),
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
          color: borderColor.withValues(alpha: 0.15),
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
    'ar':
        '⚠️ {أَلَمْ يَأْنِ لِلَّذِينَ آمَنُوا أَن تَخْشَعَ قُلُوبُهُمْ لِذِكْرِ اللَّهِ وَمَا نَزَلَ مِنَ الْحَقِّ}.. اقرأ بقلبٍ حاضر.',
    'en':
        '⚠️ {Has the time not come for those who have believed that their hearts should submit to the remembrance of Allah and what has come down of the truth...} Read with an attentive heart.',
    'am':
        '⚠️ {ካመኑት ወገኖች ልቦቻቸው ለአላህ ውሳኔና ከእውነት ለወረደው (ለቁርኣን) ሊሰበሩና ሊያጎነብሱ ጊዜው አልደረሰምን?}.. በልብህ ተገኝተህ አንብብ።',
    'om':
        '⚠️ {Yeroon warra amananiif qalbiiwwan isaanii zikrii Allaahifi dhugaa bu’eef akka laaftu hin geennee?...} Qalbii dammaqiinsaan dubbisi.',
  },
  {
    'ar':
        '🚨 سيأتي زمانٌ يُسرى على كتاب الله في ليلة فلا يبقى في الأرض منه آية، وتُغلق التوبة.. ماذا أنت فاعلٌ بمصحفك اليوم؟',
    'en':
        '🚨 A time will come when the Book of Allah will be taken away in a single night, leaving not a single verse on Earth, and repentance will be closed... What are you doing with your Mus-haf today?',
    'am':
        '🚨 የአላህ መጽሐፍ (ቁርኣን) በአንድ ሌሊት የሚነጠቅበትና በምድር ላይ አንዲትም አንቀጽ የማይቀርበት، ተውበትም የሚዘጋበት ጊዜ ይመጣል። ዛሬ ከቁርኣንህ ጋር ምን እያደረግክ ነው?',
    'om':
        "🚨 Yeroon Kitaabni Allaah halkan tokkotti ol fudhamuufi dachii irratti aayanni tokkollee hin hafne, tawbaanis cufamu ni dhufa... Har'a immoo ati qur'aana keetiin maal gochaa jirtaa?",
  },
  {
    'ar':
        '⏱️ فرصتك الآن بين يديك! اقرأ وتدبر بقلبك قبل أن يُرفع القرآن من الصدور والسطور.',
    'en':
        '⏱️ Your opportunity is now in your hands! Read and contemplate with your heart before the Qur\'an is lifted from hearts and pages.',
    'am': '⏱️ ዕድሉ አሁን በእጅህ ነው! ቁርኣን ከልቦችና ከገጾች ከመነሳቱ በፊት በልብህ አንብብና አሰላስል።',
    'om':
        "⏱️ Carraan kee amma harka kee jira! Qur'aanni onneefi barruu keessaa osoo hin fudaatamin dura qalbii keetiin dubbisi, xiinxali.",
  },
  {
    'ar':
        '📖 قال النبي ﷺ: «اقرؤوا القرآن فإنه يأتي يوم القيامة شفيعاً لأصحابه».. فضمن شفاعته الآن.',
    'en':
        '📖 The Prophet ﷺ said: "Read the Qur\'an, for it will come on the Day of Resurrection as an intercessor for its companions." Secure its intercession now.',
    'am': '📖 ቁርኣንን አንብቡ፤ በትንሣኤ ቀን ለባልደረቦቹ አማላጅ ሆኖ ይመጣልና።',
    'om':
        '📖 Nabiyyiin ﷺ jedhan: "Qur’aana dubbisaa, inni Guyyaa Qiyamaa saahiboota isaatiif shafaa’aa (mangaastuu) ta’ee ni dhufaa." Ammuma shafaa’ummaa isaa mirkaneeffadhu.',
  },
  {
    'ar':
        '💎 قال النبي ﷺ: «الماهر بالقرآن مع السفرة الكرام البررة».. جاهد لتكون معهم.',
    'en':
        '💎 The Prophet ﷺ said: "The one who is proficient in the Qur\'an will be with the noble and obedient scribes (angels)." Strive to be with them.',
    'am':
        '💎 ነቢዩ ﷺ እንዲህ ብለዋል፡- «በቁرኣን ጎበز የሆነው ከተከበሩትና ታዛዦች መላእክት ጋር ነው።» ከእነሱ ጋር ለመሆን ታገል።',
    'om':
        '💎 Nabiyyiin ﷺ jedhan: "Inni qur’aana ogummaan dubbisu malaykoota kabajamoo fi qajeeloo waliin ta\'a." Isaaniin waliin ta\'uuf qabsaa\'i.',
  },
  {
    'ar':
        '🔥 قال النبي ﷺ: «يؤتى بالقرآن يوم القيامة تقدمه سورة البقرة وآل عمران تحاجان عن صاحبهما».. لا تترك صاحبيك اليوم.',
    'en':
        '🔥 The Prophet ﷺ said: "The Qur\'an will be brought on the Day of Resurrection, preceded by Surah Al-Baqarah and Al-Imran, arguing on behalf of their companion." Do not abandon your two companions today.',
    'am':
        '🔥 ነቢዩ ﷺ እንዲህ ብለዋል፡- «ቁርኣን በትንሳኤ ቀን ይመጣል؛ ሱረቱ አል-በቀራህና אሊ-ዒምራን እየመሩት ለባለቤታቸው ይሟገتاሉ።» ዛሬ ሁለቱን ጓደኞችህን አትተዋቸው።',
    'om':
        '🔥 Nabiyyiin ﷺ jedhan: "Qur’aanni Guyyaa Qiyamaa ni fidama, Suuraa Al-Baqaraafi Al-Imraan dursanii dhufeen saahiba isaaniitiif falmu." Har\'a saahiboota kee lamaan kana hin dhiisin.',
  },
  {
    'ar':
        '⚖️ قال النبي ﷺ: «القرآن حجة لك أو عليك».. فتأمل في آياتك؛ هل تقودك إلى الجنة أم تشهد عليك؟',
    'en':
        '⚖️ The Prophet ﷺ said: "The Qur\'an is a proof for you or against you." So reflect upon your verses; are they leading you to Paradise or testifying against you?',
    'am':
        '⚖️ ነቢዩ ﷺ እንዲህ ብለዋል፡- «ቁርኣን ለአንተ ወይም በአንተ ላይ ምስክር ነው።» ስለዚህ አንቀጾችህን አሰላስል፤ ወደ ጀነት እየመሩህ ነው ወይስ በአንተ ላይ እየመሰከሩብህ؟',
    'om':
        '⚖️ Nabiyyiin ﷺ jedhan: "Qur’aanni siif ragaa ykn sitti ragaa dha." Sila aayatoota kee xiinxali; gara Jannataa si geessaa jiran moo sitti ragaa bahaa jiru?',
  },
  {
    'ar':
        '⚡ قال عمر بن الخطاب: «إن الله يرفع بهذا الكتاب أقواماً ويضع به آخرين».. فكن ممن رفعه الله بالقرآن.',
    'en':
        '⚡ Umar ibn al-Khattab said: "Indeed, Allah raises nations by this Book and degrades others by it." So be among those whom Allah raises with the Qur\'an.',
    'am':
        '⚡ ዑመር ቢን አል-ኸጧብ እንዲህ ብለዋል፡- «አላህ በዚህ መጽሐፍ ህዝቦችን ከፍ ያደርጋል، ሌሎችንም ዝቅ ያደርጋል።» አላህ በቁርኣን ከፍ ካደረጋቸው መካከል ሁን።',
    'om':
        '⚡ Umar bin Al-Khattaab jedhan: "Dhugumatti Allaah kitaaba kanaan uummata tokko ol kaasa, kaan immoo gadi qaba." Warra Allaah Qur\'aanaan ol kaase keessaa tokko ta\'i.',
  },

  // المجموعة 2: أبيات شعرية (مستثناة من الترجمة الإنجليزية والأمهرية والأورومية)
  {
    'ar':
        '«يا ليت شعري كيف حالي في غدٍ.. وبأيِّ وجهٍ ألتَقِي رَبِّي غَدَا\nأمَّا إلى جَنَّاتِ خُلْدٍ عَالِيَةْ.. أوْ هَاوِيَةْ تَصْلَى جَحِيمًا جَامِدَا!»\nاقرأ لِتَنْجُو.',
    'en':
        '«يا ليت شعري كيف حالي في غدٍ.. وبأيِّ وجهٍ ألتَقِي رَبِّي غَدَا\nأمَّا إلى جَنَّاتِ خُلْدٍ عَالِيَةْ.. أوْ هَاوِيَةْ تَصْلَى جَحِيمًا جَامِدَا!»\nاقرأ لِتَنْجُو.',
    'am':
        '«يا ليت شعري كيف حالي في غدٍ.. وبأيِّ وجهٍ ألتَقِي رَبِّي غَدَا\nأمَّا إلى جَنَّاتِ خُلْدٍ عَالِيَةْ.. أوْ هَاوِيَةْ تَصْلَى جَحِيمًا جَامِدَا!»\nاقرأ لِتَنْجُو.',
    'om':
        '«يا ليت شعري كيف حالي في غدٍ.. وبأيِّ وجهٍ ألتَقِي رَبِّي غَدَا\nأمَّا إلى جَنَّاتِ خُلْدٍ عَالِيَةْ.. أوْ هَاوِيَةْ تَصْلَى جَحِيمًا جَامِدَا!»\nاقرأ لِتَنْجُو.',
  },
  {
    'ar':
        '«وإذا خلوت بريبة في ظلمة.. والنفس داعية إلى الطغيان\nفاستحي من نظر الإله وقل لها.. إن الذي خلق الظلام يراني»\nطهّر قلبك بالقرآن.',
    'en':
        '«وإذا خلوت بريبة في ظلمة.. والنفس داعية إلى الطغيان\nفاستحي من نظر الإله وقل لها.. إن الذي خلق الظلام يراني»\nطهّر قلبك بالقرآن.',
    'am':
        '«وإذا خلوت بريبة في ظلمة.. والنفس داعية إلى الطغيان\nفاستحي من نظر الإله وقل لها.. إن الذي خلق الظلام يراني»\nطهّر قلبك بالقرآن.',
    'om':
        '«وإذا خلوت بريبة في ظلمة.. والنفس داعية إلى الطغيان\nفاستحي من نظر الإله وقل لها.. إن الذي خلق الظلام يراني»\nطهّر قلبك بالقرآن.',
  },
  {
    'ar':
        '«تنسى الموت وتلهو بالحياة.. وكأنك مخلدٌ فيها لا محالة\nوالقبر يناديك كل ليلة.. أنا بيت الغربة والظلمة والوحدة».. تدبر كلام ربك.',
    'en':
        '«تنسى الموت وتلهو بالحياة.. وكأنك مخلدٌ فيها لا محالة\nوالقبر يناديك كل ليلة.. أنا بيت الغربة والظلمة والوحدة».. تدبر كلام ربك.',
    'am':
        '«تنسى الموت وتلهو بالحياة.. وكأنك مخلدٌ فيها لا محالة\nوالقبر يناديك كل ليلة.. أنا بيت الغربة والظلمة والوحدة».. تدبر كلام ربك.',
    'om':
        '«تنسى الموت وتلهو بالحياة.. وكأنك مخلدٌ فيها لا محالة\nوالقبر يناديك كل ليلة.. أنا بيت الغربة والظلمة والوحدة».. تدبر كلام ربك.',
  },
  {
    'ar':
        '«أتنبت بالذنوب وأنت فانٍ.. وتنسى موقف العرض العظيم؟\nوتعرض عن كتاب الله لاهٍ.. كأنك قد ضمنت لظى الجحيم!»\nاستفق واقرأ بوجل.',
    'en':
        '«أتنبت بالذنوب وأنت فانٍ.. وتنسى موقف العرض العظيم؟\nوتعرض عن كتاب الله لاهٍ.. كأنك قد ضمنت لظى الجحيم!»\nاستفق واقرأ بوجل.',
    'am':
        '«أتنبت بالذنوب وأنت فانٍ.. وتنسى موقف العرض العظيم؟\nوتعرض عن كتاب الله لاهٍ.. كأنك قد ضمنت لظى الجحيم!»\nاستفق واقرأ بوجل.',
    'om':
        '«أتنبت بالذنوب وأنت فانٍ.. وتنسى موقف العرض العظيم؟\nوتعرض عن كتاب الله لاهٍ.. كأنك قد ضمنت لظى الجحيم!»\nاستفق واقرأ بوجل.',
  },
  {
    'ar':
        '«عمرك يمضي والأنفاس معدودة.. والمصحف يشكو الهجر في زاوية دارك\nفقم وتزود بآياتٍ تنير بها.. قبراً غداً ستحل فيه ضيفاً بجوارك».',
    'en':
        '«عمرك يمضي والأنفاس معدودة.. والمصحف يشكو الهجر في زاوية دارك\nفقم وتزود بآياتٍ تنير بها.. قبراً غداً ستحل فيه ضيفاً بجوارك».',
    'am':
        '«عمرك يمضي والأنفاس معدودة.. والمصحف يشكو الهجر في زاوية دارك\nفقم وتزود بآياتٍ تنير بها.. قبراً غداً ستحل فيه ضيفاً بجوارك».',
    'om':
        '«عمرك يمضي والأنفاس معدودة.. والمصحف يشكو الهجر في زاوية دارك\nفقم وتزود بآياتٍ تنير بها.. قبراً غداً ستحل فيه ضيفاً بجوارك».',
  },

  // المجموعة 3: أقوال الأئمة الأربعة وكبار السلف
  {
    'ar':
        'قال الإمام عثمان بن عفان رضي الله عنه: «لو طهرت قلوبكم ما شبعت من كلام ربكم.»',
    'en':
        'Imam Uthman ibn Affan (may Allah be pleased with him) said: "If your hearts were pure, they would never have enough of the speech of your Lord."',
    'am':
        'ኢማም ዑስማን ቢን ዓፋን (ረዲየላሁ ዐንሁ) እንዲህ ብለዋል፡- «ልቦቻችሁ ቢጠሩ ኖሮ ከጌታችሁ ንግግር ባልጠገቡ ነበር።»',
    'om':
        'Imaam Usmaan bin Affaan (R.A) jedhan: "Osoo onneen keessan qulqullooftee, jecha Rabbii keessanii hin quuftu turtte."',
  },
  {
    'ar': 'قال الإمام الشافعي رحمه الله: «من قرأ القرآن عظُمت قيمته.»',
    'en':
        'Imam Al-Shafi\'i (may Allah have mercy on him) said: "Whoever reads the Qur\'an, their value becomes magnificent."',
    'am': 'ኢማም አሽ-ሻፊዒይ (ረሂመሁላህ) እንዲህ ብለዋል፡- «ቁርኣንን ያነበበ ሰው እሴቱ ታላቅ ይሆናል።»',
    'om':
        'Imaam Al-Shaafi\'ii (R.H) jedhan: "Namni Qur’aana dubbise gatiin isaa guddata."',
  },
  {
    'ar':
        'قيل للإمام أحمد: بمَ يتقرب المتقربون إلى الله؟ قال: «بِكَلَامِهِ». قيل: بفهمٍ أو بغير فهم؟ قال: «بِفَهْمٍ وَبِغَيْرِ فَهْمٍ».',
    'en':
        'It was said to Imam Ahmad: "With what do those drawing close to Allah draw close?" He said: "With His Speech." It was asked: "With understanding or without understanding?" He said: "With understanding and without understanding."',
    'am':
        'ለኢማም አሕመድ ተባለ፡ «ወደ አلاህ ተቃራኒዎች በምን ይቃረባሉ?» እርሳቸውም «በቃሉ» አሉ። «በመረዳት ወይስ ያለመረዳት?» ተብለው ተጠየቁ። «በመረዳትም ያለመረዳትም» አሉ።',
    'om':
        'Imaam Ahmadaniin jedhame: "Warri gara Allaah dhiyaatan maaliin dhiyaatu?" Innis: "Jecha Isaatiin" jedhe. "Hubannoodhaan moo hubannoo malee?" jedhamee gaafatame. Innis: "Hubannoodhaanis hubannoo malees" jedhe.',
  },
  {
    'ar':
        'قال الإمام مالك رحمه الله: «ما من شيء من أعمال البر إلا وله حدٌّ ينتهي إليه، إلا ذكر الله وتلاوة كتابه.»',
    'en':
        'Imam Malik (may Allah have mercy on him) said: "There is no righteous deed except that it has a limit where it ends, except the remembrance of Allah and the recitation of His Book."',
    'am':
        'ኢማም ማሊክ (ረሂመሁላህ) እንዲህ ብለዋል፡- «ከመልካም ስራዎች ሁሉ የሚቆምበት ወሰን የሌለው የለም، አላህን ማውሳትና መጽሐፉን ማንበብ ሲቀር።»',
    'om':
        'Imaam Maalik (R.H) jedhan: "Hojiiwwan gaarii keessaa waan daangaa qabu malee hin jiru, zikrii Allaah fi Kitaaba Isaa dubbisuu malee."',
  },
  {
    'ar':
        'قال الإمام عبد الله بن مسعود رضي الله عنه: «إن هذا القرآن مأدبة الله, فخذوا من مأدبته ما استطعتم.»',
    'en':
        'Imam Abdullah ibn Mas\'ud (may Allah be pleased with him) said: "Indeed, this Qur\'an is the banquet of Allah, so take from His banquet as much as you can."',
    'am':
        'ኢማም ዓብደላህ ቢን መስዑድ (ረዲየላሁ ዐንሁ) እንዲህ ብለዋል፡- «ይህ ቁርኣን የአላህ ግብዣ ነው፤ ስለዚህ ከግብዣው የቻላችሁትን ያህል ውሰዱ።»',
    'om':
        'Imaam Abdullaah bin Mas’uud (R.A) jedhan: "Dhugumatti Qur’aanni kun maaddii (afeerraa) Allaahati, kanaaf maaddii Isaa irraa waan dandeessan fudhadhaa."',
  },
  {
    'ar':
        'قال الإمام سفيان الثوري: «إذا أراد العبد أن يزداد مقاطعة للدنيا وإقبالاً على الآخرة، فلينظر في المصحف.»',
    'en':
        'Imam Sufyan al-Thawri said: "If a servant wants to increase their detachment from this world and focus on the Hereafter, let them look into the Mus-haf."',
    'am':
        'ኢማም ሱፍያን አጥ-ሰውሪ እንዲህ ብለዋል፡- «አንድ ባሪያ ከዱንያ መራቅና ወደ አኺራ መቃረብን መጨመር ከፈለገ ቁርኣንን ይመልከት።»',
    'om':
        'Imaam Sufyaaan Al-Sawrii jedhan: "Yoo gabrichi addunyaa irraa fagaachuu fi gara aakhiraa deemuu dabaluu fedhe, Qur\'aana haa ilaalu."',
  },
  {
    'ar':
        'قال الإمام الفضيل بن عياض: «حامل القرآن حامل راية الإسلام، لا ينبغي أن يلهو مع من يلهو.»',
    'en':
        'Imam Al-Fudayl ibn Iyad said: "The bearer of the Qur\'an is the bearer of the banner of Islam, it is not fitting for him to idle with those who idle."',
    'am':
        'ኢማም አል-ፉደይል ቢን ኢያድ እንዲህ ብለዋል፡- «የቁርኣን ተሸካሚ የእስልምናን ሰንደቅ አላማ ተሸካሚ ነው، ከሚጫወቱት ጋር ሊጫወት አይገባውም።»',
    'om':
        'Imaam Fudayl bin Iyaad jedhan: "Baataan Qur’aanaa alaabaa Islaamaa baataadha, nama taphatu waliin taphachuun isaaf hin malu."',
  },
  {
    'ar':
        'قال الإمام الحسن البصري: «تفقَّدوا الحلاوة في ثلاثة أشياء: في الصلاة، وفي الذكر، وفي قراءة القرآن.»',
    'en':
        'Imam Al-Hasan al-Basri said: "Seek sweetness in three things: in prayer, in remembrance, and in the recitation of the Qur\'an."',
    'am':
        'ኢማም አል-ሀሰن አል-በስሪ እንዲህ ብለዋል፡- «ጣፋጭነትን በሶስት ነገሮች ውስጥ ፈልጉ፡ በሶላት، በዚክር እና ቁرኣን በማንበብ ውስጥ።»',
    'om':
        'Imaam Al-Hasan Al-Basrii jedhan: "Miyaawaa waan sadii keessatti barbaadaa: salaata keessatti, zikrii keessatti fi Qur’aana dubbisuu keessatti."',
  },
  {
    'ar':
        'قال ابن القيم رحمه الله: «قراءة آية بتفكر وتدبر خير من قراءة ختمة بغير تدبر وفهم.»',
    'en':
        'Ibn al-Qayyim (may Allah have mercy on him) said: "Reading a single verse with reflection and contemplation is better than completing the entire Qur\'an without contemplation and understanding."',
    'am':
        'ኢብኑል ቀይም (ረሂመሁላህ) እንዲህ ብለዋል፡- «አንዲትን አንቀጽ በትኩረትና በማስተንተን ማንበብ ቁርኣንን ሙሉ በሙሉ ያለ ማስተንተንና መረዳት ከማንበብ ይበልጣል።»',
    'om':
        'Ibn Al-Qayyim (R.H) jedhan: "Aayata tokko xiinxalaafi hubannoodhaan dubbisuun Qur’aana guutuu osoo hin xiinxalin dubbisuu irra caala."',
  },
  {
    'ar':
        'قال الإمام ذو النون المصري: «القرآن دواء القلوب البالية، وصلاح الأنفس العاصية.»',
    'en':
        'Imam Dhu\'n-Nun al-Misri said: "The Qur\'an is the cure for worn-out hearts and the righteousness of disobedient souls."',
    'am':
        'ኢማም ዙን-ኑን አል-ሚስሪ እንዲህ ብለዋል፡- «ቁርኣን ለዛሉ ልቦች መድኃኒት، ለአመጸኞች ነፍሳትም ማስተካከያ ነው።»',
    'om':
        'Imaam Dhu Al-Nuun Al-Misrii jedhan: "Qur’aanni qoricha onnee dhumteeti, fi qajeelfama lubbuu finciltuuti."',
  },

  // المجموعة 4: وعظ، مقارنة بالأموات، وشحن الهمة
  {
    'ar':
        '⚰️ الأموات في قبورهم يتمنون سجدة أو آية، وأنت كتاب الله بين يديك كاملاً.. اغتنم حياتك قبل حسرتك!',
    'en':
        '⚰️ The deceased in their graves wish for a single prostration or a single verse, while the Book of Allah is fully in your hands... Seize your life before your regret!',
    'am':
        '⚰️ ሙታን በመቃብራቸው ውስጥ ሆነው አንዲት ሱጁድ ወይም አንቀጽ ይመኛሉ، አንተ ግን የአላህ መጽሐፍ ሙሉ በሙሉ በእጅህ ነው... ከቆጨህ በፊት ሕይወትህን ተጠቀምባት!',
    'om':
        "⚰️ Warri du'an qabrii keessatti sujuuda tokko ykn aayata tokko hawwu, ati immoo Kitaabni Allaah guutuun harka kee jira... Osoo hin gaabin jireenya kee gorfadhu!",
  },
  {
    'ar':
        '🕯️ اقرأ بتمهل.. فرُبّ آيةٍ تتلوها وتتدبرها اليوم، تكون هي أنيسك والضياء الشافي لك في ظلمات قبرك.',
    'en':
        '🕯️ Read slowly... For perhaps a verse you recite and ponder today will be your companion and healing light in the darkness of your grave.',
    'am':
        '🕯️ ቀስ ብለህ አንብብ... ዛሬ የምታነባትና የምታስተነትናት አንቀጽ ነገ በመቃብርህ ጨለما ውስጥ አጋዥህና ፈዋሽ ብርሃንህ ትሆን ይሆናል።',
    'om':
        "🕯️ Suuta jedhii dubbisi... Tarii aayanni ati har'a qaraatanii xiinxaltu, dukkana qabrii keetii keessatti hiriyaa keefi ibsaa si fayyisu ta'uu danda'a.",
  },
  {
    'ar':
        '🏰 كل آية تقرؤها وتعمل بها الآن هي لبنةٌ ودرجةٌ تبنيها في قصرك بالجنة.. اقرأ وارتقِ!',
    'en':
        '🏰 Every verse you read and act upon now is a brick and a step you build in your palace in Paradise... Read and rise!',
    'am':
        '🏰 አሁን የምታነባትና የምትሰራባት እያንዳንዱ አንቀጽ በጀነት ውስጥ ላለህ ቤተመንግስት የምትገነባው ጡብና ደረጃ ነው... አንብብና ከፍ በል!',
    'om':
        '🏰 Aayanni ati amma dubbistee hojiirra oolchitu hundi riqaa fi sadarkaa ati gamooma jannata keessatti ijaarrattudha... Dubbisi ol ka\'i!',
  },
  {
    'ar':
        '🪙 الحرف بعشر حسنات، والحسنات جبالٌ تثقل الميزان يوم القيامة.. ابدأ تجارتك الرابحة الآن مع الله.',
    'en':
        '🪙 A letter earns ten good deeds, and good deeds are mountains that weigh heavy on the Scale on the Day of Resurrection... Start your profitable trade with Allah now.',
    'am':
        '🪙 እያንዳንዱ ፊደል በአስር መልካም ስራዎች ነው، መልካم ስራዎች ደግሞ በትንሳኤ ቀን ሚዛኑን የሚያከብዱ ተራሮች ናቸው... አሁኑኑ ከአлаህ ጋር አترافي ንግድህን ጀምር።',
    'om':
        '🪙 Harfiin tokko tola kudhaniin, tolaa immoo gaarren Guyyaa Qiyamaa mizaana ulfeessanidha... Ammuma daldala kee kan bu\'aa qabu Allaah waliin jalقabi.',
  },
  {
    'ar':
        '❤️ القرآن لا يترك صاحبه أبداً؛ يرافقك في الدنيا، ويحميك في القبر، ويجادل عنك يوم القيامة حتى تدخل الجنة.',
    'en':
        '❤️ The Qur\'an never leaves its companion; it accompanies you in this world, protects you in the grave, and advocates for you on the Day of Resurrection until you enter Paradise.',
    'am':
        '❤️ ቁርኣን ባለቤቱን በፍጹም አይተውም፤ በዱንያ አብሮህ ይሆናል، በመቃብር ይጠብቅሃل، በትንሳኤ ቀንም ጀነት እስክትገባ ድረስ ይከراكرلሃል።',
    'om':
        '❤️ Qur’aanni saahiba isaa hin dhiisu; addunyaa keessatti si waliin ta\'a, qabrii keessatti si eega, Guyyaa Qiyamaas hamma Jannata seentutti siif falma.',
  },
  {
    'ar':
        '🌟 لا تجعل مصحفك مهجوراً； فالقلب الذي لا يقرأ القرآن كالبيت الخرب الذي لا يسكنه أحد.',
    'en':
        '🌟 Do not leave your Mus-haf abandoned; for the heart that does not read the Qur\'an is like a ruined house in which no one dwells.',
    'am': '🌟 ቁርኣንህን የተተወ አታድርገው፤ ቁርኣን የማይነበብበት ልብ ማንም እንደማይኖርበት የፈረሰ ቤት ነውና።',
    'om':
        '🌟 Qur’aana kee gatamoo hin godhin; onneen Qur’aana hin dubbisne akka mana diigamee nama keessa hin jirreeti.',
  },
  {
    'ar':
        '🕊️ النجاة النجاة! غداً تُوضع الموازين وتنكشف الأستار، ولن ينفعك إلا ما قدمت من كتاب الله.',
    'en':
        '🕊️ Salvation, salvation! Tomorrow the scales will be set and secrets revealed, and nothing will benefit you except what you offered from the Book of Allah.',
    'am':
        '🕊️ መዳን، መዳን! ነገ ሚዛኖች ይቀመጣሉ، መጋረጃዎችም ይገለጣሉ، ከአላህ መጽሐፍ ካቀረብከው በስተቀር ምንም አይጠቅምህም።',
    'om':
        '🕊️ Fayyinna, fayyinna! Bor mizaanni ni kaa\'ama, haguuggiinis ni saaqama, waan ati Kitaaba Allaah irraa dabarsite malee maaltu si fayyada.',
  },
  {
    'ar':
        '💧 بكاء العين من خشية آية، يطفئ بحاراً من عذاب يوم القيامة.. تدبر حروفه.',
    'en':
        '💧 The weeping of the eye out of fear from a verse extinguishes oceans of torment on the Day of Resurrection... Ponder its letters.',
    'am':
        '💧 ከአንቀጽ ፍርሃት የተነሳ የአይን ማልቀስ የትንሳኤ ቀንን የስቃይ ባህሮች ያጠፋል... ፊደሎቹን አስተንትን።',
    'om':
        '💧 Imimmaan ijaa sodaa aayata tokkoo irraa ka\'e, galaana adaba Guyyaa Qiyamaa balleessa... Harfii isaa xiinxali.',
  },
  {
    'ar':
        '👑 يُقال لقارئ القرآن يوم القيامة: اقرأ وارتق ورتل كما كنت ترتل في الدنيا، فإن منزلتك عند آخر آية تقرؤها.',
    'en':
        '👑 It will be said to the companion of the Qur\'an on the Day of Resurrection: "Read and ascend, and recite smoothly as you used to recite in the world, for your status will be at the last verse you read."',
    'am':
        '👑 በትንሳኤ ቀን ለቁርኣን አንባቢ እንዲህ ይባላል፡- «አንብብና ከፍ በል፤ በዱንያ ላይ እንደምታነበው አሳምረህ አንብብ፤ ደረጃህ የመጨረሻዋ የምታነባት አንቀጽ ጋ ነውና।»',
    'om':
        '👑 Guyyaa Qiyamaa qaraataa Qur’aanaatiin ni jedhama: "Dubbisi ol ka\'i, akkuma addunyaa keessatti suuta dubbisaa turtetti suuta dubbisi, sadarkaan kee aayata dhumaa ati dubbistu biratti dha."',
  },
  {
    'ar':
        '🚨 لا تخرج من الدنيا صفر اليدين، والقرآن حجة لك أو عليك.. اجعله حجة لك.',
    'en':
        '🚨 Do not leave this world empty-handed, while the Qur\'an is a proof for you or against you... Make it a proof for you.',
    'am':
        '🚨 ከዱንያ ባዶ እጅህን አትውጣ، ቁርኣን ለአንተ ወይም በአንተ ላይ ምስክር ነው... ለአንተ ምስክር አድርገው።',
    'om':
        '🚨 Harka duwwaa addunyaa irraa hin ba\'in, Qur’aanni siif ragaa ykn sitti ragaa dha... Ofiif ragaa godhadhu.',
  },
  {
    'ar':
        '🗺️ إذا تاهت بك السبل وضاق صدرك، فافتح مصحفك؛ ففيه نبأ من قبلكم، وخبر ما بعدكم، وحكم ما بينكم.',
    'en':
        '🗺️ If the ways confuse you and your chest feels tight, open your Mus-haf; for in it is the news of those before you, information of what is after you, and judgment for what is between you.',
    'am':
        '🗺️ መንገዶች ቢጠፉብህና ደረትህ ቢጠበብ ቁርኣንህን ክፈት؛ በእሱ ውስጥ የእናንተ በፊት የነበሩት ወሬ، ከእናንተ በኋላ የሚመጣው ዜና እና በመካከላችሁ ያለው ፍርድ አለና።',
    'om':
        '🗺️ Yoo karaaleen sitti badanii garaan kee dhiphate, Qur\'aana kee bani; isa keessa oduu warra isiniin duraa, oduu warra isiniin boodaa fi murtii gidduu keessanii jirutu jira.',
  },
  {
    'ar':
        '⚡ شعلة الحماس لا تنطفئ في قلبٍ أدمن تلاوة كلام ربه.. ابدأ قراءتك بهمة عالية.',
    'en':
        '⚡ The flame of enthusiasm does not die out in a heart addicted to reciting the speech of its Lord... Start your reading with high resolve.',
    'am': '⚡ የጌታውን ቃል ማንበብ በለመደ ልብ ውስጥ የنቃት እሳት አይጠፋም... ንባብህን በከፍተኛ ጉጉት ጀምር።',
    'om':
        '⚡ Labbiin fedhii onnee keessa jiru kan daddabalatee jecha Rabbii isaa dubbisuun adiktee ta\'e hin dhabamu... Dubbisa kee hamilee olaanaan jalqabi.',
  },
  {
    'ar':
        '🤝 ليكن القرآن صاحبك المفضل؛ فكل الأصحاب يفارقونك عند الموت، إلا القرآن يدخل معك قبرك.',
    'en':
        '🤝 Let the Qur\'an be your favorite companion; for all companions part with you at death, except the Qur\'an, which enters your grave with you.',
    'am':
        '🤝 ቁርኣن ተወዳጅ ጓደኛህ ይሁን፤ ጓደኞች ሁሉ ሲሞቱ ይለዩሃል، ቁርኣን ግን ካንተ ጋር ወደ መቃብርህ ይገባል።',
    'om':
        '🤝 Qur’aanni saahiba kee filatamaa haa ta’u; saahiboonni hundi yeroo du\'aa si biraa deemu, Qur’aana malee kan qabrii kee si waliin seenu.',
  },
  {
    'ar':
        '✨ استشعر الآن وأنت تفتح المصحف أن ملك الملوك يكلمك أنت مباشرة.. فاستمع وأنصت.',
    'en':
        '✨ Feel now as you open the Mus-haf that the King of kings is speaking to you directly... So listen and pay attention.',
    'am':
        '✨ አሁን ቁርኣኑን ስትከፍት የነገስታት ንጉስ በቀጥታ እያናገረህ እንደሆነ ይሰማህ... ስለዚህ አድምጥ، ጸጥም በል።',
    'om':
        '✨ Amma yeroo Qur\'aana bantu Mootiin moototaa kallattiin sitti dubbachaa akka jiru sitti haa dhaga\'amu... Kanaaf dhaggeeffadhu, cal\'isis.',
  },
  {
    'ar':
        '🛑 احذر الحرمان! أن يمر عليك يومك المكتظ بالمشاغل دون أن تفتح لقلبك نافذة نور من كلام ربك.',
    'en':
        '🛑 Beware of deprivation! That your day crowded with concerns passes by without opening a window of light for your heart from the speech of your Lord.',
    'am': '🛑 ከመነፈግ ተጠንቀቅ! በስራ የተጠመደው ቀንህ ለልብህ ከጌታህ ቃል የብርሃن መስኮት ሳትከፍት ማለፉ።',
    'om':
        '🛑 Akka hin dhabamne of eeggaddhu! Guyyaan kee kan hojiidhaan dhiphate osoo onnee keetiif foddaa ifaa jecha Rabbii keetii irraa hin banin akka hin dabarre.',
  },
  {
    'ar':
        '🥀 ما جفّت دماء القلوب ولا قست، إلا بعد أن هجرت تدبر المصحف الكريم.. رطّب قلبك بآياته.',
    'en':
        '🥀 The blood of the hearts did not dry up nor harden, except after they abandoned contemplating the Noble Mus-haf... Moisten your heart with its verses.',
    'am':
        '🥀 የልቦች ደም አልደረቀም ወይም አልጠነከረም، የተከበረውን ቁርኣን ማስተንተن ከተዉ በኋላ ቢሆን እንጂ... ልብህን በአንቀጾቹ አርጥብ።',
    'om':
        '🥀 Dhiigni onnee hin gogne, hin jabaannes, osoo xiinxala Qur\'aana kabajamaa dhiisanii booda malee... Onnee kee aayatoota isaatiin jiisi.',
  },
  {
    'ar':
        '🔍 تفكّر في عاقبتك.. لو قُبضت روحك الليلة، أيسرّك أن يكون آخر عهدك بالدنيا آية قرأتها أم تفاهة تصفحتها؟',
    'en':
        '🔍 Think about your end... If your soul were taken tonight, would it please you for your last moment in the world to be a verse you read, or triviality you scrolled through?',
    'am':
        '🔍 ስለ መጨረሻህ አስብ... ዛሬ ማታ ነፍስህ ብትወሰድ، በዱንያ ላይ የመጨረሻ ጊዜህ ያነበብከው አንቀጽ መሆኑ ወይس የተመለከትከው ከንቱ ነገር መሆኑ ያስደስትሃል؟',
    'om':
        '🔍 Gara dhuma keetii xiinxali... Yoo lubbuun kee halkan kana fudhatamte, addunyaa irratti yeroon kee dhumaa aayata ati dubbifte ta\'u moo waan faayidaa hin qabne kan ati laaltee dabarsitedha kan si gammachiisu?',
  },
  {
    'ar':
        '🏹 آيات الوعيد كالسِّهام، تفلق صخور القلوب القاسية.. فقف عند وعيد الله خاشعاً منيباً.',
    'en':
        '🏹 The verses of warning are like arrows, splitting the rocks of hard hearts... So halt at the warning of Allah in humility and repentance.',
    'am':
        '🏹 የማስጠንቀቂያ አንቀጾች እንደ ቀስት ናቸው، የጠነከሩ ልቦችን ዓለቶች ይሰነጥቃሉ... ስለዚህ በአላህ ማስጠንቀቂያ ላይ በትህتናና በመጸጸት ቁም።',
    'om':
        '🏹 Aayatoonni akeekkachiisaa akka xiyyaati, dhagaa onnee gantuu dhoosu... Kanaaf sodaa fi tawbaadhaan akeekkachiisa Allaah biratti dhaabbadhu.',
  },
  {
    'ar':
        '🌻 اقرأ بتلذذ، فهذه الدنيا ممر وساعات القراءة في المصحف هي روضة الجنة المعجّلة في الأرض.',
    'en':
        '🌻 Read with pleasure, for this world is a transit, and the hours of reading the Mus-haf are the hastened garden of Paradise on Earth.',
    'am':
        '🌻 በደስታ አንብብ، ይህች ዱንያ መሻገሪያ ነችና، በቁርኣን ውስጥ የምታነብባቸው ሰዓታት በምድር ላይ ያለችው የጀነት መናፈሻ ናቸው።',
    'om':
        '🌻 Mi’aa dubbisi, addunyaan tun karaa darbiinsati, sa\'aatiin ati Qur’aana keessatti dabarsitus jannata daddafte kan dachii irratti argamte dha.',
  },
  {
    'ar':
        '🌌 لو علم القارئ ما ينتظره من الإكرام عند منتهى سورة يرتلها، لسالت روحه شوقاً لتلاوة كتاب ربه.',
    'en':
        '🌌 If the reader knew what honor awaits them at the end of a Surah they recite, their soul would have flowed with longing to recite the Book of their Lord.',
    'am':
        '🌌 አንባቢው በሚያነበው ሱራ መጨረሻ ላይ ምን ዓይነት ክብር እንደሚጠብቀው ቢያውቅ ኖሮ، ነፍሱ የጌታውን መጽሐፍ ለማንبه በጉጉት ትፈስ ነበር።',
    'om':
        '🌌 Osoo qaraataan kabaja dhuma suuraa inni qara\'u biratti isa eeggatu beekee, lubbuun isaa kitaaba Rabbii isaa qara\'uuf hawwiidhaan yaati turte.',
  },
  {
    'ar':
        '🚪 باب الإقبال على الله مفتوح الآن عبر هذه الشاشة.. ادخل بقلب منكسر خاشع عسى أن يُرحم.',
    'en':
        '🚪 The door of turning to Allah is open now through this screen... Enter with a broken, humble heart, so you may be shown mercy.',
    'am':
        '🚪 ወደ አላህ የመመለሻ በር አሁን በዚህ ስክሪን በኩል ክፍት ነው... ምሕረት ይደረግልህ ዘንድ በሰበረና በትሑት ልብ ግبا።',
    'om':
        '🚪 Balbalonni gara Allaah deebi\'u amma iskiriinii kanaan banameera... Qalbii cabduu fi gadi jedheen seeni, tarii rahmanni siif godhama.',
  },
  {
    'ar':
        '🍂 العمر ينقضي سريعاً والأيام تطوى.. ولا يبقى في صحيفتك غداً إلا ما وعاه قلبك من هذا التنزيل.',
    'en':
        '🍂 Life passes quickly and days fold... and nothing remains in your record tomorrow except what your heart preserved of this Revelation.',
    'am':
        '🍂 ዕድሜ በፍጥነት ያልፋል ቀናትም ይታጠፋሉ... ነገ በምዝግብ ማስታወሻህ ውስጥ ከዚህ መገለጥ ልብህ ከያዘው በስተቀር ምንም አይቀርም።',
    'om':
        '🍂 Umriin dafee dhumata, guyyoonnis ni dacha\'u... Bor galmee kee keessatti waan onneen kee bu\'iinsa kana irraa qabatte malee homtuu hin hafu.',
  },
  {
    'ar':
        '💡 القرآن نور البصيرة، من استضاء به هُدي إلى الصراط المستقيم ومن أعرض عنه عاش في ظلمة التيه.',
    'en':
        '💡 The Qur\'an is the light of insight, whoever seeks light from it is guided to the Straight Path, and whoever turns away from it lives in the darkness of wandering.',
    'am':
        '💡 ቁርኣን የእውቀት ብርሃን ነው، በእሱ የበራ ወደ ቀጥተኛው መንገድ ይመራል، ከእሱ የራቀ ግን በመጥፋት ጨለማ ውስጥ ይኖራል።',
    'om':
        '💡 Qur’aanni ifa ija qalbii ti, namni ifa isaan ibsate gara karaa qajeelaa qajeelfama, namni isarraa garagale immoo dukkana badinsaa keessa jiraata.',
  },
  {
    'ar':
        '🔔 تذكرة للمغترّ بطول الأمل: الموت يأتي بغتة، والقبر صندوق العمل.. فاجعل صندوقك مليئاً بالقرآن.',
    'en':
        '🔔 A reminder for the one deceived by long hopes: Death comes suddenly, and the grave is the chest of deeds... So make your chest full of the Qur\'an.',
    'am':
        '🔔 ረጅም ተስፋ ላለው ሰው ማስታወሻ፡ ሞት በድንገት ይመጣል، መቃብርም የስራ ሳጥን ነው... ስለዚህ ሳጥንህን በቁርኣን የተሞላ አድርገው።',
    'om':
        '🔔 Hawwii dheeraan kan gowwoomeef yaadachiisa: Duuti dingata dhufa, qabriin saanduqaa hojiiti... Kanaaf saanduqa kee Qur\'aanaan guuti.',
  },
  {
    'ar':
        '💎 القرآن لا يعطيك بعضه حتى تعطيه كلك.. فأعطِ مصحفك كليّة قلبك وانتباهك الآن.',
    'en':
        '💎 The Qur\'an does not give you some of it until you give it all of you... So give your Mus-haf the whole of your heart and your attention now.',
    'am':
        '💎 ቁርኣን ሙሉ ማንነትህን እስክትሰጠው ድረስ ከፊሉን አይሰጥህም... ስለዚህ አሁን ለቁርኣንህ ሙሉ ልብህንና ትኩረትህን ስጠው።',
    'om':
        '💎 Qur’aanni hamma ati guutuu kee kennitutti gartokkee isaa siif hin kennu... Kanaaf guutuu onnee keetii fi xiyyeeffannaa kee amma Qur\'aanaaf kenni.',
  },
  {
    'ar':
        '🌊 اغسل هموم صدرك الـمُتعبة بفيضان من آيات الطمأنينة.. أنصت لخطاب الله لك.',
    'en':
        '🌊 Wash away the tired worries of your chest with a flood of verses of tranquility... Listen to Allah\'s discourse to you.',
    'am':
        '🌊 የደረትህን የዛሉ ጭንቀቶች በእርጋታ አንቀጾች ጎርፍ እጠባቸው... አላህ ለአንተ የሚናገረውን ንግግር አድምጥ።',
    'om':
        '🌊 Yaaddoo garba dhiphina garaa keetii dambalii aayatoota tasgabbii kanaan dhuqi... Dubbii Allaah kan sitti dubbatu dhaggeeffadhu.',
  },
  {
    'ar':
        '🤲 اللهم اجعلنا ممن يقرأ القرآن فيرقى، ولا تجعلنا ممن يقرأه فيشقى.. ابدأ قراءتك مستعيناً بالله.',
    'en':
        '🤲 O Allah, make us of those who read the Qur\'an and ascend, and do not make us of those who read it and are miserable... Start your reading seeking help from Allah.',
    'am':
        '🤲 አላህ ሆይ! ቁርኣን አንብበው ከፍ ከሚሉት አድርገን، አንብበው ከሚቸገሩት አታድርገን... አላህን በመታገዝ ንባብህን ጀምር።',
    'om':
        'Ya Allaah! warra Qur’aana qara’ee ol ka’u nu taasisi, warra qara’ee hoonga’u nu hin taasisin... Gargaarsa Allaah barbaacha dubbisa kee jalqabi.',
  },
];

/// ودجت التذكير التفاعلي المحمي ضد تجاوز حدود المساحة الرأسية والأفقية.
class QuranReminderWidget extends StatelessWidget {
  final int pageNum;
  final String languageCode;
  final Color textColor;
  final int reminderIndex;
  final bool forceArabic;

  const QuranReminderWidget({
    Key? key,
    required this.pageNum,
    required this.languageCode,
    required this.textColor,
    required this.reminderIndex,
    required this.forceArabic,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (pageNum != 1 && pageNum != 2) return const SizedBox.shrink();
    final selectedItem = quranReminders[reminderIndex];
    const String displayLang = 'ar';
    final String localizedText =
        selectedItem[displayLang] ?? selectedItem['ar'] ?? '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      alignment: Alignment.center,
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
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  height: 1.4,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuranWordSearchModal extends StatefulWidget {
  final QuranTheme theme;
  final Color pageBgColor;
  final Color borderColor;
  final Color goldTextColor;
  final Color mainTextColor;
  final Function(int surahNum, int ayahNum, int pageNum) onJumpToAyah;

  const _QuranWordSearchModal({
    required this.theme,
    required this.pageBgColor,
    required this.borderColor,
    required this.goldTextColor,
    required this.mainTextColor,
    required this.onJumpToAyah,
  });

  @override
  State<_QuranWordSearchModal> createState() => _QuranWordSearchModalState();
}

class _QuranWordSearchModalState extends State<_QuranWordSearchModal> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _isSearching = false;

  // Removed _normalizeArabic as we do SQLite search directly

  Future<void> _performSearch(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      if (mounted) {
        setState(() {
          _results = [];
          _isSearching = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isSearching = true;
      });
    }

    // Notice: We query the 'aya' column using standard SQL LIKE.
    // If the DB has a diacritic-free column like 'aya_text_emlaey', it should be used here.
    // Otherwise, SQLite LIKE requires exactly matching the diacritics present in the column.
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery(
          "SELECT sura_num, aya_num, page_aya, aya as text, sura as surahName "
          "FROM quran WHERE search_aya LIKE ? LIMIT 100",
          ['%$cleanQuery%']);

      final List<Map<String, dynamic>> matches = rows
          .map((r) => {
                'surahNumber': r['sura_num'],
                'ayahNumber': r['aya_num'],
                'page': r['page_aya'],
                'text': r['text'],
                'surahName': DatabaseHelper
                    .surahNamesArabicList[(r['sura_num'] as int) - 1],
              })
          .toList();

      if (mounted) {
        setState(() {
          _results = matches;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        setState(() {
          _results = [];
          _isSearching = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: mediaQuery.viewInsets.bottom + 20,
      ),
      height: mediaQuery.size.height * 0.75,
      decoration: BoxDecoration(
        color: widget.pageBgColor.withValues(alpha: 0.98),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
            color: widget.borderColor.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: widget.borderColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.actionSearch,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.mainTextColor,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            onChanged: _performSearch,
            textAlign: TextAlign.right,
            style: TextStyle(color: widget.mainTextColor, fontFamily: 'Amiri'),
            decoration: InputDecoration(
              hintText: 'ابحث عن كلمة أو آية...',
              hintStyle: TextStyle(
                  color: widget.mainTextColor.withValues(alpha: 0.5),
                  fontFamily: 'Amiri'),
              prefixIcon: Icon(Icons.search, color: widget.borderColor),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: widget.mainTextColor),
                      onPressed: () {
                        _controller.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: widget.borderColor.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: widget.borderColor),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isSearching
                ? Center(
                    child: CircularProgressIndicator(color: widget.borderColor))
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          _controller.text.isEmpty
                              ? 'اكتب كلمة للبحث في القرآن الكريم'
                              : 'لم يتم العثور على نتائج',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 16,
                            color: widget.mainTextColor.withValues(alpha: 0.6),
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder: (context, index) => Divider(
                          color: widget.borderColor.withValues(alpha: 0.15),
                        ),
                        itemBuilder: (context, index) {
                          final v = _results[index];
                          final sName = v['surahName'] ?? '';
                          final sNum = v['surahNumber'] ?? 1;
                          final aNum = v['ayahNumber'] ?? 1;
                          final text = v['text'] ?? '';

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            title: Text(
                              text,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 18,
                                color: widget.mainTextColor,
                                height: 1.4,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'الصفحة: ${v['page']}',
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 12,
                                      color: widget.goldTextColor,
                                    ),
                                  ),
                                  Text(
                                    'سورة $sName [الآية: $aNum]',
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: widget.goldTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              widget.onJumpToAyah(
                                  sNum, aNum, v['page'] as int? ?? 1);
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
