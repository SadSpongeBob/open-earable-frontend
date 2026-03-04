import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:openearable/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Page Integration Tests', () {
    
    testWidgets('User can login successfully with valid credentials', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final emailField = find.widgetWithText(TextField, 'Email Address');
      final passwordField = find.widgetWithText(TextField, 'Password');

      // Fill valid credentials
      await tester.enterText(emailField, 'existing_user@test.com');
      await tester.enterText(passwordField, 'password123');
      await tester.pumpAndSettle();

      // Tap Login button
      await tester.tap(find.text('Log In'));
      
      // Allow time for API response and navigation
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Verify we arrived at the Home Page
      expect(find.text('Default'), findsOneWidget);
    });

    testWidgets('Login button is disabled until form is filled', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Check button state when empty
      var loginButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(loginButton.enabled, isFalse);

      // Fill only email
      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'test@test.com');
      await tester.pump();
      
      loginButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(loginButton.enabled, isFalse);

      // Fill password - button should enable
      await tester.enterText(find.widgetWithText(TextField, 'Password'), '12345678');
      await tester.pump();

      loginButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(loginButton.enabled, isTrue);
    });

  testWidgets('Shows error toast on invalid credentials', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'wrong@email.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'wrongpassword');
  
    await tester.tap(find.text('Log In'));

    await tester.pump(const Duration(milliseconds: 300));

    // If the DioException has no message, the controller defaults to 'Login failed'
    final errorFinder = find.text('Login failed');
  
    expect(errorFinder, findsOneWidget);
  });

    /// Test for the first tap of a toggle visibility
    testWidgets('Can toggle password visibility', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final passwordFieldFinder = find.widgetWithText(TextField, 'Password');
      TextField passwordWidget = tester.widget<TextField>(passwordFieldFinder);
      
      expect(passwordWidget.obscureText, isTrue);

      // Tap the eye icon
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      // Now visible
      passwordWidget = tester.widget<TextField>(passwordFieldFinder);
      expect(passwordWidget.obscureText, isFalse);
    });

    testWidgets('User can navigate from Login to Signup page', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Find the "Sign Up" link
      final signupLink = find.text('Sign Up');

      // Tap the link
      await tester.tap(signupLink);
  
      // Wait for the GoRouter transition to finish
      await tester.pumpAndSettle();

      // Verify we are now on the Signup page
      expect(find.text('Create your account'), findsOneWidget); 
    });

    testWidgets('User can continue as guest from Login page', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      final guestLink = find.text('Continue as Guest');
      await tester.tap(guestLink);
  
      await tester.pumpAndSettle();

      expect(find.text('Default'), findsOneWidget);
    });
  });
}