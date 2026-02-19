/// A generic wrapper for authentication results.
///
/// Represents the outcome of an authentication operation, such as login,
/// registration, or token refresh. It contains:
/// - [success]: whether the operation succeeded,
/// - [errorMessage]: an optional message if the operation failed,
/// - [data]: the returned data on success (e.g., user info or tokens).
class AuthResult<T> {
  final bool success;
  final String? errorMessage;
  final T? data;

  const AuthResult({
    required this.success,
    this.errorMessage,
    this.data,
  });

  /// Success factory
  factory AuthResult.success(T data) {
    return AuthResult(
      success: true,
      data: data,
    );
  }

  /// Error factory
  factory AuthResult.error(String message) {
    return AuthResult(
      success: false,
      errorMessage: message,
    );
  }
}
