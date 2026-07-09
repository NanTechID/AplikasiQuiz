import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

abstract class AuthService {
  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  });
  
  Future<UserModel?> signIn({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();

  Stream<UserModel?> get onAuthStateChanged;
}

// ==========================================
// Firebase Implementation
// ==========================================
class FirebaseAuthService implements AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user != null) {
      final userModel = UserModel(
        uid: credential.user!.uid,
        name: name,
        email: email,
        role: role,
      );
      await _db.collection('users').doc(userModel.uid).set(userModel.toMap());
      return userModel;
    }
    return null;
  }

  @override
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    if (credential.user != null) {
      final doc = await _db.collection('users').doc(credential.user!.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, credential.user!.uid);
      }
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      final doc = await _db.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, firebaseUser.uid);
      }
    }
    return null;
  }

  @override
  Stream<UserModel?> get onAuthStateChanged {
    return _auth.authStateChanges().asyncMap((firebaseUser) async {
      if (firebaseUser == null) return null;
      final doc = await _db.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, firebaseUser.uid);
      }
      return null;
    });
  }
}

// ==========================================
// Mock Implementation
// ==========================================
class MockAuthService implements AuthService {
  UserModel? _currentUser;
  
  MockAuthService();

  @override
  Future<UserModel?> signUp({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    // Check if user already exists
    final prefs = await SharedPreferences.getInstance();
    final usersStr = prefs.getString('mock_users_list') ?? '[]';
    final List<dynamic> list = json.decode(usersStr);
    
    if (list.any((u) => u['email'] == email)) {
      throw FirebaseAuthException(
        code: 'email-already-in-use',
        message: 'The email address is already in use by another account.',
      );
    }

    final newUid = 'mock_uid_${DateTime.now().millisecondsSinceEpoch}';
    final userMap = {
      'uid': newUid,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    };

    list.add(userMap);
    await prefs.setString('mock_users_list', json.encode(list));

    final user = UserModel(
      uid: newUid,
      name: name,
      email: email,
      role: role,
    );

    // Save active session
    _currentUser = user;
    await prefs.setString(AppConstants.keyUserData, json.encode(user.toMap()));
    await prefs.setString(AppConstants.keyUserToken, newUid);

    return user;
  }

  @override
  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final usersStr = prefs.getString('mock_users_list') ?? '[]';
    final List<dynamic> list = json.decode(usersStr);

    final matchingUser = list.firstWhere(
      (u) => u['email'] == email && u['password'] == password,
      orElse: () => null,
    );

    if (matchingUser == null) {
      throw FirebaseAuthException(
        code: 'wrong-password',
        message: 'Incorrect email or password.',
      );
    }

    final user = UserModel.fromMap(matchingUser, matchingUser['uid']);
    _currentUser = user;

    await prefs.setString(AppConstants.keyUserData, json.encode(user.toMap()));
    await prefs.setString(AppConstants.keyUserToken, user.uid);

    return user;
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.keyUserData);
    await prefs.remove(AppConstants.keyUserToken);
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.keyUserToken);
    final dataStr = prefs.getString(AppConstants.keyUserData);

    if (token != null && dataStr != null) {
      final map = json.decode(dataStr);
      _currentUser = UserModel.fromMap(map, token);
      return _currentUser;
    }
    return null;
  }

  @override
  Stream<UserModel?> get onAuthStateChanged {
    // Generate a simple periodic stream check for mock auto-login
    return Stream.periodic(const Duration(seconds: 1)).asyncMap((_) async {
      return await getCurrentUser();
    }).distinct();
  }
}
