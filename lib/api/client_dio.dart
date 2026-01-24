import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/network_module.dart';
import 'package:openearable/api/services/auth/auth_service.dart';
import 'package:openearable/api/services/project/project_service.dart';
import 'package:openearable/api/services/user/user_service.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/api/services/auth/token_storage.dart';

final _networkModuleProvider = Provider<NetworkModule>((ref) {
  return NetworkModule.create(
    logout: () async {
      ref
          .read(sessionProvider.notifier)
          .setLoggedOut('Session expired. Please log in again.');
    },
  );
});

final apiDioProvider = Provider<Dio>((ref) {
  return ref.read(_networkModuleProvider).dio;
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return ref.read(_networkModuleProvider).tokenStorage;
});

final userServiceProvider = Provider<UserService>((ref) {
  return ref.read(_networkModuleProvider).userService;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return ref.read(_networkModuleProvider).authService;
});

final projectServiceProvider = Provider<ProjectService>((ref) {
  final dio = ref.read(apiDioProvider);
  return ProjectService(dioClient: dio);
});

final awsDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 120),
    ),
  );
});
