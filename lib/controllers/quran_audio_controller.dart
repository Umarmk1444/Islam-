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
  ),
  QuranReciter(
    id: 2,
    name: 'محمد صديق المنشاوي(مجود)',
    identifier: 'ar.minshawimujawwad',
    englishName: 'Minshawy (Mujawwad)',
    aliases: ['Minshawi', 'Minshawy', 'Mujawwad'],
    source: QuranAudioSource.alquranCloud,
    cloudBitrate: 64,
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
];

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
// Global Audio Controller — Dual-Player Ping-Pong for Gapless Playback
// ─────────────────────────────────────────────────────────────────────────────
//
// Strategy:
//   • _active  → currently playing verse N
//   • _standby → pre-loading verse N+1 in background, already buffered
//   When _active completes → swap pointers, start _standby instantly,
//   then start loading verse N+2 into the now-free _active player.
// ─────────────────────────────────────────────────────────────────────────────

class QuranAudioController extends ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────────────────────────
  QuranAudioController._internal();
  static final QuranAudioController instance = QuranAudioController._internal();

  // ── Dual-player engine ─────────────────────────────────────────────────────
  final AudioPlayer _playerA = AudioPlayer();
  final AudioPlayer _playerB = AudioPlayer();
  bool _usingA = true;

  /// Increments every time the active player swaps.
  /// UI widgets can key StreamBuilders on this to reconnect to the new stream.
  int streamKey = 0;

  AudioPlayer get _active => _usingA ? _playerA : _playerB;
  AudioPlayer get _standby => _usingA ? _playerB : _playerA;

  StreamSubscription<PlayerState>? _activeSub;

  // ── Standby state ──────────────────────────────────────────────────────────
  // The absolute index that is currently being (or has been) pre-loaded
  // into the standby player.
  int? _standbyIdx;
  bool _standbyReady = false; // true once setUrl() completes on standby

  // ── Completion guard ───────────────────────────────────────────────────────
  bool _isHandlingCompletion = false;

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

  // ── Reciter ────────────────────────────────────────────────────────────────
  QuranReciter selectedReciter = kAllReciters.firstWhere(
    (r) => r.identifier == 'ar.minshawi',
    orElse: () => kAllReciters.first,
  );
  bool hasUserSelectedReciter = false;

  // ── Controls ───────────────────────────────────────────────────────────────
  final List<int> repetitionOptions = const [1, 2, 3, 5, -1];
  int repetitionIndex = 0;
  int _remainingLoops = 1;

  final List<int> delayOptions = const [0, 2, 5, 10, -1];
  int delayIndex = 0;

  final List<double> speedOptions = const [0.75, 1.0, 1.25, 1.5, 1.75, 2.0];
  int speedIndex = 1; // default 1.0x
  double currentSpeed = 1.0;

  // ── Data Callbacks ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _surahList = [];
  int _totalVerses = 6236;
  Map<String, dynamic>? Function(int surah, int ayah)? _getVerseData;
  void Function(int surah, int ayah)? onAyahChanged;

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

    _isHandlingCompletion = false;
    _standbyIdx = null;
    _standbyReady = false;

    _setCurrentFromSurahAyah(surah, ayah);
    isActive = true;

    // Set loop mode natively for infinite repeats
    if (repetitionOptions[repetitionIndex] == -1) {
      _playerA.setLoopMode(LoopMode.one);
      _playerB.setLoopMode(LoopMode.one);
    } else {
      _playerA.setLoopMode(LoopMode.off);
      _playerB.setLoopMode(LoopMode.off);
    }

    await _loadActiveAndPlay();
    notifyListeners();
  }

  Future<void> play() async => _active.play();

  Future<void> pause() async => _active.pause();

  Future<void> seek(Duration position) async => _active.seek(position);

  Future<void> nextAyah() async {
    if (currentAbsoluteIdx < _totalVerses) {
      _isHandlingCompletion = false;
      _updateFromAbsoluteIndex(currentAbsoluteIdx + 1);
      onAyahChanged?.call(currentSurah, currentAyah);
      notifyListeners();
      await _loadActiveAndPlay();
    }
  }

  Future<void> previousAyah() async {
    if (currentAbsoluteIdx > 1) {
      _isHandlingCompletion = false;
      _updateFromAbsoluteIndex(currentAbsoluteIdx - 1);
      onAyahChanged?.call(currentSurah, currentAyah);
      notifyListeners();
      await _loadActiveAndPlay();
    }
  }

  Future<void> changeReciter(QuranReciter reciter) async {
    selectedReciter = reciter;
    _urlCache.clear();
    _standbyIdx = null;
    _standbyReady = false;
    notifyListeners();
    await _loadActiveAndPlay();
  }

  void setRepetition(int value) {
    int idx = repetitionOptions.indexOf(value);
    if (idx != -1) {
      repetitionIndex = idx;
      _remainingLoops = value;

      if (value == -1) {
        _playerA.setLoopMode(LoopMode.one);
        _playerB.setLoopMode(LoopMode.one);
      } else {
        _playerA.setLoopMode(LoopMode.off);
        _playerB.setLoopMode(LoopMode.off);
      }
      notifyListeners();
    }
  }

  void setDelay(int optionValue) {
    delayIndex = delayOptions.indexOf(optionValue);
    notifyListeners();
  }

  void setSpeed(double speed) {
    int idx = speedOptions.indexOf(speed);
    if (idx != -1) {
      speedIndex = idx;
      currentSpeed = speed;
      _playerA.setSpeed(speed);
      _playerB.setSpeed(speed);
      notifyListeners();
    }
  }

  void stopAndDismiss() {
    _activeSub?.cancel();
    _activeSub = null;
    _playerA.stop();
    _playerB.stop();
    _isHandlingCompletion = false;
    _standbyIdx = null;
    _standbyReady = false;
    isActive = false;
    isPlaying = false;
    hasUserSelectedReciter = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Dual-player core
  // ─────────────────────────────────────────────────────────────────────────

  /// Load the current verse URL into the ACTIVE player and play it.
  /// Then kick off loading of the NEXT verse into the standby player.
  Future<void> _loadActiveAndPlay() async {
    isLoading = true;
    notifyListeners();
    lastPlaybackError = null;

    try {
      // Tear down existing listener and stop both players cleanly.
      _activeSub?.cancel();
      _activeSub = null;
      await _active.stop();

      _isHandlingCompletion = false;
      _standbyIdx = null;
      _standbyReady = false;
      await _standby.stop();

      // Resolve URL for current verse.
      final url = await _getAudioUrl(currentAbsoluteIdx);
      _remainingLoops = repetitionOptions[repetitionIndex] == -1
          ? -1
          : repetitionOptions[repetitionIndex];

      // Re-attach listener then load & play.
      _attachActiveListener();
      if (url != null) {
        try {
          final mediaItem = MediaItem(
            id: currentAbsoluteIdx.toString(),
            album: 'القرآن الكريم',
            title: 'الآية $currentAbsoluteIdx',
            artist: selectedReciter.name,
          );
          if (url.startsWith('http')) {
            await _active.setAudioSource(AudioSource.uri(Uri.parse(url), tag: mediaItem));
          } else {
            await _active.setAudioSource(AudioSource.uri(Uri.file(url), tag: mediaItem));
          }
          await _active.play();
        } catch (e) {
          debugPrint('[QuranAudio] Error setting url/playing: $e');
          // Clear standby/preload queue and surface error to UI without crashing
          _standbyIdx = null;
          _standbyReady = false;
          try {
            await _standby.stop();
          } catch (_) {}
          isActive = false;
          lastPlaybackError = e.toString();
          notifyListeners();
          return;
        }
      }

      // Begin pre-loading the NEXT verse into standby (fire-and-forget).
      _preloadStandby(currentAbsoluteIdx + 1);
    } catch (e) {
      debugPrint('[QuranAudio] Error loading active: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Silently load the next verse URL into the standby player so it's
  /// ready to play the instant the active player finishes.
  /// Also batch-prefetch URLs for 2 verses ahead into the cache.
  void _preloadStandby(int nextIdx) {
    if (nextIdx > _totalVerses) return;
    _standbyIdx = nextIdx;
    _standbyReady = false;

    // If the selected reciter only provides full-surah files, do not
    // attempt verse-by-verse preloading.
    final selectedRouting = kReciterRouting[selectedReciter.identifier];
    if (selectedRouting != null &&
        selectedRouting.type == ReciterPlaybackType.fullSurahOnly) {
      debugPrint(
          '[QuranAudio] Preload disabled for full-surah-only reciter=${selectedReciter.identifier}');
      return;
    }

    for (int ahead = 1; ahead <= 2; ahead++) {
      final futureIdx = nextIdx + ahead;
      if (futureIdx <= _totalVerses && !_urlCache.containsKey(futureIdx)) {
        int remaining = futureIdx;
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
        _getAudioUrl(futureIdx,
            prefetchSurah: targetSurah,
            prefetchAyah: remaining); // fire-and-forget, populates _urlCache
      }
    }

    _getAudioUrl(nextIdx).then((url) async {
      // Abort if we've since moved on (user skipped or stopped).
      if (_standbyIdx != nextIdx || !isActive) return;
      if (url == null) return;

      try {
        final mediaItem = MediaItem(
          id: nextIdx.toString(),
          album: 'القرآن الكريم',
          title: 'الآية $nextIdx',
          artist: selectedReciter.name,
        );
        if (url.startsWith('http')) {
          await _standby.setAudioSource(AudioSource.uri(Uri.parse(url), tag: mediaItem));
        } else {
          await _standby.setAudioSource(AudioSource.uri(Uri.file(url), tag: mediaItem));
        }
        // Only mark ready if still targeting the same index.
        if (_standbyIdx == nextIdx && isActive) {
          _standbyReady = true;
          debugPrint(
              '[QuranAudio] Standby ready for idx=$nextIdx (local: ${url.startsWith('/')})');
        }
      } catch (e) {
        debugPrint('[QuranAudio] Failed to preload standby idx=$nextIdx: $e');
      }
    });
  }

  void _attachActiveListener() {
    _activeSub?.cancel();
    _activeSub = _active.playerStateStream.listen((state) {
      isPlaying =
          state.playing && state.processingState != ProcessingState.completed;
      notifyListeners();

      if (state.processingState == ProcessingState.completed) {
        if (!_isHandlingCompletion) {
          _isHandlingCompletion = true;
          _handleCompletion();
        }
      }
    });
  }

  Future<void> _handleCompletion() async {
    // ── Repetition ────────────────────────────────────────────────────────
    if (_remainingLoops > 1) {
      _remainingLoops--;
      await _active.seek(Duration.zero);
      await _active.play();
      _isHandlingCompletion = false;
      return;
    } else if (repetitionOptions[repetitionIndex] == -1) {
      // Infinite repeat is natively handled by LoopMode.one, so we should never hit this.
      _isHandlingCompletion = false;
      return;
    }

    // Reset loop counter for the next verse
    _remainingLoops = repetitionOptions[repetitionIndex];

    // ── Delay ─────────────────────────────────────────────────────────────
    final delay = delayOptions[delayIndex];
    if (delay > 0) {
      await Future.delayed(Duration(seconds: delay));
    } else if (delay == -1) {
      final dur = _active.duration ?? const Duration(seconds: 3);
      await Future.delayed(dur);
    }

    // ── Advance to next verse ─────────────────────────────────────────────
    if (currentAbsoluteIdx >= _totalVerses) {
      stopAndDismiss();
      return;
    }

    final nextIdx = currentAbsoluteIdx + 1;
    _updateFromAbsoluteIndex(nextIdx);
    onAyahChanged?.call(currentSurah, currentAyah);
    notifyListeners();

    // ── Gapless swap ──────────────────────────────────────────────────────
    if (_standbyReady && _standbyIdx == nextIdx) {
      // Standby is already loaded → INSTANT swap, zero gap.
      debugPrint('[QuranAudio] Gapless swap to idx=$nextIdx');

      // Detach active listener before swap.
      _activeSub?.cancel();
      _activeSub = null;

      // Swap the player roles.
      _usingA = !_usingA;
      streamKey++;
      _isHandlingCompletion = false;
      _standbyIdx = null;
      _standbyReady = false;

      // Attach listener to the new active (was standby).
      _attachActiveListener();
      await _active.play();

      // Kick off preload for verse N+1.
      _preloadStandby(currentAbsoluteIdx + 1);
    } else {
      // Standby wasn't ready in time — fall back to normal load.
      debugPrint(
          '[QuranAudio] Standby not ready, loading idx=$nextIdx normally');
      await _loadActiveAndPlay();
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
    _playerA.dispose();
    _playerB.dispose();
    super.dispose();
  }
}
