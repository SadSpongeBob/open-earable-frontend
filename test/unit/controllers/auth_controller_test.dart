import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import 'package:openearable/features/auth/controllers/auth_controller.dart';
import 'package:openearable/api/services/auth/auth_service.dart';
import 'package:openearable/api/services/auth/guest_storage.dart';
import 'package:openearable/api/services/user/user_service.dart';
import 'package:openearable/api/models/auth/user.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/app/ui/toast_event.dart';
import 'package:openearable/api/models/auth/auth_tokens.dart';
import 'package:openearable/features/home/state/network_status.dart';

/// Mocks
class MockAuthService extends Mock implements AuthService {}
class MockUserService extends Mock implements UserService {}
class MockGuestStorage extends Mock implements GuestStorage {}
class MockSessionNotifier extends Mock implements SessionNotifier {}
class MockHomeStateNotifier extends Mock implements HomeStateNotifier {}

void main() {
  late AuthController controller;
  late MockAuthService authService;
  late MockUserService userService;
  late MockGuestStorage guestStorage;
  late MockSessionNotifier session;
  late MockHomeStateNotifier homeState;
  late StateController<ToastEvent?> toast;
  late ProviderContainer container;

  final fakeUser = User(
    userId: '1',
    name: 'Test User',
    emailAddress: 'test@mail.com',
    photoUrl: null,
  );

  setUp(() {
    authService = MockAuthService();
    userService = MockUserService();
    guestStorage = MockGuestStorage();
    session = MockSessionNotifier();
    homeState = MockHomeStateNotifier();
    toast = StateController<ToastEvent?>(null);
    container = ProviderContainer(overrides: [
      networkStatusProvider.overrideWith((ref) => Stream.value(NetworkStatus.wifi)),
    ]);
    final ref = container.read(Provider((ref) => ref));

    controller = AuthController(
      authService,
      userService,
      guestStorage,
      session,
      homeState,
      toast,
      ref,
    );
  });

  group('AuthController.login', () {
    test('sets authenticated session on successful login', () async {
      when(() => authService.login(
        email: any(named: 'email'),
        password: any(named: 'password')
      )).thenAnswer((_) async => Tokens(
        accessToken: 'fake_access',
        refreshToken: 'fake_refresh',
      ));
      when(() => guestStorage.clear()).thenAnswer((_) async {});
      when(() => userService.getUser()).thenAnswer((_) async => fakeUser);

      await controller.login(email: 'test@test.com', password: '123456');

      verify(() => session.setLoading()).called(1);
      verify(() => authService.login(email: 'test@test.com', password: '123456')).called(1);
      verify(() => session.setAuthenticated(fakeUser)).called(1);
    });

    test('sets error toast on DioException', () async {
      when(() => authService.login(
        email: any(named: 'email'), 
        password: any(named: 'password')
      )).thenThrow(DioException(
        requestOptions: RequestOptions(path: ''),
        message: 'Invalid credentials',
      ));

      await controller.login(email: 'wrong@test.com', password: 'wrong');

      verify(() => session.setLoggedOut(any())).called(1);
      expect(toast.state, isA<ToastEvent>());
    });

    test('sets default error toast on unknown login error', () async {
      when(() => authService.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      )).thenThrow(Exception('Unexpected'));

      await controller.login(email: 'test@test.com', password: '123');

      verify(() => session.setLoggedOut('Login failed')).called(1);
      expect(toast.state, isA<ToastEvent>());
      expect(toast.state!.message, 'Login failed');
    });
  });

  group('AuthController.signup', () {
    test('sets authenticated session on successful signup', () async {
      when(() => authService.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          name: any(named: 'name'),
        )).thenAnswer((_) async => Tokens(
          accessToken: 'fake_access', 
          refreshToken: 'fake_refresh'
        ));

      when(() => guestStorage.clear()).thenAnswer((_) async {});
      when(() => userService.getUser()).thenAnswer((_) async => fakeUser);

      await controller.signup(
        name: 'Test User',
        email: 'test@test.com',
        password: '123456',
      );

      verify(() => session.setLoading()).called(1);
      verify(() => authService.register(
          email: 'test@test.com',
          password: '123456',
          name: 'Test User',
        )).called(1);
      verify(() => session.setAuthenticated(fakeUser)).called(1);
    });

    test('sets error toast on DioException during signup', () async {
      when(() => authService.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          name: any(named: 'name'),
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          message: 'Sign Up failed',
      ));

      await controller.signup(
        name: 'Test User',
        email: 'wrong@test.com',
        password: 'wrong',
      );

      verify(() => session.setLoggedOut(any())).called(1);
      expect(toast.state, isA<ToastEvent>());
      expect(toast.state!.kind, ToastKind.error);
      expect(toast.state!.message, 'Sign Up failed');
    });

    test('sets default error toast on unknown signup error', () async {
      when(() => authService.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          name: any(named: 'name'),
        )).thenThrow(Exception('Unexpected'));

      await controller.signup(
        name: 'Test',
        email: 'test@test.com',
        password: '123',
      );

      verify(() => session.setLoggedOut('Sign up failed')).called(1);
      expect(toast.state, isA<ToastEvent>());
      expect(toast.state!.message, 'Sign up failed');
    });
  });

  group('AuthController.bootstrap', () {
    test('sets guest session if guestStorage says so', () async {
      when(() => guestStorage.isGuest()).thenAnswer((_) async => true);

      await controller.bootstrap();

      verify(() => session.setLoading()).called(1);
      verify(() => session.setGuest()).called(1);
      verifyNever(() => authService.refresh());
    });

    test('sets guest session if network is offline', () async {
      when(() => guestStorage.isGuest()).thenAnswer((_) async => false);
    
      // Override the network status to offline
      container.updateOverrides([
        networkStatusProvider.overrideWith(
          (ref) => Stream.value(NetworkStatus.offline)
        ),
      ]);

      await controller.bootstrap();

      verify(() => session.setGuest()).called(1);
      verifyNever(() => authService.refresh());
    });

    test('sets authenticated if refresh and getUser succeed', () async {
      when(() => guestStorage.isGuest()).thenAnswer((_) async => false);

      // Mock online status
      container.updateOverrides([
        networkStatusProvider.overrideWith(
          (ref) => Stream.value(NetworkStatus.wifi)
        ),
      ]);
      when(() => authService.refresh()).thenAnswer((_) async => Tokens(accessToken: 'a', refreshToken: 'r'));
      when(() => userService.getUser()).thenAnswer((_) async => fakeUser);

      await controller.bootstrap();

      verify(() => session.setAuthenticated(fakeUser)).called(1);
    });
  });

  group('AuthController.logout', () {
    test('clears storage and resets home state', () async {
      when(() => authService.logout()).thenAnswer((_) async {});
      when(() => guestStorage.clear()).thenAnswer((_) async {});

      await controller.logout(message: 'Good bye!');

      verify(() => authService.logout()).called(1);
      verify(() => guestStorage.clear()).called(1);
      verify(() => homeState.setProjectsLoaded(false)).called(1);
      verify(() => session.setLoggedOut('Good bye!')).called(1);
    });
  });

  group('AuthController.guestLogin', () {
    test('logs out and sets guest storage flag', () async {
      when(() => authService.logout()).thenAnswer((_) async {});
      when(() => guestStorage.setGuest(true)).thenAnswer((_) async {});

      await controller.guestLogin();

      verify(() => authService.logout()).called(1);
      verify(() => guestStorage.setGuest(true)).called(1);
      verify(() => session.setGuest()).called(1);
    });
  });
}