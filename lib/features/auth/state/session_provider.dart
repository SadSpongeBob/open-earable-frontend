import 'package:flutter_riverpod/legacy.dart';
import 'package:openearable/api/models/auth/auth_state.dart';

final sessionProvider = StateNotifierProvider<SessionNotifier, AuthState>((
  ref,
) {
  return SessionNotifier();
});

class SessionNotifier extends StateNotifier<AuthState> {
  SessionNotifier() : super(AuthState.initial());

  void setMode(AuthMode mode) =>
      state = state.copyWith(mode: mode, error: null);

  void setLoggedOut([String? message]) =>
      state = state.copyWith(mode: AuthMode.loggedOut, error: message);

  void setLoading() =>
      state = state.copyWith(mode: AuthMode.loading, error: null);

  void clearError() => state = state.copyWith(error: null);
}
