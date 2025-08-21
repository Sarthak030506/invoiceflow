import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _user = _authService.currentUser;
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  Future<UserCredential?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      _setLoading(true);
      _error = null;
      print('Attempting to sign in with email: $email');
      
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _setLoading(false);
      
      if (userCredential == null) {
        print('Sign in failed - null user credential');
        _setError('Failed to sign in. Please try again.');
        return null;
      }
      
      final user = userCredential.user;
      if (user != null) {
        print('Successfully signed in user: ${user.uid}');
      } else {
        print('Sign in successful but user is null');
        _setError('Failed to retrieve user information. Please try again.');
        return null;
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error (${e.code}): ${e.message}');
      String errorMessage = _getUserFriendlyErrorMessage(e);
      _setError(errorMessage);
      return null;
    } catch (e, stackTrace) {
      print('Unexpected error during sign in: $e');
      print('Stack trace: $stackTrace');
      _setError('An unexpected error occurred. Please try again.');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<UserCredential?> signUpWithEmailAndPassword(
      String email, String password) async {
    try {
      _setLoading(true);
      _error = null;
      final userCredential = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );
      _setLoading(false);
      return userCredential;
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      _setLoading(true);
      _error = null;
      print('Starting Google Sign-In process');
      
      final userCredential = await _authService.signInWithGoogle();
      
      if (userCredential == null) {
        print('Google Sign-In failed - null user credential');
        _setError('Failed to sign in with Google. Please try again.');
        return null;
      }
      
      final user = userCredential.user;
      if (user != null) {
        print('Google Sign-In successful for user: ${user.uid}');
      } else {
        print('Google Sign-In successful but user is null');
        _setError('Failed to retrieve user information. Please try again.');
        return null;
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error during Google Sign-In (${e.code}): ${e.message}');
      String errorMessage = _getGoogleSignInErrorMessage(e);
      _setError(errorMessage);
      return null;
    } catch (e, stackTrace) {
      print('Unexpected error during Google Sign-In: $e');
      print('Stack trace: $stackTrace');
      _setError('An unexpected error occurred during Google Sign-In. Please try again.');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      _error = null;
      await _authService.signOut();
      _user = null;
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _error = null;
      await _authService.sendPasswordResetEmail(email);
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _getUserFriendlyErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email. Please check and try again.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please contact support.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'An error occurred: ${e.message ?? e.code}';
    }
  }

  String _getGoogleSignInErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email but different sign-in credentials.';
      case 'invalid-credential':
        return 'The authentication credential is malformed or has expired.';
      case 'operation-not-allowed':
        return 'Google Sign-In is not enabled. Please contact support.';
      case 'user-disabled':
        return 'This user account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No user found with this Google account.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-verification-code':
        return 'The verification code is invalid.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection and try again.';
      default:
        return 'Failed to sign in with Google: ${e.message ?? e.code}';
    }
  }

  void _setError(String? error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
