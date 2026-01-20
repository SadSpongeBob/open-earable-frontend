import 'dart:async';
import 'package:dio/dio.dart';
import 'package:openearable/api/services/auth/auth_endpoints.dart';
import 'package:openearable/api/services/auth/token_storage.dart';

class AttachTokenInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;

  AttachTokenInterceptor({required TokenStorage tokenStorage})
    : _tokenStorage = tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (_isAuthEndpoint(options.path)) {
      return handler.next(options);
    }

    final accessToken = await _tokenStorage.readAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }

  bool _isAuthEndpoint(String path) {
    const resetPrefix = '/api/auth/';
    const resetSuffix = '/reset-password';

    return path == AuthEndpoints.login ||
        path == AuthEndpoints.register ||
        path == AuthEndpoints.refresh ||
        (path.startsWith(resetPrefix) && path.endsWith(resetSuffix));
  }
}
