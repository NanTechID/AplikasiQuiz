import 'package:cloud_firestore/cloud_firestore.dart';

class AnswerModel {
  final String id;
  final String quizId;
  final String studentId;
  final String studentName;
  final Map<String, int> selectedAnswers; // questionId -> optionIndex
  final double score;
  final int correctCount;
  final int incorrectCount;
  final DateTime submittedAt;

  AnswerModel({
    required this.id,
    required this.quizId,
    required this.studentId,
    required this.studentName,
    required this.selectedAnswers,
    required this.score,
    required this.correctCount,
    required this.incorrectCount,
    required this.submittedAt,
  });

  factory AnswerModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.parse(value);
      return DateTime.now();
    }

    // Safely parse selectedAnswers map
    final Map<String, int> answersMap = {};
    if (map['selectedAnswers'] is Map) {
      (map['selectedAnswers'] as Map).forEach((key, value) {
        answersMap[key.toString()] = value is int ? value : (int.tryParse(value?.toString() ?? '') ?? 0);
      });
    }

    return AnswerModel(
      id: id,
      quizId: map['quizId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      selectedAnswers: answersMap,
      score: map['score'] is num ? (map['score'] as num).toDouble() : (double.tryParse(map['score']?.toString() ?? '') ?? 0.0),
      correctCount: map['correctCount'] is int ? map['correctCount'] : (int.tryParse(map['correctCount']?.toString() ?? '') ?? 0),
      incorrectCount: map['incorrectCount'] is int ? map['incorrectCount'] : (int.tryParse(map['incorrectCount']?.toString() ?? '') ?? 0),
      submittedAt: parseDateTime(map['submittedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'quizId': quizId,
      'studentId': studentId,
      'studentName': studentName,
      'selectedAnswers': selectedAnswers,
      'score': score,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'submittedAt': Timestamp.fromDate(submittedAt),
    };
  }

  Map<String, dynamic> toMockMap() {
    return {
      'quizId': quizId,
      'studentId': studentId,
      'studentName': studentName,
      'selectedAnswers': selectedAnswers,
      'score': score,
      'correctCount': correctCount,
      'incorrectCount': incorrectCount,
      'submittedAt': submittedAt.toIso8601String(),
    };
  }
}
