import 'package:firebase_core/firebase_core.dart';
import 'auth_service.dart';
import 'quiz_service.dart';
import 'notification_service.dart';
import '../utils/constants.dart';

class ServiceRegistry {
  static final ServiceRegistry _instance = ServiceRegistry._internal();
  factory ServiceRegistry() => _instance;
  ServiceRegistry._internal();

  late AuthService authService;
  late QuizService quizService;
  final NotificationService notificationService = NotificationService();
  bool isFirebaseMode = false;

  Future<void> initialize() async {
    if (AppConstants.attemptFirebase) {
      try {
        // Check if Firebase is already initialized or has config
        // In Flutter, initializing without parameters relies on google-services.json / GoogleService-Info.plist.
        // If they are missing, it will throw an exception.
        await Firebase.initializeApp();
        authService = FirebaseAuthService();
        quizService = FirebaseQuizService();
        isFirebaseMode = true;
        
        // Setup FCM
        await notificationService.initializeFCM();
        print("--- Services Initialized with FIREBASE ---");
        return;
      } catch (e) {
        print("Firebase initialization failed: $e. Falling back to DEMO Mode.");
      }
    }
    
    // Fallback to Mock Services
    authService = MockAuthService();
    quizService = MockQuizService();
    isFirebaseMode = false;
    print("--- Services Initialized with DEMO MODE (Mock) ---");
  }
}
