import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/services/auth/auth_service.dart';
import 'package:openearable/features/auth/pages/reset_password_page.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/app/routing/routes.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:dio/dio.dart';

class MockAuthService extends Mock implements AuthService {}
class MockGoRouter extends Mock implements GoRouter {}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Reset Password Page Integration Tests', () {
    late MockAuthService mockAuthService;
    late MockGoRouter mockRouter;
    const testToken = "fake-auth-token-123";

    // Helper to start the app directly on the Reset Password page
    Future<void> setupResetPasswordPage(WidgetTester tester) async {
      mockAuthService = MockAuthService();
      mockRouter = MockGoRouter();

      when(() => mockRouter.go(any())).thenReturn(null);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuthService),
          ],
          child: MaterialApp(
            home: InheritedGoRouter(
              goRouter: mockRouter,
              child: ResetPasswordPage(authToken: testToken),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
    }

    testWidgets('Successfully resets password and redirects to login', (WidgetTester tester) async {
      await setupResetPasswordPage(tester);

      expect(find.text('Reset Password'), findsOneWidget);

      when(() => mockAuthService.updatePassword(
            password: any(named: 'password'),
            authToken: any(named: 'authToken'),
          )).thenAnswer((_) async => Response(requestOptions: RequestOptions(), statusCode: 200));

      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'NewPassword123!');
      await tester.pump();

      final resetButton = find.byWidgetPredicate(
        (widget) => widget is AppButton && widget.text == 'Reset',
      );

      // Tap Reset button
      await tester.tap(resetButton);
      
      await tester.pump(const Duration(milliseconds: 800));

      // Verify Dialog
      expect(find.text('Password Reset'), findsOneWidget);
      expect(find.text('Your password has been reset successfully'), findsOneWidget);

      // Tap 'Ok'
      await tester.tap(find.text('Ok'));
      
      // Wait for navigation back to login
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockRouter.go(Routes.login)).called(1);
    });

    testWidgets('Reset button is disabled until password is typed', (WidgetTester tester) async {
      await setupResetPasswordPage(tester);

      var resetButton = tester.widget<AppButton>(find.widgetWithText(AppButton, 'Reset'));
      expect(resetButton.onPressed, isNull);

      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'some-pw');
      await tester.pump();

      resetButton = tester.widget<AppButton>(find.widgetWithText(AppButton, 'Reset'));
      expect(resetButton.onPressed, isNotNull);
    });

    testWidgets('Shows validation error for short password', (WidgetTester tester) async {
      await setupResetPasswordPage(tester);

      await tester.enterText(find.widgetWithText(TextField, 'Password'), '123');
      await tester.pump();

      await tester.tap(find.widgetWithText(AppButton, 'Reset'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('at least'), findsOneWidget);
    });

    testWidgets('Can toggle password visibility', (WidgetTester tester) async {
      await setupResetPasswordPage(tester);

      final passwordField = find.widgetWithText(TextField, 'Password');
      
      // Initially obscured
      expect(tester.widget<TextField>(passwordField).obscureText, isTrue);

      // Tap the eye icon
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      // Now visible
      expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
    });

    testWidgets('Shows error toast on API failure', (WidgetTester tester) async {
      await setupResetPasswordPage(tester);

      when(() => mockAuthService.updatePassword(
            password: any(named: 'password'),
            authToken: any(named: 'authToken'),
          )).thenThrow(DioException(
            requestOptions: RequestOptions(),
            message: 'Invalid or expired token',
          ));

      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'ValidPassword123');
      await tester.pump();

      await tester.tap(find.widgetWithText(AppButton, 'Reset'));
      
      // Wait for Toast
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Invalid or expired token'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 3));
    });
  });
}