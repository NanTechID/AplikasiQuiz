import 'dart:async';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class NotificationProvider extends ChangeNotifier {
  final List<NotificationEvent> _notifications = [];
  NotificationEvent? _currentNotification;
  StreamSubscription<NotificationEvent>? _subscription;

  List<NotificationEvent> get notifications => _notifications;
  NotificationEvent? get currentNotification => _currentNotification;

  NotificationProvider() {
    _initSubscription();
  }

  void _initSubscription() {
    _subscription = NotificationService().notificationStream.listen((event) {
      _notifications.insert(0, event); // Add to the top of the list
      _currentNotification = event;
      notifyListeners();

      // Automatically clear the top overlay notification after 4 seconds
      Future.delayed(const Duration(seconds: 4), () {
        if (_currentNotification == event) {
          _currentNotification = null;
          notifyListeners();
        }
      });
    });
  }

  void clearCurrentNotification() {
    _currentNotification = null;
    notifyListeners();
  }

  void clearAllNotifications() {
    _notifications.clear();
    _currentNotification = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
