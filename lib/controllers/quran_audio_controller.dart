import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reciter Model
// ─────────────────────────────────────────────────────────────────────────────

class QuranReciter {
  final int id;
  final String name;
  final String identifier; // CDN subdirectory identifier

  const QuranReciter({
    required this.id,
    required this.name,
    required this.identifier,
  });
}

// 12 verified reciters using cdn.islamic.network identifiers
const List<QuranReciter> kAllReciters = [
  QuranReciter(id: 1,  name: 'مشاري راشد العفاسي',          identifier: 'ar.alafasy'),
  QuranReciter(id: 2,  name: 'عبد الباسط عبد الصمد (مرتل)', identifier: 'ar.abdulsamad'),
  QuranReciter(id: 3,  name: 'عبد الباسط عبد الصمد (مجود)', identifier: 'ar.abdulsamadmujawwad'),
  QuranReciter(id: 4,  name: 'محمود خليل الحصري',            identifier: 'ar.husary'),
  QuranReciter(id: 5,  name: 'محمد صديق المنشاوي',           identifier: 'ar.minshawi'),
  QuranReciter(id: 6,  name: 'سعود الشريم',                  identifier: 'ar.shuraim'),
  QuranReciter(id: 7,  name: 'عبد الرحمن السديس',            identifier: 'ar.sudais'),
  QuranReciter(id: 8,  name: 'ماهر المعيقلي',                identifier: 'ar.mahermuaiqly'),
  QuranReciter(id: 9,  name: 'سعد الغامدي',                  identifier: 'ar.saadalghamidi'),
  QuranReciter(id: 10, name: 'ياسر الدوسري',                 identifier: 'ar.yasseraddussary'),
  QuranReciter(id: 11, name: 'ناصر القطامي',                 identifier: 'ar.qatami'),
  QuranReciter(id: 12, name: 'بدر التركي',                   identifier: 'ar.badrturkiafasy'),
];

// ─────────────────────────────────────────────────────────────────────────────
// Global Audio Controller (Singleton ChangeNotifier)
// ─────────────────────────────────────────────────────────────────────────────

class QuranAudioController extends ChangeNotifier {
  // ── Singleton ──────────────────────────────────────────────────────────────
  QuranAudioController._internal();
  static final QuranAudioController instance = QuranAudioController._internal();

  // ── Audio Engine ───────────────────────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<PlayerState>? _stateSub;

  // ── Playback State ─────────────────────────────────────────────────────────
  bool isActive  = false; // Whether the mini-player bar should be shown
  bool isPlaying = false;
  bool isLoading = false;

  // ── Verse Tracking ─────────────────────────────────────────────────────────
  int currentSurah        = 1;
  int currentAyah         = 1;
  int currentAbsoluteIdx  = 1;
  String currentSurahName = '';
  String currentVerseText = '';

  // ── Reciter ────────────────────────────────────────────────────────────────
  QuranReciter selectedReciter = kAllReciters.first;

  // ── Controls ───────────────────────────────────────────────────────────────
  // Repetition: 1=play once, 2/3/5=repeat N times, -1=infinite
  final List<int> repetitionOptions = const [1, 2, 3, 5, -1];
  int repetitionIndex = 0;
  int _remainingLoops = 1; // runtime counter

  // Delay: 0=none, 2/5/10=seconds, -1=verse duration
  final List<int> delayOptions = const [0, 2, 5, 10, -1];
  int delayIndex = 0;

  // ── Data Callbacks (set by QuranScreen via startPlayback) ─────────────────
  List<Map<String, dynamic>> _surahList = [];
  int _totalVerses = 6236;
  Map<String, dynamic>? Function(int surah, int ayah)? _getVerseData;

  // Callback so QuranScreen can scroll/highlight the new active ayah
  void Function(int surah, int ayah)? onAyahChanged;

  // ─────────────────────────────────────────────────────────────────────────
  // Public API
  // ─────────────────────────────────────────────────────────────────────────

  /// Call this from the Action Grid's 'Listen' button.
  Future<void> startPlayback({
    required int surah,
    required int ayah,
    required List<Map<String, dynamic>> surahList,
    required int totalVerses,
    required Map<String, dynamic>? Function(int, int) getVerseData,
    void Function(int surah, int ayah)? onAyahChanged,
  }) async {
    _surahList   = surahList;
    _totalVerses = totalVerses;
    _getVerseData = getVerseData;
    this.onAyahChanged = onAyahChanged;

    _setCurrentFromSurahAyah(surah, ayah);
    isActive = true;
    _initStateListener();
    await _loadAndPlay();
    notifyListeners();
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> nextAyah() async {
    if (currentAbsoluteIdx < _totalVerses) {
      _updateFromAbsoluteIndex(currentAbsoluteIdx + 1);
      await _loadAndPlay();
    }
  }

  Future<void> previousAyah() async {
    if (currentAbsoluteIdx > 1) {
      _updateFromAbsoluteIndex(currentAbsoluteIdx - 1);
      await _loadAndPlay();
    }
  }

  Future<void> changeReciter(QuranReciter reciter) async {
    selectedReciter = reciter;
    notifyListeners();
    await _loadAndPlay();
  }

  void setRepetition(int optionValue) {
    repetitionIndex = repetitionOptions.indexOf(optionValue);
    _remainingLoops = optionValue;
    notifyListeners();
  }

  void setDelay(int optionValue) {
    delayIndex = delayOptions.indexOf(optionValue);
    notifyListeners();
  }

  void stopAndDismiss() {
    _player.stop();
    isActive  = false;
    isPlaying = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Internal helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _initStateListener() {
    _stateSub?.cancel();
    _stateSub = _player.playerStateStream.listen((state) {
      isPlaying = state.playing &&
          state.processingState != ProcessingState.completed;
      notifyListeners();

      if (state.processingState == ProcessingState.completed) {
        _handleCompletion();
      }
    });
  }

  Future<void> _loadAndPlay() async {
    isLoading = true;
    notifyListeners();

    try {
      final url =
          'https://cdn.islamic.network/quran/audio/128/${selectedReciter.identifier}/$currentAbsoluteIdx.mp3';
      await _player.setUrl(url);
      _remainingLoops = repetitionOptions[repetitionIndex];
      await _player.play();
    } catch (e) {
      debugPrint('[QuranAudioController] Error loading audio: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _handleCompletion() async {
    // ── Step 1: Repetition check ──────────────────────────────────────────
    if (_remainingLoops == -1 || _remainingLoops > 1) {
      if (_remainingLoops != -1) _remainingLoops--;
      await _player.seek(Duration.zero);
      await _player.play();
      return;
    }

    // ── Step 2: Delay check ───────────────────────────────────────────────
    final delay = delayOptions[delayIndex];
    if (delay > 0) {
      await Future.delayed(Duration(seconds: delay));
    } else if (delay == -1) {
      // Delay equal to verse duration
      final dur = _player.duration ?? const Duration(seconds: 3);
      await Future.delayed(dur);
    }

    // ── Step 3: Advance to next ayah ─────────────────────────────────────
    if (currentAbsoluteIdx < _totalVerses) {
      _updateFromAbsoluteIndex(currentAbsoluteIdx + 1);
      // Notify host screen to scroll/highlight
      onAyahChanged?.call(currentSurah, currentAyah);
      await _loadAndPlay();
    } else {
      stopAndDismiss();
    }
  }

  /// Resolves surah+ayah from an absolute index (1-based, 1–6236).
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
    _stateSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
