import '../core/database/database_helper.dart';
import '../models/library_item.dart';
import '../models/fatwa_item.dart';
import '../models/roqua_item.dart';

class LibraryService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  static const String _libraryListCols = 'id, part, type, title, fav, last_read, num_readings';
  static const String _fatwaListCols = 'id, mofty_name, fatwy_type, question';
  static const String _roquaListCols = 'id, level, roqua';

  // ---------------------------------------------------------------------------
  // Domains and Categories (Level 1 & 2)
  // ---------------------------------------------------------------------------

  Future<List<Map<String, String>>> getLibraryCategories(String part) async {
    final db = await _dbHelper.database;
    if (part == 'صحيح البخارى' || part == 'البخارى') {
      final result = await db.rawQuery('SELECT abc, abc2 FROM all_index WHERE title = "البخارى"');
      return result.map((e) => {
        'id': e['abc2'].toString(),
        'title': e['abc'].toString(),
      }).toList();
    } else if (part == 'الرقية الشرعية') {
      final result = await db.rawQuery(
        'SELECT DISTINCT level FROM roqua WHERE level IS NOT NULL AND level != ""',
      );
      return result.map((e) => {
        'id': e['level'].toString(),
        'title': e['level'].toString(),
      }).toList();
    } else {
      final result = await db.rawQuery(
        'SELECT DISTINCT type FROM library WHERE part = ? AND type IS NOT NULL AND type != ""',
        [part],
      );
      return result.map((e) => {
        'id': e['type'].toString(),
        'title': e['type'].toString(),
      }).toList();
    }
  }

  Future<List<Map<String, String>>> getFatawyCategories() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT fatwy_type FROM fatawy WHERE fatwy_type IS NOT NULL AND fatwy_type != ""',
    );
    return result.map((e) => {
      'id': e['fatwy_type'].toString(),
      'title': e['fatwy_type'].toString(),
    }).toList();
  }

  Future<String> getCategoryTitleById(String part, String typeId) async {
    if (typeId.trim().isEmpty) return '';
    final db = await _dbHelper.database;
    if (part == 'صحيح البخارى' || part == 'البخارى') {
      final rows = await db.rawQuery(
        'SELECT abc FROM all_index WHERE (abc2 = ? OR abc = ?) AND (title = "البخارى" OR title LIKE "%البخار%")',
        [typeId, typeId],
      );
      if (rows.isNotEmpty) {
        return rows.first['abc']?.toString() ?? typeId;
      }
    }
    return typeId;
  }

  // ---------------------------------------------------------------------------
  // Featured Inspirations / Speed Reads (50% Islamic Library & 50% Bukhari)
  // ---------------------------------------------------------------------------

  Future<List<LibraryItem>> getFeaturedPamphlets() async {
    final db = await _dbHelper.database;
    try {
      // 1. Fetch 4 random items from Islamic Library (المكتبة)
      final libraryRows = await db.rawQuery(
        'SELECT $_libraryListCols FROM library WHERE part = "المكتبة" AND title IS NOT NULL AND title != "" ORDER BY RANDOM() LIMIT 4',
      );

      // 2. Fetch 4 random items from Sahih Al-Bukhari (صحيح البخارى)
      final bukhariRows = await db.rawQuery(
        'SELECT $_libraryListCols FROM library WHERE (part = "صحيح البخارى" OR part = "البخارى") AND title IS NOT NULL AND title != "" ORDER BY RANDOM() LIMIT 4',
      );

      final List<LibraryItem> results = [];
      final libItems = libraryRows.map((e) => LibraryItem.fromMap(e)).toList();
      final bukhariItems = bukhariRows.map((e) => LibraryItem.fromMap(e)).toList();

      // Interleave for a balanced 50/50 mix
      int maxLen = libItems.length > bukhariItems.length ? libItems.length : bukhariItems.length;
      for (int i = 0; i < maxLen; i++) {
        if (i < libItems.length) results.add(libItems[i]);
        if (i < bukhariItems.length) results.add(bukhariItems[i]);
      }

      if (results.isNotEmpty) return results;

      // Fallback
      final anyRows = await db.rawQuery(
        'SELECT $_libraryListCols FROM library ORDER BY RANDOM() LIMIT 8',
      );
      return anyRows.map((e) => LibraryItem.fromMap(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ---------------------------------------------------------------------------
  // Content Lists (Level 3)
  // ---------------------------------------------------------------------------

  Future<List<LibraryItem>> getLibraryItems(String part, String typeId, {String? searchQuery}) async {
    final db = await _dbHelper.database;
    String query;
    List<dynamic> args;

    if (part == 'صحيح البخارى' || part == 'البخارى') {
      query = 'SELECT $_libraryListCols FROM library WHERE (part = "صحيح البخارى" OR part = "البخارى") AND type = ?';
      args = [typeId];
    } else {
      query = 'SELECT $_libraryListCols FROM library WHERE part = ? AND type = ?';
      args = [part, typeId];
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query += ' AND title LIKE ?';
      args.add('%$searchQuery%');
    }

    final rows = await db.rawQuery(query, args);
    return rows.map((e) => LibraryItem.fromMap(e)).toList();
  }

  Future<List<FatwaItem>> getFatawyItems(String fatwyType, {String? searchQuery}) async {
    final db = await _dbHelper.database;
    String query = 'SELECT $_fatwaListCols FROM fatawy WHERE fatwy_type = ?';
    List<dynamic> args = [fatwyType];
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query += ' AND question LIKE ?';
      args.add('%$searchQuery%');
    }
    final rows = await db.rawQuery(query, args);
    return rows.map((e) => FatwaItem.fromMap(e)).toList();
  }
  
  Future<List<RoquaItem>> getRoquaItems(String level, {String? searchQuery}) async {
    final db = await _dbHelper.database;
    String query = 'SELECT $_roquaListCols, "" as story, info FROM roqua WHERE level = ?';
    List<dynamic> args = [level];
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query += ' AND roqua LIKE ?';
      args.add('%$searchQuery%');
    }
    
    final rows = await db.rawQuery(query, args);
    return rows.map((e) => RoquaItem.fromMap(e)).toList();
  }

  Future<List<LibraryItem>> getFavorites() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT $_libraryListCols FROM library WHERE fav = ?',
      [1],
    );
    return rows.map((e) => LibraryItem.fromMap(e)).toList();
  }

  // ---------------------------------------------------------------------------
  // Universal Search (Cross-Domain)
  // ---------------------------------------------------------------------------

  Future<List<LibraryItem>> searchLibrary(String query) async {
    if (query.isEmpty) return [];
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT $_libraryListCols FROM library WHERE title LIKE ? AND part NOT IN ("صوتيات", "مرئيات")',
      ['%$query%']
    );
    return rows.map((e) => LibraryItem.fromMap(e)).toList();
  }

  // ---------------------------------------------------------------------------
  // Lazy Loaded Heavy Content (Level 4)
  // ---------------------------------------------------------------------------

  Future<String> getLibraryStory(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('SELECT part, story FROM library WHERE id = ?', [id]);
    if (rows.isNotEmpty) {
      final part = rows.first['part']?.toString() ?? '';
      final raw = rows.first['story']?.toString() ?? '';
      if (part == 'صحيح البخارى' || part == 'البخارى') {
        return cleanDuplicateHadithText(raw);
      }
      return raw;
    }
    return '';
  }

  /// Removes duplicate non-voweled copies and removes '{' and '}' braces from Bukhari Hadiths.
  static String cleanDuplicateHadithText(String raw) {
    if (raw.trim().isEmpty) return raw;

    String text = raw.trim();

    // 1. Remove duplicate non-voweled trailing block
    final int lastOpen = text.lastIndexOf('{');
    if (lastOpen > 20) {
      final after = text.substring(lastOpen).trim();
      if (after.length >= 20 &&
          (after.endsWith('}') ||
              after.endsWith('}.') ||
              after.endsWith('} .'))) {
        final before = text.substring(0, lastOpen).trim();
        if (before.length > 20) {
          text = before;
        }
      }
    }

    // 2. Remove curly braces '{' and '}' completely from Hadith
    text = text.replaceAll('{', '').replaceAll('}', '');

    // 3. Normalize spaces
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  Future<String> getFatwaAnswer(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('SELECT answer FROM fatawy WHERE id = ?', [id]);
    if (rows.isNotEmpty) return rows.first['answer']?.toString() ?? '';
    return '';
  }

  Future<String> getRoquaStory(int id) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('SELECT story FROM roqua WHERE id = ?', [id]);
    if (rows.isNotEmpty) return rows.first['story']?.toString() ?? '';
    return '';
  }

  // ---------------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------------

  Future<void> toggleFavorite(int id, bool isFav) async {
    final db = await _dbHelper.database;
    await db.update('library', {'fav': isFav ? 1 : 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> recordReading(int id, int currentReadings) async {
    final db = await _dbHelper.database;
    await db.update(
      'library',
      {
        'num_readings': currentReadings + 1,
        'last_read': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
