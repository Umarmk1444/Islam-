import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:quran_zone/models/hadith_models.dart';

void main() {
  group('Hadith Models Unit Tests', () {
    test('HadithCollection.fromMap correctly parses collection attributes', () {
      final map = {
        'id': 1,
        'source_collection_id': 1,
        'slug': 'bukhari',
        'name_ar': 'صحيح البخاري',
        'author_ar': 'الإمام البخاري',
        'numbering_source': 'فؤاد عبد الباقي',
        'total_books': 97,
        'total_chapters': 4084,
        'total_hadiths': 7277,
        'has_chapters': 1,
        'sort_order': 1,
      };

      final col = HadithCollection.fromMap(map);
      expect(col.id, equals(1));
      expect(col.slug, equals('bukhari'));
      expect(col.nameAr, equals('صحيح البخاري'));
      expect(col.totalBooks, equals(97));
      expect(col.totalChapters, equals(4084));
      expect(col.totalHadiths, equals(7277));
      expect(col.hasChapters, isTrue);
    });

    test('HadithBook.fromMap parses book attributes', () {
      final map = {
        'id': 1,
        'collection_id': 1,
        'book_number': 1,
        'name_ar': 'كتاب بدء الوحي',
        'intro_ar': null,
        'first_hadith_num': 1,
        'last_hadith_num': 7,
        'total_hadiths': 7,
        'total_chapters': 6,
      };

      final book = HadithBook.fromMap(map);
      expect(book.id, equals(1));
      expect(book.collectionId, equals(1));
      expect(book.bookNumber, equals(1));
      expect(book.nameAr, equals('كتاب بدء الوحي'));
      expect(book.totalHadiths, equals(7));
      expect(book.totalChapters, equals(6));
      expect(book.hasChapters, isTrue);
    });

    test('HadithBook.fromMap handles computed ranges and discards zero first/last hadith numbers', () {
      final mapWithZeros = {
        'id': 701,
        'collection_id': 7,
        'book_number': 1,
        'name_ar': 'كتاب وقوت الصلاة',
        'first_hadith_num': 0,
        'last_hadith_num': 0,
        'total_hadiths': 32,
        'total_chapters': 0,
      };
      final book1 = HadithBook.fromMap(mapWithZeros);
      expect(book1.firstHadithNum, isNull);
      expect(book1.lastHadithNum, isNull);
      expect(book1.hasChapters, isFalse);

      final mapWithComputed = {
        'id': 701,
        'collection_id': 7,
        'book_number': 1,
        'name_ar': 'كتاب وقوت الصلاة',
        'first_hadith_num': 0,
        'last_hadith_num': 0,
        'computed_first_num': 1,
        'computed_last_num': 32,
        'total_hadiths': 32,
        'total_chapters': 0,
      };
      final book2 = HadithBook.fromMap(mapWithComputed);
      expect(book2.firstHadithNum, equals(1));
      expect(book2.lastHadithNum, equals(32));
      expect(book2.hasChapters, isFalse);
    });

    test('HadithChapter.fromMap parses chapter with intro preamble', () {
      final map = {
        'id': 49,
        'collection_id': 1,
        'book_id': 3,
        'chapter_number': 49.0,
        'bab_ar': 'باب مَنْ خَصَّ بِالْعِلْمِ قَوْمًا دُونَ قَوْمٍ',
        'intro_ar': 'وَقَالَ عَلِيٌّ حَدِّثُوا النَّاسَ بِمَا يَعْرِفُونَ...',
      };

      final chapter = HadithChapter.fromMap(map);
      expect(chapter.id, equals(49));
      expect(chapter.collectionId, equals(1));
      expect(chapter.chapterNumber, equals(49.0));
      expect(chapter.introAr, isNotNull);
      expect(chapter.introAr, contains('وَقَالَ عَلِيٌّ'));
    });

    test('HadithChapter.fromMap safely handles empty string or string chapter_number', () {
      final mapEmpty = {
        'id': 50,
        'collection_id': 1,
        'book_id': 3,
        'chapter_number': '',
        'bab_ar': 'باب بدون رقم',
        'intro_ar': null,
      };

      final chapter = HadithChapter.fromMap(mapEmpty);
      expect(chapter.chapterNumber, equals(0.0));

      final mapStringNum = {
        'id': 51,
        'collection_id': 1,
        'book_id': 3,
        'chapter_number': '14.5',
        'bab_ar': 'باب برقم نصي',
        'intro_ar': null,
      };

      final chapter2 = HadithChapter.fromMap(mapStringNum);
      expect(chapter2.chapterNumber, equals(14.5));
    });

    test('HadithItem.fromMap parses hadith record with isnad, matn, and legacy ID', () {
      final map = {
        'id': 1,
        'collection_id': 1,
        'book_id': 1,
        'chapter_id': 1,
        'source_urn': 100010,
        'hadith_number': '1',
        'in_book_number': 1,
        'arabic_text': 'حَدَّثَنَا الْحُمَيْدِيُّ... إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ',
        'arabic_clean': 'حدثنا الحميدي... انما الاعمال بالنيات',
        'isnad_ar': 'حَدَّثَنَا الْحُمَيْدِيُّ...',
        'matn_ar': 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ',
        'grade': 'صحيح',
        'grade_by': null,
        'legacy_bukhari_id': 4515,
        'is_favorite': 1,
        'last_read_timestamp': 1690000000,
        'read_count': 5,
        'notes': null,
      };

      final item = HadithItem.fromMap(map);
      expect(item.id, equals(1));
      expect(item.hadithNumber, equals('1'));
      expect(item.legacyBukhariId, equals(4515));
      expect(item.isFavorite, isTrue);
      expect(item.grade, equals('صحيح'));
      expect(item.readCount, equals(5));
    });

    test('HadithItem.copyWith preserves immutability and updates states', () {
      const item = HadithItem(
        id: 1,
        collectionId: 1,
        bookId: 1,
        sourceUrn: 100010,
        hadithNumber: '1',
        inBookNumber: 1,
        arabicText: 'إنما الأعمال بالنيات',
        arabicClean: 'انما الاعمال بالنيات',
        isFavorite: false,
      );

      final updated = item.copyWith(isFavorite: true, readCount: 2);
      expect(updated.isFavorite, isTrue);
      expect(updated.readCount, equals(2));
      expect(item.isFavorite, isFalse); // original untouched
    });
  });

  group('Arabic Search Normalization Tests', () {
    String normalize(String text) {
      if (text.isEmpty) return '';
      var norm = text;
      norm = norm.replaceAll(RegExp(r'[\u0617-\u061A\u064B-\u0652]'), '');
      norm = norm.replaceAll('\u0640', '');
      norm = norm.replaceAll(RegExp(r'[إأآٱ]'), 'ا');
      norm = norm.replaceAll('ى', 'ي');
      norm = norm.replaceAll('ة', 'ه');
      return norm.replaceAll(RegExp(r'\s+'), ' ').trim();
    }

    test('Strips diacritics / tashkeel accurately', () {
      const input = 'إِنَّمَا الأَعْمَالُ بِالنِّيَّاتِ';
      final cleaned = normalize(input);
      expect(cleaned, equals('انما الاعمال بالنيات'));
    });

    test('Standardizes varied alifs and yeh forms', () {
      const input = 'إِسْمَاعِيلُ عَلَى التَّقْوَى';
      final cleaned = normalize(input);
      expect(cleaned, equals('اسماعيل علي التقوي'));
    });

    test('Normalizes taa marbuta to haa', () {
      const input = 'الصَّلَاةُ وَالزَّكَاةُ';
      final cleaned = normalize(input);
      expect(cleaned, equals('الصلاه والزكاه'));
    });
  });

  group('Streaming Extraction & Integrity Logic Tests', () {
    test('Stream decompression via gzip restores exact byte payload', () async {
      const sample = 'موسوعة الحديث الشريف - اختبار استخراج البيانات المحمية';
      final uncompressedBytes = utf8.encode(sample);
      final compressedBytes = gzip.encode(uncompressedBytes);

      final decompressedSink = <int>[];
      final stream = Stream<List<int>>.value(compressedBytes).transform(gzip.decoder);
      await for (final chunk in stream) {
        decompressedSink.addAll(chunk);
      }

      final restoredString = utf8.decode(decompressedSink);
      expect(restoredString, equals(sample));
    });

    test('assets/hadith_library.db.gz exists and is a valid gzip archive', () {
      final assetFile = File('assets/hadith_library.db.gz');
      expect(assetFile.existsSync(), isTrue);
      final size = assetFile.lengthSync();
      // Compressed size is ~49-52 MB for the full 10-collection library (40,937 hadiths)
      expect(size, greaterThan(20 * 1024 * 1024));
      expect(size, lessThan(65 * 1024 * 1024));

      // Verify gzip header (magic bytes 0x1F, 0x8B)
      final bytes = assetFile.openSync().readSync(2);
      expect(bytes[0], equals(0x1F));
      expect(bytes[1], equals(0x8B));
    });
  });

  group('Legacy User Data Migration Tests', () {
    late Database legacyDb;
    late Database hadithDb;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      legacyDb = await openDatabase(inMemoryDatabasePath);
      hadithDb = await openDatabase(inMemoryDatabasePath);

      // Setup legacy library schema
      await legacyDb.execute('''
        CREATE TABLE library (
          id INTEGER PRIMARY KEY,
          part TEXT,
          fav INTEGER DEFAULT 0,
          last_read INTEGER DEFAULT 0,
          num_readings INTEGER DEFAULT 0
        );
      ''');

      // Setup new hadith library schema
      await hadithDb.execute('''
        CREATE TABLE hadiths (
          id INTEGER PRIMARY KEY,
          collection_id INTEGER,
          legacy_bukhari_id INTEGER
        );
      ''');
      await hadithDb.execute('''
        CREATE TABLE hadith_user_data (
          hadith_id INTEGER PRIMARY KEY,
          collection_id INTEGER,
          is_favorite INTEGER DEFAULT 0,
          last_read_timestamp INTEGER,
          read_count INTEGER DEFAULT 0,
          notes TEXT
        );
      ''');
      await hadithDb.execute('''
        CREATE TABLE hadith_unmatched_legacy (
          legacy_id INTEGER PRIMARY KEY,
          fav INTEGER DEFAULT 0,
          last_read INTEGER DEFAULT 0,
          num_readings INTEGER DEFAULT 0
        );
      ''');

      // Seed candidate hadiths
      await hadithDb.insert('hadiths', {'id': 101, 'collection_id': 1, 'legacy_bukhari_id': 4515});
    });

    tearDown(() async {
      await legacyDb.close();
      await hadithDb.close();
    });

    test('Migration correctly merges matched records and preserves unmatched in recovery table', () async {
      // 1 matched Bukhari favorite (id: 4515), 1 unmatched Bukhari favorite (id: 99999), 1 non-Bukhari record
      // In muslim_house.db, fav, last_read, and num_readings are stored as TEXT
      await legacyDb.insert('library', {
        'id': 4515,
        'part': 'صحيح البخاري',
        'fav': '1',
        'last_read': '1700000000',
        'num_readings': '3',
      });
      await legacyDb.insert('library', {
        'id': 99999,
        'part': 'صحيح البخاري',
        'fav': '1',
        'last_read': '1699999999',
        'num_readings': '1',
      });
      await legacyDb.insert('library', {
        'id': 12,
        'part': 'تفسير ابن كثير',
        'fav': '1',
        'last_read': '0',
        'num_readings': '0',
      });

      int parseInt(dynamic val, [int fallback = 0]) {
        if (val == null) return fallback;
        if (val is int) return val;
        if (val is num) return val.toInt();
        if (val is String) return int.tryParse(val) ?? fallback;
        return fallback;
      }

      // Run migration logic
      final legacyRows = await legacyDb.rawQuery('''
        SELECT id, fav, last_read, num_readings 
        FROM library 
        WHERE (part LIKE '%بخار%' OR part = 'البخارى') 
          AND (fav = '1' OR fav = 1 OR (last_read IS NOT NULL AND last_read != '' AND last_read != '0'));
      ''');

      expect(legacyRows.length, equals(2)); // Only the 2 Bukhari records

      await hadithDb.transaction((txn) async {
        for (final row in legacyRows) {
          final legacyId = parseInt(row['id']);
          final isFav = parseInt(row['fav']) == 1;
          final lastRead = parseInt(row['last_read']);
          final numReadings = parseInt(row['num_readings']);

          final matches = await txn.rawQuery(
            'SELECT id, collection_id FROM hadiths WHERE legacy_bukhari_id = ? LIMIT 1;',
            [legacyId],
          );

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
          } else {
            await txn.rawInsert('''
              INSERT OR REPLACE INTO hadith_unmatched_legacy (
                legacy_id, fav, last_read, num_readings
              ) VALUES (?, ?, ?, ?);
            ''', [legacyId, isFav ? 1 : 0, lastRead, numReadings]);
          }
        }
      });

      // Assertions
      final userData = await hadithDb.query('hadith_user_data');
      expect(userData.length, equals(1));
      expect(userData.first['hadith_id'], equals(101));
      expect(userData.first['is_favorite'], equals(1));
      expect(userData.first['last_read_timestamp'], equals(1700000000));
      expect(userData.first['read_count'], equals(3));

      final unmatched = await hadithDb.query('hadith_unmatched_legacy');
      expect(unmatched.length, equals(1));
      expect(unmatched.first['legacy_id'], equals(99999));
      expect(unmatched.first['fav'], equals(1));

      // Test idempotency: re-running does not corrupt or overwrite
      await hadithDb.transaction((txn) async {
        for (final row in legacyRows) {
          final legacyId = row['id'] as int;
          final isFav = (row['fav'] as int? ?? 0) == 1;
          final lastRead = row['last_read'] as int? ?? 0;
          final numReadings = row['num_readings'] as int? ?? 0;

          final matches = await txn.rawQuery(
            'SELECT id, collection_id FROM hadiths WHERE legacy_bukhari_id = ? LIMIT 1;',
            [legacyId],
          );

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
          }
        }
      });

      final reCheckedData = await hadithDb.query('hadith_user_data');
      expect(reCheckedData.length, equals(1));
      expect(reCheckedData.first['is_favorite'], equals(1));
    });
  });

  group('Book and Chapter Navigation & Structure Tests', () {
    late Database testDb;

    setUp(() async {
      testDb = await openDatabase(inMemoryDatabasePath);
      await testDb.execute('''
        CREATE TABLE collections (
          id INTEGER PRIMARY KEY,
          slug TEXT,
          name_ar TEXT,
          author_ar TEXT,
          numbering_source TEXT,
          total_books INTEGER,
          total_chapters INTEGER,
          total_hadiths INTEGER,
          has_chapters INTEGER,
          sort_order INTEGER
        );
      ''');
      await testDb.execute('''
        CREATE TABLE books (
          id INTEGER PRIMARY KEY,
          collection_id INTEGER,
          book_number INTEGER,
          name_ar TEXT,
          intro_ar TEXT,
          first_hadith_num INTEGER,
          last_hadith_num INTEGER,
          total_hadiths INTEGER
        );
      ''');
      await testDb.execute('''
        CREATE TABLE chapters (
          id INTEGER PRIMARY KEY,
          collection_id INTEGER,
          book_id INTEGER,
          chapter_number REAL,
          bab_ar TEXT,
          intro_ar TEXT,
          source_chapter_id TEXT
        );
      ''');
      await testDb.execute('''
        CREATE TABLE hadiths (
          id INTEGER PRIMARY KEY,
          collection_id INTEGER,
          book_id INTEGER,
          chapter_id INTEGER,
          hadith_number TEXT,
          in_book_number INTEGER,
          arabic_text TEXT,
          arabic_clean TEXT
        );
      ''');
      await testDb.execute('''
        CREATE TABLE hadith_user_data (
          hadith_id INTEGER PRIMARY KEY,
          collection_id INTEGER,
          is_favorite INTEGER DEFAULT 0,
          last_read_timestamp INTEGER,
          read_count INTEGER DEFAULT 0,
          notes TEXT
        );
      ''');

      // Seed Bulugh al-Maram (Col 10)
      // Book 1 (Taharah): has chapters
      await testDb.insert('books', {
        'id': 474,
        'collection_id': 10,
        'book_number': 1,
        'name_ar': 'كتاب الطهارة',
        'total_hadiths': 2,
      });
      await testDb.insert('chapters', {
        'id': 1001,
        'collection_id': 10,
        'book_id': 474,
        'chapter_number': 1.0,
        'bab_ar': 'باب المياه',
      });
      await testDb.insert('hadiths', {
        'id': 39171,
        'collection_id': 10,
        'book_id': 474,
        'chapter_id': 1001,
        'hadith_number': '1',
        'in_book_number': 1,
        'arabic_text': 'طهور ماؤه الحل ميتته',
      });
      await testDb.insert('hadiths', {
        'id': 39172,
        'collection_id': 10,
        'book_id': 474,
        'chapter_id': 1001,
        'hadith_number': '2',
        'in_book_number': 2,
        'arabic_text': 'الماء طهور لا ينجسه شيء',
      });

      // Book 2 (Salah): has NO chapters (chapters = 0, chapter_id = null)
      await testDb.insert('books', {
        'id': 475,
        'collection_id': 10,
        'book_number': 2,
        'name_ar': 'كتاب الصلاة',
        'total_hadiths': 2,
      });
      await testDb.insert('hadiths', {
        'id': 39350,
        'collection_id': 10,
        'book_id': 475,
        'chapter_id': null,
        'hadith_number': '180',
        'in_book_number': 1,
        'arabic_text': 'فرض الله الصلاة',
      });
      await testDb.insert('hadiths', {
        'id': 39351,
        'collection_id': 10,
        'book_id': 475,
        'chapter_id': null,
        'hadith_number': '181',
        'in_book_number': 2,
        'arabic_text': 'بني الإسلام على خمس',
      });
    });

    tearDown(() async {
      await testDb.close();
    });

    test('Book with chapters correctly detects hasChapters=true and chapters count', () async {
      final rows = await testDb.rawQuery('''
        SELECT b.*,
               (SELECT COUNT(*) FROM chapters c WHERE c.book_id = b.id) as total_chapters
        FROM books b
        WHERE b.id = 474;
      ''');
      final book = HadithBook.fromMap(rows.first);
      expect(book.hasChapters, isTrue);
      expect(book.totalChapters, equals(1));
      expect(book.totalHadiths, equals(2));
    });

    test('Book without chapters correctly detects hasChapters=false and totalChapters=0', () async {
      final rows = await testDb.rawQuery('''
        SELECT b.*,
               (SELECT COUNT(*) FROM chapters c WHERE c.book_id = b.id) as total_chapters
        FROM books b
        WHERE b.id = 475;
      ''');
      final book = HadithBook.fromMap(rows.first);
      expect(book.hasChapters, isFalse);
      expect(book.totalChapters, equals(0));
      expect(book.totalHadiths, equals(2));
    });

    test('Direct book reader query returns all hadiths regardless of null chapter_id', () async {
      // Reader query does NOT filter by chapter_id
      final hadithRows = await testDb.rawQuery('''
        SELECT h.*, 
               COALESCE(u.is_favorite, 0) as is_favorite,
               u.last_read_timestamp,
               COALESCE(u.read_count, 0) as read_count,
               u.notes
        FROM hadiths h
        LEFT JOIN hadith_user_data u ON u.hadith_id = h.id
        WHERE h.collection_id = ? AND h.book_id = ?
        ORDER BY h.in_book_number ASC, h.id ASC;
      ''', [10, 475]);

      expect(hadithRows.length, equals(2));
      final items = hadithRows.map((r) => HadithItem.fromMap(r)).toList();
      expect(items.first.chapterId, isNull);
      expect(items.first.arabicText, contains('فرض الله الصلاة'));
      expect(items.last.arabicText, contains('بني الإسلام على خمس'));
    });

    test('Verification: no books have zero actual hadiths', () async {
      final zeroHadithBooks = await testDb.rawQuery('''
        SELECT b.id, b.name_ar, COUNT(h.id) as actual_count
        FROM books b
        LEFT JOIN hadiths h ON h.book_id = b.id
        GROUP BY b.id
        HAVING COUNT(h.id) = 0;
      ''');
      expect(zeroHadithBooks.isEmpty, isTrue);
    });

    test('Verification: displayed book count matches actual hadith row count', () async {
      final mismatches = await testDb.rawQuery('''
        SELECT b.id, b.name_ar, b.total_hadiths, COUNT(h.id) as actual_count
        FROM books b
        LEFT JOIN hadiths h ON h.book_id = b.id
        GROUP BY b.id
        HAVING b.total_hadiths != COUNT(h.id);
      ''');
      expect(mismatches.isEmpty, isTrue);
    });
  });
}

