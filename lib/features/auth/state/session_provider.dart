import 'package:flutter_riverpod/legacy.dart';
import 'package:openearable/api/models/auth/auth_state.dart';
import 'package:openearable/api/models/auth/user.dart';

final sessionProvider = StateNotifierProvider<SessionNotifier, AuthState>((
  ref,
) {
  return SessionNotifier();
});

class SessionNotifier extends StateNotifier<AuthState> {
  SessionNotifier() : super(AuthState.initial());

  void setAuthenticated(User user) => state = state.copyWith(
    mode: AuthMode.authenticated,
    error: null,
    user: user,
  );

  void setGuest() =>
      state = state.copyWith(mode: AuthMode.guest, error: null, user: null);

  void setLoggedOut([String? message]) => state = state.copyWith(
    mode: AuthMode.loggedOut,
    error: message,
    user: null,
  );

  void setLoading() => state = state.copyWith(
    mode: AuthMode.loading,
    error: null,
    user: state.user,
  );

  void clearError() =>
      state = state.copyWith(mode: state.mode, error: null, user: state.user);
}
