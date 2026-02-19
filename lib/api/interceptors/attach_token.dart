import 'dart:async';
import 'package:dio/dio.dart';
import 'package:openearable/api/services/auth/auth_endpoints.dart';
import 'package:openearable/api/services/auth/token_storage.dart';

/// Dio interceptor that automatically attaches an authorization token to HTTP requests.
///
/// Uses [TokenStorage] to read the current access token and attaches it as a Bearer
/// token in the `Authorization` header, unless:
/// - The request already provides an override token via `options.extra['authTokenOverride']`.
/// - The request targets authentication endpoints (login, register, refresh, or reset password).
///
/// This interceptor ensures that API requests requiring authentication include the token
/// without manually setting headers each time.
class AttachTokenInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;

  AttachTokenInterceptor({required TokenStorage tokenStorage})
    : _tokenStorage = tokenStorage;

  /// Called before a request is sent.
  ///
  /// - Checks if an override token is provided in `options.extra['authTokenOverride']`.
  ///   If so, it attaches that token and proceeds.
  /// - Skips attaching tokens for authentication endpoints (login, register, refresh, reset password).
  /// - Otherwise, reads the stored access token from [TokenStorage] and attaches it if available.
  ///
  /// [options] The request options, including path and headers.
  /// [handler] Handler to continue or stop the request.
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final override = options.extra['authTokenOverride'] as String?;
    if (override != null && override.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $override';
      return handler.next(options);
    }

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
    return path == AuthEndpoints.login ||
        path == AuthEndpoints.register ||
        path == AuthEndpoints.refresh ||
        (path.startsWith(AuthEndpoints.baseUrl) &&
            path.endsWith(AuthEndpoints.resetPasswordSuffix));
  }
}
