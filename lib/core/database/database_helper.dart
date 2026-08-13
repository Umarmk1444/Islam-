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
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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

  static const String _kDbName    = 'muslim_house.db';
  static const String _kDbSubDir  = 'databases';
  static const String _kLogName   = 'DatabaseHelper';

  Future<void> init() async {
    // Just trigger database getter
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
      
      final dbFile = File(dbPath);
      if (!await dbFile.exists()) {
        throw Exception('Database file not found at $dbPath. It should be downloaded first.');
      }

      _db = await _openDatabase(dbPath);
      
      await insertDuaAfterSalahIfNotExists(_db!);

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
  // Asset → device copy (REMOVED: Now downloaded dynamically)
  // ---------------------------------------------------------------------------

  // ---------------------------------------------------------------------------
  // Database open
  // ---------------------------------------------------------------------------

  Future<Database> _openDatabase(String dbPath) async {
    return openDatabase(
      dbPath,
      readOnly: false,      // Changed to false to allow insertions
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
      debugPrint('[DatabaseHelper] fetchTafsir query finished. Rows: ${rows.length}');
      if (rows.isNotEmpty) {
        final text = rows.first[tafsirColumn] as String?;
        debugPrint('[DatabaseHelper] Tafsir content length: ${text?.length ?? 0}');
        if (text != null && text.isNotEmpty) return text;
      }
      return 'لا يوجد تفسير لهذه الآية.';
    } catch (e, stackTrace) {
      debugPrint('[DatabaseHelper] CRITICAL ERROR fetching tafsir ($tafsirColumn) for $surahNumber:$ayahNumber: $e\n$stackTrace');
      return 'خطأ في تحميل التفسير.';
    }
  }

  /// Fetches Word Meanings (ma3ny_aya) and I'rab (e3rab_quran) for a given verse.
  Future<Map<String, String>> fetchMeaningsAndIrab({
    required int surahNumber,
    required int ayahNumber,
  }) async {
    try {
      final rows = await rawQuery(
        'SELECT ma3ny_aya, e3rab_quran FROM quran WHERE sura_num = ? AND aya_num = ? LIMIT 1',
        [surahNumber, ayahNumber],
      );
      if (rows.isNotEmpty) {
        final meanings = rows.first['ma3ny_aya'] as String? ?? '';
        final irab = rows.first['e3rab_quran'] as String? ?? '';
        return {
          'meanings': meanings,
          'irab': irab,
        };
      }
      return {'meanings': '', 'irab': ''};
    } catch (e, stackTrace) {
      debugPrint('[DatabaseHelper] ERROR fetching meanings and irab for $surahNumber:$ayahNumber: $e\n$stackTrace');
      return {'meanings': '', 'irab': ''};
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
      debugPrint('[DatabaseHelper] ERROR fetching verses for page $pageNumber: $e\n$stackTrace');
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
      debugPrint('[DatabaseHelper] ERROR querying page for $surahNumber:$ayahNumber: $e\n$stackTrace');
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

final List<Map<String, dynamic>> duaAfterSalahData = [
  {
    'id': -13,
    'type': 'دعاء بعد الصلاة',
    'zekr': 'أَسْتَغْفِرُ اللهَ',
    'zekr_info': 'I ask Allah to forgive me\nAlso recommended for: Dhikr',
    'num_zekr': 3,
    'zekr_sound': ''
  },
  {
    'id': -12,
    'type': 'دعاء بعد الصلاة',
    'zekr': 'اللَّهُمَّ أَنْتَ السَّلامُ ، وَمِنْكَ السَّلَامُ ، تَبَارَكْتَ يَاذَ الْجَلَالِ وَالْإِكْرَامِ',
    'zekr_info': 'O Allah! You are peace and from You comes peace. Blessed are You, O owner of Majesty and Honour.\nSahih Muslim 1/414 | Abu Dawood 2/62 | Ibn Majah 2/1267',
    'num_zekr': 1,
    'zekr_sound': ''
  },
  {
    'id': -11,
    'type': 'دعاء بعد الصلاة',
    'zekr': 'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لا شَرِيكَ لَهُ ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ ، وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    'zekr_info': 'None has the right to be worshipped except Allah, alone, without partner, to Him belongs all sovereignty and He is over all things omnipotent.\nSahih Muslim 1/415',
    'num_zekr': 1,
    'zekr_sound': ''
  },
  {
    'id': -10,
    'type': 'دعاء بعد الصلاة',
    'zekr': 'سُبْحَانَ اللهِ ، وَالْحَمْدُ للهِ ، وَاللَّهُ أَكْبَرُ',
    'zekr_info': 'Glorious is Allah. Praises are due to Allah. Allah is the greatest.\nSahih Muslim 11/418',
    'num_zekr': 33,
    'zekr_sound': ''
  },
  {
    'id': -9,
    'type': 'دعاء بعد الصلاة',
    'zekr': 'لا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لاَ شَرِيكَ لَهُ ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ ، يُحْيِي وَيُمِيْتُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
    'zekr_info': 'None has the right to be worshipped except Allah, alone, without partner, to Him belongs all sovereignty and praise, He gives life and causes death and He is over all things omnipotent.\nSahih Muslim 1/418/597 | Ahmed 2/371',
    'num_zekr': 10,
    'zekr_sound': ''
  },
  {
    'id': -8,
    'type': 'دعاء بعد الصلاة',
    'zekr': 'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ\nاللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ ۚ لَّهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَن ذَا الَّذِي يَشْفَعُ عِندَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِّنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ وَهُوَ الْعَلِيُّ الْعَظِيمُ',
    'zekr_info': 'Allah - there is no deity except Him... His Kursi extends over the heavens and the earth, and their preservation tires Him not. And He is the Most High, the Most Great.\nSurah Al Baqarah 2: 255 | Al-Hakim 1/562',
    'num_zekr': 1,
    'zekr_sound': ''
  },
  {
    'id': -7,
    'type': 'دعاء بعد الصلاة',
    'zekr': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nقُلْ هُوَ اللَّهُ أَحَدٌ * اللَّهُ الصَّمَدُ * لَمْ يَلِدْ وَلَمْ يُولَدْ * وَلَمْ يَكُن لَّهُ كُفُوًا أَحَدٌ',
    'zekr_info': 'In the name of Allah, the Entirely Merciful, the Especially Merciful... Say, "He is Allah, [who is] One..."\nAl-Ikhlas 112 | Abu Dawood 2/86',
    'num_zekr': 1,
    'zekr_sound': ''
  },
  {
    'id': -6,
    'type': 'دعاء بعد الصلاة',
    'zekr': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nقُلْ أَعُوذُ بِرَبِّ الْفَلَقِ * مِن شَرِّ مَا خَلَقَ * وَمِن شَرِّ غَاسِقٍ إِذَا وَقَبَ * وَمِن شَرِّ النَّفَّاثَاتِ فِي الْعُقَدِ * وَمِن شَرِّ حَاسِدٍ إِذَا حَسَدَ',
    'zekr_info': 'In the name of Allah, the Entirely Merciful, the Especially Merciful... Say, "I seek refuge in the Lord of daybreak..."\nAl-Falaq 113 | Abu Dawood 2/86',
    'num_zekr': 1,
    'zekr_sound': ''
  },
  {
    'id': -5,
    'type': 'دعاء بعد الصلاة',
    'zekr': 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nقُلْ أَعُوذُ بِرَبِّ النَّاسِ * مَلِكِ النَّاسِ * إِلَٰهِ النَّاسِ * مِن شَرِّ الْوَسْوَاسِ الْخَنَّاسِ * الَّذِي يُوَسْوِسُ فِي صُدُورِ النَّاسِ * مِنَ الْجِنَّةِ وَالنَّاسِ',
    'zekr_info': 'In the name of Allah, the Entirely Merciful, the Especially Merciful... Say, "I seek refuge in the Lord of mankind..."\nAn-Naas 114 | Abu Dawood 2/86',
    'num_zekr': 1,
    'zekr_sound': ''
  },
  {
    'id': -4,
    'type': 'دعاء بعد الصلاة',
    'zekr': 'اللَّهُمَّ إِنِّي أَسْأَلُكَ رِضَاكَ وَالْجَنَّةِ، وَأَعُوْذُبِكَ مِنْ سَخَطِكَ وَالنَّارِ',
    'zekr_info': 'O Allah! We ask You to be pleased with us, reward us with the Paradise and we seek Your refuge from Your anger and the punishment of the Fire.\nAbu Dawood | Ibn Majah 2/328',
    'num_zekr': 1,
    'zekr_sound': ''
  },
  {
    'id': -3,
    'type': 'دعاء بعد الصلاة',
    'zekr': 'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ ، وَشُكْرِكَ ، وَحُسْنِ عِبَادَتِكَ',
    'zekr_info': 'O Allah Assist me in remembering you, in thanking you, and worshipping you in the best of manners.\nAl Bhukari 4/95 | Sahih Muslim 4/2071',
    'num_zekr': 1,
    'zekr_sound': ''
  },
  {
    'id': -2,
    'type': 'دعاء بعد الصلاة',
    'zekr': 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ، وَعَلَى آلِ مُحَمَّدٍ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ، وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ، اللَّهُمَّ بَارِكْ عَلَى مُحَمَّدٍ، وَعَلَى آلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ، وَعَلَى آلِ إِبْرَاهِيمَ، إِنَّكَ حَمِيدٌ مَجِيدٌ',
    'zekr_info': 'O Allah, let Your Blessings come upon Muhammad and the family of Muhammad, as you have blessed Ibrahim and his family. Truly, You are Praiseworthy and Glorious\nAl Bhukari 1/286 | Sahih Muslim 1/301',
    'num_zekr': 1,
    'zekr_sound': ''
  }
];

Future<void> insertDuaAfterSalahIfNotExists(Database db) async {
  for (var dua in duaAfterSalahData) {
    try {
      await db.insert(
        'azkar',
        dua,
        conflictAlgorithm: ConflictAlgorithm.ignore, 
      );
    } catch (e) {
      // Ignore if table structure differs slightly, though it should match.
      debugPrint("Error inserting dua: $e");
    }
  }
  debugPrint("Dua After Salah check complete. No existing entries were modified.");
}
