import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationEvent {
  final String title;
  final String body;
  final String type; // 'quiz_opened' | 'quiz_submitted'
  final Map<String, dynamic>? payload;

  NotificationEvent({
    required this.title,
    required this.body,
    required this.type,
    this.payload,
  });
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _eventController = StreamController<NotificationEvent>.broadcast();

  // Expose stream of notifications for the UI overlay to listen to
  Stream<NotificationEvent> get notificationStream => _eventController.stream;

  // Initialize FCM for real Firebase mode
  Future<void> initializeFCM() async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request permission
      await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      // Get FCM token
      String? token = await messaging.getToken();
      print("FCM Token: $token");

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        if (message.notification != null) {
          triggerNotification(
            title: message.notification!.title ?? 'New Notification',
            body: message.notification!.body ?? '',
            type: message.data['type'] ?? 'fcm',
            payload: message.data,
          );
        }
      });
    } catch (e) {
      print("FCM initialization failed (normal if not configured): $e");
    }
  }

  // Trigger a notification (both local simulation and Firebase Messaging updates)
  void triggerNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? payload,
  }) {
    final event = NotificationEvent(
      title: title,
      body: body,
      type: type,
      payload: payload,
    );
    _eventController.add(event);
  }

  void dispose() {
    _eventController.close();
  }
}
