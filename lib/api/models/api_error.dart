/// Represents an error returned by the API, including a human-readable message
/// and an optional list of detailed error strings.
///
/// Parameters:
/// - [message]: The main error message describing the failure.
/// - [errors]: Optional list of detailed error messages from the API.
class ApiError {
  final String message;
  final List<String> errors;

  ApiError({required this.message, required this.errors});

  /// Creates an [ApiError] instance from a JSON map returned by the API.
  ///
  /// - `message` → [message], defaults to 'Request failed' if missing.
  /// - `errors` → [errors], defaults to an empty list if missing.
  factory ApiError.fromJson(Map<String, dynamic> json) {
    final msg = (json['message'] as String?) ?? 'Request failed';
    final errs =
        (json['errors'] as List?)?.whereType<String>().toList(
          growable: false,
        ) ??
        const <String>[];
    return ApiError(message: msg, errors: errs);
  }

  @override
  String toString() {
    return message;
  }
}
