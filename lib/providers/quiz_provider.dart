import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/quiz_model.dart';
import '../models/question_model.dart';
import '../models/answer_model.dart';
import '../services/service_registry.dart';

class QuizProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  List<QuizModel> _quizzes = [];
  bool _isLoading = false;
  StreamSubscription<List<QuizModel>>? _quizzesSubscription;

  // Question Management
  List<QuestionModel> _questions = [];

  // Active Quiz taking state (for students)
  QuizModel? _activeQuiz;
  List<QuestionModel> _activeQuestions = [];
  final Map<String, int> _selectedAnswers = {};
  int _remainingTimeSeconds = 0;
  Timer? _quizTimer;
  bool _isQuizSubmitted = false;

  // Submissions state
  List<AnswerModel> _quizSubmissions = [];
  List<AnswerModel> _studentSubmissions = [];
  final Map<String, AnswerModel?> _studentQuizSubmissions = {}; // quizId -> submission

  // Getters
  List<QuizModel> get quizzes => _quizzes;
  List<QuizModel> get openQuizzes => _quizzes.where((q) => q.isOpen).toList();
  List<QuizModel> get draftQuizzes => _quizzes.where((q) => q.isDraft).toList();
  List<QuizModel> get closedQuizzes => _quizzes.where((q) => q.isClosed).toList();
  bool get isLoading => _isLoading;

  List<QuestionModel> get questions => _questions;
  
  QuizModel? get activeQuiz => _activeQuiz;
  List<QuestionModel> get activeQuestions => _activeQuestions;
  Map<String, int> get selectedAnswers => _selectedAnswers;
  int get remainingTimeSeconds => _remainingTimeSeconds;
  bool get isQuizSubmitted => _isQuizSubmitted;
  
  List<AnswerModel> get quizSubmissions => _quizSubmissions;
  List<AnswerModel> get studentSubmissions => _studentSubmissions;

  QuizProvider() {
    _initQuizzesSubscription();
  }

  void _initQuizzesSubscription() {
    _isLoading = true;
    notifyListeners();
    
    _quizzesSubscription = ServiceRegistry().quizService.getQuizzes().listen(
      (quizList) {
        _quizzes = quizList;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  // ==========================================
  // Quiz CRUD
  // ==========================================
  Future<void> createQuiz({
    required String title,
    required String description,
    required String creatorId,
    required int duration,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final quiz = QuizModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      creatorId: creatorId,
      startTime: startTime,
      endTime: endTime,
      duration: duration,
      status: 'draft',
      createdAt: DateTime.now(),
    );
    await ServiceRegistry().quizService.createQuiz(quiz);
  }

  Future<void> updateQuiz(QuizModel quiz) async {
    await ServiceRegistry().quizService.updateQuiz(quiz);
  }

  Future<void> deleteQuiz(String quizId) async {
    await ServiceRegistry().quizService.deleteQuiz(quizId);
  }

  Future<void> changeQuizStatus(QuizModel quiz, String newStatus) async {
    final updatedQuiz = quiz.copyWith(status: newStatus);
    await ServiceRegistry().quizService.updateQuiz(updatedQuiz);

    // Trigger Notification for Students when Quiz is Opened
    if (newStatus == 'open') {
      ServiceRegistry().notificationService.triggerNotification(
        title: 'Quiz Opened! 📝',
        body: 'Quiz "${quiz.title}" is now open. Don\'t forget to complete it before the deadline!',
        type: 'quiz_opened',
        payload: {'quizId': quiz.id},
      );
    }
  }

  // ==========================================
  // Question CRUD
  // ==========================================
  Future<void> loadQuestions(String quizId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _questions = await ServiceRegistry().quizService.getQuestions(quizId);
    } catch (e) {
      _questions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addQuestion({
    required String quizId,
    required String text,
    required List<String> options,
    required int correctOptionIndex,
  }) async {
    final question = QuestionModel(
      id: _uuid.v4(),
      quizId: quizId,
      text: text,
      options: options,
      correctOptionIndex: correctOptionIndex,
    );
    await ServiceRegistry().quizService.createQuestion(question);
    await loadQuestions(quizId);
  }

  Future<void> updateQuestion(QuestionModel question) async {
    await ServiceRegistry().quizService.updateQuestion(question);
    await loadQuestions(question.quizId);
  }

  Future<void> deleteQuestion(String quizId, String questionId) async {
    await ServiceRegistry().quizService.deleteQuestion(quizId, questionId);
    await loadQuestions(quizId);
  }

  // ==========================================
  // Active Quiz Taking & Timer
  // ==========================================
  Future<void> startQuiz(QuizModel quiz, String studentId) async {
    _activeQuiz = quiz;
    _isQuizSubmitted = false;
    _selectedAnswers.clear();
    _isLoading = true;
    notifyListeners();

    try {
      _activeQuestions = await ServiceRegistry().quizService.getQuestions(quiz.id);
      _remainingTimeSeconds = quiz.duration * 60;
      
      _quizTimer?.cancel();
      _quizTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_remainingTimeSeconds > 0) {
          _remainingTimeSeconds--;
          notifyListeners();
        } else {
          timer.cancel();
          // Auto submit when time runs out!
          submitQuiz(studentId, 'Mahasiswa', autoSubmit: true);
        }
      });
    } catch (e) {
      _activeQuestions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectAnswer(String questionId, int optionIndex) {
    _selectedAnswers[questionId] = optionIndex;
    notifyListeners();
  }

  Future<AnswerModel?> submitQuiz(String studentId, String studentName, {bool autoSubmit = false}) async {
    if (_activeQuiz == null || _isQuizSubmitted) return null;

    _quizTimer?.cancel();
    _isQuizSubmitted = true;
    notifyListeners();

    // Grade Quiz
    int correctCount = 0;
    for (var question in _activeQuestions) {
      final selected = _selectedAnswers[question.id];
      if (selected != null && selected == question.correctOptionIndex) {
        correctCount++;
      }
    }
    
    final int totalQuestions = _activeQuestions.isEmpty ? 1 : _activeQuestions.length;
    final double score = (correctCount / totalQuestions) * 100.0;
    final int incorrectCount = _activeQuestions.length - correctCount;

    final submission = AnswerModel(
      id: '${_activeQuiz!.id}_$studentId',
      quizId: _activeQuiz!.id,
      studentId: studentId,
      studentName: studentName,
      selectedAnswers: Map<String, int>.from(_selectedAnswers),
      score: double.parse(score.toStringAsFixed(1)),
      correctCount: correctCount,
      incorrectCount: incorrectCount,
      submittedAt: DateTime.now(),
    );

    await ServiceRegistry().quizService.submitAnswer(submission);
    _studentQuizSubmissions[_activeQuiz!.id] = submission;

    // Trigger Notification for Lecturer when Student completes Quiz
    ServiceRegistry().notificationService.triggerNotification(
      title: 'Quiz Completed! 🎓',
      body: 'Student $studentName has finished the quiz "${_activeQuiz!.title}" with score ${submission.score}.',
      type: 'quiz_submitted',
      payload: {'quizId': _activeQuiz!.id, 'studentId': studentId},
    );

    notifyListeners();
    return submission;
  }

  void exitQuiz() {
    _quizTimer?.cancel();
    _activeQuiz = null;
    _activeQuestions = [];
    _selectedAnswers.clear();
    _isQuizSubmitted = false;
    notifyListeners();
  }

  // ==========================================
  // Results and Submissions Loader
  // ==========================================
  Future<void> loadQuizSubmissions(String quizId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _quizSubmissions = await ServiceRegistry().quizService.getQuizSubmissions(quizId);
      _quizSubmissions.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    } catch (e) {
      _quizSubmissions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStudentSubmissions(String studentId) async {
    _isLoading = true;
    notifyListeners();
    try {
      _studentSubmissions = await ServiceRegistry().quizService.getStudentSubmissions(studentId);
      _studentSubmissions.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    } catch (e) {
      _studentSubmissions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AnswerModel?> getCachedOrFetchSubmission(String studentId, String quizId) async {
    final cached = _studentQuizSubmissions[quizId];
    if (cached != null) return cached;

    try {
      final fetched = await ServiceRegistry().quizService.getStudentSubmissionForQuiz(studentId, quizId);
      if (fetched != null) {
        _studentQuizSubmissions[quizId] = fetched;
        notifyListeners();
      }
      return fetched;
    } catch (e) {
      return null;
    }
  }

  @override
  void dispose() {
    _quizzesSubscription?.cancel();
    _quizTimer?.cancel();
    super.dispose();
  }
}
