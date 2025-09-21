import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = true; // start loading while we detect auth state
  String? _error;

  StreamSubscription<User?>? _authSub;

  // getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isFirstTimeUser => _isFirstTimeUser;

  bool _isFirstTimeUser = false;
  bool _hasCompletedOnboarding = false;
  bool get hasCompletedOnboarding => _hasCompletedOnboarding;

  AuthProvider() {
    _init();
  }

  Future<void> _init() async {
    // Observe authStateChanges and make it the single source-of-truth.
    _authSub = _authService.authStateChanges.listen((User? u) async {
      debugPrint('[AuthProvider] authStateChanges: user=${u?.uid}');
      _user = u;

      // Mark loading complete first (we are now aware of current auth state)
      _isLoading = false;
      
      // Notify listeners immediately so UI can update
      notifyListeners();
      debugPrint('[AuthProvider] notifyListeners called after setting user');

      // If the user just signed in or signed up, ensure first-time prefs are set
      if (_user != null) {
        await _handleNewlySignedInUser();
        // Notify again after handling new user setup to trigger any UI updates
        notifyListeners();
        debugPrint('[AuthProvider] notifyListeners called after handling new user');
      }
    }, onError: (e) {
      debugPrint('[AuthProvider] authStateChanges error: $e');
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    });

    // If you want an immediate value from currentUser, set it synchronously:
    final current = _authService.currentUser;
    if (current != null) {
      // If currentUser exists immediately, let the stream listener still handle it,
      // but set fields to avoid a long loading state.
      _user = current;
      _isLoading = false;
    }
  }

  /// Called when the provider sees a non-null user from Firebase.
  /// Idempotent: it will only mark prefs if needed.
  Future<void> _handleNewlySignedInUser() async {
    try {
      debugPrint('[AuthProvider] _handleNewlySignedInUser called for user: ${_user?.uid}');
      final prefs = await SharedPreferences.getInstance();
      
      // Debug: Check current state of preferences
      final hasFirstTimeKey = prefs.containsKey('is_first_time_user');
      final firstTimeValue = prefs.getBool('is_first_time_user');
      final hasOnboardingKey = prefs.containsKey('has_completed_items_onboarding');
      final onboardingValue = prefs.getBool('has_completed_items_onboarding');
      
      debugPrint('[AuthProvider] Current prefs state:');
      debugPrint('  - has_first_time_key: $hasFirstTimeKey, value: $firstTimeValue');
      debugPrint('  - has_onboarding_key: $hasOnboardingKey, value: $onboardingValue');

      // Default to not being a first-time user
      _isFirstTimeUser = false;

      // If there is no explicit flag set, treat it as first sign-in and mark it
      if (!prefs.containsKey('is_first_time_user')) {
        debugPrint('[AuthProvider] Setting first-time user flags...');
        await prefs.setBool('is_first_time_user', true);
        _isFirstTimeUser = true; // Update the state

        // ensure we don't mark onboarding completed accidentally
        await prefs.remove('has_completed_items_onboarding');
        debugPrint('[AuthProvider] Marked user as first-time for onboarding (prefs updated).');
        
        // Force a small delay to ensure SharedPreferences are fully committed
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Verify the changes were saved
        final verifyFirstTime = prefs.getBool('is_first_time_user');
        final verifyOnboarding = prefs.containsKey('has_completed_items_onboarding');
        debugPrint('[AuthProvider] Verification - is_first_time_user: $verifyFirstTime, has_onboarding_key: $verifyOnboarding');
      } else {
        // If the flag exists, respect its value
        _isFirstTimeUser = prefs.getBool('is_first_time_user') ?? false;
        debugPrint('[AuthProvider] is_first_time_user already present: $_isFirstTimeUser');
      }
    } catch (e) {
      debugPrint('[AuthProvider] _handleNewlySignedInUser error: $e');
    }
  }

  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time_user', false);
    _isFirstTimeUser = false;
    notifyListeners();
    debugPrint('[AuthProvider] Onboarding completed, is_first_time_user set to false.');
  }

  
  Future<UserCredential?> signUpWithEmailAndPassword(String email, String password) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final userCredential = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
      );

      _user = userCredential?.user;
      await _handleNewlySignedInUser();
      notifyListeners();
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

  /// Google sign-in
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

      // Let authStateChanges handle setting _user
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
      await _authService.signOut();
      // authStateChanges listener will update _user -> null and notify
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
