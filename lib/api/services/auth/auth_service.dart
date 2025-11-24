import 'package:dio/dio.dart';

import '../../../models/auth_result.dart';
import '../../client.dart';
import 'auth_endpoints.dart';

class AuthService {
  final Dio _dio = Client.dio;

  /// LOGIN
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await _dio.post(
        AuthEndpoints.login,
        data: {
          "email": email,
          "password": password,
        },
      );

      return AuthResult.success(response.data);
    } on DioException catch (e) {
      return AuthResult.error(
        e.response?.data["message"] ?? "Login failed",
      );
    }
  }

  /// SIGNUP
  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
    required String downloadMethod,
  }) async {
    try {
      final response = await _dio.post(
        AuthEndpoints.signup,
        data: {
          "name": name,
          "email": email,
          "password": password,
          "downloadMethod": downloadMethod,
        },
      );

      return AuthResult.success(response.data);
    } on DioException catch (e) {
      return AuthResult.error(
        e.response?.data["message"] ?? "Signup failed",
      );
    }
  }
}
