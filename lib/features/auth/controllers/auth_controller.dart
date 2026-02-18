import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/api/services/auth/auth_service.dart';
import 'package:openearable/api/services/auth/guest_storage.dart';
import 'package:openearable/api/services/user/user_service.dart';
import 'package:openearable/app/ui/toast_controller.dart';
import 'package:openearable/app/ui/toast_event.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/home/state/network_status.dart';

/// Controller responsible for managing all authentication flows in the app.
///
/// Handles user signup, login, guest login, logout, and session bootstrapping.
/// Interacts with [AuthService], [UserService], and [GuestStorage] to maintain
/// the user's session state. Updates UI feedback through [ToastEvent] notifications.
class AuthController {
  final AuthService _authService;
  final GuestStorage _guestStorage;
  final SessionNotifier _session;
  final UserService _userService;
  final HomeStateNotifier _homeState;
  final StateController<ToastEvent?> _toast;
  final Ref _ref;

  AuthController(
      this._authService,
      this._userService,
      this._guestStorage,
      this._session,
      this._homeState,
      this._toast,
      this._ref,
      );

  /// Initializes the user session on app start.
  ///
  /// Checks if the user is a guest, if network is available, and refreshes
  /// the authenticated session if necessary. Updates [SessionNotifier] accordingly.
  Future<void> bootstrap() async {
    _session.setLoading();

    try {
      if (await _guestStorage.isGuest()) {
        _session.setGuest();
        return;
      }

      final status = await waitForFirstData(
        _ref,
        networkStatusProvider,
        timeout: const Duration(seconds: 2),
      ).catchError((_) => NetworkStatus.offline);

      if (status.isOffline) {
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

  /// Registers a new user account with name, email and password.
  ///
  /// Updates the session to authenticated upon success, or triggers a toast
  /// notification on failure.
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
      _toast.state = ToastEvent.error(e.message ?? 'Sign up failed');
    } catch (_) {
      _session.setLoggedOut('Sign up failed');
      _toast.state = const ToastEvent.error('Sign up failed');
    }
  }

  /// Logs in an existing user using email and password.
  ///
  /// Updates the session and triggers toast notifications on failure.
  Future<void> login({required String email, required String password}) async {
    _session.setLoading();
    try {
      await _authService.login(email: email, password: password);
      await _guestStorage.clear();
      final user = await _userService.getUser();
      _session.setAuthenticated(user);
    } on DioException catch (exception) {
      _session.setLoggedOut(exception.message);
      _toast.state = ToastEvent.error(exception.message ?? 'Login failed');
    } catch (_) {
      _session.setLoggedOut('Login failed');
      _toast.state = const ToastEvent.error('Login failed');
    }
  }

  /// Initiates a guest session.
  ///
  /// Logs out any current session and sets the guest flag in storage.
  Future<void> guestLogin() async {
    await _authService.logout();
    await _guestStorage.setGuest(true);
    _session.setGuest();
  }

  /// Logs out the current user and clears all relevant session data.
  ///
  /// Optionally accepts a [message] to show as a toast notification after logout.
  Future<void> logout({String? message}) async {
    await _authService.logout();
    await _guestStorage.clear();
    _homeState.setProjectsLoaded(false);
    _session.setLoggedOut(message);
  }
}

/// Provider for [AuthController], exposing it to the app.
final authControllerProvider = Provider<AuthController>((ref) {
  final authService = ref.read(authServiceProvider);
  final userService = ref.read(userServiceProvider);
  final session = ref.read(sessionProvider.notifier);
  final guestStorage = ref.read(guestStorageProvider);
  final homeState = ref.read(homeStateProvider.notifier);
  final toast = ref.read(toastProvider.notifier);

  return AuthController(
    authService,
    userService,
    guestStorage,
    session,
    homeState,
    toast,
    ref,
  );
});
