class TafsirResource {
  final int id;
  final String name;
  final String authorName;
  final String languageName;

  TafsirResource({
    required this.id,
    required this.name,
    required this.authorName,
    required this.languageName,
  });

  factory TafsirResource.fromJson(Map<String, dynamic> json) {
    return TafsirResource(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      authorName: json['author_name'] as String? ?? '',
      languageName: json['language_name'] as String? ?? '',
    );
  }
}

class TranslationResource {
  final int id;
  final String name;
  final String authorName;
  final String languageName;

  TranslationResource({
    required this.id,
    required this.name,
    required this.authorName,
    required this.languageName,
  });

  factory TranslationResource.fromJson(Map<String, dynamic> json) {
    return TranslationResource(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      authorName: json['author_name'] as String? ?? '',
      languageName: json['language_name'] as String? ?? '',
    );
  }
}

class LanguageOption {
  final String code;
  final String displayName;
  final String nativeName;

  const LanguageOption({
    required this.code,
    required this.displayName,
    required this.nativeName,
  });
}
