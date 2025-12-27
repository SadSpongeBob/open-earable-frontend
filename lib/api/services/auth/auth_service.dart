import 'package:dio/dio.dart';
import 'package:openearable/api/client_dio.dart';
import '../../models/auth/auth_result.dart';
import 'auth_endpoints.dart';

class AuthService {
  /// LOGIN
  Future<AuthResult> login(String email, String password) async {
    try {
      final response = await dio.post(
        AuthEndpoints.login,
        data: {
          "email": email,
          "password": password,
        },
      );

      return AuthResult.success(response.data);
    } on DioException catch (e) {
      String errorMsg = "Login failed";

      if (e.response?.data is Map<String, dynamic>) {
        errorMsg = (e.response!.data["message"] ?? errorMsg).toString();
      }

      return AuthResult.error(errorMsg);
    } catch (e) {
      return AuthResult.error("An unexpected error occurred");
    }
  }

  /// signup
  Future<AuthResult> signup({
    required String name,
    required String email,
    required String password,
    required String downloadMethod,
  }) async {
    try {
      final response = await dio.post(
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
      String errorMsg = "Signup failed";

      if (e.response?.data is Map<String, dynamic>) {
        errorMsg = (e.response!.data["message"] ?? errorMsg).toString();
      }

      return AuthResult.error(errorMsg);
    } catch (e) {
      return AuthResult.error("An unexpected error occurred");
    }
  }
}
