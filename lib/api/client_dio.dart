import 'package:dio/dio.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

final dio = Dio(
  BaseOptions(
    baseUrl: dotenv.env['API_BASE_URL'] ??
        (throw Exception('API_BASE_URL not found in .env file')),
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    contentType: "application/json",
  ),
);

