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
