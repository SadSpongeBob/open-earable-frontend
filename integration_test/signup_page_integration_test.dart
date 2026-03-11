import 'package:flutter/material.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/features/auth/controllers/auth_controller.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/features/auth/pages/signup_page.dart';
import 'package:openearable/api/services/project/project_service.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/services/user/user_service.dart';
import 'package:openearable/app/widgets/app_button.dart';
import 'package:openearable/api/models/auth/user.dart';
import 'package:openearable/api/local_media.dart';
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

// Helper to navigate from Login to Signup Page
Future<MockAuthController> setupSignupPage(WidgetTester tester) async {
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

  await tester.pump(const Duration(seconds: 1));
  await tester.tap(find.text('Sign Up'));
  await tester.pump(); 
  await tester.pump(const Duration(seconds: 1));

  return mockAuthController;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Signup Page Integration Tests', () {

    testWidgets('User can sign up successfully', (WidgetTester tester) async {
      final mockAuth = await setupSignupPage(tester);

      when(() => mockAuth.signup(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async {});

      final mockName = 'Test User';
      final mockEmailAddress = 'test@email.com';
      final mockPassword = '123456789';

      await tester.enterText(find.widgetWithText(TextField, 'Name'), mockName);
      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), mockEmailAddress);
      await tester.enterText(find.widgetWithText(TextField, 'Password'), mockPassword);
      await tester.pump();

      final signupButton = find.byWidgetPredicate(
        (widget) => widget is AppButton && widget.text == 'Sign Up',
      );

      await tester.tap(signupButton);

      final mockUser = User(
        userId: '1', 
        name: mockName, 
        emailAddress: mockEmailAddress, 
        photoUrl: null
      );

      final container = ProviderScope.containerOf(tester.element(find.byType(app.OpenEarableApp)));
      container.read(sessionProvider.notifier).setAuthenticated(mockUser);

      // Go to Home using the context of the login page.
      final signupContext = tester.element(find.byType(SignupPage));
      GoRouter.of(signupContext).go(Routes.home);

      for(int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      
      // Verify we arrived at the Home Page
      final addFolderImageFinder = find.byWidgetPredicate(
        (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == 'assets/buttons/home/add_folder.png',
      );
      
      expect(addFolderImageFinder, findsOneWidget, reason: 'Home page image should be present');
    });

    testWidgets('Signup button is disabled until all three fields are filled', (WidgetTester tester) async {
      await setupSignupPage(tester);

      // Initial state: Disabled
      var signupButton = tester.widget<AppButton>(find.byType(AppButton));
      expect(signupButton.onPressed, isNull);

      // Fill Name and Email only: Still disabled
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Test');
      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'test@test.com');
      await tester.pump();
      
      signupButton = tester.widget<AppButton>(find.byType(AppButton));
      expect(signupButton.onPressed, isNull);

      // Fill Password: Now enabled
      await tester.enterText(find.widgetWithText(TextField, 'Password'), '12345678');
      await tester.pump();

      signupButton = tester.widget<AppButton>(find.byType(AppButton));
      expect(signupButton.onPressed, isNotNull, 
        reason: 'The signup button should be enabled after filling all of the fields');
    });

    testWidgets('Shows validation errors for invalid input formats', (WidgetTester tester) async {
      await setupSignupPage(tester);

      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'invalid  name?');
      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'not-an-email');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), '123');

      await tester.pump();

      final signupButton = find.byWidgetPredicate(
        (widget) => widget is AppButton && widget.text == 'Sign Up',
      );

      await tester.tap(signupButton);

      for(int i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }

      expect(find.text("Name can't include special characters"), findsOneWidget);
      expect(find.text('Enter a valid email address'), findsOneWidget);
      expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    });

    testWidgets('Shows error toast on failed signup API call', (WidgetTester tester) async {
      final mockAuthController = await setupSignupPage(tester);

      when(() => mockAuthController.signup(
        name: any(named: 'name'),
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenAnswer((_) async {});

      // Using an email that we know will fail (e.g., already exists)
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Test');
      await tester.enterText(find.widgetWithText(TextField, 'Email Address'), 'existing@test.com');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'password123');
      
      final signupButton = find.byWidgetPredicate(
        (widget) => widget is AppButton && widget.text == 'Sign Up',
      );

      await tester.tap(signupButton);

      final container = ProviderScope.containerOf(tester.element(find.byType(app.OpenEarableApp)));
      container.read(toastProvider.notifier).state = const ToastEvent.error('Sign up failed');

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text('Sign up failed', skipOffstage: false), 
        findsOneWidget,
        reason: 'The PopupToast should be visible after toastProvider is updated'
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('Can toggle password visibility', (WidgetTester tester) async {
      await setupSignupPage(tester);

      final passwordFieldFinder = find.widgetWithText(TextField, 'Password');
      
      // Initially hidden
      expect(tester.widget<TextField>(passwordFieldFinder).obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility));
      await tester.pump();

      // Now visible
      expect(tester.widget<TextField>(passwordFieldFinder).obscureText, isFalse);
    });

    testWidgets('User can navigate from Signup back to Login page', (WidgetTester tester) async {
      await setupSignupPage(tester);

      // Tap the 'Log in' link
      await tester.tap(find.text('Log in'));
      
      // Wait for the GoRouter transition to finish
      await tester.pump(); 
      await tester.pump(const Duration(seconds: 1));

      // Verify we are now on the Login page
      expect(find.text('Log into\nyour account'), findsOneWidget); 
    });

    testWidgets('User can continue as guest from Signup Page', (WidgetTester tester) async {
      final mockAuthController = await setupSignupPage(tester);

      when(() => mockAuthController.guestLogin())
        .thenAnswer((_) async {});

      await tester.tap(find.text('Continue as Guest'));
      
      await tester.pump(); 
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Default'), findsOneWidget);
    });
  });
}