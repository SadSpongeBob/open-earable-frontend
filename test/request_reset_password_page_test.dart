import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:openearable/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Request Reset Page Integration Tests', () {
    
    // Helper to navigate from Login to Request Reset page
    Future<void> navigateToRequestReset(WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();
      
      // Tap the "Forgot Password?" link on the Login page
      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();
    }

    testWidgets('User can request password reset successfully', (WidgetTester tester) async {
      await navigateToRequestReset(tester);

      final emailField = find.widgetWithText(TextField, 'Email Address');
      await tester.enterText(emailField, 'existing_user@test.com');
      await tester.pumpAndSettle();

      // Tap Send button
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      // Verify the Success Dialog appears
      expect(find.text('Reset request'), findsOneWidget);
      expect(find.text('Password reset link has been sent to your email address!'), findsOneWidget);

      await tester.tap(find.text('OK')); 
      await tester.pumpAndSettle();

      // Verify we are redirected back to Login page
      expect(find.text('Log into your account'), findsOneWidget);
    });

    testWidgets('Send button is disabled until email is entered', (WidgetTester tester) async {
      await navigateToRequestReset(tester);

      // Initially disabled
      var sendButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Send'));
      expect(sendButton.enabled, isFalse);

      // Fill email
      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'test@test.com');
      await tester.pump();

      // Now enabled
      sendButton = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Send'));
      expect(sendButton.enabled, isTrue);
    });

    testWidgets('Shows validation error for invalid email format', (WidgetTester tester) async {
      await navigateToRequestReset(tester);

      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'not-an-email');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('Shows error toast if the API request fails', (WidgetTester tester) async {
      await navigateToRequestReset(tester);

      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'error@test.com');
      await tester.tap(find.text('Send'));

      // Wait for the toast overlay to appear
      await tester.pump(const Duration(milliseconds: 300));

      // Matches the fallback message in your catch block
      expect(find.text('Request failed'), findsOneWidget);
    });

    testWidgets('User can navigate back to Login via button', (WidgetTester tester) async {
      await navigateToRequestReset(tester);

      await tester.tap(find.text('Back to Log In'));
      await tester.pumpAndSettle();

      expect(find.text('Log into your account'), findsOneWidget);
    });
  });
}