import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/api/services/auth/auth_service.dart';
import 'package:openearable/api/services/auth/guest_storage.dart';
import 'package:openearable/api/services/user/user_service.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/features/home/state/home_provider.dart';

class AuthController {
  final AuthService _authService;
  final GuestStorage _guestStorage;
  final SessionNotifier _session;
  final UserService _userService;
  final HomeStateNotifier _homeState;

  AuthController(
    this._authService,
    this._userService,
    this._guestStorage,
    this._session,
    this._homeState,
  );

  Future<void> bootstrap() async {
    _session.setLoading();
    try {
      if (await _guestStorage.isGuest()) {
        _session.setGuest();
        return;
      }

      await _authService.refresh();
      final user = await _userService.getUser();
      _session.setAuthenticated(user);
    } catch (_) {
      _session.setLoggedOut();
    }
  }

  Future<void> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    _session.setLoading();

    try {
      await _authService.register(email: email, password: password, name: name);
      await _guestStorage.clear();
      final user = await _userService.getUser();
      _session.setAuthenticated(user);
    } on DioException catch (e) {
      _session.setLoggedOut(e.message ?? 'Sign up failed');
    } catch (_) {
      _session.setLoggedOut('Sign up failed');
    }
  }

  Future<void> login({required String email, required String password}) async {
    _session.setLoading();
    try {
      await _authService.login(email: email, password: password);
      await _guestStorage.clear();
      final user = await _userService.getUser();
      _session.setAuthenticated(user);
    } on DioException catch (exception) {
      _session.setLoggedOut(exception.message);
    } catch (_) {
      _session.setLoggedOut('Login failed');
    }
  }

  Future<void> guestLogin() async {
    await _authService.logout();
    await _guestStorage.setGuest(true);
    _session.setGuest();
  }

  Future<void> logout({String? message}) async {
    await _authService.logout();
    await _guestStorage.clear();
    _homeState.setProjectsLoaded(false);
    _session.setLoggedOut(message);
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  final authService = ref.read(authServiceProvider);
  final userService = ref.read(userServiceProvider);
  final session = ref.read(sessionProvider.notifier);
  final guestStorage = ref.read(guestStorageProvider);
  final homeState = ref.read(homeStateProvider.notifier);

  return AuthController(
    authService,
    userService,
    guestStorage,
    session,
    homeState,
  );
});
