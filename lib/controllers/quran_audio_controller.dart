import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reciter Model
// ─────────────────────────────────────────────────────────────────────────────

enum QuranAudioSource { everyayah, alquranCloud, quranCom, directTemplate }

enum QuranAudioType { everyayah, verseByVerse, verseByVerseFallback }

class QuranReciter {
  final int id;
  final String name;
  final String identifier;
  final String englishName;
  final List<String> aliases;
  final QuranAudioSource source;
  final QuranAudioType audioType;
  final int? cloudBitrate;
  final int? sourceId;
  final String? apiEndpoint;
  final String? directAyahCdnTemplate;
  final int? quranComId;

  const QuranReciter({
    required this.id,
    required this.name,
    required this.identifier,
    required this.englishName,
    this.aliases = const [],
    this.source = QuranAudioSource.everyayah,
    this.audioType = QuranAudioType.everyayah,
    this.cloudBitrate,
    this.sourceId,
    this.apiEndpoint,
    this.directAyahCdnTemplate,
    this.quranComId,
  });

  bool get hasDirectTemplate => directAyahCdnTemplate != null;
  bool get hasApiEndpoint => apiEndpoint != null && sourceId != null;

  String get searchText {
    final normalizedAliases =
        aliases.map((alias) => alias.toLowerCase()).join(' ');
    return '${name.toLowerCase()} ${englishName.toLowerCase()} ${identifier.toLowerCase()} $normalizedAliases';
  }
}

/// Verified reciters — identifiers are alquran.cloud edition identifiers and supported online sources.
const List<QuranReciter> kAllReciters = [
  QuranReciter(
    id: 1,
    name: 'محمد صديق المنشاوي',
    identifier: 'ar.minshawi',
    englishName: 'Minshawy',
    aliases: ['Minshawi', 'Minshawy'],
    source: QuranAudioSource.alquranCloud,
    quranComId: 9,
  ),
  QuranReciter(
    id: 2,
    name: 'محمد صديق المنشاوي(مجود)',
    identifier: 'ar.minshawimujawwad',
    englishName: 'Minshawy (Mujawwad)',
    aliases: ['Minshawi', 'Minshawy', 'Mujawwad'],
    source: QuranAudioSource.alquranCloud,
    cloudBitrate: 64,
    quranComId: 8,
  ),
  // Removed: ar.minshawi-2 (Alternate) — duplicate of same person
  QuranReciter(
    id: 3,
    name: 'عبد الباسط عبد الصمد',
    identifier: 'ar.abdulbasitmurattal',
    englishName: 'Abdul Basit (Murattal)',
    aliases: ['Abdul Basit', 'Basit', 'Murattal'],
    source: QuranAudioSource.alquranCloud,
    cloudBitrate: 192,
    quranComId: 2,
  ),
  // Removed: ar.abdulsamad — same person (عبد الباسط عبد الصمد) as above, different identifier
  QuranReciter(
    id: 4,
    name: 'عبد الرحمن السديس',
    identifier: 'ar.abdurrahmaansudais',
    englishName: 'Abdurrahmaan As-Sudais',
    aliases: ['Sudais', 'As-Sudais', 'Al-Sudais'],
    source: QuranAudioSource.alquranCloud,
    cloudBitrate: 192,
  ),
  QuranReciter(
    id: 5,
    name: 'سعود الشريم',
    identifier: 'ar.saoodshuraym',
    englishName: 'Saood Al-Shuraym',
    aliases: ['Saood Shuraym', 'Shuraym', 'Shuraim'],
    source: QuranAudioSource.alquranCloud,
    cloudBitrate: 64,
    quranComId: 10,
  ),
  QuranReciter(
    id: 6,
    name: 'ماهر المعيقلي',
    identifier: 'ar.mahermuaiqly',
    englishName: 'Maher Al Muaiqly',
    aliases: ['Maher', 'Muaiqly', 'Al Muaiqly'],
    source: QuranAudioSource.alquranCloud,
    cloudBitrate: 128,
  ),
  // Removed: ar.mahermuaiqly-2 (Alternate) — duplicate of same person
  QuranReciter(
    id: 7,
    name: 'علي الحذيفي',
    identifier: 'ar.hudhaify',
    englishName: 'Hudhaify',
    aliases: ['Hudhaify', 'Al Hudhaify'],
    source: QuranAudioSource.alquranCloud,
    cloudBitrate: 128,
  ),
  // Removed: ar.hudhaify-2 (Alternate) — duplicate of same person
  QuranReciter(
    id: 8,
    name: 'أحمد بن علي العجمي',
    identifier: 'ar.ahmedajamy',
    englishName: 'Ahmed Al-Ajami',
    aliases: ['Ahmed Ajamy', 'Al Ajami'],
    source: QuranAudioSource.alquranCloud,
    cloudBitrate: 128,
  ),
  QuranReciter(
    id: 9,
    name: 'أبو بكر الشاطري',
    identifier: 'ar.shaatree',
    englishName: 'Abu Bakr Ash-Shaatree',
    aliases: ['Shaatree', 'Shatri', 'Ash Shaatree'],
    source: QuranAudioSource.alquranCloud,
    cloudBitrate: 128,
    quranComId: 4,
  ),
  QuranReciter(
    id: 10,
    name: 'محمد جبريل',
    identifier: 'ar.muhammadjibreel',
    englishName: 'Muhammad Jibreel',
    aliases: ['Jibreel', 'Jibril'],
    source: QuranAudioSource.alquranCloud,
    cloudBitrate: 128,
  ),
  // Removed: ar.muhammadjibreel-2 (Alternate) — duplicate of same person
  QuranReciter(
    id: 11,
    name: 'هاني الرفاعي',
    identifier: 'ar.hanirifai',
    englishName: 'Hani Rifai',
    aliases: ['Hani', 'Rifai'],
    source: QuranAudioSource.alquranCloud,
    cloudBitrate: 192,
    quranComId: 5,
  ),
  QuranReciter(
    id: 12,
    name: 'إبراهيم الأخضر',
    identifier: 'ar.ibrahimakhbar',
    englishName: 'Ibrahim Akhdar',
    aliases: ['Ibrahim', 'Akhdar'],
    source: QuranAudioSource.alquranCloud,
    cloudBitrate: 32,
  ),
  QuranReciter(
    id: 13,
    name: 'محمود خليل الحصري',
    identifier: 'ar.husary',
    englishName: 'Husary',
    aliases: ['Husary', 'Al Husary'],
    source: QuranAudioSource.alquranCloud,
    cloudBitrate: 128,
    quranComId: 6,
  ),
  // Removed: ar.husary-2 (Alternate) — duplicate of same person
  QuranReciter(
    id: 14,
    name: 'محمود خليل الحصري (مجود)',
    identifier: 'ar.husarymujawwad',
    englishName: 'Husary (Mujawwad)',
    aliases: ['Husary', 'Mujawwad'],
    source: QuranAudioSource.alquranCloud,
    cloudBitrate: 128,
  ),
  QuranReciter(
    id: 15,
    name: 'ياسر الدوسري', // Fixed: was incorrectly set to سعود الشريم
    identifier: 'ar.yasseraldossari',
    englishName: 'Yasser Al-Dosari',
    aliases: ['Yasser Al Dosari', 'Yasir Al-Dosari', 'Al-Dosari'],
    source: QuranAudioSource.directTemplate,
    audioType: QuranAudioType.verseByVerse,
    directAyahCdnTemplate:
        'https://cdn.islamic.network/quran/audio/128/ar.yasseraldossari/{global_ayah_id}.mp3',
  ),
  QuranReciter(
    id: 16,
    name: 'ناصر القطامي',
    identifier: 'ar.qatami',
    englishName: 'Nasser Alqatami',
    aliases: ['Nasser Al Qatami', 'Nasir Alqatami'],
    source: QuranAudioSource.directTemplate,
    audioType: QuranAudioType.verseByVerse,
    directAyahCdnTemplate:
        'https://cdn.islamic.network/quran/audio/128/ar.qatami/{global_ayah_id}.mp3',
  ),
  QuranReciter(
    id: 17,
    name: 'محمد أيوب',
    identifier: 'ar.muhammadayyub',
    englishName: 'Muhammad Ayyoub',
    aliases: ['Muhammad Ayoub', 'Muhammad Ayoob'],
    source: QuranAudioSource.directTemplate,
    audioType: QuranAudioType.verseByVerse,
    directAyahCdnTemplate:
        'https://cdn.islamic.network/quran/audio/128/ar.muhammadayyub/{global_ayah_id}.mp3',
  ),
  QuranReciter(
    id: 18,
    name: 'علي عبدالله جابر',
    identifier: 'ar.alijaber',
    englishName: 'Ali Abdullah Jaber',
    aliases: ['Ali Abdullah Jaber', 'Ali Jaber'],
    source: QuranAudioSource.directTemplate,
    audioType: QuranAudioType.verseByVerse,
    directAyahCdnTemplate:
        'https://cdn.islamic.network/quran/audio/128/ar.alijaber/{global_ayah_id}.mp3',
  ),
  QuranReciter(
    id: 19,
    name: 'مشاري راشد العفاسي',
    identifier: 'ar.alafasy',
    englishName: 'Mishary Rashid Alafasy',
    aliases: ['Mishary', 'Alafasy', 'Afasy'],
    source: QuranAudioSource.alquranCloud,
    cloudBitrate: 128,
    quranComId: 7,
  ),
];

List<QuranReciter> get sortedReciters {
  final List<QuranReciter> supported = [];
  final List<QuranReciter> fallback = [];

  for (final r in kAllReciters) {
    if (r.quranComId != null) {
      supported.add(r);
    } else {
      fallback.add(r);
    }
  }

  supported.sort((a, b) => a.name.compareTo(b.name));
  fallback.sort((a, b) => a.name.compareTo(b.name));

  return [...supported, ...fallback];
}

// ─────────────────────────────────────────────────────────────────────────────
// Reciter Playback Routing Matrix
// Some reciters only provide full-surah files while others provide per-ayah
// split audio. This matrix enforces explicit routing so we don't guess URL
// templates and attempt to play non-existent per-ayah files.
//
// NOTE: Web playback requires CORS headers. everyayah.com sometimes lacks
// proper CORS configuration for all browsers. Islamic.network CDN is preferred.
// ─────────────────────────────────────────────────────────────────────────────
enum ReciterPlaybackType { ayahSplit, fullSurahOnly }

class ReciterRouting {
  final ReciterPlaybackType type;
  final String
      sourceTemplate; // may contain {global_ayah_id} or {three_digit_surah_id}
  const ReciterRouting(this.type, this.sourceTemplate);
}

const Map<String, ReciterRouting> kReciterRouting = {
  // ─── EveryAyah.com — reliable CORS-safe CDN, preferred for web ──────────────
  'ar.yasseraldossari': ReciterRouting(ReciterPlaybackType.ayahSplit,
      'https://everyayah.com/data/Yasser_Ad-Dussary_128kbps/{surah3}{ayah3}.mp3'),
  'ar.qatami': ReciterRouting(ReciterPlaybackType.ayahSplit,
      'https://everyayah.com/data/Nasser_Alqatami_128kbps/{surah3}{ayah3}.mp3'),
  'ar.muhammadayyub': ReciterRouting(ReciterPlaybackType.ayahSplit,
      'https://everyayah.com/data/Muhammad_Ayyoub_128kbps/{surah3}{ayah3}.mp3'),
  'ar.shaatree': ReciterRouting(ReciterPlaybackType.ayahSplit,
      'https://everyayah.com/data/Abu_Bakr_Ash-Shaatree_128kbps/{surah3}{ayah3}.mp3'),
  'ar.mahermuaiqly': ReciterRouting(ReciterPlaybackType.ayahSplit,
      'https://everyayah.com/data/MaherAlMuaiqly128kbps/{surah3}{ayah3}.mp3'),
  'ar.abdurrahmaansudais': ReciterRouting(ReciterPlaybackType.ayahSplit,
      'https://everyayah.com/data/Abdurrahmaan_As-Sudais_192kbps/{surah3}{ayah3}.mp3'),
  'ar.minshawi': ReciterRouting(ReciterPlaybackType.ayahSplit,
      'https://everyayah.com/data/Minshawy_Murattal_128kbps/{surah3}{ayah3}.mp3'),
  'ar.minshawimujawwad': ReciterRouting(ReciterPlaybackType.ayahSplit,
      'https://everyayah.com/data/Minshawy_Mujawwad_192kbps/{surah3}{ayah3}.mp3'),
  'ar.abdulbasitmurattal': ReciterRouting(ReciterPlaybackType.ayahSplit,
      'https://everyayah.com/data/Abdul_Basit_Murattal_192kbps/{surah3}{ayah3}.mp3'),
  'ar.saoodshuraym': ReciterRouting(ReciterPlaybackType.ayahSplit,
      'https://everyayah.com/data/Saood_ash-Shuraym_128kbps/{surah3}{ayah3}.mp3'),
  'ar.hudhaify': ReciterRouting(ReciterPlaybackType.ayahSplit,
      'https://everyayah.com/data/Hudhaify_128kbps/{surah3}{ayah3}.mp3'),
  'ar.ahmedajamy': ReciterRouting(ReciterPlaybackType.ayahSplit,
      'https://everyayah.com/data/Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net/{surah3}{ayah3}.mp3'),
  'ar.muhammadjibreel': ReciterRouting(ReciterPlaybackType.ayahSplit,
      'https://everyayah.com/data/Muhammad_Jibreel_128kbps/{surah3}{ayah3}.mp3'),
  'ar.hanirifai': ReciterRouting(ReciterPlaybackType.ayahSplit,
      'https://everyayah.com/data/Hani_Rifai_192kbps/{surah3}{ayah3}.mp3'),
  'ar.husary': ReciterRouting(ReciterPlaybackType.ayahSplit,
      'https://everyayah.com/data/Husary_128kbps/{surah3}{ayah3}.mp3'),
  'ar.husarymujawwad': ReciterRouting(ReciterPlaybackType.ayahSplit,
      'https://everyayah.com/data/Husary_128kbps_Mujawwad/{surah3}{ayah3}.mp3'),
  'ar.ibrahimakhbar': ReciterRouting(ReciterPlaybackType.ayahSplit,
      'https://everyayah.com/data/Ibrahim_Akhdar_32kbps/{surah3}{ayah3}.mp3'),

  // ─── cdn.islamic.network — reciters not on everyayah.com ────────────────────
  'ar.alijaber': ReciterRouting(ReciterPlaybackType.ayahSplit,
      'https://everyayah.com/data/Ali_Jaber_64kbps/{surah3}{ayah3}.mp3'),
};

// ─────────────────────────────────────────────────────────────────────────────
// Global Audio Controller — Gapless Playback Engine
// ─────────────────────────────────────────────────────────────────────────────
//
// Strategy:
//   Use just_audio's ConcatenatingAudioSource to load the entire Surah.
// ─────────────────────────────────────────────────────────────────────────────

class QuranAudioController extends ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────────────────────────
  QuranAudioController._internal();
  static final QuranAudioController instance = QuranAudioController._internal();

  // ── Audio engine ───────────────────────────────────────────────────────────
  final AudioPlayer _active = AudioPlayer();
  int streamKey = 0;

  StreamSubscription<PlayerState>? _activeSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<int?>? _indexSub;

  // ── URL cache (absoluteIdx → url) ──────────────────────────────────────────
  final Map<String, String> _urlCache = {};

  String _cacheKey(int absoluteIdx) =>
      '$absoluteIdx|${selectedReciter.identifier}';

  // ── Download Progress State ────────────────────────────────────────────────
  bool isDownloading = false;
  double downloadProgress = 0.0;
  bool isActive = false;
  bool isPlaying = false;
  bool isLoading = false;
  String? lastPlaybackError;

  // ── Streams (always from the active player) ────────────────────────────────
  Stream<Duration> get positionStream => _active.positionStream;
  Stream<Duration?> get durationStream => _active.durationStream;

  // ── Verse Tracking ─────────────────────────────────────────────────────────
  int currentSurah = 1;
  int currentAyah = 1;
  int currentAbsoluteIdx = 1;
  String currentSurahName = '';
  String currentVerseText = '';

  // ── Word-by-word state ─────────────────────────────────────────────────────
  int? activeWordPosition;
  Map<String, dynamic>? _currentChapterSegments;
  Map<String, Set<int>>? _currentChapterSymbols;

  bool isWordSymbol(int surah, int verse, int wordIndex) {
    if (_currentChapterSymbols == null) return false;
    final key = '$surah:$verse';
    final symbols = _currentChapterSymbols![key];
    if (symbols == null) return false;
    return symbols.contains(wordIndex);
  }

  // ── Reciter ────────────────────────────────────────────────────────────────
  QuranReciter selectedReciter = kAllReciters.firstWhere(
    (r) => r.identifier == 'ar.minshawi',
    orElse: () => kAllReciters.first,
  );
  bool hasUserSelectedReciter = false;

  // ── Controls ───────────────────────────────────────────────────────────────
  final List<int> repetitionOptions = const [1, 2, 3, 5, -1];
  int repetitionIndex = 0;
  int _currentLoopCount = 0;

  final List<int> delayOptions = const [0, 2, 5, 10, -1];
  int delayIndex = 0;
  bool _isDelaying = false;
  bool _isHandlingCompletion = false;

  final List<double> speedOptions = const [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  int speedIndex = 1; // default 1.0x
  double currentSpeed = 1.0;

  bool get _isGaplessMode =>
      delayOptions[delayIndex] == 0 && repetitionOptions[repetitionIndex] == 1;

  // ── Data Callbacks ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _surahList = [];
  int _totalVerses = 6236;
  Map<String, dynamic>? Function(int surah, int ayah)? _getVerseData;
  void Function(int surah, int ayah)? onAyahChanged;

  // ─────────────────────────────────────────────────────────────────────────
  // Word-by-word core
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _fetchSegmentsForChapter(int surah, int? quranComId) async {
    _currentChapterSegments = null;
    _currentChapterSymbols = null;
    activeWordPosition = null;
    notifyListeners();

    if (quranComId == null) return;

    try {
      debugPrint('[QuranAudio] Fetching segments for surah=$surah audio=$quranComId page=1');
      final response = await http.get(
        Uri.parse('https://api.quran.com/api/v4/verses/by_chapter/$surah?words=true&audio=$quranComId&per_page=300'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentChapterSegments = {};
        _currentChapterSymbols = {};
        
        void parseVerses(List verses) {
          if (_currentChapterSegments == null) return;
          for (final verse in verses) {
            final audio = verse['audio'];
            if (audio != null && audio['segments'] != null) {
              _currentChapterSegments![verse['verse_key']] = audio['segments'];
            }
            final words = verse['words'];
            if (words != null && words is List) {
              Set<int> symbols = {};
              for (int i = 0; i < words.length; i++) {
                final w = words[i];
                final type = w['char_type_name'];
                // Only 'word' is a standard Arabic word, everything else is a symbol (end, pause, sajdah, rub-el-hizb)
                if (type != 'word') {
                  symbols.add(i + 1); // 1-based index to match UI
                }
              }
              _currentChapterSymbols![verse['verse_key']] = symbols;
            }
          }
        }

        parseVerses(data['verses'] as List);
        
        final pagination = data['pagination'];
        final totalPages = pagination['total_pages'] as int? ?? 1;
        
        notifyListeners();
        debugPrint('[QuranAudio] Fetched segments for ${_currentChapterSegments!.length} verses (Page 1/$totalPages)');
        
        // Fetch remaining pages asynchronously
        for (int page = 2; page <= totalPages; page++) {
          if (surah != currentSurah || quranComId != selectedReciter.quranComId) break;
          try {
            debugPrint('[QuranAudio] Fetching segments for surah=$surah audio=$quranComId page=$page');
            final pageRes = await http.get(
              Uri.parse('https://api.quran.com/api/v4/verses/by_chapter/$surah?words=true&audio=$quranComId&per_page=50&page=$page'),
            );
            
            if (surah != currentSurah || quranComId != selectedReciter.quranComId) break;
            
            if (pageRes.statusCode == 200) {
              final pageData = json.decode(pageRes.body);
              parseVerses(pageData['verses'] as List);
              notifyListeners();
            }
          } catch (e) {
            debugPrint('[QuranAudio] Error fetching segments page $page: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('[QuranAudio] Error fetching segments: $e');
    }
  }

  void _syncWordPosition(Duration position) {
    if (_currentChapterSegments == null || _currentChapterSegments!.isEmpty) {
      if (activeWordPosition != null) {
        activeWordPosition = null;
        notifyListeners();
      }
      return;
    }

    final verseKey = '$currentSurah:$currentAyah';
    final segments = _currentChapterSegments![verseKey];
    if (segments == null) {
      if (activeWordPosition != null) {
        activeWordPosition = null;
        notifyListeners();
      }
      return;
    }

    int ms = position.inMilliseconds;
    int? newPos;
    for (final seg in segments) {
      if (seg is List && seg.length >= 4) {
        final startMs = seg[2] as int;
        final endMs = seg[3] as int;
        if (ms >= startMs && ms <= endMs) {
          newPos = (seg[0] as int) + 1; // Map 0-based index to 1-based wordIndex
          break;
        }
      }
    }

    if (newPos != activeWordPosition) {
      activeWordPosition = newPos;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> startPlayback({
    required int surah,
    required int ayah,
    required List<Map<String, dynamic>> surahList,
    required int totalVerses,
    required Map<String, dynamic>? Function(int, int) getVerseData,
    void Function(int surah, int ayah)? onAyahChanged,
  }) async {
    _surahList = surahList;
    _totalVerses = totalVerses;
    _getVerseData = getVerseData;
    this.onAyahChanged = onAyahChanged;

    // Fetch word timestamps asynchronously if available
    _fetchSegmentsForChapter(surah, selectedReciter.quranComId);

    _setCurrentFromSurahAyah(surah, ayah);
    isActive = true;

    if (repetitionOptions[repetitionIndex] == -1) {
      _active.setLoopMode(LoopMode.all);
    } else {
      _active.setLoopMode(LoopMode.off);
    }

    await _loadSurahPlaylist(surah, ayah);
    notifyListeners();
  }

  Future<void> play() async {
    if (!_isDelaying && !isPlaying) {
      if (_active.processingState == ProcessingState.completed) {
        _handleTrackCompletion();
      } else {
        _active.play();
      }
    }
  }

  Future<void> pause() async {
    _active.pause();
    if (_isDelaying) {
      _isDelaying = false;
      isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> seek(Duration position) async => _active.seek(position);

  Future<void> nextAyah() async {
    if (currentAbsoluteIdx < _totalVerses) {
      if (_isGaplessMode) {
        final nextSurahInfo = _surahList.firstWhere((s) => s['number'] == currentSurah);
        if (currentAyah >= nextSurahInfo['totalVerses']) {
          // Going to next surah
          final nextS = currentSurah + 1;
          if (nextS <= 114) {
            _updateFromAbsoluteIndex(currentAbsoluteIdx + 1);
            _fetchSegmentsForChapter(nextS, selectedReciter.quranComId);
            onAyahChanged?.call(nextS, 1);
            notifyListeners();
            await _loadSurahPlaylist(nextS, 1);
          }
        } else {
          await _active.seekToNext();
        }
      } else {
        final nextSurahInfo = _surahList.firstWhere((s) => s['number'] == currentSurah);
        if (currentAyah >= nextSurahInfo['totalVerses']) {
          // Going to next surah
          final nextS = currentSurah + 1;
          if (nextS <= 114) {
            _updateFromAbsoluteIndex(currentAbsoluteIdx + 1);
            _fetchSegmentsForChapter(nextS, selectedReciter.quranComId);
            onAyahChanged?.call(nextS, 1);
            notifyListeners();
            await _loadSurahPlaylist(nextS, 1);
          }
        } else {
          _updateFromAbsoluteIndex(currentAbsoluteIdx + 1);
          onAyahChanged?.call(currentSurah, currentAyah);
          notifyListeners();
          await _loadSurahPlaylist(currentSurah, currentAyah);
        }
      }
    }
  }

  Future<void> previousAyah() async {
    if (currentAbsoluteIdx > 1) {
      if (_isGaplessMode) {
        if (currentAyah == 1) {
          // Going to previous surah
          final prevS = currentSurah - 1;
          _updateFromAbsoluteIndex(currentAbsoluteIdx - 1);
          _fetchSegmentsForChapter(prevS, selectedReciter.quranComId);
          final prevSurahInfo = _surahList.firstWhere((s) => s['number'] == prevS);
          final prevTotal = prevSurahInfo['totalVerses'] as int;
          onAyahChanged?.call(prevS, prevTotal);
          notifyListeners();
          await _loadSurahPlaylist(prevS, prevTotal);
        } else {
          await _active.seekToPrevious();
        }
      } else {
        if (currentAyah == 1) {
          // Going to previous surah
          final prevS = currentSurah - 1;
          _updateFromAbsoluteIndex(currentAbsoluteIdx - 1);
          _fetchSegmentsForChapter(prevS, selectedReciter.quranComId);
          final prevSurahInfo = _surahList.firstWhere((s) => s['number'] == prevS);
          final prevTotal = prevSurahInfo['totalVerses'] as int;
          onAyahChanged?.call(prevS, prevTotal);
          notifyListeners();
          await _loadSurahPlaylist(prevS, prevTotal);
        } else {
          _updateFromAbsoluteIndex(currentAbsoluteIdx - 1);
          onAyahChanged?.call(currentSurah, currentAyah);
          notifyListeners();
          await _loadSurahPlaylist(currentSurah, currentAyah);
        }
      }
    }
  }

  Future<void> changeReciter(QuranReciter reciter) async {
    selectedReciter = reciter;
    _urlCache.clear();
    
    _fetchSegmentsForChapter(currentSurah, selectedReciter.quranComId);
    
    notifyListeners();
    await _loadSurahPlaylist(currentSurah, currentAyah);
  }

  void setRepetition(int value) {
    int idx = repetitionOptions.indexOf(value);
    if (idx != -1) {
      repetitionIndex = idx;
      if (value == -1) {
        _active.setLoopMode(LoopMode.all);
      } else {
        _active.setLoopMode(LoopMode.off);
      }
      notifyListeners();
      if (isActive) {
        _loadSurahPlaylist(currentSurah, currentAyah);
      }
    }
  }

  void setDelay(int optionValue) {
    delayIndex = delayOptions.indexOf(optionValue);
    notifyListeners();
    if (isActive) {
      _loadSurahPlaylist(currentSurah, currentAyah);
    }
  }

  void setSpeed(double speed) {
    int idx = speedOptions.indexOf(speed);
    if (idx != -1) {
      speedIndex = idx;
      currentSpeed = speed;
      _active.setSpeed(speed);
      notifyListeners();
    }
  }

  void stopAndDismiss() {
    _activeSub?.cancel();
    _activeSub = null;
    _positionSub?.cancel();
    _positionSub = null;
    _indexSub?.cancel();
    _indexSub = null;
    
    _active.stop();
    isActive = false;
    isPlaying = false;
    _isDelaying = false;
    _currentLoopCount = 0;
    hasUserSelectedReciter = false;
    activeWordPosition = null;
    _currentChapterSegments = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Gapless Engine Core
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _loadSurahPlaylist(int surah, int startAyah) async {
    isLoading = true;
    notifyListeners();
    lastPlaybackError = null;

    try {
      _activeSub?.cancel();
      _activeSub = null;
      _indexSub?.cancel();
      _indexSub = null;
      await _active.stop();

      final routing = kReciterRouting[selectedReciter.identifier];
      bool isFullSurah = routing != null && routing.type == ReciterPlaybackType.fullSurahOnly;

      if (isFullSurah) {
        final url = await _getAudioUrl(currentAbsoluteIdx, prefetchSurah: surah, prefetchAyah: 1);
        if (url != null) {
          final mediaItem = MediaItem(
            id: currentAbsoluteIdx.toString(),
            album: 'القرآن الكريم',
            title: 'سورة $currentSurahName',
            artist: selectedReciter.name,
          );
          final source = url.startsWith('http') 
              ? AudioSource.uri(Uri.parse(url), tag: mediaItem)
              : AudioSource.uri(Uri.file(url), tag: mediaItem);
          await _active.setAudioSource(source);
        }
      } else if (_isGaplessMode) {
        final surahInfo = _surahList.firstWhere((s) => s['number'] == surah);
        final totalAyahs = surahInfo['totalVerses'] as int;
        
        int absStart = 1;
        for (final s in _surahList) {
          if (s['number'] == surah) break;
          absStart += s['totalVerses'] as int;
        }

        List<AudioSource> sources = [];
        for (int a = 1; a <= totalAyahs; a++) {
          final absIdx = absStart + a - 1;
          final url = await _getAudioUrl(absIdx, prefetchSurah: surah, prefetchAyah: a);
          if (url != null) {
            final mediaItem = MediaItem(
              id: absIdx.toString(),
              album: 'القرآن الكريم',
              title: 'الآية $absIdx',
              artist: selectedReciter.name,
            );
            sources.add(url.startsWith('http') 
              ? AudioSource.uri(Uri.parse(url), tag: mediaItem)
              : AudioSource.uri(Uri.file(url), tag: mediaItem));
          }
        }
        
        if (sources.isNotEmpty) {
          final playlist = ConcatenatingAudioSource(children: sources);
          await _active.setAudioSource(playlist, initialIndex: startAyah - 1);
        } else {
           throw Exception("No audio sources found for this Surah.");
        }
      } else {
        _currentLoopCount = 0; // reset loop when manually loaded
        final url = await _getAudioUrl(currentAbsoluteIdx, prefetchSurah: surah, prefetchAyah: startAyah);
        if (url != null) {
          final mediaItem = MediaItem(
            id: currentAbsoluteIdx.toString(),
            album: 'القرآن الكريم',
            title: 'الآية $currentAbsoluteIdx',
            artist: selectedReciter.name,
          );
          final source = url.startsWith('http') 
              ? AudioSource.uri(Uri.parse(url), tag: mediaItem)
              : AudioSource.uri(Uri.file(url), tag: mediaItem);
          await _active.setAudioSource(source);
        } else {
           throw Exception("No audio sources found for this Ayah.");
        }
      }
      
      _attachActiveListener();
      await _active.play();
    } catch (e) {
      debugPrint('[QuranAudio] Error in audio engine: $e');
      isActive = false;
      lastPlaybackError = e.toString();
      notifyListeners();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _attachActiveListener() {
    _activeSub?.cancel();
    _positionSub?.cancel();
    _indexSub?.cancel();
    
    _positionSub = _active.positionStream.listen(_syncWordPosition);

    _indexSub = _active.currentIndexStream.listen((index) {
      if (index == null) return;
      final sequence = _active.sequenceState?.sequence;
      if (sequence == null || index >= sequence.length) return;
      
      final mediaItem = sequence[index].tag as MediaItem;
      final absoluteIdx = int.tryParse(mediaItem.id);
      
      if (absoluteIdx != null && absoluteIdx != currentAbsoluteIdx) {
        final oldSurah = currentSurah;
        _updateFromAbsoluteIndex(absoluteIdx);
        
        if (oldSurah != currentSurah) {
          _fetchSegmentsForChapter(currentSurah, selectedReciter.quranComId);
        }
        
        onAyahChanged?.call(currentSurah, currentAyah);
        notifyListeners();
      }
    });

    _activeSub = _active.playerStateStream.listen((state) {
      isPlaying = (state.playing && state.processingState != ProcessingState.completed) || _isDelaying;
      notifyListeners();

      if (state.processingState == ProcessingState.completed) {
         _handleTrackCompletion();
      }
    });
  }

  Future<void> _handleTrackCompletion() async {
    if (_isHandlingCompletion) return;
    _isHandlingCompletion = true;

    try {
      final routing = kReciterRouting[selectedReciter.identifier];
      bool isFullSurah = routing != null && routing.type == ReciterPlaybackType.fullSurahOnly;
      
      if (isFullSurah) {
        stopAndDismiss();
        return;
      }

      if (_isGaplessMode) {
        // In gapless mode, completion means the entire Surah playlist has finished.
        if (currentAbsoluteIdx < _totalVerses) {
          final nextSurah = currentSurah + 1;
          if (nextSurah <= 114) {
            _updateFromAbsoluteIndex(currentAbsoluteIdx + 1);
            _fetchSegmentsForChapter(nextSurah, selectedReciter.quranComId);
            onAyahChanged?.call(nextSurah, 1);
            notifyListeners();
            await _loadSurahPlaylist(nextSurah, 1);
          } else {
            stopAndDismiss();
          }
        } else {
          stopAndDismiss();
        }
        return;
      }

      int targetRepeats = repetitionOptions[repetitionIndex];

      _currentLoopCount++;

      // STEP 1: APPLY THE GAP DELAY FIRST (Applies to both repeats and next Ayahs)
      int delaySecs = delayOptions[delayIndex];

      if (delaySecs == -1) {
        isPlaying = false;
        notifyListeners();
        return;
      }

      if (delaySecs > 0) {
        // Keep UI state as 'playing' so it doesn't look broken during the silence
        _isDelaying = true;
        isPlaying = true;
        notifyListeners();
        
        await Future.delayed(Duration(seconds: delaySecs));
        
        _isDelaying = false;
        notifyListeners();
        
        // Ensure we don't proceed if user intentionally stopped player during gap
        if (!isActive || !isPlaying) return;
      }

      // STEP 2: Check if we need to repeat the current Ayah
      if (targetRepeats == -1 || _currentLoopCount < targetRepeats) {
        await _active.seek(Duration.zero);
        await _active.play(); // Play the repeat
        return; // EXIT FUNCTION HERE
      }

      // STEP 3: The current Ayah is fully finished. Reset counter.
      _currentLoopCount = 0;

      // STEP 4: Move to the next Ayah
      if (currentAbsoluteIdx < _totalVerses) {
        
        int prevSurah = currentSurah;
        _updateFromAbsoluteIndex(currentAbsoluteIdx + 1);
        
        if (currentSurah != prevSurah) {
           _fetchSegmentsForChapter(currentSurah, selectedReciter.quranComId);
        }
        
        onAyahChanged?.call(currentSurah, currentAyah);

        // STEP 6: Load the new audio and FORCE PLAY
        final url = await _getAudioUrl(currentAbsoluteIdx, prefetchSurah: currentSurah, prefetchAyah: currentAyah);
        if (url != null) {
          final mediaItem = MediaItem(
            id: currentAbsoluteIdx.toString(),
            album: 'القرآن الكريم',
            title: 'الآية $currentAbsoluteIdx',
            artist: selectedReciter.name,
          );
          final source = url.startsWith('http') 
              ? AudioSource.uri(Uri.parse(url), tag: mediaItem)
              : AudioSource.uri(Uri.file(url), tag: mediaItem);
              
          await _active.setAudioSource(source); // Adjust to setSource method
          await _active.play(); // CRITICAL: Force it to play the new Ayah
        } else {
          stopAndDismiss();
        }
        
      } else {
        // STEP 7: Reached the end of the list/Surah
        stopAndDismiss();
      }
    } finally {
      _isHandlingCompletion = false;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Offline & URL resolution
  // ─────────────────────────────────────────────────────────────────────────

  Future<String> _getDirPath() async {
    final dir = await getApplicationDocumentsDirectory();
    final quranDir = Directory('${dir.path}/quran_audio');
    if (!await quranDir.exists()) {
      await quranDir.create(recursive: true);
    }
    return quranDir.path;
  }

  Future<String?> _getAudioUrl(int absoluteIdx,
      {int? prefetchSurah, int? prefetchAyah}) async {
    if (absoluteIdx < 1 || absoluteIdx > _totalVerses) return null;

    final cacheKey = _cacheKey(absoluteIdx);
    if (_urlCache.containsKey(cacheKey)) {
      return _urlCache[cacheKey];
    }

    // Calculate Surah and Ayah for the absolute index if not provided
    int s = prefetchSurah ?? currentSurah;
    int a = prefetchAyah ?? currentAyah;
    if (prefetchSurah == null || prefetchAyah == null) {
      int remaining = absoluteIdx;
      for (final sur in _surahList) {
        final total = sur['totalVerses'] as int;
        if (remaining <= total) {
          s = sur['number'] as int;
          a = remaining;
          break;
        }
        remaining -= total;
      }
    }

    final id = selectedReciter.identifier;

    // Web Fallback: bypass local file system checks and return online URL immediately
    if (kIsWeb) {
      final routing = kReciterRouting[selectedReciter.identifier];
      if (routing != null) {
        if (routing.type == ReciterPlaybackType.fullSurahOnly) {
          final three = s.toString().padLeft(3, '0');
          final url = routing.sourceTemplate
              .replaceAll('{three_digit_surah_id}', three);
          _urlCache[cacheKey] = url;
          debugPrint(
              '[QuranAudio] Generated full-surah URL for idx=$absoluteIdx (Web)');
          return url;
        }

        final surahPad = s.toString().padLeft(3, '0');
        final ayahPad = a.toString().padLeft(3, '0');
        String template = routing.sourceTemplate;
        String url;

        if (template.contains('{global_ayah_id}')) {
          url = template.replaceAll('{global_ayah_id}', absoluteIdx.toString());
        } else if (template.contains('{surah3}') ||
            template.contains('{ayah3}')) {
          url = template
              .replaceAll('{surah3}', surahPad)
              .replaceAll('{ayah3}', ayahPad);
        } else if (template.contains('{surah_ayah}')) {
          url = template.replaceAll('{surah_ayah}', '$surahPad$ayahPad');
        } else {
          url = template
              .replaceAll('{surahPad}', surahPad)
              .replaceAll('{ayahPad}', ayahPad);
        }

        _urlCache[cacheKey] = url;
        debugPrint(
            '[QuranAudio] Generated routing URL for idx=$absoluteIdx (Web)');
        return url;
      }

      if (selectedReciter.hasDirectTemplate) {
        final template = selectedReciter.directAyahCdnTemplate!;
        final url =
            template.replaceAll('{global_ayah_id}', absoluteIdx.toString());
        _urlCache[cacheKey] = url;
        debugPrint(
            '[QuranAudio] Generated direct-template URL for idx=$absoluteIdx (Web)');
        return url;
      }

      final url =
          _buildRemoteUrl(id, absoluteIdx, selectedReciter, surah: s, ayah: a);
      _urlCache[cacheKey] = url;
      debugPrint(
          '[QuranAudio] Generated remote URL for idx=$absoluteIdx (Web Fallback)');
      return url;
    }

    final filename = '${id}_${s}_$a.mp3';
    final dirPath = await _getDirPath();
    final localPath = '$dirPath/$filename';

    // 1. Check if true local offline file exists
    if (await File(localPath).exists()) {
      _urlCache[cacheKey] = localPath;
      debugPrint('[QuranAudio] Found LOCAL audio for idx=$absoluteIdx');
      return localPath;
    }

    // 2. Enforce explicit routing matrix (do not guess per-ayah files)
    final routing = kReciterRouting[selectedReciter.identifier];
    if (routing != null) {
      if (routing.type == ReciterPlaybackType.fullSurahOnly) {
        final three = s.toString().padLeft(3, '0');
        final url =
            routing.sourceTemplate.replaceAll('{three_digit_surah_id}', three);
        _urlCache[cacheKey] = url;
        debugPrint(
            '[QuranAudio] Routing resolved full-surah URL for idx=$absoluteIdx (reciter=${selectedReciter.identifier})');
        return url;
      }

      if (routing.type == ReciterPlaybackType.ayahSplit) {
        final surahPad = s.toString().padLeft(3, '0');
        final ayahPad = a.toString().padLeft(3, '0');
        String template = routing.sourceTemplate;

        String url;
        if (template.contains('{global_ayah_id}')) {
          url = template.replaceAll('{global_ayah_id}', absoluteIdx.toString());
        } else if (template.contains('{surah3}') ||
            template.contains('{ayah3}')) {
          url = template
              .replaceAll('{surah3}', surahPad)
              .replaceAll('{ayah3}', ayahPad);
        } else if (template.contains('{surah_ayah}')) {
          url = template.replaceAll('{surah_ayah}', '$surahPad$ayahPad');
        } else {
          // Fallback: attempt {surahPad}{ayahPad} style by replacing known tokens
          url = template
              .replaceAll('{surahPad}', surahPad)
              .replaceAll('{ayahPad}', ayahPad);
        }

        _urlCache[cacheKey] = url;
        debugPrint(
            '[QuranAudio] Routing resolved ayah-split URL for idx=$absoluteIdx (reciter=${selectedReciter.identifier})');
        return url;
      }
    }

    // 3. Fallback to supported online source
    if (selectedReciter.audioType == QuranAudioType.verseByVerse) {
      if (selectedReciter.source == QuranAudioSource.quranCom &&
          selectedReciter.hasApiEndpoint) {
        final url = await _fetchVerseByVerseAudioUrl(
            selectedReciter, absoluteIdx, s, a);
        if (url != null) {
          _urlCache[cacheKey] = url;
          debugPrint(
              '[QuranAudio] Resolved quran.com audio URL for idx=$absoluteIdx');
          return url;
        }
      }
      if (selectedReciter.hasDirectTemplate) {
        final template = selectedReciter.directAyahCdnTemplate!;
        final url =
            template.replaceAll('{global_ayah_id}', absoluteIdx.toString());
        _urlCache[cacheKey] = url;
        debugPrint(
            '[QuranAudio] Generated direct-template URL for idx=$absoluteIdx');
        return url;
      }
    } else if (selectedReciter.audioType ==
        QuranAudioType.verseByVerseFallback) {
      if (selectedReciter.hasDirectTemplate) {
        final template = selectedReciter.directAyahCdnTemplate!;
        final url =
            template.replaceAll('{global_ayah_id}', absoluteIdx.toString());
        _urlCache[cacheKey] = url;
        debugPrint(
            '[QuranAudio] Generated fallback direct-template URL for idx=$absoluteIdx');
        return url;
      }
    }

    final url =
        _buildRemoteUrl(id, absoluteIdx, selectedReciter, surah: s, ayah: a);
    _urlCache[cacheKey] = url;
    debugPrint('[QuranAudio] Generated remote URL for idx=$absoluteIdx');
    return url;
  }

  Future<String?> _fetchVerseByVerseAudioUrl(
      QuranReciter reciter, int absoluteIdx, int surah, int ayah) async {
    if (!reciter.hasApiEndpoint) return null;

    final endpoint = reciter.apiEndpoint!.trim();
    final baseUri = Uri.parse(endpoint.replaceAll(RegExp(r'/+$'), ''));
    final path = baseUri.path.isEmpty
        ? '/api/v4/recitations/${reciter.sourceId}/audio_files'
        : '${baseUri.path.replaceAll(RegExp(r'/*$'), '')}/api/v4/recitations/${reciter.sourceId}/audio_files';
    final uri = baseUri
        .replace(path: path, queryParameters: {'verse_id': '$surah:$ayah'});

    try {
      final response =
          await http.get(uri, headers: {'User-Agent': 'Mozilla/5.0'});
      if (response.statusCode != 200) {
        debugPrint(
            '[QuranAudio] Failed quran.com fetch ${response.statusCode} for idx=$absoluteIdx');
        return null;
      }

      final decoded = jsonDecode(response.body);
      dynamic audioFiles = decoded;
      if (decoded is Map && decoded.containsKey('audio_files')) {
        audioFiles = decoded['audio_files'];
      } else if (decoded is Map &&
          decoded.containsKey('data') &&
          decoded['data'] is Map &&
          decoded['data'].containsKey('audio_files')) {
        audioFiles = decoded['data']['audio_files'];
      }

      if (audioFiles is String && audioFiles.endsWith('.mp3')) {
        return audioFiles;
      }

      if (audioFiles is List) {
        for (final entry in audioFiles) {
          final url = _extractAudioUrl(entry);
          if (url != null) return url;
        }
      }

      if (audioFiles is Map) {
        return _extractAudioUrl(audioFiles);
      }
    } catch (e) {
      debugPrint('[QuranAudio] Exception resolving quran.com audio URL: $e');
    }

    return null;
  }

  String? _extractAudioUrl(dynamic entry) {
    if (entry is String && entry.endsWith('.mp3')) return entry;
    if (entry is Map) {
      if (entry['url'] is String && (entry['url'] as String).endsWith('.mp3')) {
        return entry['url'];
      }
      if (entry['audio'] is String &&
          (entry['audio'] as String).endsWith('.mp3')) {
        return entry['audio'];
      }
      if (entry['audio_url'] is String &&
          (entry['audio_url'] as String).endsWith('.mp3')) {
        return entry['audio_url'];
      }
      if (entry['audio_file'] is String &&
          (entry['audio_file'] as String).endsWith('.mp3')) {
        return entry['audio_file'];
      }
    }
    return null;
  }

  String _buildRemoteUrl(String id, int absoluteIdx, QuranReciter reciter,
      {int? surah, int? ayah}) {
    if (reciter.source == QuranAudioSource.alquranCloud) {
      final bitrate = reciter.cloudBitrate ?? 128;
      return 'https://cdn.islamic.network/quran/audio/$bitrate/$id/$absoluteIdx.mp3';
    }

    final surahPad = (surah ?? currentSurah).toString().padLeft(3, '0');
    final ayahPad = (ayah ?? currentAyah).toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$id/$surahPad$ayahPad.mp3';
  }

  /// Downloads all verses of a Surah for the currently selected reciter.
  Future<void> downloadSurah(int surahNumber, int totalVerses) async {
    if (isDownloading || kIsWeb) return;

    isDownloading = true;
    downloadProgress = 0.0;
    notifyListeners();

    try {
      final id = selectedReciter.identifier;
      final dirPath = await _getDirPath();

      for (int a = 1; a <= totalVerses; a++) {
        if (!isDownloading) break; // Check for cancellation

        final filename = '${id}_${surahNumber}_$a.mp3';
        final localPath = '$dirPath/$filename';

        if (!await File(localPath).exists()) {
          final remoteAbsolute = _calculateAbsoluteIndex(surahNumber, a);
          final url = _buildRemoteUrl(id, remoteAbsolute, selectedReciter,
              surah: surahNumber, ayah: a);
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            await File(localPath).writeAsBytes(response.bodyBytes);
          }
        }

        downloadProgress = a / totalVerses;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[QuranAudio] Error downloading Surah: $e');
    } finally {
      isDownloading = false;
      notifyListeners();
    }
  }

  void cancelDownload() {
    isDownloading = false;
    notifyListeners();
  }

  Future<bool> hasOfflineAudio(int surahNumber, int ayahNumber) async {
    if (kIsWeb) return false;
    final id = selectedReciter.identifier;
    final filename = '${id}_${surahNumber}_$ayahNumber.mp3';
    final dirPath = await _getDirPath();
    final localPath = '$dirPath/$filename';
    return await File(localPath).exists();
  }

  Future<void> downloadAyah(int surahNumber, int ayahNumber) async {
    if (isDownloading || kIsWeb) return;

    isDownloading = true;
    downloadProgress = 0.0;
    notifyListeners();

    try {
      final id = selectedReciter.identifier;
      final dirPath = await _getDirPath();
      final filename = '${id}_${surahNumber}_$ayahNumber.mp3';
      final localPath = '$dirPath/$filename';

      if (!await File(localPath).exists()) {
        final remoteAbsolute = _calculateAbsoluteIndex(surahNumber, ayahNumber);
        final url = _buildRemoteUrl(id, remoteAbsolute, selectedReciter,
            surah: surahNumber, ayah: ayahNumber);
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          await File(localPath).writeAsBytes(response.bodyBytes);
        }
      }

      downloadProgress = 1.0;
      notifyListeners();
    } catch (e) {
      debugPrint('[QuranAudio] Error downloading Ayah: $e');
    } finally {
      isDownloading = false;
      notifyListeners();
    }
  }

  Future<void> downloadPage(
      int pageNumber, List<Map<String, dynamic>> versesOnPage) async {
    if (isDownloading || kIsWeb) return;

    isDownloading = true;
    downloadProgress = 0.0;
    notifyListeners();

    try {
      final id = selectedReciter.identifier;
      final dirPath = await _getDirPath();
      final total = versesOnPage.length;

      for (int index = 0; index < total; index++) {
        if (!isDownloading) break;

        final verse = versesOnPage[index];
        final surahNumber = verse['surahNumber'] as int? ?? 1;
        final ayahNumber = verse['ayahNumber'] as int? ?? 1;
        final filename = '${id}_${surahNumber}_$ayahNumber.mp3';
        final localPath = '$dirPath/$filename';

        if (!await File(localPath).exists()) {
          final remoteAbsolute =
              _calculateAbsoluteIndex(surahNumber, ayahNumber);
          final url = _buildRemoteUrl(id, remoteAbsolute, selectedReciter,
              surah: surahNumber, ayah: ayahNumber);
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 200) {
            await File(localPath).writeAsBytes(response.bodyBytes);
          }
        }

        downloadProgress = (index + 1) / total;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[QuranAudio] Error downloading Page $pageNumber: $e');
    } finally {
      isDownloading = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Index helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _updateFromAbsoluteIndex(int absoluteIndex) {
    if (absoluteIndex < 1 || absoluteIndex > _totalVerses) return;

    int remaining = absoluteIndex;
    int targetSurah = 1;
    for (final s in _surahList) {
      final total = s['totalVerses'] as int;
      if (remaining <= total) {
        targetSurah = s['number'] as int;
        break;
      }
      remaining -= total;
      targetSurah++;
    }
    final targetAyah = remaining;
    currentAbsoluteIdx = absoluteIndex;
    _setCurrentFromSurahAyah(targetSurah, targetAyah);
  }

  void _setCurrentFromSurahAyah(int surah, int ayah) {
    currentSurah = surah;
    currentAyah = ayah;
    currentAbsoluteIdx = _calculateAbsoluteIndex(surah, ayah);

    final data = _getVerseData?.call(surah, ayah);
    if (data != null) {
      currentSurahName = data['surahName'] ?? _surahNameFallback(surah);
      currentVerseText = data['text'] ?? '';
    } else {
      currentSurahName = _surahNameFallback(surah);
      currentVerseText = '';
    }
  }

  int _calculateAbsoluteIndex(int surah, int ayah) {
    int absolute = 0;
    for (final s in _surahList) {
      if (s['number'] == surah) break;
      absolute += s['totalVerses'] as int;
    }
    return absolute + ayah;
  }

  static const String ayahSplit = 'ayahSplit';

  static const String fullSurahOnly = 'fullSurahOnly';

  String _surahNameFallback(int surah) {
    try {
      return _surahList.firstWhere((s) => s['number'] == surah)['name'] ?? '';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _activeSub?.cancel();
    _positionSub?.cancel();
    _indexSub?.cancel();
    _active.dispose();
    super.dispose();
  }
}
