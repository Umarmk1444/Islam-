import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/database/database_helper.dart';
import '../widgets/liquid_pressable.dart';

enum TafsirTheme {
  light,
  sepia,
  night,
  emerald,
}

class TafsirReaderScreen extends StatefulWidget {
  final int initialSurah;
  final String initialTafsir; // 'tafsir_moysar', 'tafsir_saadi', 'tafsir_baghawi'
  final int? targetAyah;

  const TafsirReaderScreen({
    super.key,
    this.initialSurah = 1,
    this.initialTafsir = 'tafsir_moysar',
    this.targetAyah,
  });

  @override
  State<TafsirReaderScreen> createState() => _TafsirReaderScreenState();
}

class _TafsirReaderScreenState extends State<TafsirReaderScreen>
    with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchFilterController = TextEditingController();
  bool _showTopBars = true;
  double _accumulatedUpwardScroll = 0.0;
  double _accumulatedDownwardScroll = 0.0;

  late int _currentSurah;
  late String _selectedTafsirKey;
  double _tafsirFontSize = 18.0;
  TafsirTheme _readerTheme = TafsirTheme.emerald;
  int _activeVisibleAyah = 1;

  List<Map<String, dynamic>> _ayahs = [];
  bool _isLoading = true;
  String _filterQuery = '';
  bool _showOnlyBookmarks = false;
  Set<String> _bookmarkedAyahs = {};

  // Audio Playback & Reciter
  AudioPlayer? _audioPlayer;
  int? _playingAyahNum;
  bool _isPlayingAudio = false;
  bool _isBufferingAudio = false;
  String _selectedReciterId = 'ar.alafasy';
  String _selectedReciterNameAr = 'مشاري راشد العفاسي';

  static const List<Map<String, String>> _kReciterOptions = [
    {
      'id': 'ar.alafasy',
      'nameAr': 'مشاري راشد العفاسي',
      'nameEn': 'Mishary Rashid Alafasy',
      'descAr': 'قراءة عذبة مرتلة (عالي الجودة)',
    },
    {
      'id': 'ar.husary',
      'nameAr': 'محمود خليل الحصري',
      'nameEn': 'Mahmoud Khalil Al-Husary',
      'descAr': 'شيخ عموم المقارئ المصرية (ترتيل متقن)',
    },
    {
      'id': 'ar.minshawi',
      'nameAr': 'محمد صديق المنشاوي',
      'nameEn': 'Mohamed Siddiq Al-Minshawi',
      'descAr': 'الصوت الباكي الخاشع (تلاوة مباركة)',
    },
  ];

  static const List<int> _kSurahVerseCounts = [
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109,
    123, 111, 43, 52, 99, 128, 111, 110, 98, 135,
    112, 78, 118, 64, 77, 227, 93, 88, 69, 60,
    34, 30, 73, 54, 45, 83, 182, 88, 75, 85,
    54, 53, 89, 59, 37, 35, 38, 29, 18, 45,
    60, 49, 62, 55, 78, 96, 29, 22, 24, 13,
    14, 11, 11, 18, 12, 12, 30, 52, 52, 44,
    28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20,
    15, 21, 11, 8, 8, 19, 5, 8, 8, 11,
    11, 8, 3, 9, 5, 4, 7, 3, 6, 3,
    5, 4, 5, 6
  ];

  static int _getGlobalAyahIndex(int surahNum, int ayahNum) {
    int total = 0;
    for (int i = 0; i < surahNum - 1 && i < _kSurahVerseCounts.length; i++) {
      total += _kSurahVerseCounts[i];
    }
    return total + ayahNum;
  }

  // Dot Pulse Animation
  late final AnimationController _dotPulseController;
  late final Animation<double> _dotScale;
  late final Animation<double> _dotOpacity;

  // 28 Madani Surah numbers
  static const Set<int> _kMadaniSurahs = {
    2, 3, 4, 5, 8, 9, 22, 24, 33, 47, 48, 49,
    57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 76, 98, 110
  };

  static const List<Map<String, String>> _kTafsirOptions = [
    {
      'key': 'tafsir_moysar',
      'titleAr': 'التفسير الميسر',
      'titleEn': 'Al-Muyassar',
      'scholarAr': 'مجمع الملك فهد لطباعة المصحف الشريف',
      'scholarEn': 'King Fahd Glorious Quran Complex',
      'badgeAr': 'الميسر',
    },
    {
      'key': 'tafsir_saadi',
      'titleAr': 'تفسير السعدي',
      'titleEn': "As-Sa'di",
      'scholarAr': 'تيسير الكريم الرحمن للعلامة عبد الرحمن السعدي',
      'scholarEn': "Taysir Al-Karim by Sh. Abdur-Rahman As-Sa'di",
      'badgeAr': 'السعدي',
    },
    {
      'key': 'tafsir_baghawi',
      'titleAr': 'تفسير البغوي',
      'titleEn': 'Al-Baghawi',
      'scholarAr': 'معالم التنزيل للإمام الحسين بن مسعود البغوي',
      'scholarEn': "Ma'alim At-Tanzil by Imam Al-Baghawi",
      'badgeAr': 'البغوي',
    },
  ];

  @override
  void initState() {
    super.initState();
    _currentSurah = widget.initialSurah.clamp(1, 114);
    _selectedTafsirKey = widget.initialTafsir;

    _dotPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _dotScale = Tween<double>(begin: 0.8, end: 1.25).animate(
      CurvedAnimation(parent: _dotPulseController, curve: Curves.easeInOut),
    );
    _dotOpacity = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _dotPulseController, curve: Curves.easeInOut),
    );

    _initAudioPlayer();
    _loadUserPreferencesAndProgress();

    _scrollController.addListener(_onScrollUpdateVisibleAyah);
    _scrollController.addListener(() {
      if (_scrollController.hasClients && _scrollController.offset <= 20) {
        if (!_showTopBars) {
          setState(() => _showTopBars = true);
        }
      }
    });
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer();
    _audioPlayer?.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlayingAudio = state.playing && state.processingState != ProcessingState.completed;
          _isBufferingAudio = state.processingState == ProcessingState.buffering || state.processingState == ProcessingState.loading;
          if (state.processingState == ProcessingState.completed) {
            _playingAyahNum = null;
            _isPlayingAudio = false;
            _isBufferingAudio = false;
          }
        });
      }
    });
  }

  Future<void> _loadUserPreferencesAndProgress() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load Font Size & Reader Theme
    final savedFontSize = prefs.getDouble('tafsir_font_size');
    if (savedFontSize != null && savedFontSize >= 14 && savedFontSize <= 30) {
      _tafsirFontSize = savedFontSize;
    }

    final savedThemeStr = prefs.getString('tafsir_reader_theme');
    if (savedThemeStr != null) {
      switch (savedThemeStr) {
        case 'light':
          _readerTheme = TafsirTheme.light;
          break;
        case 'sepia':
          _readerTheme = TafsirTheme.sepia;
          break;
        case 'night':
          _readerTheme = TafsirTheme.night;
          break;
        case 'emerald':
        default:
          _readerTheme = TafsirTheme.emerald;
          break;
      }
    }

    // 2. Load Bookmarks
    final savedBookmarks = prefs.getStringList('tafsir_bookmarks') ?? [];
    _bookmarkedAyahs = savedBookmarks.toSet();

    // 3. Load Reciter
    final savedReciter = prefs.getString('tafsir_reciter_id');
    if (savedReciter != null && _kReciterOptions.any((r) => r['id'] == savedReciter)) {
      _selectedReciterId = savedReciter;
      _selectedReciterNameAr = _kReciterOptions.firstWhere((r) => r['id'] == savedReciter)['nameAr']!;
    }

    // 4. Check and restore saved reading position if user opened default reader
    int? restoredAyah;
    if (widget.initialSurah == 1 && widget.targetAyah == null) {
      final lastSurah = prefs.getInt('tafsir_last_surah');
      final lastAyah = prefs.getInt('tafsir_last_ayah');
      final lastKey = prefs.getString('tafsir_last_key');

      if (lastSurah != null && lastSurah >= 1 && lastSurah <= 114) {
        _currentSurah = lastSurah;
        if (lastAyah != null && lastAyah > 1) {
          restoredAyah = lastAyah;
        }
        if (lastKey != null && _kTafsirOptions.any((o) => o['key'] == lastKey)) {
          _selectedTafsirKey = lastKey;
        }
      }
    }

    await _loadCurrentSurahAyahs(targetAyahToScroll: restoredAyah ?? widget.targetAyah);

    if (restoredAyah != null && mounted) {
      final sName = _getSurahArabicName(_currentSurah);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '📍 استأنفت قراءتك السابقة: سورة $sName • الآية $restoredAyah',
            style: const TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF0F4E3D),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(milliseconds: 2500),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _saveReadingProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tafsir_last_surah', _currentSurah);
    await prefs.setInt('tafsir_last_ayah', _activeVisibleAyah);
    await prefs.setString('tafsir_last_key', _selectedTafsirKey);
    await prefs.setString('tafsir_last_surah_ar', _getSurahArabicName(_currentSurah));
  }

  Future<void> _saveFontSize(double size) async {
    setState(() => _tafsirFontSize = size);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('tafsir_font_size', size);
  }

  Future<void> _saveTheme(TafsirTheme theme) async {
    setState(() => _readerTheme = theme);
    final prefs = await SharedPreferences.getInstance();
    final strVal = theme.name;
    await prefs.setString('tafsir_reader_theme', strVal);
  }

  Future<void> _toggleBookmark(int surahNum, int ayahNum) async {
    final key = '$surahNum:$ayahNum';
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_bookmarkedAyahs.contains(key)) {
        _bookmarkedAyahs.remove(key);
      } else {
        _bookmarkedAyahs.add(key);
      }
    });
    await prefs.setStringList('tafsir_bookmarks', _bookmarkedAyahs.toList());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScrollUpdateVisibleAyah);
    _scrollController.dispose();
    _searchFilterController.dispose();
    _dotPulseController.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  void _onScrollUpdateVisibleAyah() {
    if (_ayahs.isEmpty || !_scrollController.hasClients) return;
    final estimatedIndex = (_scrollController.offset / 320.0).floor().clamp(0, _ayahs.length - 1);
    final visibleAyahNum = (_ayahs[estimatedIndex]['aya_num'] as num).toInt();
    if (visibleAyahNum != _activeVisibleAyah) {
      setState(() {
        _activeVisibleAyah = visibleAyahNum;
      });
      _saveReadingProgress();
    }
  }

  Future<void> _loadCurrentSurahAyahs({int? targetAyahToScroll}) async {
    setState(() => _isLoading = true);
    try {
      final db = await _dbHelper.database;
      final rows = await db.rawQuery(
        'SELECT id_quran_ayat, sura_num, aya_num, sura, aya, search_aya, '
        'tafsir_moysar, tafsir_saadi, tafsir_baghawi, e3rab_quran, ma3ny_aya '
        'FROM quran WHERE sura_num = ? ORDER BY aya_num ASC',
        [_currentSurah],
      );

      if (mounted) {
        setState(() {
          _ayahs = rows;
          _isLoading = false;
          _activeVisibleAyah = targetAyahToScroll ?? 1;
        });

        if (targetAyahToScroll != null && targetAyahToScroll > 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToTargetAyah(targetAyahToScroll);
          });
        } else if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }

        _saveReadingProgress();
      }
    } catch (e) {
      debugPrint('[TafsirReaderScreen] Error loading ayahs: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToTargetAyah(int ayahNum) {
    if (!_scrollController.hasClients) return;
    final index = _ayahs.indexWhere((a) => (a['aya_num'] as num).toInt() == ayahNum);
    if (index != -1) {
      final targetOffset = index * 320.0;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
      setState(() => _activeVisibleAyah = ayahNum);
      _saveReadingProgress();
    }
  }

  void _switchSurah(int newSurah) {
    if (newSurah < 1 || newSurah > 114 || newSurah == _currentSurah) return;
    _stopAudio();
    setState(() {
      _currentSurah = newSurah;
      _filterQuery = '';
      _searchFilterController.clear();
      _showOnlyBookmarks = false;
    });
    _loadCurrentSurahAyahs();
  }

  void _stopAudio() {
    if (_isPlayingAudio || _isBufferingAudio) {
      _audioPlayer?.stop();
      setState(() {
        _playingAyahNum = null;
        _isPlayingAudio = false;
        _isBufferingAudio = false;
      });
    }
  }

  Future<void> _selectReciter(String reciterId, String reciterNameAr) async {
    _stopAudio();
    setState(() {
      _selectedReciterId = reciterId;
      _selectedReciterNameAr = reciterNameAr;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tafsir_reciter_id', reciterId);
  }

  Future<void> _playAyahAudio(int surahNum, int ayahNum, {int? absoluteAyahIndex}) async {
    if (_playingAyahNum == ayahNum && (_isPlayingAudio || _isBufferingAudio)) {
      _stopAudio();
      return;
    }

    final absIdx = (absoluteAyahIndex != null && absoluteAyahIndex > 0)
        ? absoluteAyahIndex
        : _getGlobalAyahIndex(surahNum, ayahNum);

    final surahAr = _getSurahArabicName(surahNum);

    setState(() {
      _playingAyahNum = ayahNum;
      _isBufferingAudio = true;
      _isPlayingAudio = false;
    });

    final mediaItem = MediaItem(
      id: 'tafsir_${_selectedReciterId}_${surahNum}_$ayahNum',
      album: 'تلاوة آيات القرآن الكريم - $_selectedReciterNameAr',
      title: 'سورة $surahAr - الآية $ayahNum',
      artist: _selectedReciterNameAr,
    );

    // Primary: Cloudflare-accelerated Islamic Network CDN (sub-100ms response, high reliability)
    final primaryUrl = 'https://cdn.islamic.network/quran/audio/128/$_selectedReciterId/$absIdx.mp3';
    debugPrint('[TafsirAudio] 🎵 Playing primary stream: $primaryUrl (Surah $surahNum: $surahAr, Ayah $ayahNum, Global Ayah #$absIdx, Reciter: $_selectedReciterNameAr)');

    try {
      final source = AudioSource.uri(Uri.parse(primaryUrl), tag: mediaItem);
      await _audioPlayer?.setAudioSource(source).timeout(const Duration(seconds: 8));
      await _audioPlayer?.play();
      if (mounted) {
        setState(() {
          _isBufferingAudio = false;
          _isPlayingAudio = true;
        });
      }
      return;
    } catch (e) {
      debugPrint('[TafsirAudio] Primary CDN stream encounter: $e. Trying fallback stream...');
    }

    // Fallback: Fallback to Alafasy on CDN or EveryAyah
    try {
      final fallbackUrl = 'https://cdn.islamic.network/quran/audio/128/ar.alafasy/$absIdx.mp3';
      debugPrint('[TafsirAudio] 🔄 Trying fallback stream: $fallbackUrl');
      final fallbackSource = AudioSource.uri(Uri.parse(fallbackUrl), tag: mediaItem);
      await _audioPlayer?.setAudioSource(fallbackSource).timeout(const Duration(seconds: 8));
      await _audioPlayer?.play();
      if (mounted) {
        setState(() {
          _isBufferingAudio = false;
          _isPlayingAudio = true;
        });
      }
      return;
    } catch (e2) {
      debugPrint('[TafsirAudio] Fallback audio playback also failed: $e2');
      if (mounted) {
        setState(() {
          _playingAyahNum = null;
          _isPlayingAudio = false;
          _isBufferingAudio = false;
        });
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'تعذر تشغيل تلاوة الآية حالياً. يرجى التحقق من اتصال الإنترنت',
              style: TextStyle(fontFamily: 'Amiri'),
            ),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  String _getSurahArabicName(int surahNum) {
    if (surahNum >= 1 && surahNum <= DatabaseHelper.surahNamesArabicList.length) {
      return DatabaseHelper.surahNamesArabicList[surahNum - 1];
    }
    return 'سورة $surahNum';
  }

  String _getSurahEnglishName(int surahNum) {
    if (surahNum >= 1 && surahNum <= DatabaseHelper.surahTransliterations.length) {
      return DatabaseHelper.surahTransliterations[surahNum - 1];
    }
    return 'Surah $surahNum';
  }

  bool _isMadani(int surahNum) => _kMadaniSurahs.contains(surahNum);

  // ───────────────────────────────────────────────────────────────────────────
  // Reader Display & Customization Sheet (Theme & Font Size & Live Preview)
  // ───────────────────────────────────────────────────────────────────────────
  void _openDisplaySettingsSheet(BuildContext context, String locale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isAr = locale == 'ar';

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
              decoration: BoxDecoration(
                color: _readerTheme == TafsirTheme.night
                    ? const Color(0xFF131D1A)
                    : (_readerTheme == TafsirTheme.emerald
                        ? const Color(0xFF0A241B)
                        : (_readerTheme == TafsirTheme.sepia
                            ? const Color(0xFFFAF6EE)
                            : Colors.white)),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 20, spreadRadius: 2),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.palette_rounded, color: _getGoldAccent(), size: 21),
                          const SizedBox(width: 8),
                          Text(
                            isAr ? 'تخصيص مظهر وحجم القراءة' : 'Reading Display Settings',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: _getTextColor(),
                              fontFamily: isAr ? 'Amiri' : null,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: _getGoldAccent().withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _getGoldAccent().withValues(alpha: 0.35), width: 0.8),
                        ),
                        child: Text(
                          '${_tafsirFontSize.toStringAsFixed(1)} pt',
                          style: TextStyle(
                            color: _getGoldAccent(),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 1. Reading Theme Selection (4 Authentic Hues)
                  Text(
                    isAr ? 'نمط وألوان القراءة' : 'Reading Color Theme',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _getTextColor().withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildThemeTile(
                        theme: TafsirTheme.light,
                        label: isAr ? 'نهاري' : 'Light',
                        bgSample: const Color(0xFFF7FAF8),
                        borderSample: const Color(0xFF1B8A6B),
                        onTap: () {
                          _saveTheme(TafsirTheme.light);
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildThemeTile(
                        theme: TafsirTheme.sepia,
                        label: isAr ? 'كلاسيكي' : 'Sepia',
                        bgSample: const Color(0xFFF4EFE6),
                        borderSample: const Color(0xFF9E6E27),
                        onTap: () {
                          _saveTheme(TafsirTheme.sepia);
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildThemeTile(
                        theme: TafsirTheme.night,
                        label: isAr ? 'ليلي' : 'Night',
                        bgSample: const Color(0xFF090E11),
                        borderSample: const Color(0xFF2ECC9A),
                        onTap: () {
                          _saveTheme(TafsirTheme.night);
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildThemeTile(
                        theme: TafsirTheme.emerald,
                        label: isAr ? 'زمردي' : 'Emerald',
                        bgSample: const Color(0xFF071B14),
                        borderSample: const Color(0xFFE2BC6A),
                        onTap: () {
                          _saveTheme(TafsirTheme.emerald);
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // 2. Interactive Font Size Controller
                  Text(
                    isAr ? 'حجم خط التفسير والآيات' : 'Tafsir & Verse Font Size',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _getTextColor().withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Stepper Row + Slider
                  Row(
                    children: [
                      // A- Button
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: _getCardBgColor(),
                          side: BorderSide(color: _getBorderColor()),
                        ),
                        icon: const Icon(Icons.text_decrease_rounded, size: 20),
                        color: _getTextColor(),
                        onPressed: _tafsirFontSize > 14.0
                            ? () {
                                final n = (_tafsirFontSize - 1.5).clamp(14.0, 28.0);
                                _saveFontSize(n);
                                setSheetState(() {});
                              }
                            : null,
                      ),

                      // Slider
                      Expanded(
                        child: Slider(
                          value: _tafsirFontSize,
                          min: 14.0,
                          max: 28.0,
                          divisions: 14,
                          activeColor: const Color(0xFFD4AF37),
                          inactiveColor: Colors.grey.withValues(alpha: 0.3),
                          onChanged: (val) {
                            _saveFontSize(val);
                            setSheetState(() {});
                          },
                        ),
                      ),

                      // A+ Button
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: _getCardBgColor(),
                          side: BorderSide(color: _getBorderColor()),
                        ),
                        icon: const Icon(Icons.text_increase_rounded, size: 20),
                        color: _getTextColor(),
                        onPressed: _tafsirFontSize < 28.0
                            ? () {
                                final n = (_tafsirFontSize + 1.5).clamp(14.0, 28.0);
                                _saveFontSize(n);
                                setSheetState(() {});
                              }
                            : null,
                      ),
                    ],
                  ),

                  // Quick Preset Chips
                  Wrap(
                    spacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildPresetChip('15 pt', 15.0, isAr ? 'عادي' : 'Normal', setSheetState),
                      _buildPresetChip('18 pt', 18.0, isAr ? 'مريح' : 'Medium', setSheetState),
                      _buildPresetChip('22 pt', 22.0, isAr ? 'كبير' : 'Large', setSheetState),
                      _buildPresetChip('26 pt', 26.0, isAr ? 'ضخم' : 'X-Large', setSheetState),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // 3. Dynamic Live Preview Box
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _getAyahBoxBgColor(),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _getAyahBoxBorderColor(), width: 0.9),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '﴿ إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ ﴾',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: (_tafsirFontSize + 3.0).clamp(17.0, 31.0),
                            fontWeight: FontWeight.bold,
                            color: _getAyahTextColor(),
                            height: 1.6,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isAr
                            ? 'معاينة حية: إن هذا القرآن يرشد إلى أكمل الطرق وأصلح الأحوال'
                            : 'Live Preview: Verily this Quran guides to that which is most suitable.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: isAr ? 'Amiri' : null,
                            fontSize: _tafsirFontSize,
                            color: _getTextColor().withValues(alpha: 0.85),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. Reciter Voice Selection
                  Text(
                    isAr ? 'القارئ الصوتي للآيات' : 'Ayah Reciter Voice',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _getTextColor().withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: _kReciterOptions.map((rec) {
                      final isSelected = rec['id'] == _selectedReciterId;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFD4AF37).withValues(alpha: 0.14)
                              : _getCardBgColor(),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFD4AF37)
                                : _getBorderColor(),
                            width: isSelected ? 1.4 : 0.8,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          leading: CircleAvatar(
                            radius: 15,
                            backgroundColor: isSelected
                                ? const Color(0xFFD4AF37)
                                : Colors.grey.withValues(alpha: 0.15),
                            child: Icon(
                              isSelected ? Icons.record_voice_over_rounded : Icons.person_outline_rounded,
                              size: 16,
                              color: isSelected ? Colors.black : _getTextColor(),
                            ),
                          ),
                          title: Text(
                            isAr ? rec['nameAr']! : rec['nameEn']!,
                            style: TextStyle(
                              color: _getTextColor(),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 13.5,
                              fontFamily: isAr ? 'Amiri' : null,
                            ),
                          ),
                          subtitle: Text(
                            rec['descAr']!,
                            style: TextStyle(
                              color: _getTextColor().withValues(alpha: 0.6),
                              fontSize: 11,
                              fontFamily: isAr ? 'Amiri' : null,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: Color(0xFFD4AF37), size: 19)
                              : null,
                          onTap: () {
                            _selectReciter(rec['id']!, rec['nameAr']!);
                            setSheetState(() {});
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThemeTile({
    required TafsirTheme theme,
    required String label,
    required Color bgSample,
    required Color borderSample,
    required VoidCallback onTap,
  }) {
    final isSelected = _readerTheme == theme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bgSample,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFFD4AF37) : borderSample.withValues(alpha: 0.4),
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              if (isSelected)
                const BoxShadow(
                  color: Color(0x33D4AF37),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: borderSample,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: (theme == TafsirTheme.night || theme == TafsirTheme.emerald) ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(String sizeLabel, double sizeVal, String name, StateSetter setSheetState) {
    final isSelected = (_tafsirFontSize - sizeVal).abs() < 0.5;

    return ActionChip(
      label: Text('$name ($sizeLabel)', style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      backgroundColor: isSelected ? const Color(0xFFD4AF37).withValues(alpha: 0.2) : _getCardBgColor(),
      side: BorderSide(color: isSelected ? const Color(0xFFD4AF37) : _getBorderColor(), width: 0.8),
      onPressed: () {
        _saveFontSize(sizeVal);
        setSheetState(() {});
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Theme Color Resolvers
  // ───────────────────────────────────────────────────────────────────────────
  Color _getBgColor() {
    switch (_readerTheme) {
      case TafsirTheme.light:
        return const Color(0xFFF7FAF8);
      case TafsirTheme.sepia:
        return const Color(0xFFF4EFE6);
      case TafsirTheme.night:
        return const Color(0xFF090E11);
      case TafsirTheme.emerald:
        return const Color(0xFF071B14);
    }
  }

  Color _getCardBgColor() {
    switch (_readerTheme) {
      case TafsirTheme.light:
        return Colors.white;
      case TafsirTheme.sepia:
        return const Color(0xFFFAF7F0);
      case TafsirTheme.night:
        return const Color(0xFF111A18);
      case TafsirTheme.emerald:
        return const Color(0xFF0D2920);
    }
  }

  Color _getBorderColor() {
    switch (_readerTheme) {
      case TafsirTheme.light:
        return const Color(0xFFE2EBE7);
      case TafsirTheme.sepia:
        return const Color(0xFFE2D5BE);
      case TafsirTheme.night:
        return Colors.white.withValues(alpha: 0.08);
      case TafsirTheme.emerald:
        return const Color(0xFF1B4E3E);
    }
  }

  Color _getTextColor() {
    switch (_readerTheme) {
      case TafsirTheme.light:
        return const Color(0xFF112620);
      case TafsirTheme.sepia:
        return const Color(0xFF382819);
      case TafsirTheme.night:
        return const Color(0xFFEDF2EE);
      case TafsirTheme.emerald:
        return const Color(0xFFF3F7F5);
    }
  }

  Color _getAyahBoxBgColor() {
    switch (_readerTheme) {
      case TafsirTheme.light:
        return const Color(0xFFF0F6F3);
      case TafsirTheme.sepia:
        return const Color(0xFFEFE8DA);
      case TafsirTheme.night:
        return const Color(0xFF0C1613);
      case TafsirTheme.emerald:
        return const Color(0xFF14392D);
    }
  }

  Color _getAyahBoxBorderColor() {
    switch (_readerTheme) {
      case TafsirTheme.light:
        return const Color(0xFF1B8A6B).withValues(alpha: 0.25);
      case TafsirTheme.sepia:
        return const Color(0xFFB78A48).withValues(alpha: 0.35);
      case TafsirTheme.night:
        return const Color(0xFF1B8A6B).withValues(alpha: 0.3);
      case TafsirTheme.emerald:
        return const Color(0xFFE2BC6A).withValues(alpha: 0.4);
    }
  }

  Color _getAyahTextColor() {
    switch (_readerTheme) {
      case TafsirTheme.light:
        return const Color(0xFF0F4D3C);
      case TafsirTheme.sepia:
        return const Color(0xFF4A2B0E);
      case TafsirTheme.night:
        return const Color(0xFF70E1B4);
      case TafsirTheme.emerald:
        return const Color(0xFFFFD54F);
    }
  }

  Color _getGoldAccent() {
    switch (_readerTheme) {
      case TafsirTheme.light:
      case TafsirTheme.sepia:
        return const Color(0xFF8A6208);
      case TafsirTheme.night:
      case TafsirTheme.emerald:
        return const Color(0xFFD4AF37);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Quick Ayah Jumper Modal
  // ───────────────────────────────────────────────────────────────────────────
  void _openAyahJumperModal(BuildContext context, String locale) {
    final TextEditingController ayahInputController = TextEditingController();
    double sliderVal = _activeVisibleAyah.toDouble().clamp(1.0, _ayahs.length.toDouble());
    final cardBg = _getCardBgColor();
    final textColor = _getTextColor();
    final borderColor = _getBorderColor();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final surahName = _getSurahArabicName(_currentSurah);
            final totalAyahs = _ayahs.length;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.gps_fixed_rounded, color: Color(0xFFC68A2E), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            locale == 'ar' ? 'انتقال سريع لآية في $surahName' : 'Jump to Ayah in $surahName',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontFamily: locale == 'ar' ? 'Amiri' : null,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B8A6B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          locale == 'ar' ? 'إجمالي: $totalAyahs آية' : 'Total: $totalAyahs',
                          style: const TextStyle(
                            color: Color(0xFF1B8A6B),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: _readerTheme == TafsirTheme.night || _readerTheme == TafsirTheme.emerald
                                ? Colors.white.withValues(alpha: 0.06)
                                : const Color(0xFFF1F5F3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: borderColor),
                          ),
                          child: TextField(
                            controller: ayahInputController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: locale == 'ar' ? 'اكتب رقم الآية (1 - $totalAyahs)...' : 'Ayah (1 - $totalAyahs)...',
                              hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.7), fontSize: 13),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            onChanged: (val) {
                              final numVal = int.tryParse(val);
                              if (numVal != null && numVal >= 1 && numVal <= totalAyahs) {
                                setModalState(() => sliderVal = numVal.toDouble());
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1B8A6B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          final numVal = int.tryParse(ayahInputController.text) ?? sliderVal.round();
                          Navigator.pop(ctx);
                          _scrollToTargetAyah(numVal.clamp(1, totalAyahs));
                        },
                        child: Text(
                          locale == 'ar' ? 'انتقال' : 'Jump',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Text('1', style: TextStyle(color: textColor, fontSize: 12)),
                      Expanded(
                        child: Slider(
                          value: sliderVal,
                          min: 1.0,
                          max: totalAyahs.toDouble(),
                          divisions: totalAyahs > 1 ? totalAyahs - 1 : 1,
                          activeColor: const Color(0xFF1B8A6B),
                          inactiveColor: Colors.grey.withValues(alpha: 0.3),
                          label: 'الآية ${sliderVal.round()}',
                          onChanged: (newVal) {
                            setModalState(() {
                              sliderVal = newVal;
                              ayahInputController.text = newVal.round().toString();
                            });
                          },
                        ),
                      ),
                      Text('$totalAyahs', style: TextStyle(color: textColor, fontSize: 12)),
                    ],
                  ),

                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildQuickJumpChip(1, 'الآية 1 (البداية)', ctx),
                      if (totalAyahs >= 10) _buildQuickJumpChip(10, 'الآية 10', ctx),
                      if (totalAyahs >= 25) _buildQuickJumpChip(25, 'الآية 25', ctx),
                      if (totalAyahs >= 50) _buildQuickJumpChip(50, 'الآية 50', ctx),
                      if (totalAyahs >= 100) _buildQuickJumpChip(100, 'الآية 100', ctx),
                      if (totalAyahs >= 200) _buildQuickJumpChip(200, 'الآية 200', ctx),
                      _buildQuickJumpChip(totalAyahs, 'الآية $totalAyahs (الخاتمة)', ctx),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickJumpChip(int ayahNum, String label, BuildContext modalCtx) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
      backgroundColor: const Color(0xFF1B8A6B).withValues(alpha: 0.1),
      side: BorderSide(color: const Color(0xFF1B8A6B).withValues(alpha: 0.25), width: 0.8),
      onPressed: () {
        Navigator.pop(modalCtx);
        _scrollToTargetAyah(ayahNum);
      },
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Surah Picker Modal
  // ───────────────────────────────────────────────────────────────────────────
  void _openSurahPickerModal(BuildContext context, String locale) {
    final cardBg = _getCardBgColor();
    final textColor = _getTextColor();
    final borderColor = _getBorderColor();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        String modalSearch = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = List.generate(114, (i) => i + 1).where((sIndex) {
              if (modalSearch.trim().isEmpty) return true;
              final q = modalSearch.trim().toLowerCase();
              final ar = _getSurahArabicName(sIndex);
              final en = _getSurahEnglishName(sIndex).toLowerCase();
              return ar.contains(q) || en.contains(q) || sIndex.toString() == q;
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.78,
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.menu_book_rounded, color: Color(0xFF1B8A6B), size: 20),
                          const SizedBox(width: 8),
                          Text(
                            locale == 'ar' ? 'فهرس سور القرآن الكريم' : 'Quran Surah Index',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                              fontFamily: locale == 'ar' ? 'Amiri' : null,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B8A6B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '114 ${locale == 'ar' ? 'سورة' : 'Surahs'}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF1B8A6B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: _readerTheme == TafsirTheme.night || _readerTheme == TafsirTheme.emerald
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFF1F5F3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextField(
                      onChanged: (val) => setModalState(() => modalSearch = val),
                      style: TextStyle(color: textColor, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: locale == 'ar' ? 'ابحث باسم السورة أو رقمها...' : 'Search surah name or number...',
                        hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.7), fontSize: 12),
                        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF1B8A6B)),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => Divider(color: borderColor, height: 1),
                      itemBuilder: (context, idx) {
                        final sNum = filtered[idx];
                        final arName = _getSurahArabicName(sNum);
                        final enName = _getSurahEnglishName(sNum);
                        final isMadani = _isMadani(sNum);
                        final isCurrent = sNum == _currentSurah;

                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          onTap: () {
                            Navigator.pop(ctx);
                            _switchSurah(sNum);
                          },
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? const Color(0xFF1B8A6B)
                                  : (_readerTheme == TafsirTheme.night || _readerTheme == TafsirTheme.emerald
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : const Color(0xFFE2EBE7)),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '$sNum',
                                style: TextStyle(
                                  color: isCurrent ? Colors.white : textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                arName,
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 16.5,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                  color: isCurrent ? const Color(0xFF1B8A6B) : textColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: (isMadani ? const Color(0xFF2B6CB0) : const Color(0xFFC68A2E)).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isMadani ? (locale == 'ar' ? 'مدنية' : 'Madani') : (locale == 'ar' ? 'مكية' : 'Makki'),
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: isMadani ? const Color(0xFF2B6CB0) : const Color(0xFFC68A2E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            enName,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.withValues(alpha: 0.8),
                            ),
                          ),
                          trailing: isCurrent
                              ? const Icon(Icons.check_circle_rounded, color: Color(0xFF1B8A6B), size: 20)
                              : const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.black26),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _copyAyahAndTafsir(Map<String, dynamic> ayah, String tafsirTitle, String tafsirText, String locale) {
    final surahName = _getSurahArabicName(_currentSurah);
    final aNum = ayah['aya_num'];
    final aText = ayah['aya'] ?? '';

    final fullText = '﴿ $aText ﴾ [$surahName: $aNum]\n\n'
        '• $tafsirTitle:\n'
        '$tafsirText\n\n'
        '— عبر تطبيق نور الهدى';

    Clipboard.setData(ClipboardData(text: fullText));

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          locale == 'ar' ? 'تم نسخ الآية وتفسيرها بنجاح' : 'Verse & Tafsir copied to clipboard',
          style: TextStyle(fontFamily: locale == 'ar' ? 'Amiri' : null),
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(milliseconds: 1800),
      ),
    );
  }

  void _shareAyahAndTafsir(Map<String, dynamic> ayah, String tafsirTitle, String tafsirText) {
    final surahName = _getSurahArabicName(_currentSurah);
    final aNum = ayah['aya_num'];
    final aText = ayah['aya'] ?? '';

    final fullText = '﴿ $aText ﴾ [$surahName: $aNum]\n\n'
        '• $tafsirTitle:\n'
        '$tafsirText\n\n'
        '— تطبيق نور الهدى';

    Share.share(fullText);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context)?.languageCode ?? 'ar';
    final isArabic = locale == 'ar';

    final bgColor = _getBgColor();
    final cardBg = _getCardBgColor();
    final textColor = _getTextColor();
    final borderColor = _getBorderColor();

    final surahAr = _getSurahArabicName(_currentSurah);
    final surahEn = _getSurahEnglishName(_currentSurah);
    final prevSurahAr = _currentSurah > 1 ? _getSurahArabicName(_currentSurah - 1) : '';
    final nextSurahAr = _currentSurah < 114 ? _getSurahArabicName(_currentSurah + 1) : '';

    // Filter ayahs by search query or bookmarks
    final displayAyahs = _ayahs.where((a) {
      final aNum = a['aya_num'] as int;
      if (_showOnlyBookmarks && !_bookmarkedAyahs.contains('$_currentSurah:$aNum')) {
        return false;
      }
      if (_filterQuery.trim().isEmpty) return true;
      final q = _filterQuery.trim().toLowerCase();
      final ayaText = (a['search_aya'] ?? a['aya'] ?? '').toString().toLowerCase();
      final tafsirText = (a[_selectedTafsirKey] ?? '').toString().toLowerCase();
      final aNumStr = aNum.toString();
      return ayaText.contains(q) || tafsirText.contains(q) || aNumStr == q;
    }).toList();

    final tafsirShortName = _selectedTafsirKey == 'tafsir_moysar'
        ? (isArabic ? 'الميسر' : 'Al-Muyassar')
        : _selectedTafsirKey == 'tafsir_saadi'
            ? (isArabic ? 'السعدي' : 'As-Saadi')
            : (isArabic ? 'البغوي' : 'Al-Baghawi');

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        top: _showTopBars,
        bottom: true,
        child: Stack(
          children: [
            Column(
              children: [
                // ── Animated Collapsing Header (AppBar + Surah Bar + Tafsir Switcher + Search Bar) ──
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 240),
                  firstCurve: Curves.easeOutCubic,
                  secondCurve: Curves.easeOutCubic,
                  crossFadeState: _showTopBars ? CrossFadeState.showFirst : CrossFadeState.showSecond,
                  firstChild: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Custom Top Navigation Bar
                      Container(
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
                                    isArabic ? 'جامع التفاسير القرآنية' : 'Quranic Tafsir Library',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.5,
                                      fontFamily: isArabic ? 'Amiri' : null,
                                    ),
                                  ),
                                  Text(
                                    isArabic ? 'التفسير الميسر • السعدي • البغوي' : 'Al-Muyassar • As-Saadi • Al-Baghawi',
                                    style: TextStyle(
                                      color: textColor.withValues(alpha: 0.65),
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _showOnlyBookmarks ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                color: _showOnlyBookmarks ? _getGoldAccent() : textColor,
                                size: 21,
                              ),
                              tooltip: isArabic ? 'الآيات المحفوظة' : 'Bookmarked Ayahs',
                              onPressed: () {
                                setState(() => _showOnlyBookmarks = !_showOnlyBookmarks);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.tune_rounded, size: 21),
                              color: _getGoldAccent(),
                              tooltip: isArabic ? 'تخصيص المظهر وحجم الخط' : 'Display & Font Settings',
                              onPressed: () => _openDisplaySettingsSheet(context, locale),
                            ),
                          ],
                        ),
                      ),
          // ─────────────────────────────────────────────────────────────
          // 1. Crystal Clear, Prominent Surah & Ayah Controller Bar
          // ─────────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF1B8A6B).withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Previous Surah Button (With Actual Surah Name!)
                  IgnorePointer(
                    ignoring: _currentSurah <= 1,
                    child: LiquidPressable(
                      onTap: () {
                        if (_currentSurah > 1) {
                          _switchSurah(_currentSurah - 1);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: _readerTheme == TafsirTheme.night || _readerTheme == TafsirTheme.emerald
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFE8F2EE),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chevron_left_rounded,
                              size: 16,
                              color: _currentSurah > 1 ? const Color(0xFF1B8A6B) : Colors.grey,
                            ),
                            if (_currentSurah > 1) ...[
                              const SizedBox(width: 2),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 58),
                                child: Text(
                                  prevSurahAr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B8A6B),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Center: Surah Selection Pill
                  Expanded(
                    child: LiquidPressable(
                      onTap: () => _openSurahPickerModal(context, locale),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F4E3D), Color(0xFF1B8A6B)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1B8A6B).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isArabic ? 'سورة $surahAr' : 'Surah $surahEn',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Amiri',
                                    ),
                                  ),
                                  Text(
                                    isArabic
                                        ? '${_ayahs.length} آية • تغيير السورة ▼'
                                        : '${_ayahs.length} Ayahs • Change ▼',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Next Surah Button (With Actual Surah Name!)
                  IgnorePointer(
                    ignoring: _currentSurah >= 114,
                    child: LiquidPressable(
                      onTap: () {
                        if (_currentSurah < 114) {
                          _switchSurah(_currentSurah + 1);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: _readerTheme == TafsirTheme.night || _readerTheme == TafsirTheme.emerald
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFE8F2EE),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_currentSurah < 114) ...[
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 58),
                                child: Text(
                                  nextSurahAr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B8A6B),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                            ],
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 16,
                              color: _currentSurah < 114 ? const Color(0xFF1B8A6B) : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─────────────────────────────────────────────────────────────
          // 2. Classical 3-Tafsir Volume Switcher (With Pulsing Live Dot)
          // ─────────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
            child: Container(
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                color: _readerTheme == TafsirTheme.night || _readerTheme == TafsirTheme.emerald
                    ? const Color(0xFF0C1412)
                    : const Color(0xFFE8EFEA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor, width: 0.8),
              ),
              child: Row(
                children: _kTafsirOptions.map((opt) {
                  final isSelected = _selectedTafsirKey == opt['key'];
                  return Expanded(
                    child: LiquidPressable(
                      onTap: () {
                        if (_selectedTafsirKey != opt['key']) {
                          setState(() => _selectedTafsirKey = opt['key']!);
                          _saveReadingProgress();
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? cardBg : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                          border: isSelected
                              ? Border.all(
                                  color: const Color(0xFFC68A2E).withValues(alpha: 0.4),
                                  width: 1,
                                )
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.12),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSelected) ...[
                                  AnimatedBuilder(
                                    animation: _dotPulseController,
                                    builder: (context, _) => Transform.scale(
                                      scale: _dotScale.value,
                                      child: Opacity(
                                        opacity: _dotOpacity.value,
                                        child: Container(
                                          width: 6,
                                          height: 6,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFC68A2E),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Color(0x88C68A2E),
                                                blurRadius: 4,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  isArabic ? opt['titleAr']! : opt['titleEn']!,
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFFD4AF37) : textColor.withValues(alpha: 0.65),
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    fontFamily: isArabic ? 'Amiri' : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),
                            Text(
                              isArabic ? opt['badgeAr']! : opt['titleEn']!,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFFC68A2E) : Colors.grey.withValues(alpha: 0.7),
                                fontSize: 9.5,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // ─────────────────────────────────────────────────────────────
          // 3. Ayah Controller & In-Surah Keyword Search Row
          // ─────────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            child: Row(
              children: [
                // Direct "Jump to Ayah" Controller Button
                LiquidPressable(
                  onTap: () => _openAyahJumperModal(context, locale),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC68A2E).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFC68A2E).withValues(alpha: 0.35),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.gps_fixed_rounded, size: 14, color: Color(0xFFC68A2E)),
                        const SizedBox(width: 5),
                        Text(
                          isArabic ? 'الآية: $_activeVisibleAyah / ${_ayahs.length}' : 'Ayah: $_activeVisibleAyah/${_ayahs.length}',
                          style: const TextStyle(
                            color: Color(0xFFC68A2E),
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Search within Ayah/Tafsir Text
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor),
                    ),
                    child: TextField(
                      controller: _searchFilterController,
                      onChanged: (val) => setState(() => _filterQuery = val),
                      style: TextStyle(color: textColor, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: isArabic ? 'بحث في آيات وتفسير السورة...' : 'Search within this surah...',
                        hintStyle: TextStyle(
                          color: Colors.grey.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF1B8A6B)),
                        suffixIcon: _filterQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 15),
                                onPressed: () {
                                  _searchFilterController.clear();
                                  setState(() => _filterQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

                    ],
                  ),
                  secondChild: const SizedBox(width: double.infinity, height: 0),
                ),

                // ─────────────────────────────────────────────────────────────
                // 4. Ayah & Tafsir Hero List (Wrapped in NotificationListener)
                // ─────────────────────────────────────────────────────────────
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
                          if (!_showTopBars) {
                            setState(() => _showTopBars = true);
                          }
                          return false;
                        }

                        if (delta > 0) {
                          // Scrolling down (reading deeper)
                          _accumulatedDownwardScroll += delta;
                          _accumulatedUpwardScroll = 0.0;
                          if (_accumulatedDownwardScroll >= 25.0 && _showTopBars) {
                            setState(() => _showTopBars = false);
                          }
                        } else if (delta < 0) {
                          // Scrolling up (returning backwards)
                          _accumulatedUpwardScroll += delta.abs();
                          _accumulatedDownwardScroll = 0.0;
                          // Require deliberate upward scroll of >= 45px
                          if (_accumulatedUpwardScroll >= 45.0 && !_showTopBars) {
                            setState(() => _showTopBars = true);
                          }
                        }
                      }
                      return false;
                    },
                    child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1B8A6B)),
                  )
                : displayAyahs.isEmpty
                    ? Center(
                        child: Text(
                          _showOnlyBookmarks
                              ? (isArabic ? 'لا توجد آيات محفوظة في هذه السورة' : 'No bookmarked verses in this surah')
                              : (isArabic ? 'لم يتم العثور على نتائج للبحث' : 'No matching verses found'),
                          style: TextStyle(color: textColor, fontSize: 13),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                        itemCount: displayAyahs.length + (_currentSurah != 1 && _currentSurah != 9 ? 1 : 0),
                        itemBuilder: (context, idx) {
                          // Bismillah Header
                          if (_currentSurah != 1 && _currentSurah != 9 && idx == 0) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFC68A2E).withValues(alpha: 0.3),
                                  width: 0.8,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                                  style: TextStyle(
                                    fontFamily: 'Amiri',
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B8A6B),
                                  ),
                                ),
                              ),
                            );
                          }

                          final actualIdx = (_currentSurah != 1 && _currentSurah != 9) ? idx - 1 : idx;
                          final ayah = displayAyahs[actualIdx];
                          final aNum = ayah['aya_num'] as int;
                          final ayaText = ayah['aya'] as String? ?? '';
                          final tafsirText = (ayah[_selectedTafsirKey] as String?)?.trim() ?? '';

                          final tafsirOption = _kTafsirOptions.firstWhere(
                            (o) => o['key'] == _selectedTafsirKey,
                            orElse: () => _kTafsirOptions.first,
                          );
                          final tafsirTitle = isArabic ? tafsirOption['titleAr']! : tafsirOption['titleEn']!;
                          final scholarDetail = isArabic ? tafsirOption['scholarAr']! : tafsirOption['scholarEn']!;

                          final isBookmarked = _bookmarkedAyahs.contains('$_currentSurah:$aNum');
                          final isPlayingThis = _playingAyahNum == aNum && _isPlayingAudio;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: borderColor,
                                width: 1.1,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Top Meta Header (Ayah Badge + Audio Player + Actions)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1B8A6B).withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(0xFF1B8A6B).withValues(alpha: 0.3),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(Icons.menu_book_rounded, size: 12, color: Color(0xFF1B8A6B)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  isArabic ? 'الآية $aNum' : 'Ayah $aNum',
                                                  style: const TextStyle(
                                                    color: Color(0xFF1B8A6B),
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),

                                          // Audio Recitation Listen Button
                                          LiquidPressable(
                                            onTap: () => _playAyahAudio(
                                              _currentSurah,
                                              aNum,
                                              absoluteAyahIndex: ayah['id_quran_ayat'] as int?,
                                            ),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                              decoration: BoxDecoration(
                                                color: isPlayingThis
                                                    ? _getGoldAccent()
                                                    : _getGoldAccent().withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: _getGoldAccent().withValues(alpha: 0.35),
                                                  width: 0.8,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  if (_isBufferingAudio && _playingAyahNum == aNum) ...[
                                                    SizedBox(
                                                      width: 12,
                                                      height: 12,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: _getGoldAccent(),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      isArabic ? 'تحميل...' : 'Buffering...',
                                                      style: TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: _getGoldAccent(),
                                                      ),
                                                    ),
                                                  ] else ...[
                                                    Icon(
                                                      isPlayingThis ? Icons.stop_rounded : Icons.volume_up_rounded,
                                                      size: 13,
                                                      color: isPlayingThis ? Colors.black : _getGoldAccent(),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      isPlayingThis
                                                          ? (isArabic ? 'إيقاف' : 'استماع')
                                                          : (isArabic ? 'استماع' : 'Listen'),
                                                      style: TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: isPlayingThis ? Colors.black : _getGoldAccent(),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      // Actions: Bookmark & Copy & Share
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          // Bookmark Toggle Button
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            icon: Icon(
                                              isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                                              size: 20,
                                              color: isBookmarked ? _getGoldAccent() : Colors.grey,
                                            ),
                                            onPressed: () => _toggleBookmark(_currentSurah, aNum),
                                          ),
                                          const SizedBox(width: 10),

                                          LiquidPressable(
                                            onTap: () => _copyAyahAndTafsir(ayah, tafsirTitle, tafsirText, locale),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(7),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.copy_rounded, size: 12, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isArabic ? 'نسخ' : 'Copy',
                                                    style: const TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          LiquidPressable(
                                            onTap: () => _shareAyahAndTafsir(ayah, tafsirTitle, tafsirText),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.withValues(alpha: 0.08),
                                                borderRadius: BorderRadius.circular(7),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(Icons.share_rounded, size: 12, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isArabic ? 'مشاركة' : 'Share',
                                                    style: const TextStyle(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  // Sacred Verse Container
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _getAyahBoxBgColor(),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _getAyahBoxBorderColor(),
                                        width: 0.9,
                                      ),
                                    ),
                                    child: Text(
                                      '﴿ $ayaText ﴾',
                                      textAlign: TextAlign.justify,
                                      textDirection: TextDirection.rtl,
                                      style: TextStyle(
                                        fontFamily: 'Amiri',
                                        fontSize: (_tafsirFontSize + 3.0).clamp(17.0, 31.0),
                                        fontWeight: FontWeight.bold,
                                        height: 1.85,
                                        color: _getAyahTextColor(),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 14),

                                  // Scholar Header Bar
                                  Row(
                                    children: [
                                      Container(
                                        width: 3.5,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFC68A2E),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        tafsirTitle,
                                        style: const TextStyle(
                                          fontFamily: 'Amiri',
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFC68A2E),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          '•  $scholarDetail',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            color: textColor.withValues(alpha: 0.65),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Large, Beautiful Tafseer Text
                                  Text(
                                    tafsirText.isNotEmpty
                                        ? tafsirText
                                        : (isArabic ? 'لا يتوفر نص تفسير لهذه الآية' : 'No commentary available for this verse'),
                                    textAlign: TextAlign.justify,
                                    textDirection: isArabic ? TextDirection.rtl : null,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: _tafsirFontSize,
                                      height: 1.8,
                                      fontWeight: FontWeight.w500,
                                      fontFamily: isArabic ? 'Amiri' : null,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),

              // ── Floating Restore Pill when Top Bars are Hidden ──
            if (!_showTopBars)
              Positioned(
                top: 6,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _showTopBars = true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: cardBg.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF1B8A6B).withValues(alpha: 0.40),
                          width: 1,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF1B8A6B)),
                          const SizedBox(width: 4),
                          Text(
                            isArabic ? 'سورة $surahAr • $tafsirShortName' : 'Surah $surahEn • $tafsirShortName',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              fontFamily: isArabic ? 'Amiri' : null,
                            ),
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
    );
  }
}
