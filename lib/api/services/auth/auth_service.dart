import 'package:dio/dio.dart';
import 'package:openearable/api/interceptors/map_response.dart';
import 'package:openearable/api/models/auth/auth_tokens.dart';
import 'package:openearable/api/models/auth/user.dart';

import 'auth_endpoints.dart';
import 'token_storage.dart';

class AuthService {
  final Dio _dio;
  final TokenStorage _tokenStorage;

  AuthService({required Dio dio, required TokenStorage tokenStorage})
    : _dio = dio,
      _tokenStorage = tokenStorage;

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

  Future<void> resetPassword({required String emailAddress}) async {
    await _dio.delete(AuthEndpoints.resetPassword(emailAddress));
  }

  Future<void> updatePassword({
    required String password,
    required String authToken,
  }) async {
    final user = await getUser(authToken: authToken);

    await _dio.put(
      AuthEndpoints.update,
      data: {
        'emailAddress': user.emailAddress,
        'name': user.name,
        'password': password
      },
      options: Options(extra: {'authTokenOverride': authToken}),
    );
  }

  Future<User> getUser({String? authToken}) async {
    Options? options;
    if (authToken != null && authToken.isNotEmpty) {
      options = Options(extra: {'authTokenOverride': authToken});
    }

    final res = await _dio.get(AuthEndpoints.baseUrl, options: options);

    final data = res.asMap();
    final user = User.fromJson(data);
    return user;
  }

  Future<void> logout() => _tokenStorage.clear();
}
