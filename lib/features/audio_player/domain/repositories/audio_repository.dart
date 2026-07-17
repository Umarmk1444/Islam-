import '../../data/models/audio_track_model.dart';

/// Abstract repository contract for audio library and streaming operations.
///
/// Implementation in `data/repositories/audio_repository_impl.dart`.
abstract class AudioRepository {
  // ── Library Queries ────────────────────────────────────────────────────────

  /// Returns all tracks matching the given filters.
  /// Pass null to omit a filter (returns all values for that dimension).
  Future<List<AudioTrackModel>> getTracks({
    AudioCategory? category,
    AudioLanguage? language,
    int? surahNumber,
    String? seriesId,
    bool favouritesOnly = false,
  });

  /// Returns the track with [id], or null if not found.
  Future<AudioTrackModel?> getTrackById(String id);

  /// Returns all available live stream entries (Haramain feeds).
  Future<List<AudioTrackModel>> getLiveStreams();

  /// Returns the track that was last played by [userId].
  Future<AudioTrackModel?> getLastPlayedTrack(String userId);

  // ── Cache / Download Management ────────────────────────────────────────────

  /// Starts downloading [track] to local storage.
  /// Emits progress 0.0–1.0 via the returned [Stream].
  Stream<double> downloadTrack(AudioTrackModel track);

  /// Deletes the local cached file for [track], freeing device storage.
  Future<void> deleteCachedTrack(AudioTrackModel track);

  /// Returns the total bytes occupied by all cached tracks.
  Future<int> getTotalCacheBytes();

  /// Deletes ALL cached tracks. Used in the storage management UI.
  Future<void> clearAllCache();

  // ── User State ─────────────────────────────────────────────────────────────

  /// Toggles the favourited state for [trackId].
  Future<void> toggleFavourite(String trackId);

  /// Records that [trackId] was played (increments playCount, sets lastPlayedAt).
  Future<void> recordPlay({
    required String userId,
    required String trackId,
  });

  // ── AI Recitation ──────────────────────────────────────────────────────────

  /// Submits a raw PCM audio buffer [audioBytes] (16-bit, 16 kHz, mono)
  /// for recitation analysis.
  ///
  /// [referenceAyahId] is the target ayah in "surah:ayah" format (e.g. "36:1").
  ///
  /// Returns a map containing:
  ///   - "score": double (0.0–1.0)
  ///   - "mistakes": List<Map> with word-level mistake details
  ///   - "feedback": String — localised human-readable feedback
  Future<Map<String, dynamic>> analyseRecitation({
    required List<int> audioBytes,
    required String referenceAyahId,
    String language = 'ar',
  });
}
