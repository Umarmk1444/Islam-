class RoquaItem {
  final int id;
  final String level;
  final String title;
  final String story;
  final String info;

  RoquaItem({
    required this.id,
    required this.level,
    required this.title,
    required this.story,
    required this.info,
  });

  factory RoquaItem.fromMap(Map<String, dynamic> map) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return RoquaItem(
      id: parseInt(map['id']),
      level: map['level']?.toString() ?? '',
      title: map['roqua']?.toString() ?? '',
      story: map['story']?.toString() ?? '',
      info: map['info']?.toString() ?? '',
    );
  }
}
