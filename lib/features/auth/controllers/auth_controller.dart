import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/api/models/auth/auth_state.dart';
import 'package:openearable/api/services/auth/auth_service.dart';
import 'package:openearable/api/services/auth/guest_storage.dart';
import 'package:openearable/features/auth/state/session_provider.dart';

class AuthController {
  final AuthService _authService;
  final GuestStorage _guestStorage;
  final SessionNotifier _session;

  AuthController(this._authService, this._guestStorage, this._session);

  Future<void> bootstrap() async {
    _session.setLoading();

    if (await _guestStorage.isGuest()) {
      _session.setMode(AuthMode.guest);
      return;
    }

    try {
      await _authService.refresh();
      _session.setMode(AuthMode.authenticated);
    } catch (_) {
      _session.setMode(AuthMode.loggedOut);
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
      _session.setMode(AuthMode.authenticated);
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
      _session.setMode(AuthMode.authenticated);
    } on DioException catch (exception) {
      _session.setLoggedOut(exception.message);
    } catch (_) {
      _session.setLoggedOut('Login failed');
    }
  }

  Future<void> guestLogin() async {
    await _authService.logout();
    await _guestStorage.setGuest(true);
    _session.setMode(AuthMode.guest);
  }

  Future<void> logout({String? message}) async {
    await _authService.logout();
    await _guestStorage.clear();
    _session.setLoggedOut(message);
  }
}

final authControllerProvider = Provider<AuthController>((ref) {
  final authService = ref.read(authServiceProvider);
  final session = ref.read(sessionProvider.notifier);
  final guestStorage = ref.read(guestStorageProvider);

  return AuthController(authService, guestStorage, session);
});
