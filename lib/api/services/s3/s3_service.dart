import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/client_dio.dart';

class S3Service {
  final Dio dio;

  S3Service({required this.dio});

  Future<Response> uploadFile({
    required String putUrl,
    required File file,
    required Map<String, String> headers,
    CancelToken? cancelToken,
    void Function(int sent, int total)? onProgress,
  }) async {
    final length = await file.length();
    return dio.put(
      putUrl,
      data: file.openRead(),
      options: Options(
        headers: {...headers, 'Content-Length': length.toString()},
        responseType: ResponseType.plain,
        sendTimeout: const Duration(minutes: 10),
        receiveTimeout: const Duration(minutes: 10),
      ),
      onSendProgress: onProgress,
      cancelToken: cancelToken,
    );
  }

  Future<void> downloadToFile({
    required String getUrl,
    required String filePath,
    void Function(int received, int total)? onProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      await dio.download(
        getUrl,
        filePath,
        onReceiveProgress: onProgress,
        cancelToken: cancelToken,
        options: Options(
          receiveTimeout: const Duration(minutes: 10),
          sendTimeout: const Duration(minutes: 10),
        ),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 403) {
        throw Exception('Presigned GET URL expired or not authorized.');
      }
      rethrow;
    }
  }
}

final s3ServiceProvider = Provider<S3Service>(
  (ref) => S3Service(dio: ref.read(awsDioProvider)),
);
