import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Library Classical Content Structural Preservation Tests', () {
    test('Verifies all 673 classical articles are mapped with zero orphaned categories', () async {
      File dbFile = File('assets/muslim_house.db');
      if (!dbFile.existsSync() && File('assets/muslim_house.db.gz').existsSync()) {
        final tmp = File('${Directory.systemTemp.path}/test_mh.db');
        tmp.writeAsBytesSync(gzip.decode(File('assets/muslim_house.db.gz').readAsBytesSync()));
        dbFile = tmp;
      }
      expect(dbFile.existsSync(), isTrue);

      final db = await databaseFactory.openDatabase(dbFile.absolute.path, options: OpenDatabaseOptions(readOnly: true));

      final rows = await db.rawQuery(
        "SELECT type, COUNT(*) as cnt FROM library WHERE part = 'المكتبة' GROUP BY type",
      );

      final Map<String, int> categoryCounts = {};
      int totalItems = 0;
      for (final r in rows) {
        final type = (r['type'] as String).trim();
        final count = r['cnt'] as int;
        categoryCounts[type] = (categoryCounts[type] ?? 0) + count;
        totalItems += count;
      }

      expect(totalItems, equals(673));
      expect(categoryCounts.length, equals(20));

      // 8 Scholarly Faculty groupings
      final quranSciences = ['الناسخ والمنسوخ', 'إعجاز القرآن', 'قصص القرآن', 'القرآن الكريم'];
      final seerah = ['من وصايا الرسول', 'غزوات الرسول', 'شمائل الرسول'];
      final companions = ['قصص الصحابة', 'خلفاء وقادة', 'قصص التابعين', 'قصص الصحابيات'];
      final prophets = ['قصص الأنبياء', 'قصص وعبر'];
      final aqeedah = ['الله - عز وجل', 'الملائكة', 'علامات الساعة الكبرى', 'الأحاديث القدسية'];
      final tibb = ['الطب النبوى', 'الطب البديل', 'باب المعرفة'];

      final allMapped = {
        ...quranSciences,
        ...seerah,
        ...companions,
        ...prophets,
        ...aqeedah,
        ...tibb,
      };

      // Every category in the DB must be mapped
      for (final cat in categoryCounts.keys) {
        expect(allMapped.contains(cat), isTrue, reason: 'Category "$cat" must be mapped to a scholarly faculty');
      }

      // Verify exact count sums
      int quranCount = quranSciences.fold(0, (sum, c) => sum + (categoryCounts[c] ?? 0));
      int seerahCount = seerah.fold(0, (sum, c) => sum + (categoryCounts[c] ?? 0));
      int companionsCount = companions.fold(0, (sum, c) => sum + (categoryCounts[c] ?? 0));
      int prophetsCount = prophets.fold(0, (sum, c) => sum + (categoryCounts[c] ?? 0));
      int aqeedahCount = aqeedah.fold(0, (sum, c) => sum + (categoryCounts[c] ?? 0));
      int tibbCount = tibb.fold(0, (sum, c) => sum + (categoryCounts[c] ?? 0));

      expect(quranCount, equals(174));
      expect(seerahCount, equals(91));
      expect(companionsCount, equals(252));
      expect(prophetsCount, equals(44));
      expect(aqeedahCount, equals(30));
      expect(tibbCount, equals(82));
      expect(quranCount + seerahCount + companionsCount + prophetsCount + aqeedahCount + tibbCount, equals(673));

      await db.close();
    });
  });

  group('Hadith 10 Collections Exact Row Count Audit', () {
    test('Verifies canonical database contains exactly 40,937 hadiths matching collection table', () async {
      final gzFile = File('assets/hadith_library.db.gz');
      expect(gzFile.existsSync(), isTrue);

      final bytes = gzFile.readAsBytesSync();
      final decompressed = gzip.decode(bytes);

      final tempDir = Directory.systemTemp.createTempSync('hadith_audit_test');
      final tempDbFile = File('${tempDir.path}/hadith_audit.db');
      tempDbFile.writeAsBytesSync(decompressed);

      final db = await databaseFactory.openDatabase(tempDbFile.absolute.path, options: OpenDatabaseOptions(readOnly: true));

      final totalHadithsRow = await db.rawQuery('SELECT COUNT(*) as cnt FROM hadiths');
      final int totalHadiths = totalHadithsRow.first['cnt'] as int;
      expect(totalHadiths, equals(40937));

      final collections = await db.rawQuery('SELECT id, name_ar, total_hadiths FROM collections ORDER BY sort_order');
      expect(collections.length, equals(10));

      final expectedCounts = {
        1: 7277, // صحيح البخاري
        2: 7368, // صحيح مسلم
        3: 5768, // سنن النسائي
        4: 5276, // سنن أبي داود
        5: 4053, // جامع الترمذي
        6: 4345, // سنن ابن ماجه
        7: 1861, // موطأ مالك
        8: 1896, // رياض الصالحين
        9: 1326, // الأدب المفرد
        10: 1767, // بلوغ المرام
      };

      for (final col in collections) {
        final int id = col['id'] as int;
        final int declaredCount = col['total_hadiths'] as int;
        final actualRow = await db.rawQuery('SELECT COUNT(*) as cnt FROM hadiths WHERE collection_id = ?', [id]);
        final int actualCount = actualRow.first['cnt'] as int;

        expect(declaredCount, equals(expectedCounts[id]), reason: 'Collection $id declared count mismatch');
        expect(actualCount, equals(expectedCounts[id]), reason: 'Collection $id actual row count mismatch');
      }

      await db.close();
      tempDir.deleteSync(recursive: true);
    });
  });
}
