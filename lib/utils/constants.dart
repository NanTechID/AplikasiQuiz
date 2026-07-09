class AppConstants {
  // Shared Preferences keys
  static const String keyUserToken = 'user_token';
  static const String keyUserData = 'user_data';
  static const String keyQuizzesData = 'quizzes_data';
  static const String keyQuestionsData = 'questions_data';
  static const String keyAnswersData = 'answers_data';
  static const String keyThemeMode = 'theme_mode';

  // Toggle for Firebase vs Mock Mode
  // If set to true, it will attempt to use Firebase. If Firebase initialization fails,
  // it will automatically fall back to Mock Mode.
  static const bool attemptFirebase = true;
}
