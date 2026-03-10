import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/features/auth/controllers/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openearable/main.dart' as app;

class MockAuthController extends Mock implements AuthController {}

Future<MockAuthController> mockAuth(WidgetTester tester) async {
  final mockAuthController = MockAuthController();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWithValue(mockAuthController),
      ],
      child: MaterialApp(
        home: SingleChildScrollView(
          child: const app.OpenEarableApp(),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();

  return mockAuthController;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Login Page Widget Tests', () {

    Finder emailField() => find.widgetWithText(TextField, 'Email Address');
    Finder passwordField() => find.widgetWithText(TextField, 'Password');
    
    testWidgets('User can login successfully with valid credentials', (WidgetTester tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1080, 1920);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });
      final mockAuthController = await mockAuth(tester);

      when(() => mockAuthController.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async {});

      // Fill valid credentials
      await tester.enterText(emailField(), 'existing_user@test.com');
      await tester.enterText(passwordField(), 'password123');
      await tester.pumpAndSettle();

      // Tap Login button
      await tester.tap(find.text('Log In'));
      
      await tester.pumpAndSettle();

      // Verify we arrived at the Home Page
      expect(find.text('Default'), findsOneWidget);
    });

    testWidgets('Login button is disabled until form is filled', (WidgetTester tester) async {
      await mockAuth(tester);

      // Check button state when empty
      var loginButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(loginButton.enabled, isFalse);

      // Fill only email
      await tester.enterText(emailField(), 'test@test.com');
      await tester.pump();
      
      loginButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(loginButton.enabled, isFalse);

      // Fill password - button should enable
      await tester.enterText(passwordField(), '12345678');
      await tester.pump();

      loginButton = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(loginButton.enabled, isTrue);
    });

    testWidgets('Shows error toast on invalid credentials', (WidgetTester tester) async {
      final mockAuthController = await mockAuth(tester);

      when(() => mockAuthController.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenThrow(Exception('Login failed'));

      await tester.enterText(emailField(), 'wrong@email.com');
      await tester.enterText(passwordField(), 'wrongpassword');
  
      await tester.tap(find.text('Log In'));

      await tester.pump(const Duration(milliseconds: 300));

      // If the DioException has no message, the controller defaults to 'Login failed'
      final errorFinder = find.text('Login failed');
  
      expect(errorFinder, findsOneWidget);
    });

    /// Test for the first tap of a toggle visibility
    testWidgets('Can toggle password visibility', (WidgetTester tester) async {
      await mockAuth(tester);
      TextField passwordWidget = tester.widget<TextField>(passwordField());
      
      expect(passwordWidget.obscureText, isTrue);

      // Tap the eye icon
      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      // Now visible
      passwordWidget = tester.widget<TextField>(passwordField());
      expect(passwordWidget.obscureText, isFalse);
    });

    testWidgets('User can navigate from Login to Signup page', (WidgetTester tester) async {
      await mockAuth(tester);

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
      final mockAuthController = await mockAuth(tester);

      when(() => mockAuthController.guestLogin())
        .thenAnswer((_) async {});

      final guestLink = find.text('Continue as Guest');
      await tester.tap(guestLink);
  
      await tester.pumpAndSettle();

      expect(find.text('Default'), findsOneWidget);
    });
  });
}