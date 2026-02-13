import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/services/s3/s3_service.dart';

class UploadController {
  final LocalMedia localMedia;
  final RecordingService recordingService;
  final S3Service s3Service;

  UploadController(this.localMedia, this.recordingService, this.s3Service);

  Future<bool> uploadRecording({
    required String recordingId,
    required String projectId,
    void Function(double progress)? onVideoProgress,
  }) async {
    final videoFile = localMedia.videoFile(projectId, recordingId);
    if (!await videoFile.exists()) return false;

    final metaFile = localMedia.recordingMetaFile(projectId, recordingId);
    if (!await metaFile.exists()) return false;

    late final Map<String, dynamic> meta;
    try {
      meta = jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return false;
    }

    final name = meta['name'];
    final timestampRaw = meta['timestamp'];
    if (name is! String || timestampRaw is! String) return false;

    Directory? tempDir;
    File? thumbFile;

    String? recordingIdForLog;

    try {
      final thumbBytes = await generateThumbnail(videoFile.path);
      if (thumbBytes != null) {
        tempDir = await Directory.systemTemp.createTemp();
        thumbFile = File("${tempDir.path}/${LocalMedia.thumbName}");
        await thumbFile.writeAsBytes(thumbBytes);
      }

      final req = UploadRecordingRequest(
        name: name,
        video: RecordingFile(
          filename: videoFile.uri.pathSegments.last,
          contentType: ContentType.mp4,
          sizeBytes: await videoFile.length(),
          timestamp: DateTime.parse(timestampRaw).toUtc(),
        ),
        sensors: const [],
        projectId: projectId == LocalMedia.defaultProjectId ? null : projectId,
        thumbnailContent: thumbFile != null ? ContentType.jpeg : null,
      );

      final uploadResp = await recordingService.startUpload(req);
      recordingIdForLog = uploadResp.recordingId;

      await s3Service.uploadFile(
        putUrl: uploadResp.videoUpload.uploadUrl,
        file: videoFile,
        headers: uploadResp.videoUpload.requiredHeaders,
        onProgress: (sent, total) {
          if (onVideoProgress != null && total > 0) {
            onVideoProgress(sent / total);
          }
        },
      );

      if (uploadResp.thumbnailUpload != null && thumbFile != null) {
        try {
          await s3Service.uploadFile(
            putUrl: uploadResp.thumbnailUpload!.uploadUrl,
            file: thumbFile,
            headers: uploadResp.thumbnailUpload!.requiredHeaders,
          );
        } catch (e) {
          if (kDebugMode) {
            debugPrint(
              "Thumbnail upload failed for local=$recordingId project=$projectId remote=$recordingIdForLog: $e",
            );
          }
        }
      }

      await recordingService.completeUpload(uploadResp.recordingId);
      return true;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          "Upload failed local=$recordingId project=$projectId remote=$recordingIdForLog",
        );
        debugPrint("Status: ${e.response?.statusCode}");
        debugPrint("Body: ${e.response?.data}");
        debugPrint("Error: $e");
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          "Upload failed local=$recordingId project=$projectId remote=$recordingIdForLog",
        );
      }
      return false;
    } finally {
      try {
        if (tempDir != null && await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      } catch (_) {}
    }
  }

  Future<Uint8List?> generateThumbnail(String videoPath) {
    return vt.VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: vt.ImageFormat.JPEG,
      maxWidth: 512,
      quality: 75,
    );
  }
}

final uploadControllerProvider = Provider<UploadController>((ref) {
  final localMedia = ref.read(localMediaProvider);

  return UploadController(
    localMedia,
    ref.read(recordingServiceProvider),
    ref.read(s3ServiceProvider),
  );
});
