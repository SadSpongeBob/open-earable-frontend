import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:openearable/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('User can sign up successfully', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    final uniqueEmail =
        'test_${DateTime.now().millisecondsSinceEpoch}@email.com';

    final nameField = find.widgetWithText(TextField, 'Name');
    final emailField = find.widgetWithText(TextField, 'Email Address');
    final passwordField = find.widgetWithText(TextField, 'Password');

    // Fill form
    await tester.enterText(nameField, 'Test User');
    await tester.enterText(emailField, uniqueEmail);
    await tester.enterText(passwordField, '12345678');

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Tap sign up
    await tester.tap(find.text('Sign Up'));

    // Let network call finish
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Expect navigation to home where it looks for text 'Default' of a default project
    expect(find.text('Default'), findsOneWidget);
  });

  testWidgets('Shows validation errors for invalid input', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Enter an invalid email
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'invalid name? ');
    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'not-an-email');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), '123');

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    // Verify error messages appear on screen
    expect(find.text("Name can't include special characters"), findsOneWidget);
    expect(find.text('Enter a valid email address'), findsOneWidget);
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
  });

  testWidgets('User can continue as guest', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    final guestLink = find.text('Continue as Guest');
    await tester.tap(guestLink);
  
    await tester.pumpAndSettle();

    expect(find.text('Default'), findsOneWidget);
  });

  testWidgets('User can navigate from Signup to Login page', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    // Find the "Log in" link
    final loginLink = find.text('Log in');

    // Tap the link
    await tester.tap(loginLink);
  
    // Wait for the GoRouter transition to finish
    await tester.pumpAndSettle();

    // Verify we are now on the Login page
    expect(find.text('Log into your account'), findsOneWidget); 
  });

  testWidgets('Sign Up button shows loading state and is disabled during API call', (WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Test');
    await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'test@test.com');
    await tester.enterText(find.widgetWithText(TextField, 'Password'), 'password123');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign Up'));
    await tester.pump(); 

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Look for the Button widget that is currently being used
    final buttonFinder = find.byType(ElevatedButton);
    final button = tester.widget<ElevatedButton>(buttonFinder);
    expect(button.enabled, isFalse, reason: 'Button must be disabled during API calls');
      
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}