import 'package:openearable/api/models/auth/user.dart';

/// Represents the different authentication states of the app/user.
///
/// - [loading]: Authentication status is being determined (e.g., checking tokens).
/// - [loggedOut]: User is not authenticated.
/// - [guest]: User is using the app in guest mode.
/// - [authenticated]: User is successfully logged in.
enum AuthMode { loading, loggedOut, guest, authenticated }

/// Holds the current authentication state of the application.
///
/// This class is used to track whether the user is logged in, logged out,
/// a guest, or if authentication is currently loading. It also stores
/// optional user information and error messages.
/// 
/// Parameters:
/// - [mode]: The current mode of authentication.
/// - [error]: Optional error message, typically set when authentication fails.
/// - [user]: Optional user information when [mode] is [AuthMode.authenticated].
class AuthState {
  final AuthMode mode;
  final String? error;
  final User? user;

  const AuthState({required this.mode, this.error, this.user});

  /// Returns true if authentication is currently loading.
  bool get isLoading => mode == AuthMode.loading;

  /// Returns true if the user is a guest.
  bool get isGuest => mode == AuthMode.guest;

  /// Returns true if the user is authenticated.
  bool get isAuthenticated => mode == AuthMode.authenticated;

  /// Returns true if the user is logged out.
  bool get isLoggedOut => mode == AuthMode.loggedOut;


  /// Creates the initial authentication state.
  factory AuthState.initial() => const AuthState(mode: AuthMode.loading);

  /// Creates a copy of this [AuthState] with optional updated fields.
  AuthState copyWith({AuthMode? mode, String? error, User? user}) =>
      AuthState(mode: mode ?? this.mode, error: error, user: user);
}
