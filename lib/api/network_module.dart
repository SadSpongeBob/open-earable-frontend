import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:openearable/api/interceptors/attach_token.dart';
import 'package:openearable/api/interceptors/map_response.dart';
import 'package:openearable/api/interceptors/refresh_token.dart';
import 'package:openearable/api/services/auth/auth_service.dart';
import 'package:openearable/api/services/auth/token_storage.dart';

class NetworkModule {
  final TokenStorage tokenStorage;
  final Dio dio;
  final AuthService authService;

  NetworkModule._({
    required this.tokenStorage,
    required this.dio,
    required this.authService,
  });

  factory NetworkModule.create() {
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

    final authService = AuthService(dio: dio, tokenStorage: tokenStorage);

    dio.interceptors.addAll([
      AttachTokenInterceptor(tokenStorage: tokenStorage),
      RefreshTokenInterceptor(
        dio: dio,
        tokenStorage: tokenStorage,
        refresh: () => authService.refresh(),
      ),
      MapResponseInterceptor(),
    ]);

    return NetworkModule._(
      tokenStorage: tokenStorage,
      dio: dio,
      authService: authService,
    );
  }
}
