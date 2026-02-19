import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/client_dio.dart';

/// Service for uploading and downloading files to/from S3 using presigned URLs.
///
/// Provides methods for streaming large files efficiently with progress reporting
/// and supports cancellation via [CancelToken].
class S3Service {
  final Dio dio;

  /// Creates an [S3Service] instance using a [Dio] HTTP client.
  S3Service({required this.dio});

  /// Uploads a file to a presigned S3 PUT URL.
  ///
  /// [putUrl] is the presigned URL to upload the file to.
  /// [file] is the local file to be uploaded.
  /// [headers] additional HTTP headers required by the presigned request.
  /// [cancelToken] optional token to cancel the upload.
  /// [onProgress] optional callback reporting bytes sent and total bytes.
  ///
  /// Returns the [Response] from the S3 PUT request.
  ///
  /// Throws a [DioException] if the upload fails.
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

  /// Downloads a file from a presigned S3 GET URL to a local path.
  ///
  /// [getUrl] is the presigned URL to download the file from.
  /// [filePath] is the local path to save the downloaded file.
  /// [onProgress] optional callback reporting bytes received and total bytes.
  /// [cancelToken] optional token to cancel the download.
  ///
  /// Throws an [Exception] if the GET URL is expired or unauthorized (HTTP 403),
  /// or rethrows any other [DioException].
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

/// Riverpod provider for [S3Service].
///
/// Uses the preconfigured `awsDioProvider` as the HTTP client.
final s3ServiceProvider = Provider<S3Service>(
  (ref) => S3Service(dio: ref.read(awsDioProvider)),
);
