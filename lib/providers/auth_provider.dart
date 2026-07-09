import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/service_registry.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;
  bool _isLoading = false;
  StreamSubscription<UserModel?>? _authSubscription;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;

  AuthProvider() {
    _init();
  }

  void _init() {
    _isLoading = true;
    notifyListeners();

    // Listen to authentication changes
    _authSubscription = ServiceRegistry().authService.onAuthStateChanged.listen(
      (user) {
        _currentUser = user;
        _isLoading = false;
        notifyListeners();
      },
      onError: (err) {
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  Future<void> checkCurrentUser() async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await ServiceRegistry().authService.getCurrentUser();
    } catch (e) {
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await ServiceRegistry().authService.signIn(
        email: email,
        password: password,
      );
    } catch (e) {
      _currentUser = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentUser = await ServiceRegistry().authService.signUp(
        name: name,
        email: email,
        password: password,
        role: role,
      );
    } catch (e) {
      _currentUser = null;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    try {
      await ServiceRegistry().authService.signOut();
      _currentUser = null;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
