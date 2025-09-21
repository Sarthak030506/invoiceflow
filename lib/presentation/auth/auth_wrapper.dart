import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';

import '../../../services/invoice_service.dart';
import '../../../services/onboarding_service.dart';
import '../../utils/csv_path_utils.dart' show getCsvPath;
import 'login_screen.dart';
import '../home_dashboard/home_dashboard.dart';
import '../onboarding/items_setup_onboarding_screen.dart';

/// WHY THIS VERSION?
/// ------------------------------------------------------------
/// Your original `AuthWrapper` used a `FutureBuilder` whose `future`
/// was recreated implicitly and sometimes not re-run until an app restart.
/// That led to "Create Account" apparently doing nothing, even though
/// Firebase authenticated the user.
///
/// This rewrite makes `AuthWrapper` stateful, memoizes the init future
/// per user-id, and guarantees re-initialization runs immediately when
/// auth state flips to a non-null user.
/// ------------------------------------------------------------

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  String? _lastUserId;
  Future<_InitResult>? _initFuture;

  void _maybePrepareInit(AuthProvider auth) {
    debugPrint('AuthWrapper: _maybePrepareInit called - isAuthenticated: ${auth.isAuthenticated}, user: ${auth.user?.uid}, isLoading: ${auth.isLoading}');
    
    // If not authenticated, clear any previous future (avoid stale work)
    if (!auth.isAuthenticated || auth.user == null) {
      if (_initFuture != null || _lastUserId != null) {
        debugPrint('AuthWrapper: cleared init future (signed out)');
        setState(() {
          _initFuture = null;
          _lastUserId = null;
        });
      }
      return;
    }

    final uid = auth.user!.uid;
    debugPrint('AuthWrapper: checking if need to prepare init - lastUserId: $_lastUserId, currentUid: $uid, hasFuture: ${_initFuture != null}');

    if (_lastUserId == uid && _initFuture != null) {
      // Already prepared for this user.
      debugPrint('AuthWrapper: already prepared for this user');
      return;
    }

    debugPrint('AuthWrapper: preparing init future for uid=$uid');
    setState(() {
      _lastUserId = uid;
      _initFuture = _initializeAppAndCheckOnboarding(uid);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Always check if we need to prepare init when auth state changes
        _maybePrepareInit(authProvider);
        
        // 1) Loading while provider resolves initial auth state
        if (authProvider.isLoading) {
          return const _FullScreenLoader();
        }

        // 2) Not authenticated → show Login
        if (!authProvider.isAuthenticated || authProvider.user == null) {
          return const LoginScreen();
        }

        // 3) Safety net: still null? Show loader briefly and schedule prepare.
        if (_initFuture == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _maybePrepareInit(authProvider);
          });
          return const _FullScreenLoader();
        }

        // 4) Run init and branch to onboarding/home accordingly
        return FutureBuilder<_InitResult>(
          future: _initFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _FullScreenLoader();
            }

            if (snapshot.hasError) {
              debugPrint('AuthWrapper: init error → ${snapshot.error}');
              return _InitErrorView(
                error: snapshot.error,
                onRetry: () {
                  setState(() {
                    _initFuture = _initializeAppAndCheckOnboarding(_lastUserId!);
                  });
                },
              );
            }

            final data = snapshot.data!;
            debugPrint('AuthWrapper: init OK, shouldShowOnboarding=${data.shouldShowOnboarding}, csvPath=${data.csvPath}');

            if (data.shouldShowOnboarding) {
              return const ItemsSetupOnboardingScreen(
                isFirstTimeSetup: true,
              );
            }

            return HomeDashboard(csvPath: data.csvPath);
          },
        );
      },
    );
  }
}

/// Holds init results in a typed way
class _InitResult {
  final String csvPath;
  final bool shouldShowOnboarding;
  const _InitResult({required this.csvPath, required this.shouldShowOnboarding});
}

/// Helper that runs app initialization and checks onboarding status
Future<_InitResult> _initializeAppAndCheckOnboarding(String uid) async {
  debugPrint('AuthWrapper: init start for uid=$uid');

  // Add a small delay to ensure SharedPreferences are fully committed
  await Future.delayed(const Duration(milliseconds: 200));

  // 1) Resolve CSV path (used by InvoiceService)
  final csvPath = await getCsvPath();
  debugPrint('AuthWrapper: CSV path → $csvPath');

  // 2) Ensure InvoiceService is ready (idempotent)
  try {
    // Accessing instance to see if initialized
    // If your InvoiceService throws when uninitialized, catch and init
    // otherwise you can check an `isInitialized` flag if you have one.
    // This approach is defensive and idempotent.
    try {
      // Touch singleton; if it throws we will init below
      // ignore: unnecessary_statements
      InvoiceService.instance;
      debugPrint('AuthWrapper: InvoiceService already initialized');
    } catch (_) {
      debugPrint('AuthWrapper: initializing InvoiceService');
      await InvoiceService.initialize(csvPath: csvPath);
      debugPrint('AuthWrapper: InvoiceService initialized');
    }
  } catch (e) {
    debugPrint('AuthWrapper: InvoiceService init failed: $e');
    // We still proceed so the app can show an error screen with retry
    rethrow;
  }

  // 3) Check onboarding flag for this user
  debugPrint('AuthWrapper: About to check onboarding status...');
  final onboardingService = OnboardingService.instance;
  final shouldShowOnboarding = await onboardingService.shouldShowItemsOnboarding();
  debugPrint('AuthWrapper: shouldShowOnboarding=$shouldShowOnboarding for uid=$uid');

  return _InitResult(
    csvPath: csvPath,
    shouldShowOnboarding: shouldShowOnboarding,
  );
}

/// Simple full-screen loader used in multiple places
class _FullScreenLoader extends StatelessWidget {
  const _FullScreenLoader();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

/// Error UI with a retry button so users aren't stuck
class _InitErrorView extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;
  const _InitErrorView({super.key, this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Error initializing app'),
              const SizedBox(height: 8),
              Text(
                error?.toString() ?? 'Unknown error',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
