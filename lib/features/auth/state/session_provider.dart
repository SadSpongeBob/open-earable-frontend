import 'package:flutter_riverpod/legacy.dart';
import 'package:openearable/api/models/auth/auth_state.dart';
import 'package:openearable/api/models/auth/user.dart';

/// A Riverpod [StateNotifierProvider] that exposes the current authentication
/// state of the app using [SessionNotifier].
///
/// This provider allows widgets and controllers to watch the user's session
/// state (authenticated, guest, logged out, or loading) and react accordingly.
final sessionProvider = StateNotifierProvider<SessionNotifier, AuthState>((
  ref,
) {
  return SessionNotifier();
});

/// Notifier that manages the authentication session state of the user.
///
/// Provides methods to update the session for authenticated users, guests,
/// loading state, or logging out. Also handles clearing and updating
/// errors related to authentication.
class SessionNotifier extends StateNotifier<AuthState> {

  /// Initializes the session with an initial state.
  SessionNotifier() : super(AuthState.initial());

  /// Sets the session to an authenticated state with the given [user].
  void setAuthenticated(User user) => state = state.copyWith(
    mode: AuthMode.authenticated,
    error: null,
    user: user,
  );

  /// Updates the current user data while keeping the existing session mode.
  void setUser(User user) => state = state.copyWith(
    mode: state.mode,
    error: null,
    user: user,
  );

  /// Clears the current user from the session while preserving the mode.
  void clearUser() => state = state.copyWith(
    mode: state.mode,
    error: null,
    user: null
  );

  /// Sets the session to a guest user mode.
  void setGuest() =>
      state = state.copyWith(mode: AuthMode.guest, error: null, user: null);

  /// Logs out the user and optionally sets an error [message].
  void setLoggedOut([String? message]) => state = state.copyWith(
    mode: AuthMode.loggedOut,
    error: message,
    user: null,
  );

  /// Sets the session state to loading while preserving the current user.
  void setLoading() => state = state.copyWith(
    mode: AuthMode.loading,
    error: null,
    user: state.user,
  );

  /// Clears any existing error messages in the session.
  void clearError() =>
      state = state.copyWith(mode: state.mode, error: null, user: state.user);
}
