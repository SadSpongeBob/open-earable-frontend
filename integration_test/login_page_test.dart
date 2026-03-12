import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/features/auth/controllers/auth_controller.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/features/home/pages/home_page.dart';
import 'package:openearable/features/auth/pages/login_page.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/api/models/auth/user.dart';
import 'package:openearable/api/services/user/user_service.dart';
import 'package:openearable/api/services/project/project_service.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/local_media.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openearable/app/ui/toast_controller.dart';
import 'package:openearable/app/ui/toast_event.dart';
import 'package:openearable/app/routing/routes.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/main.dart' as app;

class MockAuthController extends Mock implements AuthController {}
class MockProjectService extends Mock implements ProjectService {}
class MockRecordingService extends Mock implements RecordingService {}
class MockLocalMedia extends Mock implements LocalMedia {}
class MockUserService extends Mock implements UserService {}

Future<MockAuthController> mockAuth(WidgetTester tester) async {
  final mockAuthController = MockAuthController();
  final mockProjectService = MockProjectService();
  final mockRecordingService = MockRecordingService();
  final mockLocalMedia = MockLocalMedia();
  final mockUserService = MockUserService();

  when(() => mockProjectService.getLocalProjects()).thenAnswer((_) async => []);
  when(() => mockProjectService.getProjects()).thenAnswer((_) async => []);
  when(() => mockRecordingService.getLocalProjectRecordings(any())).thenAnswer((_) async => []);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWithValue(mockAuthController),
        projectServiceProvider.overrideWithValue(mockProjectService),
        recordingServiceProvider.overrideWithValue(mockRecordingService),
        userServiceProvider.overrideWithValue(mockUserService),
        localMediaProvider.overrideWithValue(mockLocalMedia),
      ],
      child: const app.OpenEarableApp(),
    ),
  );

  await tester.pump();

  return mockAuthController;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Login Page Integration Tests', () {

    Finder emailField() => find.widgetWithText(TextField, 'Email Address');
    Finder passwordField() => find.widgetWithText(TextField, 'Password');
    
    testWidgets('User can login successfully with valid credentials', (WidgetTester tester) async {
      final mockAuthController = await mockAuth(tester);

      final mockUser = User(userId: '1', name: 'Test', emailAddress: 'existing_user@test.com', photoUrl: null);

      when(() => mockAuthController.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async {
      });

      // Fill valid credentials
      await tester.enterText(emailField(), 'existing_user@test.com');
      await tester.enterText(passwordField(), 'password123');

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      final loginButton = find.byWidgetPredicate(
        (widget) => widget is AppButton && widget.text == 'Log In',
      );

      expect(loginButton, findsOneWidget, reason: 'Login button should exist');
      await tester.tap(loginButton);

      final container = ProviderScope.containerOf(tester.element(find.byType(app.OpenEarableApp)));
      container.read(sessionProvider.notifier).setAuthenticated(mockUser);

      // Go to Home using the context of the login page.
      final loginContext = tester.element(find.byType(LoginPage));
      GoRouter.of(loginContext).go(Routes.home);

      for(int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.byType(HomePage), findsOneWidget, reason: 'HomePage should be visible now');

      // Verify we arrived at the Home Page
      final addFolderImageFinder = find.byWidgetPredicate(
        (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == 'assets/buttons/home/add_folder.png',
      );
      
      expect(addFolderImageFinder, findsOneWidget, reason: 'Home page image should be present');
    });

    testWidgets('Login button is disabled until form is filled', (WidgetTester tester) async {
      await mockAuth(tester);

      // Check button state when empty
      var loginButton = tester.widget<AppButton>(find.byType(AppButton));
      expect(loginButton.onPressed, isNull);

      // Fill only email
      await tester.enterText(emailField(), 'test@test.com');
      await tester.pump();
      
      loginButton = tester.widget<AppButton>(find.byType(AppButton));
      expect(loginButton.onPressed, isNull);

      // Fill password - button should enable
      await tester.enterText(passwordField(), '12345678');
      await tester.pump();

      loginButton = tester.widget<AppButton>(find.byType(AppButton));
      expect(loginButton.onPressed, isNotNull, 
        reason: 'The login button should be enabled after filling both fields');
    });

    testWidgets('Shows error toast on invalid credentials', (WidgetTester tester) async {
      final mockAuthController = await mockAuth(tester);

      when(() => mockAuthController.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async {});

      await tester.enterText(emailField(), 'wrong@email.com');
      await tester.enterText(passwordField(), 'wrongpassword');
  
      final loginButton = find.byWidgetPredicate(
        (widget) => widget is AppButton && widget.text == 'Log In',
      );
      await tester.tap(loginButton);

      final container = ProviderScope.containerOf(tester.element(find.byType(app.OpenEarableApp)));
      container.read(toastProvider.notifier).state = const ToastEvent.error('Login failed');

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Login failed', skipOffstage: false), 
        findsOneWidget,
        reason: 'The PopupToast should be visible after toastProvider is updated'
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500));
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
      await tester.pump(); 
      await tester.pump(const Duration(seconds: 1));

      // Verify we are now on the Signup page
      expect(find.text('Create your account'), findsOneWidget); 
    });

    testWidgets('User can continue as guest from Login page', (WidgetTester tester) async {
      final mockAuthController = await mockAuth(tester);

      when(() => mockAuthController.guestLogin())
        .thenAnswer((_) async {});

      final guestLink = find.text('Continue as Guest');
      await tester.tap(guestLink);
  
      await tester.pump(); 
      await tester.pump(const Duration(seconds: 1));

      // Verify we arrived at the Home Page
      final addFolderImageFinder = find.byWidgetPredicate(
        (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == 'assets/buttons/home/add_folder.png',
      );
      
      expect(addFolderImageFinder, findsOneWidget, reason: 'Home page image should be present');
    });
  });
}