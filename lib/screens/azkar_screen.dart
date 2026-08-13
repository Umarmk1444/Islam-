// =============================================================================
// FILE PATH : lib/screens/azkar_screen.dart
//
// Master Azkar screen with TWO tabs:
//   Tab 1 — الأذكار اليومية  (Daily Azkar from `azkar` table)
//   Tab 2 — حصن المسلم       (Hisn Al-Muslim from `hisn_almuslim` table)
//
// Features:
//   • 12-hour smart persistence (counts auto-reset after 12h)
//   • 4-language localization wrapper (ar / en / am / om)
//   • Interactive counter cards with haptic feedback
//   • Premium UI with AppTheme.notifier color integration
// =============================================================================

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import '../l10n/app_localizations.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:share_plus/share_plus.dart';
import '../core/database/database_helper.dart';
import '../core/constants/app_colors.dart';
import '../theme_notifier.dart';
import '../language_notifier.dart';

// ═════════════════════════════════════════════════════════════════════════════
//  SECTION 1 — DATA MODELS
// ═════════════════════════════════════════════════════════════════════════════

/// Local state wrapper for a single Zekr from the `azkar` table.
class ZekrModel {
  final int id;
  final int numZekr;
  final String type;
  final String zekr;
  final String zekrInfo;
  final String zekrSound;
  int currentCount;

  ZekrModel({
    required this.id,
    required this.numZekr,
    required this.type,
    required this.zekr,
    required this.zekrInfo,
    required this.zekrSound,
  }) : currentCount = numZekr;

  factory ZekrModel.fromMap(Map<String, dynamic> row) {
    return ZekrModel(
      id: row['id'] as int? ?? 0,
      numZekr: row['num_zekr'] as int? ?? 1,
      type: (row['type'] as String?) ?? '',
      zekr: (row['zekr'] as String?) ?? '',
      zekrInfo: (row['zekr_info'] as String?) ?? '',
      zekrSound: (row['zekr_sound'] as String?) ?? '',
    );
  }

  bool get isCompleted => currentCount <= 0;
  void reset() => currentCount = numZekr;
}

/// A single entry from the `hisn_almuslim` table.
class HisnModel {
  final int id;
  final String type;
  final String title;
  final String zkr;
  final String hadith;
  final String vocabulary;
  final String sharhHadith;

  const HisnModel({
    required this.id,
    required this.type,
    required this.title,
    required this.zkr,
    required this.hadith,
    required this.vocabulary,
    required this.sharhHadith,
  });

  factory HisnModel.fromMap(Map<String, dynamic> row) {
    return HisnModel(
      id: row['id'] as int? ?? 0,
      type: (row['type'] as String?) ?? '',
      title: (row['title'] as String?) ?? '',
      zkr: (row['zkr'] as String?) ?? '',
      hadith: (row['hadith'] as String?) ?? '',
      vocabulary: (row['vocabulary'] as String?) ?? '',
      sharhHadith: (row['sharh_hadith'] as String?) ?? '',
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SECTION 2 — LOCALIZATION HELPERS
// ═════════════════════════════════════════════════════════════════════════════

/// 4-language localization wrapper for Zekr virtue / info text.
///
/// Architecture: When full translation data becomes available (e.g. a JSON
/// map keyed by ID → { ar, en, am, om }), swap the body of this method.
/// For now, Arabic text is returned as-is and a note is shown for other
/// languages indicating that translation is pending.
String getLocalizedZekrInfo(String arabicInfo, String langCode) {
  if (arabicInfo.isEmpty) return '';
  switch (langCode) {
    case 'ar':
      return arabicInfo;
    case 'en':
      // Replace with actual English translation lookup.
      return arabicInfo; // Fallback to Arabic until translations are provided.
    case 'am':
      // Replace with actual Amharic translation lookup.
      return arabicInfo;
    case 'om':
      // Replace with actual Oromo translation lookup.
      return arabicInfo;
    default:
      return arabicInfo;
  }
}

/// 4-language localization wrapper for Hisn Al-Muslim vocabulary / explanation.
String getLocalizedHisnText(String arabicText, String langCode) {
  if (arabicText.isEmpty) return '';
  // Same architecture: returns Arabic for now, ready for full translation map.
  return arabicText;
}

/// Static UI string translations for the Azkar screen.
class _AzkarL10n {
  static String dailyAzkar(String lang) {
    const m = {
      'ar': 'الأذكار اليومية',
      'en': 'Daily Azkar',
      'am': 'የዕለት አዝካር',
      'om': 'Azkaara Guyyaa'
    };
    return m[lang] ?? m['ar']!;
  }

  static String hisnAlMuslim(String lang) {
    const m = {
      'ar': 'حصن المسلم',
      'en': 'Hisn Al-Muslim',
      'am': 'ሒስኑል ሙስሊም',
      'om': 'Hisnul Muslim'
    };
    return m[lang] ?? m['ar']!;
  }

  static String azkar(String lang) {
    const m = {'ar': 'الأذكار', 'en': 'Azkar', 'am': 'አዝካር', 'om': 'Azkaara'};
    return m[lang] ?? m['ar']!;
  }

  static String reset(String lang) {
    const m = {'ar': 'إعادة', 'en': 'Reset', 'am': 'ዳግም', 'om': 'Haaromsi'};
    return m[lang] ?? m['ar']!;
  }

  static String searchHint(String lang) {
    const m = {
      'ar': 'ابحث في حصن المسلم...',
      'en': 'Search Hisn Al-Muslim...',
      'am': 'ፈልግ...',
      'om': 'Barbaadi...'
    };
    return m[lang] ?? m['ar']!;
  }

  static String vocabulary(String lang) {
    const m = {
      'ar': 'معاني الكلمات',
      'en': 'Vocabulary',
      'am': 'የቃላት ትርጉም',
      'om': 'Hiika Jechootaa'
    };
    return m[lang] ?? m['ar']!;
  }

  static String explanation(String lang) {
    const m = {
      'ar': 'شرح الحديث',
      'en': 'Explanation',
      'am': 'ማብራሪያ',
      'om': 'Ibsa'
    };
    return m[lang] ?? m['ar']!;
  }

  static String hadithRef(String lang) {
    const m = {
      'ar': 'التخريج',
      'en': 'Hadith Reference',
      'am': 'ሐዲስ ማጣቀሻ',
      'om': 'Hadiisa'
    };
    return m[lang] ?? m['ar']!;
  }

  static String noResults(String lang) {
    const m = {
      'ar': 'لا توجد نتائج',
      'en': 'No results',
      'am': 'ውጤት የለም',
      'om': 'Bu\'aa hin argamne'
    };
    return m[lang] ?? m['ar']!;
  }

  static String mashAllah(String lang) {
    const m = {
      'ar': 'ما شاء الله',
      'en': 'Masha Allah',
      'am': 'ማሻአላህ',
      'om': 'Maa shaa Allaah'
    };
    return m[lang] ?? m['ar']!;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SECTION 3 — 12-HOUR PERSISTENCE MANAGER
// ═════════════════════════════════════════════════════════════════════════════

class _AzkarPersistence {
  static const Duration _resetDuration = Duration(hours: 12);
  static const String _timestampPrefix = 'zekr_timestamp_';
  static const String _countPrefix = 'zekr_count_';

  /// Save the current count for a specific zekr and update the category timestamp.
  static Future<void> saveCount(
      int zekrId, int count, String categoryType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_countPrefix$zekrId', count);
    await prefs.setInt(
      '$_timestampPrefix$categoryType',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Check if saved counts for a category are still valid (< 12 hours old).
  static Future<bool> isCategoryFresh(String categoryType) async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('$_timestampPrefix$categoryType');
    if (timestamp == null) return false;

    final savedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final elapsed = DateTime.now().difference(savedTime);
    return elapsed < _resetDuration;
  }

  /// Load the saved count for a zekr. Returns null if not found.
  static Future<int?> loadCount(int zekrId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_countPrefix$zekrId');
  }

  /// Clear all saved counts for a category's zekrs.
  static Future<void> clearCategory(
      String categoryType, List<int> zekrIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_timestampPrefix$categoryType');
    for (final id in zekrIds) {
      await prefs.remove('$_countPrefix$id');
    }
  }
}

final ValueNotifier<bool> _showAutoPlayNotifier = ValueNotifier(false);
final ValueNotifier<bool> _isAutoPlayingNotifier = ValueNotifier(false);
final ValueNotifier<double> _fontSizeNotifier = ValueNotifier(24.0);

void showGlobalFontSizeDialog(BuildContext context) {
  final themeVal = AppTheme.notifier.value;
  final bg = AppTheme.getCardBgColor(themeVal);
  final txt = AppTheme.getMainTextColor(themeVal);
  final primary = AppTheme.getPrimaryColor(themeVal);
  showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ValueListenableBuilder<double>(
            valueListenable: _fontSizeNotifier,
            builder: (context, fontSize, _) {
              return Container(
                height: 150,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('حجم الخط',
                        style: TextStyle(
                            fontFamily: 'Amiri', fontSize: 18, color: txt)),
                    Slider(
                      value: fontSize,
                      min: 16.0,
                      max: 40.0,
                      activeColor: primary,
                      onChanged: (val) => _fontSizeNotifier.value = val,
                    ),
                  ],
                ),
              );
            });
      });
}

VoidCallback? _onAutoPlayTap;

// ═════════════════════════════════════════════════════════════════════════════
//  SECTION 4 — MAIN AZKAR SCREEN (2-TAB ARCHITECTURE)
// ═════════════════════════════════════════════════════════════════════════════

class AzkarScreen extends StatefulWidget {
  const AzkarScreen({super.key});

  @override
  State<AzkarScreen> createState() => _AzkarScreenState();
}

class _AzkarScreenState extends State<AzkarScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<_DailyAzkarTabState> _dailyTabKey =
      GlobalKey<_DailyAzkarTabState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index != 0) {
        _showAutoPlayNotifier.value = false;
        if (_isAutoPlayingNotifier.value && _onAutoPlayTap != null) {
          _onAutoPlayTap!();
        }
      } else {
        // Will be updated by _DailyAzkarTab rebuild or category change.
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final appBarBg = AppTheme.getAppBarBgColor(theme);
        final appBarText = AppTheme.getAppBarTextColor(theme);
        final borderClr = AppTheme.getBorderColor(theme);
        final screenBg = AppTheme.getScreenBgColor(theme);
        final lang = AppLanguage.notifier.value.languageCode;

        return Scaffold(
          backgroundColor: screenBg,
          appBar: AppBar(
            backgroundColor: appBarBg,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: appBarText, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              _AzkarL10n.azkar(lang),
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: appBarText,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.format_size_rounded,
                    color: appBarText, size: 24),
                onPressed: () => showGlobalFontSizeDialog(context),
              ),
              ValueListenableBuilder<bool>(
                valueListenable: _showAutoPlayNotifier,
                builder: (context, show, child) {
                  if (!show || _tabController.index != 0) {
                    return const SizedBox.shrink();
                  }
                  return ValueListenableBuilder<bool>(
                    valueListenable: _isAutoPlayingNotifier,
                    builder: (context, isPlaying, child) {
                      return IconButton(
                        icon: Icon(isPlaying
                            ? Icons.pause_circle_rounded
                            : Icons.playlist_play_rounded),
                        color: isPlaying ? AppColors.emeraldLight : appBarText,
                        iconSize: 28,
                        onPressed: () {
                          if (_onAutoPlayTap != null) _onAutoPlayTap!();
                        },
                      );
                    },
                  );
                },
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: borderClr,
              indicatorWeight: 2.5,
              labelColor: appBarText,
              unselectedLabelColor: appBarText.withValues(alpha: 0.5),
              labelStyle: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              tabs: [
                Tab(text: _AzkarL10n.dailyAzkar(lang)),
                Tab(text: _AzkarL10n.hisnAlMuslim(lang)),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _DailyAzkarTab(key: _dailyTabKey),
              const _HisnAlMuslimTab(),
            ],
          ),
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  TAB 1 — DAILY AZKAR (with 12h persistence)
// ═════════════════════════════════════════════════════════════════════════════

class _DailyAzkarTab extends StatefulWidget {
  const _DailyAzkarTab({super.key});

  @override
  State<_DailyAzkarTab> createState() => _DailyAzkarTabState();
}

class _DailyAzkarTabState extends State<_DailyAzkarTab>
    with AutomaticKeepAliveClientMixin {
  List<String> _categories = [];
  int _selectedCategoryIndex = 0;
  List<ZekrModel> _azkar = [];
  bool _isLoading = true;

  late final AudioPlayer _audioPlayer;
  late final PageController _pageController;
  int? _playingZekrId;
  Timer? _sleepTimer;

  int get _totalCompleted => _azkar.where((z) => z.isCompleted).length;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _audioPlayer = AudioPlayer();
    _onAutoPlayTap = _toggleAutoPlay;
    int? lastIndex;
    _audioPlayer.currentIndexStream.listen((index) {
      final last = lastIndex;
      if (index != null && last != null && index != last) {
        _audioPlayer.pause();
        if (_isAutoPlayingNotifier.value) {
          _handleAutoPlayNext();
        } else {
          if (mounted) setState(() => _playingZekrId = null);

          // If the user pressed Next/Prev in OS explicitly while auto-play is off
          int currentPage = _pageController.page?.round() ?? 0;
          if (index > last && currentPage < _azkar.length - 1) {
            _pageController.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut);
            Future.delayed(const Duration(milliseconds: 300),
                () => _toggleAudio(_azkar[currentPage + 1]));
          } else if (index < last && currentPage > 0) {
            _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut);
            Future.delayed(const Duration(milliseconds: 300),
                () => _toggleAudio(_azkar[currentPage - 1]));
          }
        }
      }
      lastIndex = index;
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        if (_isAutoPlayingNotifier.value) {
          _handleAutoPlayNext();
        } else {
          if (mounted) setState(() => _playingZekrId = null);
        }
      }
    });

    _loadCategories();
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _pageController.dispose();
    _audioPlayer.dispose();
    if (_onAutoPlayTap == _toggleAutoPlay) _onAutoPlayTap = null;
    super.dispose();
  }

  Future<void> _handleAutoPlayNext() async {
    if (!mounted ||
        !_pageController.hasClients ||
        !_isAutoPlayingNotifier.value) {
      return;
    }
    int currentIndex = _pageController.page?.round() ?? 0;
    if (currentIndex >= _azkar.length) return;

    final zekr = _azkar[currentIndex];

    if (!zekr.isCompleted) {
      setState(() => zekr.currentCount--);
      _AzkarPersistence.saveCount(
          zekr.id, zekr.currentCount, _categories[_selectedCategoryIndex]);
    }

    if (!zekr.isCompleted) {
      int initialIdx = currentIndex > 0 ? 1 : 0;
      await _audioPlayer.seek(Duration.zero, index: initialIdx);
      await _audioPlayer.play();
    } else {
      if (currentIndex < _azkar.length - 1) {
        await _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
        _playCurrentAutoZekr();
      } else {
        _isAutoPlayingNotifier.value = false;
        if (mounted) setState(() => _playingZekrId = null);
        HapticFeedback.heavyImpact();
      }
    }
  }

  Future<void> _toggleAutoPlay() async {
    if (_isAutoPlayingNotifier.value) {
      _isAutoPlayingNotifier.value = false;
      await _audioPlayer.pause();
    } else {
      _isAutoPlayingNotifier.value = true;
      int currentIndex = _pageController.page?.round() ?? 0;
      if (currentIndex < _azkar.length &&
          _playingZekrId == _azkar[currentIndex].id) {
        await _audioPlayer.play();
      } else {
        _playCurrentAutoZekr();
      }
    }
  }

  Future<void> _playCurrentAutoZekr() async {
    if (!mounted ||
        !_pageController.hasClients ||
        !_isAutoPlayingNotifier.value) {
      return;
    }
    int currentIndex = _pageController.page?.round() ?? 0;
    if (currentIndex >= _azkar.length) {
      _isAutoPlayingNotifier.value = false;
      return;
    }

    final zekr = _azkar[currentIndex];

    if (zekr.isCompleted) {
      if (currentIndex < _azkar.length - 1) {
        await _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut);
        _playCurrentAutoZekr();
      } else {
        _isAutoPlayingNotifier.value = false;
        if (mounted) setState(() => _playingZekrId = null);
      }
      return;
    }

    if (mounted) setState(() => _playingZekrId = zekr.id);

    String rawSound = zekr.zekrSound;
    // 1. Remove ANY hidden whitespace, tabs, or newlines
    String soundName = rawSound.replaceAll(RegExp(r'\s+'), '');

    if (soundName.isEmpty) {
      await Future.delayed(const Duration(seconds: 2));
      if (_isAutoPlayingNotifier.value) _handleAutoPlayNext();
      return;
    }

    // 2. Strip any existing path prefixes to start clean
    soundName = soundName.replaceAll('assets/audio/', '');
    soundName = soundName.replaceAll('assets/', '');
    soundName = soundName.replaceAll('/', '');

    // 3. Force the correct extension
    if (!soundName.endsWith('.mp3')) {
      soundName = '$soundName.mp3';
    }

    final List<String> localFiles = [
      'azkarsabah.mp3',
      'azkarmassa.mp3',
      'seb7a.mp3',
      'wrong_ans.mp3',
      'coreec_ans_1.mp3',
      'coreec_ans_2.mp3',
      'azkartone.mp3'
    ];

    Uri audioUri;
    if (localFiles.contains(soundName)) {
      audioUri = Uri.parse('asset:///assets/audio/$soundName');
    } else {
      audioUri = Uri.parse('https://raw.githubusercontent.com/Umarmk1444/quran_zone_audio/main/$soundName');
    }

    debugPrint("🚀 FORCE PLAYING: $audioUri");

    try {
      await _audioPlayer.setAudioSource(AudioSource.uri(
        audioUri,
        tag: MediaItem(
          id: zekr.id.toString(),
          title: zekr.type.isNotEmpty ? zekr.type : 'أذكار',
          album: 'حصن المسلم',
        ),
      ));
      await _audioPlayer.play();
    } catch (e) {
      debugPrint("🚨 AUDIO PLAY ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'تعذر تشغيل الملف الصوتي',
              style: TextStyle(fontFamily: 'Amiri', fontSize: 16),
              textAlign: TextAlign.center,
            ),
            backgroundColor: AppTheme.getPrimaryColor(AppTheme.notifier.value),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      await Future.delayed(const Duration(seconds: 1));
      if (_isAutoPlayingNotifier.value) _handleAutoPlayNext();
    }
  }

  Future<void> _loadCategories() async {
    try {
      final db = await DatabaseHelper.instance.database;

      final rows = await db.rawQuery(
        "SELECT MIN(id) as first_id, type FROM azkar WHERE type IS NOT NULL AND type != '' GROUP BY type ORDER BY first_id",
      );
      final cats = rows
          .map((r) => (r['type'] as String?) ?? '')
          .where((t) => t.isNotEmpty)
          .toList();

      cats.remove('دعاء بعد الصلاة');
      cats.insert(0, 'دعاء بعد الصلاة');
      if (mounted) {
        setState(() => _categories = cats);
        if (cats.isNotEmpty) {
          await _loadAzkarForCategory(cats[0]);
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error loading azkar categories: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAzkarForCategory(String category) async {
    setState(() => _isLoading = true);
    final isMorningOrEvening =
        category == 'أذكار الصباح' || category == 'أذكار المساء';
    _showAutoPlayNotifier.value = isMorningOrEvening;

    try {
      List<ZekrModel> azkarList = [];

      if (category == 'دعاء بعد الصلاة') {
        azkarList = duaAfterSalahData.map((e) => ZekrModel.fromMap(e)).toList();
      } else {
        final db = await DatabaseHelper.instance.database;
        final rows = await db.rawQuery(
          "SELECT id, num_zekr, type, zekr, zekr_info, zekr_sound "
          "FROM azkar WHERE type = ? ORDER BY id",
          [category],
        );
        azkarList = rows.map((r) => ZekrModel.fromMap(r)).toList();
      }

      final isFresh = await _AzkarPersistence.isCategoryFresh(category);
      if (isFresh) {
        for (final z in azkarList) {
          final savedCount = await _AzkarPersistence.loadCount(z.id);
          if (savedCount != null) {
            z.currentCount = savedCount.clamp(0, z.numZekr);
          }
        }
      }

      if (mounted) {
        setState(() {
          _azkar = azkarList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading azkar: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onCategorySelected(int index) {
    if (index == _selectedCategoryIndex) return;

    // Stop autoplay when changing categories
    if (_isAutoPlayingNotifier.value) {
      _isAutoPlayingNotifier.value = false;
      _audioPlayer.stop();
      _playingZekrId = null;
    }

    setState(() => _selectedCategoryIndex = index);
    if (_pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
    _loadAzkarForCategory(_categories[index]);
  }

  void _onZekrTap(int index) {
    final zekr = _azkar[index];
    if (zekr.isCompleted) return;

    setState(() => zekr.currentCount--);

    _AzkarPersistence.saveCount(
      zekr.id,
      zekr.currentCount,
      _categories[_selectedCategoryIndex],
    );

    if (zekr.isCompleted) {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted &&
            _pageController.hasClients &&
            index < _azkar.length - 1) {
          // If auto playing, don't interrupt with manual page jump
          if (!_isAutoPlayingNotifier.value) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
      });
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _resetAllCounters() {
    final category = _categories[_selectedCategoryIndex];
    final ids = _azkar.map((z) => z.id).toList();

    setState(() {
      for (final z in _azkar) {
        z.reset();
      }
    });

    _AzkarPersistence.clearCategory(category, ids);
    HapticFeedback.mediumImpact();
  }

  Future<void> _toggleAudio(ZekrModel zekr) async {
    if (zekr.zekrSound.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'هذا الذكر لا يحتوي على ملف صوتي',
            style: TextStyle(fontFamily: 'Amiri', fontSize: 16),
            textAlign: TextAlign.center,
          ),
          backgroundColor: AppTheme.getPrimaryColor(AppTheme.notifier.value),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      if (_playingZekrId == zekr.id && !_isAutoPlayingNotifier.value) {
        await _audioPlayer.stop();
        if (mounted) setState(() => _playingZekrId = null);
      } else {
        _isAutoPlayingNotifier.value = false;
        await _audioPlayer.stop();
        if (mounted) setState(() => _playingZekrId = zekr.id);

        String rawSound = zekr.zekrSound;
        String soundName = rawSound
            .replaceAll(RegExp(r'\s+'), '')
            .replaceAll('assets/audio/', '')
            .replaceAll('assets/', '')
            .replaceAll('/', '');
        if (!soundName.endsWith('.mp3')) soundName = '$soundName.mp3';

        final List<String> localFiles = [
          'azkarsabah.mp3',
          'azkarmassa.mp3',
          'seb7a.mp3',
          'wrong_ans.mp3',
          'coreec_ans_1.mp3',
          'coreec_ans_2.mp3',
          'azkartone.mp3'
        ];

        Uri getZekrUri(String name) {
          if (localFiles.contains(name)) {
            return Uri.parse('asset:///assets/audio/$name');
          }
          return Uri.parse('https://raw.githubusercontent.com/Umarmk1444/quran_zone_audio/main/$name');
        }

        List<AudioSource> playlist = [];
        int zekrIndex = _azkar.indexOf(zekr);

        // 1. Dummy/Prev
        if (zekrIndex > 0) {
          String prevSound = _azkar[zekrIndex - 1]
              .zekrSound
              .replaceAll(RegExp(r'\s+'), '')
              .replaceAll('assets/audio/', '')
              .replaceAll('assets/', '')
              .replaceAll('/', '');
          if (!prevSound.endsWith('.mp3')) prevSound = '$prevSound.mp3';
          playlist.add(AudioSource.uri(
            getZekrUri(prevSound),
            tag: MediaItem(
              id: _azkar[zekrIndex - 1].id.toString(),
              title: _azkar[zekrIndex - 1].type.isNotEmpty
                  ? _azkar[zekrIndex - 1].type
                  : 'أذكار',
              album: 'حصن المسلم',
            ),
          ));
        }

        // 2. Current
        playlist.add(AudioSource.uri(
          getZekrUri(soundName),
          tag: MediaItem(
            id: zekr.id.toString(),
            title: zekr.type.isNotEmpty ? zekr.type : 'أذكار',
            album: 'حصن المسلم',
          ),
        ));

        // 3. Next/Dummy
        if (zekrIndex < _azkar.length - 1) {
          String nextSound = _azkar[zekrIndex + 1]
              .zekrSound
              .replaceAll(RegExp(r'\s+'), '')
              .replaceAll('assets/audio/', '')
              .replaceAll('assets/', '')
              .replaceAll('/', '');
          if (!nextSound.endsWith('.mp3')) nextSound = '$nextSound.mp3';
          playlist.add(AudioSource.uri(
            getZekrUri(nextSound),
            tag: MediaItem(
              id: _azkar[zekrIndex + 1].id.toString(),
              title: _azkar[zekrIndex + 1].type.isNotEmpty
                  ? _azkar[zekrIndex + 1].type
                  : 'أذكار',
              album: 'حصن المسلم',
            ),
          ));
        }

        int initialIdx = zekrIndex > 0 ? 1 : 0;
        await _audioPlayer.setAudioSource(
          ConcatenatingAudioSource(children: playlist),
          initialIndex: initialIdx,
        );
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint("🚨 AUDIO PLAY ERROR: $e");
      if (mounted) {
        setState(() => _playingZekrId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'تعذر تشغيل الملف الصوتي',
              style: TextStyle(fontFamily: 'Amiri', fontSize: 16),
              textAlign: TextAlign.center,
            ),
            backgroundColor: AppTheme.getPrimaryColor(AppTheme.notifier.value),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void showSleepTimerDialog() {
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
            _audioPlayer.pause();
            _isAutoPlayingNotifier.value = false;
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

  void showIndexBottomSheet() {
    if (_azkar.isEmpty) return;

    final themeVal = AppTheme.notifier.value;
    final bg = AppTheme.getCardBgColor(themeVal);
    final txt = AppTheme.getMainTextColor(themeVal);
    final border = AppTheme.getBorderColor(themeVal);

    showModalBottomSheet(
      context: context,
      backgroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            children: [
              Text('فهرس الأذكار',
                  style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: txt)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: _azkar.length,
                  itemBuilder: (context, index) {
                    final zekr = _azkar[index];
                    final isCompleted = zekr.isCompleted;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _pageController.jumpToPage(index);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.emeraldLight.withValues(alpha: 0.1)
                              : border.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isCompleted
                                ? AppColors.emeraldLight
                                : border.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? AppColors.emeraldLight : txt,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMiniPlayer(Color borderClr, Color cardBg, Color mainText,
      Color primaryClr, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              padding:
                  const EdgeInsets.only(left: 8, right: 8, bottom: 6, top: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: borderClr.withValues(alpha: 0.5), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Slider
                    StreamBuilder<Duration>(
                      stream: _audioPlayer.positionStream,
                      builder: (context, snapshot) {
                        final position = snapshot.data ?? Duration.zero;
                        final duration = _audioPlayer.duration ?? Duration.zero;
                        double val = position.inMilliseconds.toDouble();
                        double max = duration.inMilliseconds.toDouble();
                        if (val > max) val = max;
                        if (max <= 0) max = 1;

                        return SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 5),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 10),
                            activeTrackColor: primaryClr,
                            inactiveTrackColor:
                                Colors.white.withValues(alpha: 0.2),
                            thumbColor: primaryClr,
                          ),
                          child: SizedBox(
                            height: 16,
                            child: Slider(
                              value: val,
                              min: 0,
                              max: max,
                              onChanged: (newVal) {
                                _audioPlayer.seek(
                                    Duration(milliseconds: newVal.toInt()));
                              },
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 8),
                    // Controls
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPlayerIconBtn(
                          icon: Icons.close_rounded,
                          color: Colors.white,
                          onTap: () async {
                            await _audioPlayer.stop();
                            if (mounted) setState(() => _playingZekrId = null);
                          },
                        ),
                        _buildPlayerIconBtn(
                          icon: Icons
                              .skip_next_rounded, // Wait, next is skip_next in RTL
                          color: Colors.white,
                          onTap: () {
                            if (_pageController.hasClients) {
                              _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut);
                              Future.delayed(const Duration(milliseconds: 300),
                                  () {
                                if (mounted) {
                                  int index =
                                      _pageController.page?.round() ?? 0;
                                  _toggleAudio(_azkar[index]);
                                }
                              });
                            }
                          },
                        ),
                        StreamBuilder<PlayerState>(
                          stream: _audioPlayer.playerStateStream,
                          builder: (context, snapshot) {
                            final playerState = snapshot.data;
                            final playing = playerState?.playing ?? false;
                            return GestureDetector(
                              onTap: () {
                                if (playing) {
                                  _audioPlayer.pause();
                                } else {
                                  _audioPlayer.play();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: primaryClr,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryClr.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: Icon(
                                  playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            );
                          },
                        ),
                        _buildPlayerIconBtn(
                          icon: Icons.skip_previous_rounded,
                          color: Colors.white,
                          onTap: () {
                            if (_pageController.hasClients) {
                              _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut);
                              Future.delayed(const Duration(milliseconds: 300),
                                  () {
                                if (mounted) {
                                  int index =
                                      _pageController.page?.round() ?? 0;
                                  _toggleAudio(_azkar[index]);
                                }
                              });
                            }
                          },
                        ),
                        _buildPlayerIconBtn(
                          icon: Icons.timer_outlined,
                          color: Colors.white,
                          onTap: showSleepTimerDialog,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerIconBtn(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final pageBg = AppTheme.getPageBgColor(theme);
        final borderClr = AppTheme.getBorderColor(theme);
        final goldText = AppTheme.getGoldTextColor(theme);
        final mainText = AppTheme.getMainTextColor(theme);
        final cardBg = AppTheme.getCardBgColor(theme);
        final primaryClr = AppTheme.getPrimaryColor(theme);
        final isDark = theme == QuranTheme.dark;
        final lang = AppLanguage.notifier.value.languageCode;

        return Stack(
          children: [
            Column(
              children: [
                // ── Category chips ─────────────────────────────────────────
                if (_categories.isNotEmpty)
                  _CategoryChipBar(
                    categories: _categories,
                    selectedIndex: _selectedCategoryIndex,
                    onSelected: _onCategorySelected,
                    borderColor: borderClr,
                    goldTextColor: goldText,
                    pageBgColor: pageBg,
                    isDark: isDark,
                  ),

                // ── Progress bar + Reset ───────────────────────────────────
                if (_azkar.isNotEmpty && !_isLoading)
                  _ProgressRow(
                    completed: _totalCompleted,
                    total: _azkar.length,
                    borderColor: borderClr,
                    pageBgColor: pageBg,
                    goldTextColor: goldText,
                    isDark: isDark,
                    lang: lang,
                    onReset: _resetAllCounters,
                  ),

                // ── Zekr cards (PageView) ──────────────────────────────────
                Expanded(
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: borderClr,
                            strokeWidth: 2,
                          ),
                        )
                      : _azkar.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.auto_stories_outlined,
                                      size: 64,
                                      color: goldText.withValues(alpha: 0.4)),
                                  const SizedBox(height: 16),
                                  Text(
                                    _AzkarL10n.noResults(lang),
                                    style: TextStyle(
                                      fontFamily: 'Amiri',
                                      fontSize: 18,
                                      color: mainText.withValues(alpha: 0.5),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : PageView.builder(
                              controller: _pageController,
                              itemCount: _azkar.length,
                              itemBuilder: (context, index) {
                                final zekr = _azkar[index];
                                final category = _categories.isNotEmpty
                                    ? _categories[_selectedCategoryIndex]
                                    : '';
                                return _ZekrCard(
                                  zekr: zekr,
                                  index: index,
                                  totalAzkar: _azkar.length,
                                  isPlaying: _playingZekrId == zekr.id,
                                  isMiniPlayerVisible: _playingZekrId != null,
                                  onTap: () => _onZekrTap(index),
                                  onPlayPause: () => _toggleAudio(zekr),
                                  onShowIndex: showIndexBottomSheet,
                                  category: category,
                                  borderColor: borderClr,
                                  goldTextColor: goldText,
                                  mainTextColor: mainText,
                                  pageBgColor: pageBg,
                                  cardBgColor: cardBg,
                                  isDark: isDark,
                                  lang: lang,
                                );
                              },
                            ),
                ),
              ],
            ),
            if (_playingZekrId != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.6)
                            : Colors.black.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      )
                    ],
                  ),
                  child: _buildMiniPlayer(
                      borderClr, cardBg, mainText, primaryClr, isDark),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  TAB 2 — HISN AL-MUSLIM
// ═════════════════════════════════════════════════════════════════════════════

class _HisnAlMuslimTab extends StatefulWidget {
  const _HisnAlMuslimTab();

  @override
  State<_HisnAlMuslimTab> createState() => _HisnAlMuslimTabState();
}

class _HisnAlMuslimTabState extends State<_HisnAlMuslimTab>
    with AutomaticKeepAliveClientMixin {
  /// All distinct titles with their type, ordered by first appearance.
  List<Map<String, String>> _allTitles = [];
  List<Map<String, String>> _filteredTitles = [];
  final TextEditingController _searchCtrl = TextEditingController();
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadTitles();
    _searchCtrl.addListener(_filterTitles);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTitles() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery(
        "SELECT MIN(id) as first_id, type, title, COUNT(*) as entry_count "
        "FROM hisn_almuslim GROUP BY title ORDER BY MIN(id)",
      );
      final titles = rows.map((r) {
        return {
          'type': (r['type'] as String?) ?? '',
          'title': (r['title'] as String?) ?? '',
          'count': '${r['entry_count'] ?? 1}',
        };
      }).toList();

      if (mounted) {
        setState(() {
          _allTitles = titles;
          _filteredTitles = titles;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading hisn titles: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterTitles() {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      setState(() => _filteredTitles = _allTitles);
    } else {
      setState(() {
        _filteredTitles =
            _allTitles.where((t) => (t['title'] ?? '').contains(q)).toList();
      });
    }
  }

  void _openHisnDetail(String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _HisnDetailScreen(title: title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final borderClr = AppTheme.getBorderColor(theme);
        final goldText = AppTheme.getGoldTextColor(theme);
        final mainText = AppTheme.getMainTextColor(theme);
        final cardBg = AppTheme.getCardBgColor(theme);
        final isDark = theme == QuranTheme.dark;
        final lang = AppLanguage.notifier.value.languageCode;

        return Column(
          children: [
            // ── Search bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: TextField(
                controller: _searchCtrl,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 15,
                  color: mainText,
                ),
                decoration: InputDecoration(
                  hintText: _AzkarL10n.searchHint(lang),
                  hintStyle: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 14,
                    color: goldText.withValues(alpha: 0.5),
                  ),
                  prefixIcon:
                      Icon(Icons.search_rounded, color: borderClr, size: 22),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close_rounded,
                              color: goldText, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: cardBg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: borderClr.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: borderClr.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderClr, width: 1.5),
                  ),
                ),
              ),
            ),

            // ── Title list ─────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: borderClr,
                        strokeWidth: 2,
                      ),
                    )
                  : _filteredTitles.isEmpty
                      ? Center(
                          child: Text(
                            _AzkarL10n.noResults(lang),
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 16,
                              color: mainText.withValues(alpha: 0.5),
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: _filteredTitles.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _filteredTitles[index];
                            final title = item['title'] ?? '';
                            final type = item['type'] ?? '';
                            final count = item['count'] ?? '1';

                            return _HisnTitleCard(
                              title: title,
                              type: type,
                              entryCount: count,
                              index: index,
                              borderColor: borderClr,
                              goldTextColor: goldText,
                              mainTextColor: mainText,
                              cardBgColor: cardBg,
                              isDark: isDark,
                              onTap: () => _openHisnDetail(title),
                            );
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HisnTitleCard — a single title entry in the Hisn index
// ─────────────────────────────────────────────────────────────────────────────

class _HisnTitleCard extends StatefulWidget {
  const _HisnTitleCard({
    required this.title,
    required this.type,
    required this.entryCount,
    required this.index,
    required this.borderColor,
    required this.goldTextColor,
    required this.mainTextColor,
    required this.cardBgColor,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final String type;
  final String entryCount;
  final int index;
  final Color borderColor;
  final Color goldTextColor;
  final Color mainTextColor;
  final Color cardBgColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_HisnTitleCard> createState() => _HisnTitleCardState();
}

class _HisnTitleCardState extends State<_HisnTitleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
      value: 1.0,
      lowerBound: 0.97,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) => _ctrl.forward(),
      onTapCancel: () => _ctrl.forward(),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) =>
            Transform.scale(scale: _ctrl.value, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: widget.cardBgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.borderColor.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isDark
                    ? Colors.black.withValues(alpha: 0.25)
                    : widget.borderColor.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Number badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.borderColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: widget.borderColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    '${widget.index + 1}',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: widget.goldTextColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Title + type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      widget.title,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.mainTextColor,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.type,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 12,
                        color: widget.goldTextColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Arrow icon
              Icon(
                Icons.chevron_left_rounded,
                color: widget.borderColor.withValues(alpha: 0.5),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  HISN DETAIL SCREEN — shown when a title is tapped
// ═════════════════════════════════════════════════════════════════════════════

class _HisnDetailScreen extends StatefulWidget {
  const _HisnDetailScreen({required this.title});
  final String title;

  @override
  State<_HisnDetailScreen> createState() => _HisnDetailScreenState();
}

class _HisnDetailScreenState extends State<_HisnDetailScreen> {
  List<HisnModel> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.rawQuery(
        "SELECT id, type, title, zkr, hadith, vocabulary, sharh_hadith "
        "FROM hisn_almuslim WHERE title = ? ORDER BY id",
        [widget.title],
      );
      if (mounted) {
        setState(() {
          _entries = rows.map((r) => HisnModel.fromMap(r)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading hisn entries: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<QuranTheme>(
      valueListenable: AppTheme.notifier,
      builder: (context, theme, _) {
        final screenBg = AppTheme.getScreenBgColor(theme);
        final pageBg = AppTheme.getPageBgColor(theme);
        final appBarBg = AppTheme.getAppBarBgColor(theme);
        final appBarText = AppTheme.getAppBarTextColor(theme);
        final borderClr = AppTheme.getBorderColor(theme);
        final goldText = AppTheme.getGoldTextColor(theme);
        final mainText = AppTheme.getMainTextColor(theme);
        final cardBg = AppTheme.getCardBgColor(theme);
        final isDark = theme == QuranTheme.dark;
        final lang = AppLanguage.notifier.value.languageCode;

        return Scaffold(
          backgroundColor: screenBg,
          appBar: AppBar(
            backgroundColor: appBarBg,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded,
                  color: appBarText, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              widget.title,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: appBarText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                      color: borderClr, strokeWidth: 2),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    return _HisnEntryCard(
                      entry: entry,
                      index: index,
                      totalEntries: _entries.length,
                      borderColor: borderClr,
                      goldTextColor: goldText,
                      mainTextColor: mainText,
                      pageBgColor: pageBg,
                      cardBgColor: cardBg,
                      isDark: isDark,
                      lang: lang,
                    );
                  },
                ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _HisnEntryCard — a single zkr entry with hadith, vocab, sharh
// ─────────────────────────────────────────────────────────────────────────────

class _HisnEntryCard extends StatelessWidget {
  const _HisnEntryCard({
    required this.entry,
    required this.index,
    required this.totalEntries,
    required this.borderColor,
    required this.goldTextColor,
    required this.mainTextColor,
    required this.pageBgColor,
    required this.cardBgColor,
    required this.isDark,
    required this.lang,
  });

  final HisnModel entry;
  final int index;
  final int totalEntries;
  final Color borderColor;
  final Color goldTextColor;
  final Color mainTextColor;
  final Color pageBgColor;
  final Color cardBgColor;
  final bool isDark;
  final String lang;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.3)
                  : borderColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header with entry number ────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(15),
                  topRight: Radius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${index + 1} / $totalEntries',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: goldTextColor,
                      ),
                    ),
                  ),
                  Icon(Icons.menu_book_rounded,
                      color: goldTextColor.withValues(alpha: 0.5), size: 20),
                ],
              ),
            ),

            // ── Main Arabic Zkr text ────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: ValueListenableBuilder<double>(
                  valueListenable: _fontSizeNotifier,
                  builder: (context, fontSize, _) {
                    return Text(
                      entry.zkr,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: fontSize,
                        fontWeight: FontWeight.w400,
                        color: mainTextColor,
                        height: 2.0,
                      ),
                    );
                  }),
            ),

            // ── Hadith reference ────────────────────────────────────────
            if (entry.hadith.isNotEmpty)
              _CollapsibleSection(
                title: _AzkarL10n.hadithRef(lang),
                content: getLocalizedHisnText(entry.hadith, lang),
                borderColor: borderColor,
                goldTextColor: goldTextColor,
                mainTextColor: mainTextColor,
                isDark: isDark,
              ),

            // ── Vocabulary (معاني الكلمات) ──────────────────────────────
            if (entry.vocabulary.isNotEmpty)
              _CollapsibleSection(
                title: _AzkarL10n.vocabulary(lang),
                content: getLocalizedHisnText(entry.vocabulary, lang),
                borderColor: borderColor,
                goldTextColor: goldTextColor,
                mainTextColor: mainTextColor,
                isDark: isDark,
              ),

            // ── Sharh Al-Hadith (شرح الحديث) ───────────────────────────
            if (entry.sharhHadith.isNotEmpty)
              _CollapsibleSection(
                title: _AzkarL10n.explanation(lang),
                content: getLocalizedHisnText(entry.sharhHadith, lang),
                borderColor: borderColor,
                goldTextColor: goldTextColor,
                mainTextColor: mainTextColor,
                isDark: isDark,
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _CollapsibleSection — expandable section for hadith, vocab, sharh
// ─────────────────────────────────────────────────────────────────────────────

class _CollapsibleSection extends StatefulWidget {
  const _CollapsibleSection({
    required this.title,
    required this.content,
    required this.borderColor,
    required this.goldTextColor,
    required this.mainTextColor,
    required this.isDark,
  });

  final String title;
  final String content;
  final Color borderColor;
  final Color goldTextColor;
  final Color mainTextColor;
  final bool isDark;

  @override
  State<_CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<_CollapsibleSection>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: widget.borderColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.borderColor.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        children: [
          // Header — always visible
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: _isExpanded ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: widget.goldTextColor.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: widget.goldTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content — animated expand/collapse
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                widget.content,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  color: widget.mainTextColor.withValues(alpha: 0.85),
                  height: 1.8,
                ),
              ),
            ),
            crossFadeState: _isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeInOut,
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SHARED WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

// ─────────────────────────────────────────────────────────────────────────────
// _CategoryChipBar — horizontal scrollable category filter
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryChipBar extends StatelessWidget {
  const _CategoryChipBar({
    required this.categories,
    required this.selectedIndex,
    required this.onSelected,
    required this.borderColor,
    required this.goldTextColor,
    required this.pageBgColor,
    required this.isDark,
  });

  final List<String> categories;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Color borderColor;
  final Color goldTextColor;
  final Color pageBgColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final isSelected = index == selectedIndex;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? borderColor.withValues(alpha: 0.18)
                      : pageBgColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? borderColor
                        : borderColor.withValues(alpha: 0.3),
                    width: isSelected ? 1.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: borderColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    categories[index],
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected
                          ? goldTextColor
                          : goldTextColor.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ProgressRow — progress bar with reset button
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.completed,
    required this.total,
    required this.borderColor,
    required this.pageBgColor,
    required this.goldTextColor,
    required this.isDark,
    required this.lang,
    required this.onReset,
  });

  final int completed;
  final int total;
  final Color borderColor;
  final Color pageBgColor;
  final Color goldTextColor;
  final bool isDark;
  final String lang;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final progress = total > 0 ? completed / total : 0.0;
    final allDone = completed == total && total > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Progress text
              Text(
                '$completed / $total',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: allDone ? AppColors.emeraldLight : goldTextColor,
                ),
              ),
              // Masha'Allah badge or Reset button
              if (allDone)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.emeraldLight, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _AzkarL10n.mashAllah(lang),
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 13,
                        color: AppColors.emeraldLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              // Reset button
              GestureDetector(
                onTap: onReset,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: borderColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: borderColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh_rounded,
                          color: goldTextColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        _AzkarL10n.reset(lang),
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 12,
                          color: goldTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Play Full Azkar removed from here

          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: borderColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                allDone ? AppColors.emeraldLight : borderColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ZekrCard — tappable daily Zekr card with counter + haptic feedback
// ─────────────────────────────────────────────────────────────────────────────

class _ZekrCard extends StatefulWidget {
  const _ZekrCard({
    required this.zekr,
    required this.index,
    required this.totalAzkar,
    required this.isPlaying,
    required this.isMiniPlayerVisible,
    required this.onTap,
    required this.onPlayPause,
    required this.onShowIndex,
    required this.category,
    required this.borderColor,
    required this.goldTextColor,
    required this.mainTextColor,
    required this.pageBgColor,
    required this.cardBgColor,
    required this.isDark,
    required this.lang,
  });

  final ZekrModel zekr;
  final int index;
  final int totalAzkar;
  final bool isPlaying;
  final bool isMiniPlayerVisible;
  final VoidCallback onTap;
  final VoidCallback onPlayPause;
  final VoidCallback onShowIndex;
  final String category;
  final Color borderColor;
  final Color goldTextColor;
  final Color mainTextColor;
  final Color pageBgColor;
  final Color cardBgColor;
  final bool isDark;
  final String lang;

  @override
  State<_ZekrCard> createState() => _ZekrCardState();
}

class _ZekrCardState extends State<_ZekrCard> with TickerProviderStateMixin {
  late AnimationController _scaleCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _scaleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
      value: 1.0,
      lowerBound: 0.94,
      upperBound: 1.0,
    );
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isPlaying) {
      _pulseCtrl.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_ZekrCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !oldWidget.isPlaying) {
      _pulseCtrl.repeat(reverse: true);
    } else if (!widget.isPlaying && oldWidget.isPlaying) {
      _pulseCtrl.animateTo(0.0, duration: const Duration(milliseconds: 300));
    }
  }

  @override
  void dispose() {
    _scaleCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final z = widget.zekr;
    final isCompleted = z.isCompleted;
    final lang = widget.lang;
    final isMorningOrEvening =
        widget.category == 'أذكار الصباح' || widget.category == 'أذكار المساء';

    return Column(
      children: [
        // ── Header: Number / Total & Grid Icon ───────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${widget.index + 1} / ${widget.totalAzkar}',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: widget.goldTextColor,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.grid_view_rounded,
                    color: widget.goldTextColor, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: widget.onShowIndex,
              ),
            ],
          ),
        ),
        // ── Main Card ─────────────────────────────────────────────
        Expanded(
          child: AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              final pulseColor = AppColors.emeraldLight
                  .withValues(alpha: _pulseCtrl.value * 0.15);
              final pulseBorderColor = AppColors.emeraldLight
                  .withValues(alpha: _pulseCtrl.value * 0.5 + 0.2);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.isPlaying
                      ? Color.alphaBlend(pulseColor, widget.cardBgColor)
                      : widget.cardBgColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isCompleted
                        ? AppColors.emeraldLight.withValues(alpha: 0.5)
                        : widget.isPlaying
                            ? pulseBorderColor
                            : widget.borderColor.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.isPlaying
                          ? AppColors.emeraldLight
                              .withValues(alpha: _pulseCtrl.value * 0.2)
                          : widget.isDark
                              ? Colors.black.withValues(alpha: 0.3)
                              : widget.borderColor.withValues(alpha: 0.1),
                      blurRadius: widget.isPlaying ? 24 : 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: Column(
              children: [
                // ── Main Content Area ───────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ValueListenableBuilder<double>(
                            valueListenable: _fontSizeNotifier,
                            builder: (context, fontSize, _) {
                              return Text(
                                z.zekr,
                                textAlign: TextAlign.center,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.w400,
                                  color: widget.mainTextColor,
                                  height: 1.8,
                                ),
                              );
                            }),
                        const SizedBox(height: 24),
                        if (z.zekrInfo.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: widget.borderColor.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    widget.borderColor.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Text(
                              getLocalizedZekrInfo(z.zekrInfo, lang),
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 15,
                                color: widget.goldTextColor
                                    .withValues(alpha: 0.85),
                                height: 1.6,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // ── Bottom Controls ─────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Row(
                    children: [
                      // Right side icons (Share, Copy)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            _buildIconButton(
                              icon: Icons.share_rounded,
                              onTap: () {
                                Share.share('${z.zekr}\n\n- تطبيق حصن المسلم');
                              },
                            ),
                            const SizedBox(width: 12),
                            _buildIconButton(
                              icon: Icons.copy_rounded,
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: z.zekr));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'تم نسخ الذكر بنجاح',
                                      style: TextStyle(
                                          fontFamily: 'Amiri', fontSize: 16),
                                      textAlign: TextAlign.center,
                                    ),
                                    backgroundColor: AppColors.emeraldLight,
                                    behavior: SnackBarBehavior.floating,
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      // Center Compact Counter
                      GestureDetector(
                        onTapDown: (_) {
                          if (!isCompleted) _scaleCtrl.reverse();
                        },
                        onTapUp: (_) {
                          if (!isCompleted) {
                            _scaleCtrl.forward();
                            widget.onTap();
                          }
                        },
                        onTapCancel: () {
                          if (!isCompleted) _scaleCtrl.forward();
                        },
                        child: AnimatedBuilder(
                          animation: _scaleCtrl,
                          builder: (_, child) => Transform.scale(
                              scale: isCompleted ? 1.0 : _scaleCtrl.value,
                              child: child),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCompleted
                                  ? AppColors.emeraldLight
                                  : widget.cardBgColor,
                              border: Border.all(
                                color: isCompleted
                                    ? AppColors.emeraldLight
                                    : widget.borderColor,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isCompleted
                                          ? AppColors.emeraldLight
                                          : widget.borderColor)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: isCompleted
                                  ? const Icon(Icons.check_rounded,
                                      color: Colors.white, size: 28)
                                  : Text(
                                      '${z.currentCount}',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: widget.mainTextColor,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      // Left side icon (Play Audio - only for Morning/Evening)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (isMorningOrEvening)
                              _buildIconButton(
                                icon: widget.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                isActive: widget.isPlaying,
                                onTap: widget.onPlayPause,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isMiniPlayerVisible) const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? AppColors.emeraldLight.withValues(alpha: 0.15)
              : widget.borderColor.withValues(alpha: 0.1),
          border: isActive
              ? Border.all(color: AppColors.emeraldLight, width: 1.5)
              : null,
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.emeraldLight : widget.goldTextColor,
          size: 20,
        ),
      ),
    );
  }
}
