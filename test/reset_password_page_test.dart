import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
//import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/services/auth/auth_service.dart';
import 'package:openearable/features/auth/pages/reset_password_page.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/app/routing/routes.dart';
import 'package:openearable/app/routing/router_provider.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/main.dart' as app;
import 'package:dio/dio.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reset Password Page Integration Tests', () {
    late MockAuthService mockAuth;
    const testToken = "fake-auth-token-123";

    // Helper to start the app directly on the Reset Password page
    Future<void> setupResetPasswordPage(WidgetTester tester) async {
      final dpi = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(2560 * dpi, 1800 * dpi);

      mockAuth = MockAuthService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authServiceProvider.overrideWithValue(mockAuth),
          ],
          child: const app.OpenEarableApp(),
        ),
      );

      await tester.pump();

      final container = ProviderScope.containerOf(tester.element(find.byType(app.OpenEarableApp)));
      final router = container.read(routerProvider);

      // 3. Navigate using the router instance
      router.go(
        Uri(
          path: Routes.resetPassword, 
          queryParameters: {'token': testToken}
        ).toString()
      );
      
      // Wait for navigation and allow the "pumpAndSettle" timeout issue to be avoided
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));
    }

    testWidgets('Successfully resets password and redirects to login', (WidgetTester tester) async {
      await setupResetPasswordPage(tester);

      when(() => mockAuth.updatePassword(
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
      
      // Wait for async call and Dialog animation
      await tester.pump(const Duration(milliseconds: 800));

      // Verify Dialog
      expect(find.text('Password Reset'), findsOneWidget);
      expect(find.text('Your password has been reset successfully'), findsOneWidget);

      // Tap 'Ok' (Case-sensitive check!)
      await tester.tap(find.text('Ok'));
      
      // Wait for navigation back to login
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Log into'), findsOneWidget);
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

      await tester.enterText(find.widgetWithText(TextField, 'Password'), '123'); // Too short
      await tester.pump();

      await tester.tap(find.widgetWithText(AppButton, 'Reset'));
      await tester.pump(const Duration(milliseconds: 500));

      // Adjust the string to match your Validators.password output (likely 6 or 8)
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

      when(() => mockAuth.updatePassword(
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
    });
  });
}