import 'package:openearable/api/models/auth/user.dart';

enum AuthMode { loading, loggedOut, guest, authenticated }

class AuthState {
  final AuthMode mode;
  final String? error;
  final User? user;

  const AuthState({required this.mode, this.error, this.user});

  bool get isLoading => mode == AuthMode.loading;

  bool get isGuest => mode == AuthMode.guest;

  bool get isAuthenticated => mode == AuthMode.authenticated;

  bool get isLoggedOut => mode == AuthMode.loggedOut;

  factory AuthState.initial() => const AuthState(mode: AuthMode.loading);

  AuthState copyWith({AuthMode? mode, String? error, User? user}) =>
      AuthState(mode: mode ?? this.mode, error: error, user: user);
}
