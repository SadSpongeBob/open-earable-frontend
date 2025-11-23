import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  // TODO: backend URL
  static const String baseUrl = "";

  /// LOGIN
  Future<AuthResult> login(String email, String password) async {
    final url = Uri.parse("$baseUrl/login");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      );

      if (response.statusCode == 200) {
        return AuthResult.success(jsonDecode(response.body));
      } else {
        return AuthResult.error(
          jsonDecode(response.body)["message"] ?? "Login failed",
        );
      }
    } catch (e) {
      return AuthResult.error("Network error: $e");
    }
  }

  /// SIGNUP
  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
    required String downloadMethod,
  }) async {
    final url = Uri.parse("$baseUrl/signup");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
          "downloadMethod": downloadMethod,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return AuthResult.success(jsonDecode(response.body));
      } else {
        return AuthResult.error(
          jsonDecode(response.body)["message"] ?? "Signup failed",
        );
      }
    } catch (e) {
      return AuthResult.error("Network error: $e");
    }
  }
}

/// Wrapper for login/signup result
class AuthResult {
  final bool success;
  final String? errorMessage;
  final dynamic data;

  AuthResult({
    required this.success,
    this.errorMessage,
    this.data,
  });

  factory AuthResult.success(dynamic data) {
    return AuthResult(success: true, data: data);
  }

  factory AuthResult.error(String message) {
    return AuthResult(success: false, errorMessage: message);
  }
}
