import '../core/database/hadith_database_helper.dart';
import '../models/hadith_models.dart';

class HadithService {
  final HadithDatabaseHelper _dbHelper = HadithDatabaseHelper.instance;

  Future<List<HadithCollection>> getCollections() => _dbHelper.getCollections();

  Future<HadithCollection?> getCollection(int id) => _dbHelper.getCollection(id);

  Future<List<HadithBook>> getBooks(int collectionId) => _dbHelper.getBooks(collectionId);

  Future<HadithBook?> getBook(int bookId) => _dbHelper.getBook(bookId);

  Future<List<HadithChapter>> getChapters(int collectionId, int bookId) =>
      _dbHelper.getChapters(collectionId, bookId);

  Future<HadithChapter?> getChapter(int chapterId) => _dbHelper.getChapter(chapterId);

  Future<List<HadithItem>> getHadithsByChapter(int collectionId, int bookId, int chapterId) =>
      _dbHelper.getHadithsByChapter(collectionId, bookId, chapterId);

  Future<List<HadithItem>> getHadithsByBook(
    int collectionId,
    int bookId, {
    int limit = 100,
    int offset = 0,
  }) =>
      _dbHelper.getHadithsByBook(collectionId, bookId, limit: limit, offset: offset);

  Future<HadithItem?> getHadithById(int id) => _dbHelper.getHadithById(id);

  Future<List<HadithItem>> searchHadiths(
    String query, {
    int? collectionId,
    int limit = 50,
    int offset = 0,
  }) =>
      _dbHelper.searchHadiths(query, collectionId: collectionId, limit: limit, offset: offset);

  Future<void> toggleFavorite(int hadithId, int collectionId, bool isFavorite) =>
      _dbHelper.toggleFavorite(hadithId, collectionId, isFavorite);

  Future<void> recordReading(int hadithId, int collectionId) =>
      _dbHelper.recordReading(hadithId, collectionId);

  Future<List<HadithItem>> getFavorites({int? collectionId}) =>
      _dbHelper.getFavorites(collectionId: collectionId);

  Future<HadithItem?> getLatestReadHadith() => _dbHelper.getLatestReadHadith();
}
