import '../core/database/database_helper.dart';

class AzkarService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<String?> getRandomShortZekr() async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery(
      'SELECT zekr FROM azkar WHERE LENGTH(zekr) < 80 ORDER BY RANDOM() LIMIT 1',
    );
    
    if (rows.isNotEmpty) {
      return rows.first['zekr'] as String?;
    }
    return null;
  }
}
