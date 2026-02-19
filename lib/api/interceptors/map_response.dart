import 'package:dio/dio.dart';
import 'package:openearable/api/models/api_error.dart';

/// Dio interceptor that normalizes API responses and extracts errors.
///
/// - Automatically unwraps the `data` field from API responses if present, so that
///   `response.data` contains the actual payload instead of the wrapper object.
///
/// - Intercepts errors and attempts to parse an [ApiError] from the response body.
///   If successful, it attaches the [ApiError] to the request's `extra` map and
///   updates the error message.
class MapResponseInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final body = response.data;

    if (body is Map<String, dynamic> && body.containsKey('data')) {
      response.data = body['data'];
    }

    handler.next(response);
  }

  /// Called when a Dio error occurs.
  ///
  /// Attempts to parse an `ApiError` from the response body:
  /// 1. If the body is a JSON map with `message` or `errors`, it is converted to `ApiError`.
  /// 2. If the body has a `data` field that contains a JSON map, it is also parsed.
  ///
  /// If an `ApiError` is found, it is attached to `requestOptions.extra['apiError']`
  /// and the error message is updated.
  ///
  /// [err] The Dio exception.
  /// [handler] Used to continue or stop the error flow.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final raw = err.response?.data;

    ApiError? apiError;

    // Case 1: JSON map error: { message, errors }
    if (raw is Map<String, dynamic>) {
      apiError = _tryParseApiError(raw);
    }

    // Case 2: error wrapped: { data: { message, errors } }
    if (apiError == null &&
        raw is Map<String, dynamic> &&
        raw['data'] is Map<String, dynamic>) {
      apiError = _tryParseApiError(raw['data'] as Map<String, dynamic>);
    }

    if (apiError != null) {
      final updated = err.copyWith(message: apiError.toString());
      updated.requestOptions.extra['apiError'] = apiError;
      return handler.next(updated);
    }

    handler.next(err);
  }

  ApiError? _tryParseApiError(Map<String, dynamic> json) {
    if (json.containsKey('message') || json.containsKey('errors')) {
      return ApiError.fromJson(json);
    }
    return null;
  }
}

/// Extension methods on Dio [Response] to safely cast `response.data`.
extension ResponseGuards on Response<dynamic> {
  /// Converts the response data to a [Map<String, dynamic>].
  ///
  /// Throws a [DioException] if the data is not a Map.
  Map<String, dynamic> asMap() {
    final d = data;
    if (d is Map<String, dynamic>) return d;
    throw DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.badResponse,
      message: 'Expected Map<String, dynamic>, got ${d.runtimeType}',
      response: this,
    );
  }

  /// Converts the response data to a [List<dynamic>].
  ///
  /// Throws a [DioException] if the data is not a List.
  List<dynamic> asList() {
    final d = data;
    if (d is List) return d;
    throw DioException(
      requestOptions: requestOptions,
      type: DioExceptionType.badResponse,
      message: 'Expected List, got ${d.runtimeType}',
      response: this,
    );
  }
}
