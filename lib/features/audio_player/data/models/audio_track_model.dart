// ─────────────────────────────────────────────────────────────────────────────
// Enums
// ─────────────────────────────────────────────────────────────────────────────

/// Broad content category for audio tracks.
enum AudioCategory {
  quranRecitation,    // Full Quran recitation by a qari
  quranSurah,         // Single surah excerpt
  dawahLecture,       // Da'wah / Islamic lecture
  haramainLive,       // Live Makkah or Madinah stream
  nasheed,            // Islamic vocal/nasheed
  podcast,            // Scholar podcast episode
  azkar,              // Audio Azkar
}

/// Playback language tag — mirrors the app's 4 active locales.
enum AudioLanguage { arabic, english, amharic, oromo, multilingual }

/// Current caching/download state for this track.
enum AudioCacheState {
  notCached,        // not downloaded; plays over network only
  downloading,      // download in progress
  cached,           // fully downloaded and usable offline
  cacheError,       // download failed
  stale,            // cached but source has a newer version
}

// ─────────────────────────────────────────────────────────────────────────────
// ScholarInfo — embedded scholar/reciter metadata
// ─────────────────────────────────────────────────────────────────────────────

class ScholarInfo {
  const ScholarInfo({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    this.nationality,
    this.imageUrl,
    this.bio,
  });

  final String id;
  final String nameAr;
  final String nameEn;
  final String? nationality;   // ISO 3166-1 alpha-2 e.g. "SA", "EG"
  final String? imageUrl;
  final String? bio;

  Map<String, dynamic> toJson() => {
        'id': id,
        'nameAr': nameAr,
        'nameEn': nameEn,
        'nationality': nationality,
        'imageUrl': imageUrl,
        'bio': bio,
      };

  factory ScholarInfo.fromJson(Map<String, dynamic> json) => ScholarInfo(
        id: json['id'] as String,
        nameAr: json['nameAr'] as String,
        nameEn: json['nameEn'] as String,
        nationality: json['nationality'] as String?,
        imageUrl: json['imageUrl'] as String?,
        bio: json['bio'] as String?,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// AudioTrackModel — the primary media item model
// ─────────────────────────────────────────────────────────────────────────────

/// Represents a single audio item in the app's media library.
///
/// Handles:
/// - **Streaming** via [streamUrl] (online) or [localPath] (offline).
/// - **Caching** state tracking via [cacheState] and [cachedFileSizeBytes].
/// - **Resource IDs** for grouping by surah, reciter, or lecture series.
/// - **Live streams** (e.g., Haramain) flagged via [isLiveStream].
/// - **Scholar details** embedded via [scholar].
class AudioTrackModel {
  const AudioTrackModel({
    required this.id,
    required this.title,
    required this.titleAr,
    required this.scholar,
    required this.category,
    required this.language,
    required this.streamUrl,
    this.localPath,
    this.coverImageUrl,
    this.durationSeconds,
    this.surahNumber,
    this.juzNumber,
    this.seriesId,
    this.episodeIndex,
    this.cacheState = AudioCacheState.notCached,
    this.cachedFileSizeBytes,
    this.downloadProgress = 0.0,
    this.isLiveStream = false,
    this.liveStreamQualityOptions = const {},
    this.isFavourited = false,
    this.playCount = 0,
    this.lastPlayedAt,
    this.tags = const [],
    this.bitrate,
  });

  /// Unique track identifier (UUID or slug).
  final String id;

  final String title;
  final String titleAr;
  final ScholarInfo scholar;
  final AudioCategory category;
  final AudioLanguage language;

  // ── Sources ───────────────────────────────────────────────────────────────

  /// Primary network URL (HTTP/HLS). Used when not cached.
  final String streamUrl;

  /// Absolute local file path if [cacheState] == [AudioCacheState.cached].
  final String? localPath;

  /// Thumbnail/cover art URL — used in the media library list and audio bar.
  final String? coverImageUrl;

  /// Total duration in seconds. May be null for live streams or before fetch.
  final int? durationSeconds;

  // ── Resource Identifiers ─────────────────────────────────────────────────

  /// Surah number (1–114). Non-null for Quran tracks.
  final int? surahNumber;

  /// Juz number (1–30). Non-null for Quran tracks.
  final int? juzNumber;

  /// Series / playlist ID — links episodes in a lecture series or podcast.
  final String? seriesId;

  /// Zero-based episode/track index within its [seriesId].
  final int? episodeIndex;

  // ── Cache ─────────────────────────────────────────────────────────────────

  final AudioCacheState cacheState;

  /// File size of the cached download in bytes. Null if not cached.
  final int? cachedFileSizeBytes;

  /// Download progress 0.0–1.0. Meaningful only when [cacheState] is
  /// [AudioCacheState.downloading].
  final double downloadProgress;

  // ── Live Stream ───────────────────────────────────────────────────────────

  /// True for 24/7 live feeds (Makkah, Madinah Haramain streams).
  final bool isLiveStream;

  /// Map of quality label → URL, e.g. {"HD": "...", "SD": "..."}.
  final Map<String, String> liveStreamQualityOptions;

  // ── User State ────────────────────────────────────────────────────────────

  final bool isFavourited;
  final int playCount;
  final DateTime? lastPlayedAt;

  /// Free-form tags for search (e.g. ["tazkiyah", "ramadan", "seerah"]).
  final List<String> tags;

  /// Audio bitrate in kbps. Used in storage management UI.
  final int? bitrate;

  // ── Derived Helpers ────────────────────────────────────────────────────────

  bool get isOfflineAvailable =>
      localPath != null && cacheState == AudioCacheState.cached;

  bool get isQuranContent =>
      category == AudioCategory.quranRecitation ||
      category == AudioCategory.quranSurah;

  String get effectiveUrl => isOfflineAvailable ? localPath! : streamUrl;

  /// Formatted duration string (MM:SS or HH:MM:SS).
  String get formattedDuration {
    if (durationSeconds == null) return isLiveStream ? 'LIVE' : '--:--';
    final h = durationSeconds! ~/ 3600;
    final m = (durationSeconds! % 3600) ~/ 60;
    final s = durationSeconds! % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Cached file size formatted for storage management UI (e.g. "47.3 MB").
  String get formattedCacheSize {
    if (cachedFileSizeBytes == null) return '—';
    final mb = cachedFileSizeBytes! / (1024 * 1024);
    return '${mb.toStringAsFixed(1)} MB';
  }

  AudioTrackModel copyWith({
    String? id,
    String? title,
    String? titleAr,
    ScholarInfo? scholar,
    AudioCategory? category,
    AudioLanguage? language,
    String? streamUrl,
    String? localPath,
    String? coverImageUrl,
    int? durationSeconds,
    int? surahNumber,
    int? juzNumber,
    String? seriesId,
    int? episodeIndex,
    AudioCacheState? cacheState,
    int? cachedFileSizeBytes,
    double? downloadProgress,
    bool? isLiveStream,
    Map<String, String>? liveStreamQualityOptions,
    bool? isFavourited,
    int? playCount,
    DateTime? lastPlayedAt,
    List<String>? tags,
    int? bitrate,
  }) {
    return AudioTrackModel(
      id: id ?? this.id,
      title: title ?? this.title,
      titleAr: titleAr ?? this.titleAr,
      scholar: scholar ?? this.scholar,
      category: category ?? this.category,
      language: language ?? this.language,
      streamUrl: streamUrl ?? this.streamUrl,
      localPath: localPath ?? this.localPath,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      surahNumber: surahNumber ?? this.surahNumber,
      juzNumber: juzNumber ?? this.juzNumber,
      seriesId: seriesId ?? this.seriesId,
      episodeIndex: episodeIndex ?? this.episodeIndex,
      cacheState: cacheState ?? this.cacheState,
      cachedFileSizeBytes: cachedFileSizeBytes ?? this.cachedFileSizeBytes,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isLiveStream: isLiveStream ?? this.isLiveStream,
      liveStreamQualityOptions:
          liveStreamQualityOptions ?? this.liveStreamQualityOptions,
      isFavourited: isFavourited ?? this.isFavourited,
      playCount: playCount ?? this.playCount,
      lastPlayedAt: lastPlayedAt ?? this.lastPlayedAt,
      tags: tags ?? this.tags,
      bitrate: bitrate ?? this.bitrate,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'titleAr': titleAr,
        'scholar': scholar.toJson(),
        'category': category.name,
        'language': language.name,
        'streamUrl': streamUrl,
        'localPath': localPath,
        'coverImageUrl': coverImageUrl,
        'durationSeconds': durationSeconds,
        'surahNumber': surahNumber,
        'juzNumber': juzNumber,
        'seriesId': seriesId,
        'episodeIndex': episodeIndex,
        'cacheState': cacheState.name,
        'cachedFileSizeBytes': cachedFileSizeBytes,
        'downloadProgress': downloadProgress,
        'isLiveStream': isLiveStream,
        'liveStreamQualityOptions': liveStreamQualityOptions,
        'isFavourited': isFavourited,
        'playCount': playCount,
        'lastPlayedAt': lastPlayedAt?.toIso8601String(),
        'tags': tags,
        'bitrate': bitrate,
      };

  factory AudioTrackModel.fromJson(Map<String, dynamic> json) {
    return AudioTrackModel(
      id: json['id'] as String,
      title: json['title'] as String,
      titleAr: json['titleAr'] as String? ?? '',
      scholar: ScholarInfo.fromJson(
          json['scholar'] as Map<String, dynamic>),
      category: AudioCategory.values
          .byName(json['category'] as String? ?? 'dawahLecture'),
      language: AudioLanguage.values
          .byName(json['language'] as String? ?? 'arabic'),
      streamUrl: json['streamUrl'] as String,
      localPath: json['localPath'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      durationSeconds: json['durationSeconds'] as int?,
      surahNumber: json['surahNumber'] as int?,
      juzNumber: json['juzNumber'] as int?,
      seriesId: json['seriesId'] as String?,
      episodeIndex: json['episodeIndex'] as int?,
      cacheState: AudioCacheState.values
          .byName(json['cacheState'] as String? ?? 'notCached'),
      cachedFileSizeBytes: json['cachedFileSizeBytes'] as int?,
      downloadProgress:
          (json['downloadProgress'] as num?)?.toDouble() ?? 0.0,
      isLiveStream: json['isLiveStream'] as bool? ?? false,
      liveStreamQualityOptions:
          (json['liveStreamQualityOptions'] as Map<String, dynamic>? ?? {})
              .map((k, v) => MapEntry(k, v as String)),
      isFavourited: json['isFavourited'] as bool? ?? false,
      playCount: json['playCount'] as int? ?? 0,
      lastPlayedAt: json['lastPlayedAt'] != null
          ? DateTime.parse(json['lastPlayedAt'] as String)
          : null,
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((t) => t as String)
          .toList(),
      bitrate: json['bitrate'] as int?,
    );
  }
}
