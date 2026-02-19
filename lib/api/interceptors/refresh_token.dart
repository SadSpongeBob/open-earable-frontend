import 'dart:async';

import 'package:dio/dio.dart';
import 'package:openearable/api/models/auth/auth_tokens.dart';
import 'package:openearable/api/services/auth/auth_endpoints.dart';
import 'package:openearable/api/services/auth/token_storage.dart';

/// Internal representation of a request that failed with 401 and is waiting
/// for a refreshed token.
///
/// - [requestOptions] The original Dio request options.
/// - [completer] A Completer that will be completed once the request is retried.
class _QueuedRequest {
  final RequestOptions requestOptions;
  final Completer<Response<dynamic>> completer;

  _QueuedRequest(this.requestOptions, this.completer);
}

/// Interceptor that automatically refreshes the access token when a 401 (Unauthorized)
/// response is received, and retries the original request.
///
/// - Queues any concurrent requests that also fail with 401 while a token refresh is in progress.
/// - Retries all queued requests once the refresh is complete.
/// - If the refresh fails, calls the provided logout callback to clear session state.
class RefreshTokenInterceptor extends Interceptor {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  final Future<Tokens> Function() _refresh;
  final Future<void> Function() _logout;

  bool _isRefreshing = false;
  final List<_QueuedRequest> _queue = [];

  /// Creates a [RefreshTokenInterceptor].
  ///
  /// - [dio] The Dio instance used to retry requests.
  /// - [tokenStorage] Storage for access and refresh tokens.
  /// - [refresh] Callback that returns new tokens when the refresh token is valid.
  /// - [logout] Callback called when token refresh fails or is not possible.
  RefreshTokenInterceptor({
    required Dio dio,
    required TokenStorage tokenStorage,
    required Future<Tokens> Function() refresh,
    required Future<void> Function() logout,
  }) : _dio = dio,
       _tokenStorage = tokenStorage,
       _refresh = refresh,
       _logout = logout;

  /// Called when a Dio request fails.
  ///
  /// - If the response status code is 401, attempts to refresh the token and retry.
  /// - Skips auth endpoints and requests already retried.
  /// - Queues concurrent requests while refreshing.
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) return handler.next(err);

    final requestOptions = err.requestOptions;

    if (requestOptions.extra['__retried'] == true) return handler.next(err);

    if (_isAuthEndpoint(requestOptions.path)) return handler.next(err);

    final refreshToken = await _tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return handler.next(err);
    }

    try {
      final response = await _refreshAndRetry(requestOptions);
      return handler.resolve(response);
    } catch (_) {
      await _logout();
      return handler.next(err);
    }
  }

  bool _isAuthEndpoint(String path) {
    return path == AuthEndpoints.login ||
        path == AuthEndpoints.register ||
        path == AuthEndpoints.refresh ||
        (path.startsWith(AuthEndpoints.baseUrl) &&
            path.endsWith(AuthEndpoints.resetPasswordSuffix));
  }

  Future<Response<dynamic>> _refreshAndRetry(
    RequestOptions requestOptions,
  ) async {
    if (_isRefreshing) {
      final completer = Completer<Response<dynamic>>();
      _queue.add(_QueuedRequest(requestOptions, completer));
      return completer.future;
    }

    _isRefreshing = true;

    try {
      final tokens = await _refresh();
      final accessToken = tokens.accessToken;

      final firstResponse = await _retryRequest(requestOptions, accessToken);

      final queued = List<_QueuedRequest>.from(_queue);
      _queue.clear();
      _isRefreshing = false;

      for (final item in queued) {
        _retryRequest(item.requestOptions, accessToken)
            .then(item.completer.complete)
            .catchError(item.completer.completeError);
      }

      return firstResponse;
    } catch (exception) {
      final queued = List<_QueuedRequest>.from(_queue);
      _queue.clear();
      _isRefreshing = false;

      // Fail all queued requests
      for (final item in queued) {
        item.completer.completeError(exception);
      }

      rethrow;
    }
  }

  Future<Response<dynamic>> _retryRequest(
    RequestOptions requestOptions,
    String? accessToken,
  ) {
    final headers = Map<String, dynamic>.from(requestOptions.headers);
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final options = Options(
      method: requestOptions.method,
      headers: headers,
      responseType: requestOptions.responseType,
      contentType: requestOptions.contentType,
      sendTimeout: requestOptions.sendTimeout,
      receiveTimeout: requestOptions.receiveTimeout,
      extra: <String, dynamic>{...requestOptions.extra, '__retried': true},
      followRedirects: requestOptions.followRedirects,
      validateStatus: requestOptions.validateStatus,
      receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
    );

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: options,
      cancelToken: requestOptions.cancelToken,
      onReceiveProgress: requestOptions.onReceiveProgress,
      onSendProgress: requestOptions.onSendProgress,
    );
  }
}
