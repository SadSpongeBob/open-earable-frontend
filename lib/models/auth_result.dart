class AuthResult {
  final bool success;
  final String? errorMessage;
  final dynamic data;

  const AuthResult({
    required this.success,
    this.errorMessage,
    this.data,
  });

  /// Success factory
  factory AuthResult.success(dynamic data) {
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
