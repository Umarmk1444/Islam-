import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reciter Model
// ─────────────────────────────────────────────────────────────────────────────

class QuranReciter {
  final int id;
  final String name;
  final String identifier;

  const QuranReciter({
    required this.id,
    required this.name,
    required this.identifier,
  });
}

/// Verified reciters — identifiers are everyayah.com folder identifiers.
const List<QuranReciter> kAllReciters = [
  QuranReciter(id: 1,  name: 'مشاري راشد العفاسي',          identifier: 'Alafasy_128kbps'),
  QuranReciter(id: 2,  name: 'عبد الباسط عبد الصمد (مرتل)', identifier: 'Abdul_Basit_Murattal_192kbps'),
  QuranReciter(id: 3,  name: 'عبد الباسط عبد الصمد (مجود)', identifier: 'Abdul_Basit_Mujawwad_128kbps'),
  QuranReciter(id: 4,  name: 'محمود خليل الحصري',            identifier: 'Husary_128kbps'),
  QuranReciter(id: 5,  name: 'محمد صديق المنشاوي',           identifier: 'Minshawy_Murattal_128kbps'),
  QuranReciter(id: 6,  name: 'عبد الرحمن السديس',            identifier: 'Abdurrahmaan_As-Sudais_192kbps'),
  QuranReciter(id: 7,  name: 'أبو بكر الشاطري',              identifier: 'Abu_Bakr_Ash-Shaatree_128kbps'),
  QuranReciter(id: 8,  name: 'أحمد العجمي',                  identifier: 'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net'),
  QuranReciter(id: 9,  name: 'عبد الله بصفر',                identifier: 'Abdullah_Basfar_192kbps'),
  QuranReciter(id: 10, name: 'سعد الغامدي',                  identifier: 'Saad_Al_Ghamdi_128kbps'),
  QuranReciter(id: 11, name: 'ناصر القطامي',                 identifier: 'Nasser_Alqatami_128kbps'),
];

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
  AudioPlayer _playerA = AudioPlayer();
  AudioPlayer _playerB = AudioPlayer();
  bool _usingA = true;

  /// Increments every time the active player swaps.
  /// UI widgets can key StreamBuilders on this to reconnect to the new stream.
  int streamKey = 0;

  AudioPlayer get _active  => _usingA ? _playerA : _playerB;
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
  final Map<int, String> _urlCache = {};

  // ── Download Progress State ────────────────────────────────────────────────
  bool isDownloading = false;
  double downloadProgress = 0.0;
  bool isActive  = false;
  bool isPlaying = false;
  bool isLoading = false;

  // ── Streams (always from the active player) ────────────────────────────────
  Stream<Duration> get positionStream => _active.positionStream;
  Stream<Duration?> get durationStream => _active.durationStream;

  // ── Verse Tracking ─────────────────────────────────────────────────────────
  int currentSurah        = 1;
  int currentAyah         = 1;
  int currentAbsoluteIdx  = 1;
  String currentSurahName = '';
  String currentVerseText = '';

  // ── Reciter ────────────────────────────────────────────────────────────────
  QuranReciter selectedReciter = kAllReciters.first;
  bool hasUserSelectedReciter = false;

  // ── Controls ───────────────────────────────────────────────────────────────
  final List<int> repetitionOptions = const [1, 2, 3, 5, -1];
  int repetitionIndex = 0;
  int _remainingLoops = 1;

  final List<int> delayOptions = const [0, 2, 5, 10, -1];
  int delayIndex = 0;

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
    _surahList    = surahList;
    _totalVerses  = totalVerses;
    _getVerseData = getVerseData;
    this.onAyahChanged = onAyahChanged;

    _isHandlingCompletion = false;
    _standbyIdx   = null;
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
    _standbyIdx   = null;
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
  } void setDelay(int optionValue) {
    delayIndex = delayOptions.indexOf(optionValue);
    notifyListeners();
  }

  void stopAndDismiss() {
    _activeSub?.cancel();
    _activeSub = null;
    _playerA.stop();
    _playerB.stop();
    _isHandlingCompletion = false;
    _standbyIdx   = null;
    _standbyReady = false;
    isActive  = false;
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

    try {
      // Tear down existing listener and stop both players cleanly.
      _activeSub?.cancel();
      _activeSub = null;
      await _active.stop();

      _isHandlingCompletion = false;
      _standbyIdx   = null;
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
          if (url.startsWith('http')) {
            await _active.setUrl(url);
          } else {
            await _active.setFilePath(url);
          }
          await _active.play();
        } catch (e) {
          debugPrint('[QuranAudio] Error setting url/playing: $e');
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
    _standbyIdx   = nextIdx;
    _standbyReady = false;

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
        _getAudioUrl(futureIdx, prefetchSurah: targetSurah, prefetchAyah: remaining); // fire-and-forget, populates _urlCache
      }
    }

    _getAudioUrl(nextIdx).then((url) async {
      // Abort if we've since moved on (user skipped or stopped).
      if (_standbyIdx != nextIdx || !isActive) return;
      if (url == null) return;

      try {
        if (url.startsWith('http')) {
          await _standby.setUrl(url);
        } else {
          await _standby.setFilePath(url);
        }
        // Only mark ready if still targeting the same index.
        if (_standbyIdx == nextIdx && isActive) {
          _standbyReady = true;
          debugPrint('[QuranAudio] Standby ready for idx=$nextIdx (local: ${url.startsWith('/')})');
        }
      } catch (e) {
        debugPrint('[QuranAudio] Failed to preload standby idx=$nextIdx: $e');
      }
    });
  }

  void _attachActiveListener() {
    _activeSub?.cancel();
    _activeSub = _active.playerStateStream.listen((state) {
      isPlaying = state.playing &&
          state.processingState != ProcessingState.completed;
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
      _standbyIdx   = null;
      _standbyReady = false;

      // Attach listener to the new active (was standby).
      _attachActiveListener();
      await _active.play();

      // Kick off preload for verse N+1.
      _preloadStandby(currentAbsoluteIdx + 1);
    } else {
      // Standby wasn't ready in time — fall back to normal load.
      debugPrint('[QuranAudio] Standby not ready, loading idx=$nextIdx normally');
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

  Future<String?> _getAudioUrl(int absoluteIdx, {int? prefetchSurah, int? prefetchAyah}) async {
    if (absoluteIdx < 1 || absoluteIdx > _totalVerses) return null;

    if (_urlCache.containsKey(absoluteIdx)) {
      return _urlCache[absoluteIdx];
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
      final surahPad = s.toString().padLeft(3, '0');
      final ayahPad = a.toString().padLeft(3, '0');
      final url = 'https://everyayah.com/data/$id/$surahPad$ayahPad.mp3';
      _urlCache[absoluteIdx] = url;
      debugPrint('[QuranAudio] Generated EveryAyah URL for idx=$absoluteIdx (Web Fallback)');
      return url;
    }

    final filename = '${id}_${s}_$a.mp3';
    final dirPath = await _getDirPath();
    final localPath = '$dirPath/$filename';

    // 1. Check if true local offline file exists
    if (await File(localPath).exists()) {
      _urlCache[absoluteIdx] = localPath;
      debugPrint('[QuranAudio] Found LOCAL audio for idx=$absoluteIdx');
      return localPath;
    }

    // 2. Fallback to EveryAyah direct MP3 URL
    final surahPad = s.toString().padLeft(3, '0');
    final ayahPad = a.toString().padLeft(3, '0');
    final url = 'https://everyayah.com/data/$id/$surahPad$ayahPad.mp3';
    
    _urlCache[absoluteIdx] = url;
    debugPrint('[QuranAudio] Generated EveryAyah URL for idx=$absoluteIdx');
    return url;
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
      final surahPad = surahNumber.toString().padLeft(3, '0');

      for (int a = 1; a <= totalVerses; a++) {
        if (!isDownloading) break; // Check for cancellation

        final filename = '${id}_${surahNumber}_$a.mp3';
        final localPath = '$dirPath/$filename';

        if (!await File(localPath).exists()) {
          final ayahPad = a.toString().padLeft(3, '0');
          final url = 'https://everyayah.com/data/$id/$surahPad$ayahPad.mp3';
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
      final surahPad = surahNumber.toString().padLeft(3, '0');
      final ayahPad = ayahNumber.toString().padLeft(3, '0');

      final filename = '${id}_${surahNumber}_$ayahNumber.mp3';
      final localPath = '$dirPath/$filename';

      if (!await File(localPath).exists()) {
        final url = 'https://everyayah.com/data/$id/$surahPad$ayahPad.mp3';
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

  // ─────────────────────────────────────────────────────────────────────────
  // Index helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _updateFromAbsoluteIndex(int absoluteIndex) {
    if (absoluteIndex < 1 || absoluteIndex > _totalVerses) return;

    int remaining   = absoluteIndex;
    int targetSurah = 1;
    for (final s in _surahList) {
      final total = s['totalVerses'] as int;
      if (remaining <= total) {
        targetSurah = s['number'] as int;
        break;
      }
      remaining  -= total;
      targetSurah++;
    }
    final targetAyah = remaining;
    currentAbsoluteIdx = absoluteIndex;
    _setCurrentFromSurahAyah(targetSurah, targetAyah);
  }

  void _setCurrentFromSurahAyah(int surah, int ayah) {
    currentSurah = surah;
    currentAyah  = ayah;
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
