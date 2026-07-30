class MuezzinModel {
  final String id;
  final String name;
  final String country;
  final String mosque;
  final String duration;
  final String type;
  final String url;

  MuezzinModel({
    required this.id,
    required this.name,
    required this.country,
    required this.mosque,
    required this.duration,
    required this.type,
    required this.url,
  });

  factory MuezzinModel.fromJson(Map<String, dynamic> json) {
    return MuezzinModel(
      id: json['id'],
      name: json['name'],
      country: json['country'],
      mosque: json['mosque'],
      duration: json['duration'],
      type: json['type'],
      url: json['url'],
    );
  }

  bool get isLocal => type == 'local';
}
