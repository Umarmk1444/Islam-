import 'dart:developer' as dev;
import '../core/database/database_helper.dart';
import '../models/minbar_models.dart';

class MinbarRepository {
  final DatabaseHelper _dbHelper;

  MinbarRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const String _kLogName = 'MinbarRepository';

  // Static list of main Minbar audio categories
  static const List<MinbarCategory> _categories = [
    MinbarCategory(
      id: 'quran',
      name: 'قرآن كريم',
      englishName: 'Quran Recitations',
      icon: 'quran_icon',
    ),
    MinbarCategory(
      id: 'khutbah',
      name: 'خطب',
      englishName: 'Sermons',
      icon: 'sermons_icon',
    ),
    MinbarCategory(
      id: 'dua',
      name: 'أدعية',
      englishName: 'Supplications',
      icon: 'supplications_icon',
    ),
    MinbarCategory(
      id: 'ruqyah',
      name: 'رقية شرعية',
      englishName: 'Ruqyah',
      icon: 'ruqyah_icon',
    ),
    MinbarCategory(
      id: 'ibtehalat',
      name: 'ابتهالات',
      englishName: 'Ibtehalat',
      icon: 'ibtehalat_icon',
    ),
  ];

  /// 1. Fetch all main audio categories
  Future<List<MinbarCategory>> getCategories() async {
    try {
      // Returned instantly as categories are statically defined core features.
      return _categories;
    } catch (e, st) {
      dev.log('Error fetching categories', name: _kLogName, error: e, stackTrace: st);
      throw Exception('Failed to load audio categories: $e');
    }
  }

  /// Helper to map category ID to database title used in the `all_index` table
  String _mapCategoryToDbTitle(String categoryId) {
    switch (categoryId) {
      case 'khutbah':
        return 'خطب';
      case 'dua':
        return 'أدعية';
      case 'ruqyah':
        return 'رقية شرعية';
      case 'ibtehalat':
        return 'إبتهالات';
      default:
        throw ArgumentError('Invalid or unsupported category ID: $categoryId');
    }
  }

  /// 2. Fetch all reciters/authors for a specific category
  Future<List<MinbarAuthor>> getAuthorsForCategory(String categoryId) async {
    try {
      final db = await _dbHelper.database;

      if (categoryId == 'quran') {
        // Query the dedicated reciters table
        final rows = await db.rawQuery(
          'SELECT id, name, server_num, eng_name, type FROM qoraa ORDER BY name ASC',
        );
        return rows.map((row) => MinbarAuthor.fromMap(row)).toList();
      } else {
        // Map category ID to all_index title
        final dbTitle = _mapCategoryToDbTitle(categoryId);
        final rows = await db.rawQuery(
          'SELECT id, abc AS name FROM all_index WHERE title = ? ORDER BY abc ASC',
          [dbTitle],
        );
        return rows.map((row) {
          return MinbarAuthor(
            id: row['id'].toString(),
            name: row['name'] as String,
          );
        }).toList();
      }
    } catch (e, st) {
      dev.log(
        'Error fetching authors for category $categoryId',
        name: _kLogName,
        error: e,
        stackTrace: st,
      );
      throw Exception('Failed to load authors for category $categoryId: $e');
    }
  }

  /// 3. Fetch all audio items (with their Archive URLs) for a specific reciter
  Future<List<MinbarAudioItem>> getAudioItemsForAuthor(
    String categoryId,
    String authorId,
  ) async {
    try {
      final db = await _dbHelper.database;
      final parsedAuthorId = int.tryParse(authorId);
      if (parsedAuthorId == null) {
        throw ArgumentError('Invalid author ID format: $authorId');
      }

      if (categoryId == 'quran') {
        // Step A: Find the Quran reciter metadata to get the CDN path
        final reciterRows = await db.rawQuery(
          'SELECT server_num, eng_name FROM qoraa WHERE id = ? LIMIT 1',
          [parsedAuthorId],
        );
        if (reciterRows.isEmpty) {
          throw Exception('Reciter with ID $authorId not found in database.');
        }

        final serverNum = reciterRows.first['server_num'] as String?;
        final engName = reciterRows.first['eng_name'] as String?;

        if (serverNum == null || engName == null || serverNum.isEmpty || engName.isEmpty) {
          throw Exception('Incomplete URL metadata for reciter ID $authorId.');
        }

        // Step B: Query the list of 114 Surahs from all_index
        final surahRows = await db.rawQuery(
          "SELECT abc AS title, abc2 AS surah_num FROM all_index WHERE title = 'السور' ORDER BY id ASC",
        );

        // Step C: Build direct Quran audio URLs dynamically using the mp3quran.net CDN
        return surahRows.map((row) {
          final surahNum = row['surah_num'] as String;
          final title = row['title'] as String;
          final url = 'https://$serverNum.mp3quran.net/$engName/$surahNum.mp3';

          return MinbarAudioItem(
            id: '${authorId}_$surahNum',
            title: title,
            url: url,
            authorId: authorId,
          );
        }).toList();
      } else {
        // Step A: Look up the author/category-detail name from all_index
        final authorRows = await db.rawQuery(
          'SELECT abc FROM all_index WHERE id = ? LIMIT 1',
          [parsedAuthorId],
        );
        if (authorRows.isEmpty) {
          return const [];
        }
        final authorName = authorRows.first['abc'] as String;

        // Step B: Query all matching audio files from library table
        final audioRows = await db.rawQuery(
          "SELECT id, title, story AS url FROM library WHERE type = ? AND part = 'صوتيات' ORDER BY id ASC",
          [authorName],
        );

        return audioRows.map((row) {
          return MinbarAudioItem(
            id: row['id'].toString(),
            title: row['title'] as String,
            url: row['url'] as String,
            authorId: authorId,
          );
        }).toList();
      }
    } catch (e, st) {
      dev.log(
        'Error fetching audio items for category $categoryId, author $authorId',
        name: _kLogName,
        error: e,
        stackTrace: st,
      );
      throw Exception('Failed to load audio items: $e');
    }
  }
}
