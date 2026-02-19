import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/network_module.dart';
import 'package:openearable/api/services/auth/auth_service.dart';
import 'package:openearable/api/services/user/user_service.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/api/services/auth/token_storage.dart';

/// Provides a configured [NetworkModule] for the app.
///
/// The [NetworkModule] encapsulates all network-related services and
/// handles session expiration via the `logout` callback.
final _networkModuleProvider = Provider<NetworkModule>((ref) {
  return NetworkModule.create(
    logout: () async {
      ref
          .read(sessionProvider.notifier)
          .setLoggedOut('Session expired. Please log in again.');
    },
  );
});

/// Provides a [Dio] instance configured with the app's main network module.
///
/// Use this [Dio] instance for API requests that require authentication
/// or custom headers managed by [NetworkModule].
final apiDioProvider = Provider<Dio>((ref) {
  return ref.read(_networkModuleProvider).dio;
});

/// Provides a [TokenStorage] instance for securely storing auth tokens.
///
/// This is used internally by [AuthService] and [NetworkModule] for
/// managing access/refresh tokens.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return ref.read(_networkModuleProvider).tokenStorage;
});

/// Provides a [UserService] instance for user-related API calls.
///
/// This service handles user profile retrieval, updates, and other
/// user-specific endpoints.
final userServiceProvider = Provider<UserService>((ref) {
  return ref.read(_networkModuleProvider).userService;
});

/// Provides an [AuthService] instance for authentication-related API calls.
///
/// This service handles login, signup, token refresh, and logout operations.
final authServiceProvider = Provider<AuthService>((ref) {
  return ref.read(_networkModuleProvider).authService;
});

/// Provides a standalone [Dio] instance for AWS or external services.
///
/// This instance is separate from the main [apiDioProvider] and is
/// configured with custom timeout options for AWS interactions.
final awsDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 120),
    ),
  );
});
