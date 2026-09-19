class UserPdfBook {
  final int? id;
  final String title;
  final String fileName;
  final String filePath;
  final int fileSize;
  final int totalPages;
  final int lastPageRead;
  final int addedTimestamp;
  final int lastReadTimestamp;

  const UserPdfBook({
    this.id,
    required this.title,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    required this.totalPages,
    required this.lastPageRead,
    required this.addedTimestamp,
    required this.lastReadTimestamp,
  });

  factory UserPdfBook.fromMap(Map<String, dynamic> map) {
    return UserPdfBook(
      id: map['id'] as int?,
      title: map['title'] as String? ?? 'Untitled Book',
      fileName: map['file_name'] as String? ?? '',
      filePath: map['file_path'] as String? ?? '',
      fileSize: (map['file_size'] as num?)?.toInt() ?? 0,
      totalPages: (map['total_pages'] as num?)?.toInt() ?? 0,
      lastPageRead: (map['last_page_read'] as num?)?.toInt() ?? 1,
      addedTimestamp: (map['added_timestamp'] as num?)?.toInt() ?? 0,
      lastReadTimestamp: (map['last_read_timestamp'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'file_name': fileName,
      'file_path': filePath,
      'file_size': fileSize,
      'total_pages': totalPages,
      'last_page_read': lastPageRead,
      'added_timestamp': addedTimestamp,
      'last_read_timestamp': lastReadTimestamp,
    };
  }

  UserPdfBook copyWith({
    int? id,
    String? title,
    String? fileName,
    String? filePath,
    int? fileSize,
    int? totalPages,
    int? lastPageRead,
    int? addedTimestamp,
    int? lastReadTimestamp,
  }) {
    return UserPdfBook(
      id: id ?? this.id,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      fileSize: fileSize ?? this.fileSize,
      totalPages: totalPages ?? this.totalPages,
      lastPageRead: lastPageRead ?? this.lastPageRead,
      addedTimestamp: addedTimestamp ?? this.addedTimestamp,
      lastReadTimestamp: lastReadTimestamp ?? this.lastReadTimestamp,
    );
  }

  double get progressPercent {
    if (totalPages <= 0) return 0.0;
    return (lastPageRead / totalPages).clamp(0.0, 1.0);
  }

  String get formattedSize {
    if (fileSize <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    var i = 0;
    double bytes = fileSize.toDouble();
    while (bytes >= 1024 && i < suffixes.length - 1) {
      bytes /= 1024;
      i++;
    }
    return '${bytes.toStringAsFixed(1)} ${suffixes[i]}';
  }

  String get formattedProgress {
    if (totalPages <= 0) {
      return 'Page $lastPageRead';
    }
    return 'Page $lastPageRead of $totalPages';
  }
}
