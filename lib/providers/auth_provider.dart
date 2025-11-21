import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';
import '../services/items_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final ItemsService _itemsService = ItemsService();

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
  bool _hasCatalogueItems = false;
  bool get hasCatalogueItems => _hasCatalogueItems;

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
  /// Checks if user has catalogue items to determine if they need onboarding.
  Future<void> _handleNewlySignedInUser() async {
    try {
      debugPrint('[AuthProvider] _handleNewlySignedInUser called for user: ${_user?.uid}');

      // Check if user has any catalogue items
      final hasCatalogueItems = await _checkUserHasCatalogueItems();
      _hasCatalogueItems = hasCatalogueItems;

      // User is first-time if they have NO catalogue items
      _isFirstTimeUser = !hasCatalogueItems;

      debugPrint('[AuthProvider] Has catalogue items: $hasCatalogueItems');
      debugPrint('[AuthProvider] Is first time user: $_isFirstTimeUser');

    } catch (e) {
      debugPrint('[AuthProvider] _handleNewlySignedInUser error: $e');
      // On error, assume not first time to avoid blocking user
      _isFirstTimeUser = false;
      _hasCatalogueItems = false;
    }
  }

  /// Check if the current user has any items in their catalogue
  Future<bool> _checkUserHasCatalogueItems() async {
    try {
      final itemsCount = await _itemsService.getItemsCount();
      return itemsCount > 0;
    } catch (e) {
      debugPrint('[AuthProvider] Error checking catalogue items: $e');
      return false; // Assume no items on error
    }
  }

  Future<void> completeOnboarding() async {
    _isFirstTimeUser = false;
    _hasCatalogueItems = true;
    notifyListeners();
    debugPrint('[AuthProvider] Onboarding completed');
  }

  /// Refresh the catalogue status (useful after adding/removing items)
  Future<void> refreshCatalogueStatus() async {
    final hasCatalogueItems = await _checkUserHasCatalogueItems();
    _hasCatalogueItems = hasCatalogueItems;
    _isFirstTimeUser = !hasCatalogueItems;
    notifyListeners();
    debugPrint('[AuthProvider] Catalogue status refreshed: has items = $hasCatalogueItems');
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
