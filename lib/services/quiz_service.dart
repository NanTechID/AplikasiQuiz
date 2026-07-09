import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';
import '../models/answer_model.dart';
import '../utils/constants.dart';

abstract class QuizService {
  // Quiz CRUD
  Future<void> createQuiz(QuizModel quiz);
  Future<void> updateQuiz(QuizModel quiz);
  Future<void> deleteQuiz(String quizId);
  Stream<List<QuizModel>> getQuizzes();

  // Question CRUD
  Future<void> createQuestion(QuestionModel question);
  Future<void> updateQuestion(QuestionModel question);
  Future<void> deleteQuestion(String quizId, String questionId);
  Future<List<QuestionModel>> getQuestions(String quizId);

  // Submissions (Answers)
  Future<void> submitAnswer(AnswerModel answer);
  Future<List<AnswerModel>> getQuizSubmissions(String quizId);
  Future<List<AnswerModel>> getStudentSubmissions(String studentId);
  Future<AnswerModel?> getStudentSubmissionForQuiz(String studentId, String quizId);
}

// ==========================================
// Firebase Implementation
// ==========================================
class FirebaseQuizService implements QuizService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<void> createQuiz(QuizModel quiz) async {
    await _db.collection('quiz').doc(quiz.id).set(quiz.toMap());
  }

  @override
  Future<void> updateQuiz(QuizModel quiz) async {
    await _db.collection('quiz').doc(quiz.id).update(quiz.toMap());
  }

  @override
  Future<void> deleteQuiz(String quizId) async {
    // Delete all questions first
    final questionsSnap = await _db.collection('quiz').doc(quizId).collection('questions').get();
    for (var doc in questionsSnap.docs) {
      await doc.reference.delete();
    }
    // Delete the quiz itself
    await _db.collection('quiz').doc(quizId).delete();
  }

  @override
  Stream<List<QuizModel>> getQuizzes() {
    return _db.collection('quiz').orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => QuizModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  @override
  Future<void> createQuestion(QuestionModel question) async {
    await _db
        .collection('quiz')
        .doc(question.quizId)
        .collection('questions')
        .doc(question.id)
        .set(question.toMap());
  }

  @override
  Future<void> updateQuestion(QuestionModel question) async {
    await _db
        .collection('quiz')
        .doc(question.quizId)
        .collection('questions')
        .doc(question.id)
        .update(question.toMap());
  }

  @override
  Future<void> deleteQuestion(String quizId, String questionId) async {
    await _db
        .collection('quiz')
        .doc(quizId)
        .collection('questions')
        .doc(questionId)
        .delete();
  }

  @override
  Future<List<QuestionModel>> getQuestions(String quizId) async {
    final snapshot = await _db
        .collection('quiz')
        .doc(quizId)
        .collection('questions')
        .get();
    return snapshot.docs.map((doc) => QuestionModel.fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<void> submitAnswer(AnswerModel answer) async {
    await _db.collection('answers').doc(answer.id).set(answer.toMap());
  }

  @override
  Future<List<AnswerModel>> getQuizSubmissions(String quizId) async {
    final snapshot = await _db
        .collection('answers')
        .where('quizId', isEqualTo: quizId)
        .get();
    return snapshot.docs.map((doc) => AnswerModel.fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<List<AnswerModel>> getStudentSubmissions(String studentId) async {
    final snapshot = await _db
        .collection('answers')
        .where('studentId', isEqualTo: studentId)
        .get();
    return snapshot.docs.map((doc) => AnswerModel.fromMap(doc.data(), doc.id)).toList();
  }

  @override
  Future<AnswerModel?> getStudentSubmissionForQuiz(String studentId, String quizId) async {
    final docId = '${quizId}_$studentId';
    final doc = await _db.collection('answers').doc(docId).get();
    if (doc.exists && doc.data() != null) {
      return AnswerModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}

// ==========================================
// Mock Implementation (using SharedPreferences)
// ==========================================
class MockQuizService implements QuizService {
  
  Future<void> _saveList(String key, List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, json.encode(list));
  }

  Future<List<Map<String, dynamic>>> _getList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(key);
    if (str == null) return [];
    return List<Map<String, dynamic>>.from(json.decode(str));
  }

  @override
  Future<void> createQuiz(QuizModel quiz) async {
    final list = await _getList(AppConstants.keyQuizzesData);
    list.add({
      'id': quiz.id,
      ...quiz.toMockMap(),
    });
    await _saveList(AppConstants.keyQuizzesData, list);
  }

  @override
  Future<void> updateQuiz(QuizModel quiz) async {
    final list = await _getList(AppConstants.keyQuizzesData);
    final idx = list.indexWhere((q) => q['id'] == quiz.id);
    if (idx != -1) {
      list[idx] = {
        'id': quiz.id,
        ...quiz.toMockMap(),
      };
      await _saveList(AppConstants.keyQuizzesData, list);
    }
  }

  @override
  Future<void> deleteQuiz(String quizId) async {
    // Delete Quiz
    final quizzes = await _getList(AppConstants.keyQuizzesData);
    quizzes.removeWhere((q) => q['id'] == quizId);
    await _saveList(AppConstants.keyQuizzesData, quizzes);

    // Delete Questions
    final questions = await _getList(AppConstants.keyQuestionsData);
    questions.removeWhere((q) => q['quizId'] == quizId);
    await _saveList(AppConstants.keyQuestionsData, questions);

    // Delete Submissions
    final submissions = await _getList(AppConstants.keyAnswersData);
    submissions.removeWhere((s) => s['quizId'] == quizId);
    await _saveList(AppConstants.keyAnswersData, submissions);
  }

  @override
  Stream<List<QuizModel>> getQuizzes() {
    // Periodically fetch from SharedPreferences to simulate dynamic updates
    return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
      final list = await _getList(AppConstants.keyQuizzesData);
      final quizzes = list.map((q) => QuizModel.fromMap(q, q['id'])).toList();
      quizzes.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return quizzes;
    }).distinct();
  }

  @override
  Future<void> createQuestion(QuestionModel question) async {
    final list = await _getList(AppConstants.keyQuestionsData);
    list.add({
      'id': question.id,
      ...question.toMap(),
    });
    await _saveList(AppConstants.keyQuestionsData, list);
  }

  @override
  Future<void> updateQuestion(QuestionModel question) async {
    final list = await _getList(AppConstants.keyQuestionsData);
    final idx = list.indexWhere((q) => q['id'] == question.id);
    if (idx != -1) {
      list[idx] = {
        'id': question.id,
        ...question.toMap(),
      };
      await _saveList(AppConstants.keyQuestionsData, list);
    }
  }

  @override
  Future<void> deleteQuestion(String quizId, String questionId) async {
    final list = await _getList(AppConstants.keyQuestionsData);
    list.removeWhere((q) => q['id'] == questionId);
    await _saveList(AppConstants.keyQuestionsData, list);
  }

  @override
  Future<List<QuestionModel>> getQuestions(String quizId) async {
    final list = await _getList(AppConstants.keyQuestionsData);
    return list
        .where((q) => q['quizId'] == quizId)
        .map((q) => QuestionModel.fromMap(q, q['id']))
        .toList();
  }

  @override
  Future<void> submitAnswer(AnswerModel answer) async {
    final list = await _getList(AppConstants.keyAnswersData);
    final idx = list.indexWhere((a) => a['id'] == answer.id);
    final answerMap = {
      'id': answer.id,
      ...answer.toMockMap(),
    };
    if (idx != -1) {
      list[idx] = answerMap;
    } else {
      list.add(answerMap);
    }
    await _saveList(AppConstants.keyAnswersData, list);
  }

  @override
  Future<List<AnswerModel>> getQuizSubmissions(String quizId) async {
    final list = await _getList(AppConstants.keyAnswersData);
    return list
        .where((a) => a['quizId'] == quizId)
        .map((a) => AnswerModel.fromMap(a, a['id']))
        .toList();
  }

  @override
  Future<List<AnswerModel>> getStudentSubmissions(String studentId) async {
    final list = await _getList(AppConstants.keyAnswersData);
    return list
        .where((a) => a['studentId'] == studentId)
        .map((a) => AnswerModel.fromMap(a, a['id']))
        .toList();
  }

  @override
  Future<AnswerModel?> getStudentSubmissionForQuiz(String studentId, String quizId) async {
    final list = await _getList(AppConstants.keyAnswersData);
    final matches = list.where((a) => a['studentId'] == studentId && a['quizId'] == quizId);
    if (matches.isNotEmpty) {
      final submission = matches.first;
      return AnswerModel.fromMap(submission, submission['id']);
    }
    return null;
  }
}
