import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/network_module.dart';
import 'package:openearable/api/services/auth/auth_service.dart';
import 'package:openearable/api/services/auth/token_storage.dart';

final _networkModuleProvider = Provider<NetworkModule>((ref) {
  return NetworkModule.create();
});

final apiDioProvider = Provider<Dio>((ref) {
  return ref.read(_networkModuleProvider).dio;
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return ref.read(_networkModuleProvider).tokenStorage;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return ref.read(_networkModuleProvider).authService;
});

final awsDioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 120),
    ),
  );
});
