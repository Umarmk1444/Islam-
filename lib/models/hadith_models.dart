int _toInt(dynamic val, [int fallback = 0]) {
  if (val == null) return fallback;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? fallback;
  return fallback;
}

int? _toNullableInt(dynamic val) {
  if (val == null) return null;
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val);
  return null;
}

double _toDouble(dynamic val, [double fallback = 0.0]) {
  if (val == null) return fallback;
  if (val is double) return val;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? fallback;
  return fallback;
}

class HadithCollection {
  final int id;
  final int sourceCollectionId;
  final String slug;
  final String nameAr;
  final String authorAr;
  final String numberingSource;
  final int totalBooks;
  final int totalChapters;
  final int totalHadiths;
  final bool hasChapters;
  final int sortOrder;

  const HadithCollection({
    required this.id,
    required this.sourceCollectionId,
    required this.slug,
    required this.nameAr,
    required this.authorAr,
    required this.numberingSource,
    required this.totalBooks,
    required this.totalChapters,
    required this.totalHadiths,
    required this.hasChapters,
    required this.sortOrder,
  });

  factory HadithCollection.fromMap(Map<String, dynamic> map) {
    final id = _toInt(map['id']);
    return HadithCollection(
      id: id,
      sourceCollectionId: _toInt(map['source_collection_id'], id),
      slug: map['slug']?.toString() ?? '',
      nameAr: map['name_ar']?.toString() ?? '',
      authorAr: map['author_ar']?.toString() ?? '',
      numberingSource: map['numbering_source']?.toString() ?? '',
      totalBooks: _toInt(map['total_books']),
      totalChapters: _toInt(map['total_chapters']),
      totalHadiths: _toInt(map['total_hadiths']),
      hasChapters: _toInt(map['has_chapters'], 1) == 1,
      sortOrder: _toInt(map['sort_order']),
    );
  }
}

class HadithBook {
  final int id;
  final int collectionId;
  final int bookNumber;
  final String nameAr;
  final String? introAr;
  final int? firstHadithNum;
  final int? lastHadithNum;
  final int totalHadiths;
  final int totalChapters;

  const HadithBook({
    required this.id,
    required this.collectionId,
    required this.bookNumber,
    required this.nameAr,
    this.introAr,
    this.firstHadithNum,
    this.lastHadithNum,
    required this.totalHadiths,
    this.totalChapters = 0,
  });

  bool get hasChapters => totalChapters > 0;

  factory HadithBook.fromMap(Map<String, dynamic> map) {
    final rawFirst = _toNullableInt(map['computed_first_num'] ?? map['first_hadith_num']);
    final rawLast = _toNullableInt(map['computed_last_num'] ?? map['last_hadith_num']);

    return HadithBook(
      id: _toInt(map['id']),
      collectionId: _toInt(map['collection_id']),
      bookNumber: _toInt(map['book_number']),
      nameAr: map['name_ar']?.toString() ?? '',
      introAr: map['intro_ar']?.toString(),
      firstHadithNum: (rawFirst != null && rawFirst > 0) ? rawFirst : null,
      lastHadithNum: (rawLast != null && rawLast > 0) ? rawLast : null,
      totalHadiths: _toInt(map['total_hadiths']),
      totalChapters: _toInt(map['total_chapters']),
    );
  }
}

class HadithChapter {
  final int id;
  final int collectionId;
  final int bookId;
  final double chapterNumber;
  final String babAr;
  final String? introAr;

  const HadithChapter({
    required this.id,
    required this.collectionId,
    required this.bookId,
    required this.chapterNumber,
    required this.babAr,
    this.introAr,
  });

  factory HadithChapter.fromMap(Map<String, dynamic> map) {
    return HadithChapter(
      id: _toInt(map['id']),
      collectionId: _toInt(map['collection_id']),
      bookId: _toInt(map['book_id']),
      chapterNumber: _toDouble(map['chapter_number']),
      babAr: map['bab_ar']?.toString() ?? '',
      introAr: map['intro_ar']?.toString(),
    );
  }
}

class HadithItem {
  final int id;
  final int collectionId;
  final int bookId;
  final int? chapterId;
  final int sourceUrn;
  final String hadithNumber;
  final int inBookNumber;
  final String arabicText;
  final String arabicClean;
  final String? isnadAr;
  final String? matnAr;
  final String? grade;
  final String? gradeBy;
  final int? legacyBukhariId;
  final bool isFavorite;
  final int? lastReadTimestamp;
  final int readCount;
  final String? notes;

  const HadithItem({
    required this.id,
    required this.collectionId,
    required this.bookId,
    this.chapterId,
    required this.sourceUrn,
    required this.hadithNumber,
    required this.inBookNumber,
    required this.arabicText,
    required this.arabicClean,
    this.isnadAr,
    this.matnAr,
    this.grade,
    this.gradeBy,
    this.legacyBukhariId,
    this.isFavorite = false,
    this.lastReadTimestamp,
    this.readCount = 0,
    this.notes,
  });

  HadithItem copyWith({
    bool? isFavorite,
    int? lastReadTimestamp,
    int? readCount,
    String? notes,
  }) {
    return HadithItem(
      id: id,
      collectionId: collectionId,
      bookId: bookId,
      chapterId: chapterId,
      sourceUrn: sourceUrn,
      hadithNumber: hadithNumber,
      inBookNumber: inBookNumber,
      arabicText: arabicText,
      arabicClean: arabicClean,
      isnadAr: isnadAr,
      matnAr: matnAr,
      grade: grade,
      gradeBy: gradeBy,
      legacyBukhariId: legacyBukhariId,
      isFavorite: isFavorite ?? this.isFavorite,
      lastReadTimestamp: lastReadTimestamp ?? this.lastReadTimestamp,
      readCount: readCount ?? this.readCount,
      notes: notes ?? this.notes,
    );
  }

  factory HadithItem.fromMap(Map<String, dynamic> map) {
    final id = _toInt(map['id']);
    return HadithItem(
      id: id,
      collectionId: _toInt(map['collection_id']),
      bookId: _toInt(map['book_id']),
      chapterId: _toNullableInt(map['chapter_id']),
      sourceUrn: _toInt(map['source_urn'], id),
      hadithNumber: map['hadith_number']?.toString() ?? '',
      inBookNumber: _toInt(map['in_book_number'], 1),
      arabicText: map['arabic_text']?.toString() ?? '',
      arabicClean: map['arabic_clean']?.toString() ?? '',
      isnadAr: map['isnad_ar']?.toString(),
      matnAr: map['matn_ar']?.toString(),
      grade: map['grade']?.toString(),
      gradeBy: map['grade_by']?.toString(),
      legacyBukhariId: _toNullableInt(map['legacy_bukhari_id']),
      isFavorite: _toInt(map['is_favorite']) == 1,
      lastReadTimestamp: _toNullableInt(map['last_read_timestamp']),
      readCount: _toInt(map['read_count']),
      notes: map['notes']?.toString(),
    );
  }
}
