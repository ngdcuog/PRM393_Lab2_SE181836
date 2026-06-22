import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';

/// ViewModel for Authentication state and logic.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required AuthService authService})
      : _authService = authService;

  final AuthService _authService;

  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  User? get currentUser => _authService.currentUser;
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  Future<User?> signIn() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = await _authService.signInWithGoogle();
      _isLoading = false;
      notifyListeners();
      return user;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst(RegExp(r'^.*Exception: '), '');
      notifyListeners();
      return null;
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();
    
    await _authService.signOut();
    
    _isLoading = false;
    notifyListeners();
  }
}
