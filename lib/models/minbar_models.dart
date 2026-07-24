class MinbarCategory {
  final String id;
  final String name;
  final String englishName;
  final String icon;

  const MinbarCategory({
    required this.id,
    required this.name,
    required this.englishName,
    required this.icon,
  });

  factory MinbarCategory.fromMap(Map<String, dynamic> map) {
    return MinbarCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      englishName: map['englishName'] as String,
      icon: map['icon'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'englishName': englishName,
      'icon': icon,
    };
  }
}

class MinbarAuthor {
  final String id;
  final String name;
  final String? englishName;
  final String? type;
  final String? serverNum;
  final String? engName;

  const MinbarAuthor({
    required this.id,
    required this.name,
    this.englishName,
    this.type,
    this.serverNum,
    this.engName,
  });

  factory MinbarAuthor.fromMap(Map<String, dynamic> map) {
    return MinbarAuthor(
      id: map['id'].toString(),
      name: map['name'] as String,
      englishName: map['englishName'] as String?,
      type: map['type'] as String?,
      serverNum: map['server_num'] as String?,
      engName: map['eng_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'englishName': englishName,
      'type': type,
      'server_num': serverNum,
      'eng_name': engName,
    };
  }
}

class MinbarAudioItem {
  final String id;
  final String title;
  final String url;
  final String? duration;
  final String authorId;

  const MinbarAudioItem({
    required this.id,
    required this.title,
    required this.url,
    this.duration,
    required this.authorId,
  });

  factory MinbarAudioItem.fromMap(Map<String, dynamic> map) {
    return MinbarAudioItem(
      id: map['id'].toString(),
      title: map['title'] as String,
      url: map['url'] as String,
      duration: map['duration'] as String?,
      authorId: map['authorId'].toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'duration': duration,
      'authorId': authorId,
    };
  }
}
