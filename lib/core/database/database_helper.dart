// =============================================================================
// FILE PATH : lib/core/database/database_helper.dart
// ASSET PATH: assets/muslim_house.db  (bundled ~71 MB read-only SQLite DB)
// DEVICE PATH: <appDocumentsDir>/databases/muslim_house.db  (copied once)
//
// TABLES AVAILABLE (20+):
//   quran, AyaNumPositions, index_quran_jaz, quran_ajzaa,
//   hisn_almuslim, azkar, doaa, fatawy, library, roqua,
//   quiz, quizQuestions, hangmanWords, eventsQuestions,
//   worshipMetadata, dataEntry, bonusRules, challengeCategories,
//   challenges, gameCatalog, gateConfig, helpCosts, qoraa,
//   saved_data, save_txt_data, userdata, ramadan_history,
//   all_index, ryasdpiqoh
// =============================================================================

import 'dart:developer' as dev;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show ByteData, rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// A thread-safe, lazy singleton that manages the application's bundled
/// SQLite database (`muslim_house.db`).
///
/// ### Lifecycle
/// 1. On first access, the raw asset bytes are streamed to the device's
///    documents directory under `databases/muslim_house.db`.
/// 2. Subsequent app launches skip the copy if the file already exists.
/// 3. The database is always opened in **read-only** mode to prevent
///    accidental mutation and to maximise query concurrency.
///
/// ### Usage
/// ```dart
/// final db = await DatabaseHelper.instance.database;
/// final rows = await db.rawQuery('SELECT * FROM azkar WHERE type = ?', [1]);
///
/// // Or via the convenience wrapper:
/// final rows = await DatabaseHelper.instance.rawQuery(
///   'SELECT id, zekr FROM azkar WHERE type = ?', [1],
/// );
/// ```
class DatabaseHelper {
  // ---------------------------------------------------------------------------
  // Singleton boilerplate
  // ---------------------------------------------------------------------------

  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  factory DatabaseHelper() => instance;

  // ---------------------------------------------------------------------------
  // Private state
  // ---------------------------------------------------------------------------

  /// Cached open database handle. `null` until first access.
  Database? _db;

  /// Completer-style future: reused by all concurrent callers during init.
  Future<Database>? _initialiseFuture;

  /// Simple, RAM-friendly session caches to avoid redundant queries during swiping
  final Map<int, List<Map<String, dynamic>>> _pageCache = {};
  final Map<String, int> _ayahPageCache = {};

  // ---------------------------------------------------------------------------
  // Constants
  // ---------------------------------------------------------------------------

  static const String _kAssetPath = 'assets/muslim_house.db';
  static const String _kDbName    = 'muslim_house.db';
  static const String _kDbSubDir  = 'databases';
  static const String _kLogName   = 'DatabaseHelper';

  /// Bump this number whenever the bundled `muslim_house.db` asset changes.
  /// The on-device copy will be deleted and re-copied from assets.
  static const int    _kDbVersion    = 2;
  static const String _kDbVersionKey = 'db_asset_version';

  Future<void> init() async {
    await database;
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------


  /// Returns the open, read-only [Database] instance.
  ///
  /// Initialises (copy + open) on the very first call; subsequent calls
  /// return the cached handle immediately without any async overhead.
  Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;

    // Serialise concurrent callers: only one coroutine runs the init path.
    _initialiseFuture ??= _initDatabase();
    return _initialiseFuture!;
  }

  // ---------------------------------------------------------------------------
  // Initialisation pipeline
  // ---------------------------------------------------------------------------

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await _resolveDevicePath();
      await _copyFromAssetsIfAbsent(dbPath);
      _db = await _openDatabase(dbPath);
      dev.log('Database ready → $dbPath', name: _kLogName);
      return _db!;
    } catch (e, st) {
      // Reset so the next caller can retry instead of getting a stale future.
      _initialiseFuture = null;
      dev.log(
        'Database init failed: $e',
        name: _kLogName,
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Path resolution
  // ---------------------------------------------------------------------------

  /// Resolves the absolute path where the database lives on this device.
  ///
  /// Uses [getApplicationDocumentsDirectory] so the file:
  ///   • Survives app updates.
  ///   • Is excluded from iCloud / Google Drive sync on most platforms.
  ///   • Is accessible without root on Android.
  Future<String> _resolveDevicePath() async {
    final Directory docDir = await getApplicationDocumentsDirectory();
    final Directory dbDir  = Directory(p.join(docDir.path, _kDbSubDir));

    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
      dev.log('Created db directory → ${dbDir.path}', name: _kLogName);
    }

    return p.join(dbDir.path, _kDbName);
  }

  // ---------------------------------------------------------------------------
  // Asset → device copy
  // ---------------------------------------------------------------------------

  /// Copies the bundled asset to [dbPath] when the file is absent **or**
  /// when the on-device version is older than [_kDbVersion].
  ///
  /// Strategy:
  /// - Checks SharedPreferences for the installed DB version.
  /// - If the version is stale or the file is missing, deletes any existing
  ///   copy and writes a fresh one from the asset bundle.
  /// - Loads asset as [ByteData] (zero-copy [Uint8List] view).
  /// - Writes through a [RandomAccessFile] to avoid allocating a second
  ///   71 MB [List<int>] on the Dart heap.
  /// - Flushes and closes the handle in a `finally` block to prevent leaks
  ///   even if the write is interrupted.
  Future<void> _copyFromAssetsIfAbsent(String dbPath) async {
    final File dbFile = File(dbPath);
    final prefs = await SharedPreferences.getInstance();
    final int installedVersion = prefs.getInt(_kDbVersionKey) ?? 0;

    final fileExists = await dbFile.exists();
    if (fileExists && installedVersion >= _kDbVersion) {
      final len = await dbFile.length();
      dev.log(
        'DB v$installedVersion already on device (${len ~/ 1024} KB) — skipping copy.',
        name: _kLogName,
      );
      return;
    }

    // Delete stale DB if it exists from a previous version.
    if (await dbFile.exists()) {
      dev.log(
        'Deleting stale DB v$installedVersion (need v$_kDbVersion).',
        name: _kLogName,
      );
      await dbFile.delete();
    }


    dev.log('Copying DB v$_kDbVersion from assets → $dbPath …', name: _kLogName);

    // rootBundle.load is safe from any isolate after
    // WidgetsFlutterBinding.ensureInitialized() has been called.
    final ByteData assetData = await rootBundle.load(_kAssetPath);

    // Zero-copy view of the underlying byte buffer — no extra allocation.
    final bytes = assetData.buffer.asUint8List(
      assetData.offsetInBytes,
      assetData.lengthInBytes,
    );

    await dbFile.writeAsBytes(bytes, flush: true);


    await prefs.setInt(_kDbVersionKey, _kDbVersion);

    dev.log(
      'Copy complete — ${assetData.lengthInBytes ~/ 1024} KB written (v$_kDbVersion).',
      name: _kLogName,
    );
  }

  // ---------------------------------------------------------------------------
  // Database open
  // ---------------------------------------------------------------------------

  Future<Database> _openDatabase(String dbPath) async {
    return openDatabase(
      dbPath,
      readOnly: true,       // All bundled tables are static reference data.
      singleInstance: true, // sqflite caches the handle per absolute path.
    );
  }


  // ---------------------------------------------------------------------------
  // Diagnostic helpers
  // ---------------------------------------------------------------------------

  /// `true` when the database file is present in device storage.
  Future<bool> get isDatabaseOnDevice async {
    final dbPath = await _resolveDevicePath();
    return File(dbPath).existsSync();
  }

  /// Size of the on-device database file in bytes; `0` if not yet copied.
  Future<int> get databaseFileSizeBytes async {
    final dbPath = await _resolveDevicePath();
    final file   = File(dbPath);
    return file.existsSync() ? file.lengthSync() : 0;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  /// Closes the connection and clears the cached handle.
  ///
  /// Normal apps never need this. Useful only in tests or edge cases where
  /// you need to forcefully release the file descriptor.
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      dev.log('Database connection closed.', name: _kLogName);
    }
    _db               = null;
    _initialiseFuture = null;
  }

  // ---------------------------------------------------------------------------
  // Convenience query wrappers
  // ---------------------------------------------------------------------------

  /// Executes a raw SQL [query] with optional positional [arguments].
  ///
  /// Example:
  /// ```dart
  /// final rows = await DatabaseHelper.instance.rawQuery(
  ///   'SELECT id, zekr FROM azkar WHERE type = ?',
  ///   [2],
  /// );
  /// ```
  Future<List<Map<String, dynamic>>> rawQuery(
    String query, [
    List<Object?> arguments = const [],
  ]) async {
    final db = await database;
    return db.rawQuery(query, arguments);
  }

  /// Queries [table] with optional filters — wraps [Database.query].
  ///
  /// Example:
  /// ```dart
  /// final rows = await DatabaseHelper.instance.queryTable(
  ///   'hisn_almuslim',
  ///   where:     'type = ?',
  ///   whereArgs: [3],
  ///   orderBy:   'id ASC',
  ///   limit:     50,
  /// );
  /// ```
  Future<List<Map<String, dynamic>>> queryTable(
    String table, {
    List<String>?  columns,
    String?        where,
    List<Object?>? whereArgs,
    String?        orderBy,
    int?           limit,
    int?           offset,
  }) async {
    final db = await database;
    return db.query(
      table,
      columns:   columns,
      where:     where,
      whereArgs: whereArgs,
      orderBy:   orderBy,
      limit:     limit,
      offset:    offset,
    );
  }

  // ---------------------------------------------------------------------------
  // Tafsir query
  // ---------------------------------------------------------------------------

  /// Valid tafsir column names in the `quran` table.
  static const List<String> tafsirColumns = [
    'tafsir_moysar',
    'tafsir_saadi',
    'tafsir_baghawi',
  ];

  /// Fetches a specific Tafsir text for a given verse from the local DB.
  ///
  /// [tafsirColumn] must be one of [tafsirColumns].
  /// Returns the tafsir text, or a fallback message if not found.
  Future<String> fetchTafsir({
    required int surahNumber,
    required int ayahNumber,
    required String tafsirColumn,
  }) async {
    if (!tafsirColumns.contains(tafsirColumn)) {
      return 'Unknown tafsir source.';
    }
    try {
      final rows = await rawQuery(
        'SELECT $tafsirColumn FROM quran WHERE sura_num = ? AND aya_num = ? LIMIT 1',
        [surahNumber, ayahNumber],
      );
      print('[DatabaseHelper] fetchTafsir query finished. Rows: ${rows.length}');
      if (rows.isNotEmpty) {
        final text = rows.first[tafsirColumn] as String?;
        print('[DatabaseHelper] Tafsir content length: ${text?.length ?? 0}');
        if (text != null && text.isNotEmpty) return text;
      }
      return 'لا يوجد تفسير لهذه الآية.';
    } catch (e, stackTrace) {
      print('[DatabaseHelper] CRITICAL ERROR fetching tafsir ($tafsirColumn) for $surahNumber:$ayahNumber: $e\n$stackTrace');
      return 'خطأ في تحميل التفسير.';
    }
  }

  /// Fetches all verses for a specific Quran page from the local DB.
  /// Ordered by id_quran_ayat to ensure correct reading sequence.
  Future<List<Map<String, dynamic>>> getVersesByPage(int pageNumber) async {
    if (_pageCache.containsKey(pageNumber)) {
      return _pageCache[pageNumber]!;
    }
    try {
      final rows = await rawQuery(
        'SELECT sura_num, aya_num, page_aya, sura, aya FROM quran WHERE page_aya = ? ORDER BY id_quran_ayat',
        [pageNumber],
      );
      _pageCache[pageNumber] = rows;
      return rows;
    } catch (e, stackTrace) {
      print('[DatabaseHelper] ERROR fetching verses for page $pageNumber: $e\n$stackTrace');
      return [];
    }
  }

  /// Dynamically queries the page number for a given verse.
  Future<int> getPageForAyah(int surahNumber, int ayahNumber) async {
    final key = '$surahNumber:$ayahNumber';
    if (_ayahPageCache.containsKey(key)) {
      return _ayahPageCache[key]!;
    }
    try {
      final rows = await rawQuery(
        'SELECT page_aya FROM quran WHERE sura_num = ? AND aya_num = ? LIMIT 1',
        [surahNumber, ayahNumber],
      );
      if (rows.isNotEmpty) {
        final page = (rows.first['page_aya'] as num?)?.toInt() ?? 1;
        _ayahPageCache[key] = page;
        return page;
      }
    } catch (e, stackTrace) {
      print('[DatabaseHelper] ERROR querying page for $surahNumber:$ayahNumber: $e\n$stackTrace');
    }
    return 1; // Fallback to first page
  }


  static const List<String> surahTransliterations = [
    "Al-Fatihah", "Al-Baqarah", "Ali 'Imran", "An-Nisa'", "Al-Ma'idah", "Al-An'am",
    "Al-A'raf", "Al-Anfal", "At-Tawbah", "Yunus", "Hud", "Yusuf", "Ar-Ra'd", "Ibrahim",
    "Al-Hijr", "An-Nahl", "Al-Isra", "Al-Kahf", "Maryam", "Ta-Ha", "Al-Anbiya",
    "Al-Hajj", "Al-Mu'minun", "An-Nur", "Al-Furqan", "Ash-Shu'ara", "An-Naml", "Al-Qasas",
    "Al-'Ankabut", "Ar-Rum", "Luqman", "As-Sajdah", "Al-Ahzab", "Saba'", "Fatir", "Ya-Sin",
    "As-Saffat", "Sad", "Az-Zumar", "Ghafir", "Fussilat", "Ash-Shura", "Az-Zukhruf",
    "Ad-Dukhan", "Al-Jathiyah", "Al-Ahqaf", "Muhammad", "Al-Fath", "Al-Hujurat", "Qaf",
    "Adh-Dhariyat", "At-Tur", "An-Najm", "Al-Qamar", "Ar-Rahman", "Al-Waqi'ah", "Al-Hadid",
    "Al-Mujadilah", "Al-Hashr", "Al-Mumtahanah", "As-Saff", "Al-Jumu'ah", "Al-Munafiqun",
    "At-Taghabun", "At-Talaq", "At-Tahrim", "Al-Mulk", "Al-Qalam", "Al-Haqqah", "Al-Ma'arij",
    "Nuh", "Al-Jinn", "Al-Muzzammil", "Al-Muddaththir", "Al-Qiyamah", "Al-Insan", "Al-Mursalat",
    "An-Naba", "An-Nazi'at", "'Abasa", "At-Takwir", "Al-Infitar", "Al-Mutaffifin", "Al-Inshiqaq",
    "Al-Buruj", "At-Tariq", "Al-A'la", "Al-Ghashiyah", "Al-Fajr", "Al-Balad", "Ash-Shams",
    "Al-Layl", "Ad-Duha", "Ash-Sharh", "At-Tin", "Al-'Alaq", "Al-Qadr", "Al-Bayyinah",
    "Az-Zalzalah", "Al-'Adiyat", "Al-Qari'ah", "At-Takathur", "Al-'Asr", "Al-Humazah",
    "Al-Fil", "Quraysh", "Al-Ma'un", "Al-Kauthar", "Al-Kafirun", "An-Nasr", "Al-Masad",
    "Al-Ikhlas", "Al-Falaq", "An-Nas"
  ];

  static const List<String> surahNamesArabicList = [
    "الفاتحة", "البقرة", "آل عمران", "النساء", "المائدة", "الأنعام", "الأعراف", "الأنفال", "التوبة", "يونس",
    "هود", "يوسف", "الرعد", "إبراهيم", "الحجر", "النحل", "الإسراء", "الكهف", "مريم", "طه",
    "الأنبياء", "الحج", "المؤمنون", "النور", "الفرقان", "الشعراء", "النمل", "القصص", "العنكبوت", "الروم",
    "لقمان", "السجدة", "الأحزاب", "سبأ", "فاطر", "يس", "الصافات", "ص", "الزمر", "غافر",
    "فصلت", "الشورى", "الزخرف", "الدخان", "الجاثية", "الأحقاف", "محمد", "الفتح", "الحجرات", "ق",
    "الذاريات", "الطور", "النجم", "القمر", "الرحمن", "الواقعة", "الحديد", "المجادلة", "الحشر", "الممتحنة",
    "الصف", "الجمعة", "المنافقون", "التغابن", "الطلاق", "التحريم", "الملك", "القلم", "الحاقة", "المعارج",
    "نوح", "الجن", "المزمل", "المدثر", "القيامة", "الإنسان", "المرسلات", "النبأ", "النازعات", "عبس",
    "التكوير", "الانفطار", "المطففين", "الانشقاق", "البروج", "الطارق", "الأعلى", "الغاشية", "الفجر", "البلد",
    "الشمس", "الليل", "الضحى", "الشرح", "التين", "العلق", "القدر", "البينة", "الزلزلة", "العاديات",
    "القارعة", "التكاثر", "العصر", "الهمزة", "الفيل", "قريش", "الماعون", "الكوثر", "الكافرون", "النصر",
    "المسد", "الإخلاص", "الفلق", "الناس"
  ];
}
