import 'package:dio/dio.dart';
import 'package:openearable/api/interceptors/map_response.dart';
import 'package:openearable/api/models/auth/auth_tokens.dart';
import 'package:openearable/api/services/user/user_service.dart';

import 'auth_endpoints.dart';
import 'token_storage.dart';

/// Service class for user authentication and account management.
///
/// Handles login, registration, token refresh, password updates, and logout.
/// Uses [Dio] for network requests, [TokenStorage] for saving tokens,
/// and [UserService] for user-related operations.
class AuthService {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final UserService _userService;

  AuthService({
    required Dio dio,
    required TokenStorage tokenStorage,
    required UserService userService,
  }) : _dio = dio,
       _tokenStorage = tokenStorage,
       _userService = userService;

  /// Authenticates a user with [email] and [password].
  ///
  /// Saves the received tokens to [TokenStorage].
  ///
  /// Returns a [Tokens] object containing the access and refresh tokens.
  Future<Tokens> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post(
      AuthEndpoints.login,
      data: {'emailAddress': email, 'password': password},
    );

    final data = res.asMap();

    final tokens = Tokens.fromJson(data);
    await _tokenStorage.saveTokens(tokens);
    return tokens;
  }

  /// Refreshes authentication tokens using the stored refresh token.
  ///
  /// Throws a [StateError] if no refresh token is available.
  ///
  /// Returns a new [Tokens] object.
  Future<Tokens> refresh() async {
    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null) {
      throw StateError('No refresh token available');
    }

    final res = await _dio.post(
      AuthEndpoints.refresh,
      data: {'refreshToken': refreshToken},
    );

    final data = res.asMap();

    final tokens = Tokens.fromJson(data);

    await _tokenStorage.saveTokens(tokens);
    return tokens;
  }

  /// Registers a new user with [email], [password], and [name].
  ///
  /// Saves the received tokens to [TokenStorage].
  ///
  /// Returns a [Tokens] object.
  Future<Tokens> register({
    required String email,
    required String password,
    required String name,
  }) async {
    final res = await _dio.post(
      AuthEndpoints.register,
      data: {'emailAddress': email, 'password': password, 'name': name},
    );

    final data = res.asMap();
    final tokens = Tokens.fromJson(data);
    await _tokenStorage.saveTokens(tokens);
    return tokens;
  }

  /// Sends a request to reset the password for the user identified by [emailAddress].
  ///
  /// Does not return anything; the server typically sends an email to the user.
  Future<void> resetPassword({required String emailAddress}) async {
    await _dio.delete(AuthEndpoints.resetPassword(emailAddress));
  }

  /// Updates the user's password using the provided [authToken] for authentication.
  Future<void> updatePassword({
    required String password,
    required String authToken,
  }) async {
    final user = await _userService.getUser(authToken: authToken);

    await _dio.put(
      AuthEndpoints.update,
      data: {
        'emailAddress': user.emailAddress,
        'name': user.name,
        'password': password,
      },
      options: Options(extra: {'authTokenOverride': authToken}),
    );
  }

  /// Updates user information (email, name, optional password).
  Future<void> updateUser({
    required String emailAddress,
    required String name,
    String? password,
  }) async {
    await _dio.put(
      AuthEndpoints.update,
      data: {'emailAddress': emailAddress, 'name': name, 'password': password},
    );
  }

  /// Logs out the current user by clearing stored tokens.
  Future<void> logout() => _tokenStorage.clear();
}
