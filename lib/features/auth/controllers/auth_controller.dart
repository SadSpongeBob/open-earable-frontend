import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/api/models/auth/auth_state.dart';
import 'package:openearable/api/services/auth/auth_service.dart';
import 'package:openearable/api/services/auth/guest_storage.dart';

class AuthController extends StateNotifier<AuthState> {
  final AuthService _authService;
  final GuestStorage _guestStorage;

  AuthController(this._authService, this._guestStorage)
    : super(AuthState.initial());

  Future<void> bootstrap() async {
    state = state.copyWith(mode: AuthMode.loading, error: null);

    if (await _guestStorage.isGuest()) {
      state = state.copyWith(mode: AuthMode.guest);
      return;
    }

    try {
      await _authService.refresh();
      state = state.copyWith(mode: AuthMode.authenticated);
    } catch (_) {
      state = state.copyWith(mode: AuthMode.loggedOut);
    }
  }

  Future<void> guestLogin() async {
    await _authService.logout();
    await _guestStorage.setGuest(true);

    state = state.copyWith(mode: AuthMode.guest, error: null);
  }

  Future<void> login({required String email, required String password}) async {
    state = state.copyWith(mode: AuthMode.loading, error: null);

    try {
      await _authService.login(email: email, password: password);
      await _guestStorage.clear();
      state = state.copyWith(mode: AuthMode.authenticated);
    } on DioException catch (exception) {
      state = state.copyWith(
        mode: AuthMode.loggedOut,
        error: exception.message ?? 'Login failed',
      );
    } catch (_) {
      state = state.copyWith(mode: AuthMode.loggedOut, error: 'Login failed');
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    await _guestStorage.clear();
    state = state.copyWith(mode: AuthMode.loggedOut, error: null);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    final authService = ref.read(authServiceProvider);
    final guestStorage = ref.read(guestStorageProvider);
    return AuthController(authService, guestStorage);
  },
);
