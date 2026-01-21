import 'package:dio/dio.dart';
import 'package:openearable/api/models/api_error.dart';

class MapResponseInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final body = response.data;

    if (body is Map<String, dynamic> && body.containsKey('data')) {
      response.data = body['data'];
    }

    handler.next(response);
  }

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
