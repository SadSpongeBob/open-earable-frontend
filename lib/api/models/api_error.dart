class ApiError {
  final String message;
  final List<String> errors;

  ApiError({required this.message, required this.errors});

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
