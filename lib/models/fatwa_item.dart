class FatwaItem {
  final int id;
  final String moftyName;
  final String fatwyType;
  final String question;
  final String answer;

  FatwaItem({
    required this.id,
    required this.moftyName,
    required this.fatwyType,
    required this.question,
    required this.answer,
  });

  factory FatwaItem.fromMap(Map<String, dynamic> map) {
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return FatwaItem(
      id: parseInt(map['id']),
      moftyName: map['mofty_name']?.toString() ?? '',
      fatwyType: map['fatwy_type']?.toString() ?? '',
      question: map['question']?.toString() ?? '',
      answer: map['answer']?.toString() ?? '',
    );
  }
}
