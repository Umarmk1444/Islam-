class LibraryItem {
  final int id;
  final String part;
  final String type;
  final String title;
  final String story;
  final bool isFav;
  final int lastRead;
  final int numReadings;

  const LibraryItem({
    required this.id,
    required this.part,
    required this.type,
    required this.title,
    required this.story,
    required this.isFav,
    required this.lastRead,
    required this.numReadings,
  });

  factory LibraryItem.fromMap(Map<String, dynamic> map) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return LibraryItem(
      id: parseInt(map['id']),
      part: map['part']?.toString() ?? '',
      type: map['type']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      story: map['story']?.toString() ?? '',
      isFav: parseInt(map['fav']) == 1,
      lastRead: parseInt(map['last_read']),
      numReadings: parseInt(map['num_readings']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'part': part,
      'type': type,
      'title': title,
      'story': story,
      'fav': isFav ? 1 : 0,
      'last_read': lastRead,
      'num_readings': numReadings,
    };
  }

  LibraryItem copyWith({
    int? id,
    String? part,
    String? type,
    String? title,
    String? story,
    bool? isFav,
    int? lastRead,
    int? numReadings,
  }) {
    return LibraryItem(
      id: id ?? this.id,
      part: part ?? this.part,
      type: type ?? this.type,
      title: title ?? this.title,
      story: story ?? this.story,
      isFav: isFav ?? this.isFav,
      lastRead: lastRead ?? this.lastRead,
      numReadings: numReadings ?? this.numReadings,
    );
  }
}
