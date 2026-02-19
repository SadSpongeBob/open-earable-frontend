import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openearable/api/interceptors/attach_token.dart';
import 'package:openearable/api/interceptors/map_response.dart';
import 'package:openearable/api/interceptors/refresh_token.dart';
import 'package:openearable/api/services/auth/auth_service.dart';
import 'package:openearable/api/services/auth/token_storage.dart';
import 'package:openearable/api/services/user/user_service.dart';

/// A centralized module for network communication and API services.
///
/// [NetworkModule] provides configured instances of:
/// - [Dio]: HTTP client with interceptors for attaching tokens, 
///   refreshing tokens, and mapping responses.
/// - [AuthService]: Handles authentication-related API calls and token refresh.
/// - [UserService]: Handles user-related API calls.
/// - [TokenStorage]: Handles secure storage of access and refresh tokens.
///
/// This module ensures all API requests are properly authorized, 
/// handles automatic token refresh, and maps server responses to usable formats.
class NetworkModule {
  /// Handles secure storage of access and refresh tokens.
  final TokenStorage tokenStorage;

  /// Configured HTTP client with base URL, timeouts, and interceptors.
  final Dio dio;

  /// Provides methods for user-related API operations.
  final UserService userService;

  /// Provides methods for authentication-related API operations.
  final AuthService authService;

  NetworkModule._({
    required this.tokenStorage,
    required this.dio,
    required this.authService,
    required this.userService,
  });

  /// Factory constructor to create a fully configured [NetworkModule].
  ///
  /// Parameters:
  /// - [logout]: Callback invoked when the user's session expires and they need to log in again.
  factory NetworkModule.create({required Future<void> Function() logout}) {
    final tokenStorage = TokenStorage();

    final dio = Dio(
      BaseOptions(
        baseUrl:
            dotenv.env['API_BASE_URL'] ??
            (throw Exception('API_BASE_URL not found in .env file')),
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        responseType: ResponseType.json,
        contentType: "application/json",
      ),
    );

    final userService = UserService(dio);
    final authService = AuthService(
      dio: dio,
      tokenStorage: tokenStorage,
      userService: userService,
    );

    dio.interceptors.addAll([
      AttachTokenInterceptor(tokenStorage: tokenStorage),
      RefreshTokenInterceptor(
        dio: dio,
        tokenStorage: tokenStorage,
        refresh: () => authService.refresh(),
        logout: logout,
      ),
      MapResponseInterceptor(),
    ]);

    return NetworkModule._(
      tokenStorage: tokenStorage,
      dio: dio,
      userService: userService,
      authService: authService,
    );
  }
}
