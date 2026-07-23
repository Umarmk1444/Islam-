import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  final databaseFactory = databaseFactoryFfi;
  final db = await databaseFactory.openDatabase('assets/muslim_house.db');

  final tables = await db.rawQuery("PRAGMA table_info(quran)");
  print("Columns in quran table:");
  for (var row in tables) {
    print("${row['name']} (${row['type']})");
  }

  final sample = await db.rawQuery("SELECT * FROM quran LIMIT 1");
  print("\nSample row:");
  print(sample);

  await db.close();
}
