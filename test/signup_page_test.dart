import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:openearable/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Signup Page Integration Tests', () {
    
    // Helper to navigate from Login (start) to Signup Page
    Future<void> navigateToSignup(WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();
    }

    testWidgets('User can sign up successfully', (WidgetTester tester) async {
      await navigateToSignup(tester);

      final uniqueEmail = 'test_${DateTime.now().millisecondsSinceEpoch}@email.com';

      // Fill form
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Test User');
      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), uniqueEmail);
      await tester.enterText(find.widgetWithText(TextField, 'Password'), '12345678');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign Up'));

      // Let network call finish and GoRouter navigate
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Default'), findsOneWidget);
    });

    testWidgets('Signup button is disabled until all three fields are filled', (WidgetTester tester) async {
      await navigateToSignup(tester);

      // Initial state: Disabled
      var signupButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(signupButton.enabled, isFalse);

      // Fill Name and Email only: Still disabled
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Test');
      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'test@test.com');
      await tester.pump();
      
      signupButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(signupButton.enabled, isFalse);

      // Fill Password: Now enabled
      await tester.enterText(find.widgetWithText(TextField, 'Password'), '12345678');
      await tester.pump();

      signupButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(signupButton.enabled, isTrue);
    });

    testWidgets('Shows validation errors for invalid input formats', (WidgetTester tester) async {
      await navigateToSignup(tester);

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'invalid name?');
      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'not-an-email');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), '123');

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text("Name can't include special characters"), findsOneWidget);
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('Shows error toast on failed signup API call', (WidgetTester tester) async {
      await navigateToSignup(tester);

      // Using an email that we know will fail (e.g., already exists)
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Test');
      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'existing@test.com');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'password123');
      
      await tester.tap(find.text('Sign Up'));

      // Wait for Controller to catch error and Overlay to show Toast
      await tester.pump(const Duration(milliseconds: 300));

      // Controller defaults to 'Sign up failed' if Dio message is null
      expect(find.text('Sign up failed'), findsOneWidget);
    });

    testWidgets('Can toggle password visibility', (WidgetTester tester) async {
      await navigateToSignup(tester);

      final passwordFieldFinder = find.widgetWithText(TextField, 'Password');
      
      // Initially hidden
      expect(tester.widget<TextField>(passwordFieldFinder).obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      // Now visible
      expect(tester.widget<TextField>(passwordFieldFinder).obscureText, isFalse);
    });

    testWidgets('User can navigate from Signup back to Login page', (WidgetTester tester) async {
      await navigateToSignup(tester);

      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Log into your account'), findsOneWidget); 
    });

    testWidgets('User can continue as guest from Signup Page', (WidgetTester tester) async {
      await navigateToSignup(tester);

      await tester.tap(find.text('Continue as Guest'));
      await tester.pumpAndSettle();

      expect(find.text('Default'), findsOneWidget);
    });
  });
}