import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/hadith_models.dart';
import 'database_helper.dart';

class HadithDatabaseHelper {
  static final HadithDatabaseHelper instance = HadithDatabaseHelper._init();
  static Database? _database;
  static Future<Database>? _initFuture;

  /// Notifier reflecting whether initial extraction is underway
  final ValueNotifier<bool> isExtractingNotifier = ValueNotifier<bool>(false);

  /// Notifier reflecting progress fraction (0.0 to 1.0) during extraction/preparation
  final ValueNotifier<double> extractionProgressNotifier = ValueNotifier<double>(0.0);

  HadithDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null && _database!.isOpen) return _database!;
    if (_initFuture != null && (_database == null || !_database!.isOpen)) {
      _initFuture = null;
    }
    _initFuture ??= _initDatabase();
    return _initFuture!;
  }

  Future<String> _resolveDatabasePath() async {
    final dbDir = await getDatabasesPath();
    final dir = Directory(dbDir);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return p.join(dbDir, 'hadith_library.db');
  }

  Future<bool> _isDatabaseValid(String path) async {
    final file = File(path);
    if (!await file.exists()) return false;
    final length = await file.length();
    // Valid 10-collection database is ~147 MB; must be at least 100 MB
    return length >= 100 * 1024 * 1024;
  }

  Future<bool> isDatabaseExtracted() async {
    try {
      final dbPath = await _resolveDatabasePath();
      return await _isDatabaseValid(dbPath);
    } catch (_) {
      return false;
    }
  }

  /// Returns total bytes occupied by hadith_library.db on device storage, or 0 if unextracted.
  Future<int> getDatabaseSizeBytes() async {
    try {
      final dbPath = await _resolveDatabasePath();
      final file = File(dbPath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  /// Deletes the local hadith database file from device storage, freeing ~178 MB instantly.
  Future<bool> deleteDatabaseFile() async {
    try {
      if (_database != null && _database!.isOpen) {
        await _database!.close();
        _database = null;
      }
      _initFuture = null;
      final dbPath = await _resolveDatabasePath();
      final file = File(dbPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('[HadithDatabaseHelper] Successfully deleted $dbPath (freed storage).');
      }
      final tmpFile = File('$dbPath.tmp');
      if (await tmpFile.exists()) {
        await tmpFile.delete();
      }
      extractionProgressNotifier.value = 0.0;
      return true;
    } catch (e) {
      debugPrint('[HadithDatabaseHelper] deleteDatabaseFile error: $e');
      return false;
    }
  }

  /// Explicitly triggers extraction/preparation with progress feedback.
  Future<void> prepareDatabase() async {
    final dbPath = await _resolveDatabasePath();
    final isValid = await _isDatabaseValid(dbPath);
    if (!isValid) {
      final existingFile = File(dbPath);
      if (await existingFile.exists()) {
        await existingFile.delete();
      }
      await _extractDatabaseFromAsset(dbPath);
    }
    await database;
  }

  Future<void> _extractDatabaseFromAsset(String dbPath) async {
    final tempPath = '$dbPath.tmp';
    final tempFile = File(tempPath);
    if (await tempFile.exists()) {
      await tempFile.delete();
    }

    debugPrint('[HadithDatabaseHelper] Extracting hadith_library.db.gz stream...');
    isExtractingNotifier.value = true;
    extractionProgressNotifier.value = 0.0;

    try {
      final byteData = await rootBundle.load('assets/hadith_library.db.gz');
      final compressedBytes = byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      );

      final sink = tempFile.openWrite();
      final inputStream = Stream<List<int>>.value(compressedBytes).transform(gzip.decoder);
      int writtenBytes = 0;
      const double estimatedUncompressedSize = 186675200.0; // ~178 MB

      await for (final chunk in inputStream) {
        sink.add(chunk);
        writtenBytes += chunk.length;
        extractionProgressNotifier.value = (writtenBytes / estimatedUncompressedSize).clamp(0.0, 0.98);
      }

      await sink.flush();
      await sink.close();

      final extractedLength = await tempFile.length();
      debugPrint('[HadithDatabaseHelper] Stream extraction finished: $extractedLength bytes.');

      if (extractedLength < 100 * 1024 * 1024) {
        throw Exception('Extracted database size too small ($extractedLength bytes), likely incomplete.');
      }

      final finalFile = File(dbPath);
      if (await finalFile.exists()) {
        await finalFile.delete();
      }
      await tempFile.rename(dbPath);
      extractionProgressNotifier.value = 1.0;
      debugPrint('[HadithDatabaseHelper] Database successfully ready at: $dbPath');
    } catch (e, st) {
      debugPrint('[HadithDatabaseHelper] Extraction failure: $e\n$st');
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
      rethrow;
    } finally {
      isExtractingNotifier.value = false;
    }
  }

  Future<Database> _initDatabase() async {
    try {
      final dbPath = await _resolveDatabasePath();
      final isValid = await _isDatabaseValid(dbPath);

      if (!isValid) {
        final existingFile = File(dbPath);
        if (await existingFile.exists()) {
          debugPrint('[HadithDatabaseHelper] Removing incomplete database before extraction.');
          await existingFile.delete();
        }
        await _extractDatabaseFromAsset(dbPath);
      }

      final db = await openDatabase(
        dbPath,
        version: 1,
        singleInstance: true,
        onOpen: (db) async {
          await db.execute('PRAGMA foreign_keys = ON;');
          // One-time self-healing check: guarantee books table has total_hadiths populated
          await db.execute('''
            UPDATE books 
            SET total_hadiths = (SELECT COUNT(*) FROM hadiths WHERE hadiths.book_id = books.id)
            WHERE total_hadiths = 0 OR total_hadiths IS NULL;
          ''');
        },
      );

      _database = db;

      // Run background user data migration safely
      unawaited(_migrateLegacyUserData(db));

      return db;
    } catch (e) {
      _initFuture = null;
      rethrow;
    }
  }

  /// Migrates user favorites and reading history from legacy muslim_house.db
  Future<void> _migrateLegacyUserData(Database hadithDb) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isMigrated = prefs.getBool('hadith_legacy_migrated_v1') ?? false;
      if (isMigrated) return;

      // Locate muslim_house.db in app documents or databases directory
      String? legacyPath;
      final docDir = await getApplicationDocumentsDirectory();
      final cand1 = p.join(docDir.path, 'databases', 'muslim_house.db');
      if (await File(cand1).exists()) {
        legacyPath = cand1;
      } else {
        final dbDir = await getDatabasesPath();
        final cand2 = p.join(dbDir, 'muslim_house.db');
        if (await File(cand2).exists()) {
          legacyPath = cand2;
        }
      }

      if (legacyPath == null) {
        debugPrint('[HadithDatabaseHelper] muslim_house.db not yet copied to storage. Skipping migration for next launch.');
        return; // Do NOT set isMigrated=true yet, allow next boot to migrate
      }

      debugPrint('[HadithDatabaseHelper] Accessing legacy database for migration.');
      final legacyDb = await DatabaseHelper.instance.database;

      // Create recovery table for unmatched legacy bookmarks
      await hadithDb.execute('''
        CREATE TABLE IF NOT EXISTS hadith_unmatched_legacy (
          legacy_id INTEGER PRIMARY KEY,
          fav INTEGER DEFAULT 0,
          last_read INTEGER DEFAULT 0,
          num_readings INTEGER DEFAULT 0
        );
      ''');

      final legacyRows = await legacyDb.rawQuery('''
        SELECT id, fav, last_read, num_readings 
        FROM library 
        WHERE (part LIKE '%بخار%' OR part = 'البخارى') 
          AND (fav = '1' OR fav = 1 OR (last_read IS NOT NULL AND last_read != '' AND last_read != '0'));
      ''');

      if (legacyRows.isEmpty) {
        debugPrint('[HadithDatabaseHelper] No legacy Bukhari bookmarks found.');
        await prefs.setBool('hadith_legacy_migrated_v1', true);
        return;
      }

      int parseInt(dynamic val, [int fallback = 0]) {
        if (val == null) return fallback;
        if (val is int) return val;
        if (val is num) return val.toInt();
        if (val is String) return int.tryParse(val) ?? fallback;
        return fallback;
      }

      int matchedCount = 0;
      int unmatchedCount = 0;

      await hadithDb.transaction((txn) async {
        for (final row in legacyRows) {
          final legacyId = parseInt(row['id']);
          final isFav = parseInt(row['fav']) == 1;
          final lastRead = parseInt(row['last_read']);
          final numReadings = parseInt(row['num_readings']);

          final matches = await txn.rawQuery('''
            SELECT id, collection_id FROM hadiths WHERE legacy_bukhari_id = ? LIMIT 1;
          ''', [legacyId]);

          if (matches.isNotEmpty) {
            final hadithId = matches.first['id'] as int;
            final collectionId = matches.first['collection_id'] as int;

            await txn.rawInsert('''
              INSERT INTO hadith_user_data (
                hadith_id, collection_id, is_favorite, last_read_timestamp, read_count
              ) VALUES (?, ?, ?, ?, ?)
              ON CONFLICT(hadith_id) DO UPDATE SET
                is_favorite = MAX(hadith_user_data.is_favorite, excluded.is_favorite),
                last_read_timestamp = MAX(COALESCE(hadith_user_data.last_read_timestamp, 0), excluded.last_read_timestamp),
                read_count = MAX(COALESCE(hadith_user_data.read_count, 0), excluded.read_count);
            ''', [hadithId, collectionId, isFav ? 1 : 0, lastRead, numReadings]);
            matchedCount++;
          } else {
            await txn.rawInsert('''
              INSERT OR REPLACE INTO hadith_unmatched_legacy (
                legacy_id, fav, last_read, num_readings
              ) VALUES (?, ?, ?, ?);
            ''', [legacyId, isFav ? 1 : 0, lastRead, numReadings]);
            unmatchedCount++;
          }
        }
      });

      await prefs.setBool('hadith_legacy_migrated_v1', true);
      debugPrint('[HadithDatabaseHelper] Migration completed: $matchedCount matched, $unmatchedCount preserved in recovery table.');
    } catch (e, st) {
      debugPrint('[HadithDatabaseHelper] Legacy migration error: $e\n$st');
    }
  }

  // ==========================================
  // QUERY METHODS
  // ==========================================

  Future<List<HadithCollection>> getCollections() async {
    try {
      final db = await database;
      final rows = await db.query('collections', orderBy: 'sort_order ASC');
      return rows.map((r) => HadithCollection.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[HadithDatabaseHelper] getCollections error: $e');
      rethrow;
    }
  }

  Future<HadithCollection?> getCollection(int id) async {
    try {
      final db = await database;
      final rows = await db.query('collections', where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return null;
      return HadithCollection.fromMap(rows.first);
    } catch (e) {
      debugPrint('[HadithDatabaseHelper] getCollection error: $e');
      return null;
    }
  }

  Future<List<HadithBook>> getBooks(int collectionId) async {
    try {
      final db = await database;
      final rows = await db.rawQuery('''
        SELECT b.*,
               (SELECT COUNT(*) FROM chapters c WHERE c.book_id = b.id) as total_chapters,
               COALESCE(NULLIF(b.first_hadith_num, 0), (SELECT MIN(CAST(h.hadith_number AS INTEGER)) FROM hadiths h WHERE h.book_id = b.id AND h.hadith_number GLOB '[0-9]*')) as computed_first_num,
               COALESCE(NULLIF(b.last_hadith_num, 0), (SELECT MAX(CAST(h.hadith_number AS INTEGER)) FROM hadiths h WHERE h.book_id = b.id AND h.hadith_number GLOB '[0-9]*')) as computed_last_num
        FROM books b
        WHERE b.collection_id = ?
        ORDER BY b.book_number ASC;
      ''', [collectionId]);
      return rows.map((r) => HadithBook.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[HadithDatabaseHelper] getBooks error: $e');
      rethrow;
    }
  }

  Future<HadithBook?> getBook(int bookId) async {
    try {
      final db = await database;
      final rows = await db.query('books', where: 'id = ?', whereArgs: [bookId], limit: 1);
      if (rows.isEmpty) return null;
      return HadithBook.fromMap(rows.first);
    } catch (e) {
      debugPrint('[HadithDatabaseHelper] getBook error: $e');
      return null;
    }
  }

  Future<List<HadithChapter>> getChapters(int collectionId, int bookId) async {
    try {
      final db = await database;
      final rows = await db.query(
        'chapters',
        where: 'collection_id = ? AND book_id = ?',
        whereArgs: [collectionId, bookId],
        orderBy: "CASE WHEN source_chapter_id IS NOT NULL AND source_chapter_id != '' THEN CAST(source_chapter_id AS REAL) ELSE chapter_number END ASC, id ASC",
      );
      return rows.map((r) => HadithChapter.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[HadithDatabaseHelper] getChapters error: $e');
      rethrow;
    }
  }

  Future<HadithChapter?> getChapter(int chapterId) async {
    try {
      final db = await database;
      final rows = await db.query('chapters', where: 'id = ?', whereArgs: [chapterId], limit: 1);
      if (rows.isEmpty) return null;
      return HadithChapter.fromMap(rows.first);
    } catch (e) {
      debugPrint('[HadithDatabaseHelper] getChapter error: $e');
      return null;
    }
  }

  Future<List<HadithItem>> getHadithsByChapter(int collectionId, int bookId, int chapterId) async {
    try {
      final db = await database;
      final rows = await db.rawQuery('''
        SELECT h.*, 
               COALESCE(u.is_favorite, 0) as is_favorite,
               u.last_read_timestamp,
               COALESCE(u.read_count, 0) as read_count,
               u.notes
        FROM hadiths h
        LEFT JOIN hadith_user_data u ON u.hadith_id = h.id
        WHERE h.collection_id = ? AND h.book_id = ? AND h.chapter_id = ?
        ORDER BY h.in_book_number ASC, h.id ASC;
      ''', [collectionId, bookId, chapterId]);
      return rows.map((r) => HadithItem.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[HadithDatabaseHelper] getHadithsByChapter error: $e');
      rethrow;
    }
  }

  Future<List<HadithItem>> getHadithsByBook(
    int collectionId,
    int bookId, {
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final db = await database;
      final rows = await db.rawQuery('''
        SELECT h.*, 
               COALESCE(u.is_favorite, 0) as is_favorite,
               u.last_read_timestamp,
               COALESCE(u.read_count, 0) as read_count,
               u.notes
        FROM hadiths h
        LEFT JOIN hadith_user_data u ON u.hadith_id = h.id
        WHERE h.collection_id = ? AND h.book_id = ?
        ORDER BY h.in_book_number ASC, h.id ASC
        LIMIT ? OFFSET ?;
      ''', [collectionId, bookId, limit, offset]);
      return rows.map((r) => HadithItem.fromMap(r)).toList();
    } catch (e) {
      debugPrint('[HadithDatabaseHelper] getHadithsByBook error: $e');
      rethrow;
    }
  }

  Future<HadithItem?> getHadithById(int id) async {
    try {
      final db = await database;
      final rows = await db.rawQuery('''
        SELECT h.*, 
               COALESCE(u.is_favorite, 0) as is_favorite,
               u.last_read_timestamp,
               COALESCE(u.read_count, 0) as read_count,
               u.notes
        FROM hadiths h
        LEFT JOIN hadith_user_data u ON u.hadith_id = h.id
        WHERE h.id = ?
        LIMIT 1;
      ''', [id]);
      if (rows.isEmpty) return null;
      return HadithItem.fromMap(rows.first);
    } catch (e) {
      debugPrint('[HadithDatabaseHelper] getHadithById error: $e');
      return null;
    }
  }

  /// Diacritic-agnostic full-text search across collections using SQLite FTS5
  Future<List<HadithItem>> searchHadiths(
    String query, {
    int? collectionId,
    int limit = 50,
    int offset = 0,
  }) async {
    final db = await database;
    final cleanQuery = _normalizeArabicForSearch(query);
    if (cleanQuery.isEmpty) return [];

    final ftsTokens = cleanQuery
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map((t) => '"$t"*')
        .join(' ');

    if (ftsTokens.isEmpty) return [];

    String sql;
    List<dynamic> args;

    if (collectionId != null) {
      sql = '''
        SELECT h.*, 
               COALESCE(u.is_favorite, 0) as is_favorite,
               u.last_read_timestamp,
               COALESCE(u.read_count, 0) as read_count,
               u.notes
        FROM hadith_fts fts
        JOIN hadiths h ON h.id = fts.rowid
        LEFT JOIN hadith_user_data u ON u.hadith_id = h.id
        WHERE hadith_fts MATCH ? AND h.collection_id = ?
        ORDER BY rank
        LIMIT ? OFFSET ?;
      ''';
      args = [ftsTokens, collectionId, limit, offset];
    } else {
      sql = '''
        SELECT h.*, 
               COALESCE(u.is_favorite, 0) as is_favorite,
               u.last_read_timestamp,
               COALESCE(u.read_count, 0) as read_count,
               u.notes
        FROM hadith_fts fts
        JOIN hadiths h ON h.id = fts.rowid
        LEFT JOIN hadith_user_data u ON u.hadith_id = h.id
        WHERE hadith_fts MATCH ?
        ORDER BY rank
        LIMIT ? OFFSET ?;
      ''';
      args = [ftsTokens, limit, offset];
    }

    try {
      final rows = await db.rawQuery(sql, args);
      return rows.map((r) => HadithItem.fromMap(r)).toList();
    } catch (e) {
      final likePattern = '%$cleanQuery%';
      final fallbackRows = await db.rawQuery('''
        SELECT h.*, 
               COALESCE(u.is_favorite, 0) as is_favorite,
               u.last_read_timestamp,
               COALESCE(u.read_count, 0) as read_count,
               u.notes
        FROM hadiths h
        LEFT JOIN hadith_user_data u ON u.hadith_id = h.id
        WHERE h.arabic_clean LIKE ? ${collectionId != null ? 'AND h.collection_id = ?' : ''}
        LIMIT ? OFFSET ?;
      ''', collectionId != null ? [likePattern, collectionId, limit, offset] : [likePattern, limit, offset]);
      return fallbackRows.map((r) => HadithItem.fromMap(r)).toList();
    }
  }

  Future<String?> resolveLegacyDbPath() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final cand1 = p.join(docDir.path, 'databases', 'muslim_house.db');
      if (await File(cand1).exists()) return cand1;
      final dbDir = await getDatabasesPath();
      final cand2 = p.join(dbDir, 'muslim_house.db');
      if (await File(cand2).exists()) return cand2;
    } catch (_) {}
    return null;
  }

  Future<void> toggleFavorite(int hadithId, int collectionId, bool isFavorite) async {
    final db = await database;
    await db.rawInsert('''
      INSERT INTO hadith_user_data (hadith_id, collection_id, is_favorite)
      VALUES (?, ?, ?)
      ON CONFLICT(hadith_id) DO UPDATE SET is_favorite = ?;
    ''', [hadithId, collectionId, isFavorite ? 1 : 0, isFavorite ? 1 : 0]);

    // Also sync to muslim_house.db if this hadith maps to a legacy Bukhari item
    try {
      final rows = await db.query('hadiths', columns: ['legacy_bukhari_id'], where: 'id = ?', whereArgs: [hadithId], limit: 1);
      if (rows.isNotEmpty && rows.first['legacy_bukhari_id'] != null) {
        final legacyId = rows.first['legacy_bukhari_id'] as int;
        final legacyDb = await DatabaseHelper.instance.database;
        await legacyDb.rawUpdate('UPDATE library SET fav = ? WHERE id = ?;', [isFavorite ? 1 : 0, legacyId]);
      }
    } catch (e) {
      debugPrint('[HadithDatabaseHelper] Legacy sync ignored: $e');
    }
  }

  Future<void> recordReading(int hadithId, int collectionId) async {
    final db = await database;
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.rawInsert('''
      INSERT INTO hadith_user_data (hadith_id, collection_id, last_read_timestamp, read_count)
      VALUES (?, ?, ?, 1)
      ON CONFLICT(hadith_id) DO UPDATE SET 
        last_read_timestamp = ?,
        read_count = read_count + 1;
    ''', [hadithId, collectionId, now, now]);
  }

  Future<List<HadithItem>> getFavorites({int? collectionId}) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT h.*, 
             u.is_favorite,
             u.last_read_timestamp,
             u.read_count,
             u.notes
      FROM hadith_user_data u
      JOIN hadiths h ON h.id = u.hadith_id
      WHERE u.is_favorite = 1 ${collectionId != null ? 'AND u.collection_id = ?' : ''}
      ORDER BY u.last_read_timestamp DESC;
    ''', collectionId != null ? [collectionId] : []);
    return rows.map((r) => HadithItem.fromMap(r)).toList();
  }

  Future<HadithItem?> getLatestReadHadith() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT h.*, 
             u.is_favorite,
             u.last_read_timestamp,
             u.read_count,
             u.notes
      FROM hadith_user_data u
      JOIN hadiths h ON h.id = u.hadith_id
      WHERE u.last_read_timestamp IS NOT NULL AND u.last_read_timestamp > 0
      ORDER BY u.last_read_timestamp DESC
      LIMIT 1;
    ''');
    if (rows.isEmpty) return null;
    return HadithItem.fromMap(rows.first);
  }

  static String _normalizeArabicForSearch(String text) {
    if (text.isEmpty) return '';
    var norm = text;
    norm = norm.replaceAll(RegExp(r'[\u0617-\u061A\u064B-\u0652]'), '');
    norm = norm.replaceAll('\u0640', '');
    norm = norm.replaceAll(RegExp(r'[إأآٱ]'), 'ا');
    norm = norm.replaceAll('ى', 'ي');
    norm = norm.replaceAll('ة', 'ه');
    return norm.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
