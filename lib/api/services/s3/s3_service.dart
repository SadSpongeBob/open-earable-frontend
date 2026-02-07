import 'dart:async';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class S3Service {
  S3Service({Dio? dio}) : _dio = dio ?? Dio();
  final Dio _dio;
  Future<void> put(String url, Map<String, String> headers, Uint8List bytes) async {
    await _dio.put(
      url,
      data: bytes,
      options: Options(
        headers: headers,
      ),
    );
  }
  Future<void> downloadToFile(String url, String filePath) async {
    await _dio.download(
      url,
      filePath,
    );
  }
}

final s3ServiceProvider = Provider<S3Service>((ref) => S3Service());
