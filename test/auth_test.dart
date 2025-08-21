import 'package:flutter_test/flutter_test.dart';
import 'package:invoiceflow/services/auth_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:invoiceflow/firebase_options.dart';
import 'package:invoiceflow/main.dart';
import 'package:flutter/material.dart';

void main() {
  // Set up Firebase before running tests
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  group('Authentication Tests', () {
    test('Firebase is initialized', () {
      expect(Firebase.apps.isNotEmpty, true);
    });

    test('Auth service is initialized', () {
      expect(authService, isNotNull);
    });

    testWidgets('Login screen shows Google Sign-In button', (WidgetTester tester) async {
      // Build our app and trigger a frame.
      await tester.pumpWidget(const MyApp());

      // Verify that the Google Sign-In button is present
      expect(find.text('Continue with Google'), findsOneWidget);
    });
  });
}
