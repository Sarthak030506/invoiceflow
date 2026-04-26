import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/business_profile_service.dart';
import '../services/invoice_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = true;
  String? _error;

  StreamSubscription<User?>? _authSub;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    _authSub = _authService.authStateChanges.listen((User? u) async {
      debugPrint('[AuthProvider] authStateChanges: user=${u?.uid}');
      _user = u;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('[AuthProvider] authStateChanges error: $e');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    });

    final current = _authService.currentUser;
    if (current != null) {
      _user = current;
      _isLoading = false;
    }
  }

  /// Delegates to BusinessProfileService so legacy onboarding screens still work
  /// until they are removed in Step 6.
  Future<void> completeOnboarding() async {
    await BusinessProfileService.instance.markOnboardingComplete();
    notifyListeners();
    debugPrint('[AuthProvider] Onboarding completed');
  }

  Future<UserCredential?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userCredential = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential?.user;
      notifyListeners();

      return userCredential;
    } on FirebaseAuthException catch (e) {
      _setError(_getUserFriendlyErrorMessage(e));
      return null;
    } catch (e) {
      _setError('An unexpected error occurred during sign-up.');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    try {
      _setLoading(true);
      _error = null;
      final userCredential = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      _setError(_getUserFriendlyErrorMessage(e));
      return null;
    } catch (e) {
      _setError('An unexpected error occurred during sign-in.');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      _setLoading(true);
      _error = null;
      debugPrint('Starting Google Sign-In process');

      final userCredential = await _authService.signInWithGoogle();

      if (userCredential == null) {
        _setError('Failed to sign in with Google. Please try again.');
        return null;
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Error during Google Sign-In (${e.code}): ${e.message}');
      _setError(_getGoogleSignInErrorMessage(e));
      return null;
    } catch (e, st) {
      debugPrint('Unexpected error during Google Sign-In: $e\n$st');
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
      await AnalyticsService().invalidateCache();
      InvoiceService.reset();
      await _authService.signOut();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _error = null;
      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
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

  String _getUserFriendlyErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak. Please use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account with this email already exists. Please login instead.';
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

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
