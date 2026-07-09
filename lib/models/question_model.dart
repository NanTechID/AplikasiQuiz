class QuestionModel {
  final String id;
  final String quizId;
  final String text;
  final List<String> options;
  final int correctOptionIndex;

  QuestionModel({
    required this.id,
    required this.quizId,
    required this.text,
    required this.options,
    required this.correctOptionIndex,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map, String id) {
    return QuestionModel(
      id: id,
      quizId: map['quizId'] ?? '',
      text: map['text'] ?? '',
      options: List<String>.from(map['options'] ?? []),
      correctOptionIndex: map['correctOptionIndex'] is int 
          ? map['correctOptionIndex'] 
          : (int.tryParse(map['correctOptionIndex']?.toString() ?? '') ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'text': text,
      'options': options,
      'correctOptionIndex': correctOptionIndex,
    };
  }

  QuestionModel copyWith({
    String? text,
    List<String>? options,
    int? correctOptionIndex,
  }) {
    return QuestionModel(
      id: id,
      quizId: quizId,
      text: text ?? this.text,
      options: options ?? this.options,
      correctOptionIndex: correctOptionIndex ?? this.correctOptionIndex,
    );
  }
}
