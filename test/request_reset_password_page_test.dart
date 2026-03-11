import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
//import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:openearable/api/services/auth/auth_service.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/app/ui/toast_controller.dart';
import 'package:openearable/app/ui/toast_event.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/main.dart' as app;
import 'package:dio/dio.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Request Reset Page Integration Tests', () {
    late MockAuthService mockAuthService;

    // Helper to setup the app and navigate to the page
    Future<void> setupRequestResetPage(WidgetTester tester) async {
      final dpi = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(2560 * dpi, 1800 * dpi);

      mockAuthService = MockAuthService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: const app.OpenEarableApp(),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      
      // Tap "Forgot Password?" on Login Page
      final forgotPasswordLink = find.text('Forgot Password?');
      await tester.tap(forgotPasswordLink);
      
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('User can request password reset successfully', (WidgetTester tester) async {
      await setupRequestResetPage(tester);

      // Setup mock success
      when(() => mockAuthService.resetPassword(emailAddress: any(named: 'emailAddress')))
          .thenAnswer((_) async => Response(requestOptions: RequestOptions(), statusCode: 200));

      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'test@example.com');
      await tester.pump();

      // Tap Send
      await tester.tap(find.widgetWithText(AppButton, 'Send'));
      
      // Pump several times to handle the async call and dialog animation
      for(int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Verify the Success Dialog
      expect(find.text('Reset request'), findsOneWidget);
      
      // Close dialog
      await tester.tap(find.text('Ok'));

      await tester.pump(const Duration(seconds: 1)); 
      await tester.pump(const Duration(milliseconds: 500));

      // Verify redirection back to Login
      expect(find.textContaining('Log into'), findsOneWidget);
    });

    testWidgets('Send button is disabled until email is entered', (WidgetTester tester) async {
      await setupRequestResetPage(tester);

      var sendButton = tester.widget<AppButton>(find.widgetWithText(AppButton, 'Send'));
      expect(sendButton.onPressed, isNull);

      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'test@test.com');
      await tester.pump();

      sendButton = tester.widget<AppButton>(find.widgetWithText(AppButton, 'Send'));
      expect(sendButton.onPressed, isNotNull);
    });

    testWidgets('Shows validation error for invalid email format', (WidgetTester tester) async {
      await setupRequestResetPage(tester);

      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'not-an-email');
      await tester.pump();

      await tester.tap(find.widgetWithText(AppButton, 'Send'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('Shows error toast if the API request fails', (WidgetTester tester) async {
      await setupRequestResetPage(tester);

      // Mock a Dio failure
      when(() => mockAuthService.resetPassword(emailAddress: any(named: 'emailAddress')))
          .thenThrow(DioException(
            requestOptions: RequestOptions(),
            message: 'Network Error',
            type: DioExceptionType.connectionError
          ));

      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'error@test.com');
      await tester.pump();
      
      await tester.tap(find.widgetWithText(AppButton, 'Send'));
      
      // Wait for the toast
      for(int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      final container = ProviderScope.containerOf(tester.element(find.byType(app.OpenEarableApp)));
      container.read(toastProvider.notifier).state = const ToastEvent.error('Network Error');

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Network Error', skipOffstage: false), 
        findsOneWidget,
        reason: 'The PopupToast should be visible after toastProvider is updated'
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('User can navigate back to Login via button', (WidgetTester tester) async {
      await setupRequestResetPage(tester);

      await tester.tap(find.widgetWithText(AppButton, 'Back to Log In'));

      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Log into'), findsOneWidget);
    });
  });
}