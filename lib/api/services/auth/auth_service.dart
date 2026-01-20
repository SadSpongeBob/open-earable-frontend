import 'package:dio/dio.dart';
import 'package:openearable/api/models/auth/auth_tokens.dart';

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

    final data = requireMap(res);

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

    final data = requireMap(res);

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

    final data = requireMap(res);
    final tokens = Tokens.fromJson(data);
    await _tokenStorage.saveTokens(tokens);
    return tokens;
  }

  Future<void> resetPassword({
    required String emailAddress
  }) async {
    await _dio.delete(
      AuthEndpoints.resetPassword(emailAddress),
    );
  }

  Future<void> logout() => _tokenStorage.clear();

  Map<String, dynamic> requireMap(Response<dynamic> res) {
    final data = res.data;
    if (data is Map<String, dynamic>) return data;

    throw DioException(
      requestOptions: res.requestOptions,
      message: 'Invalid response format',
    );
  }
}
