import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    final ts = DateTime.tryParse(timestampRaw)?.toUtc()
        ?? await _fallbackTimestampUtc(videoFile);


    String? recordingIdForLog;

    try {
      final thumbnail = localMedia.thumbnailFile(projectId, recordingId);
      final thumbnailExists = await thumbnail.exists();

      final req = UploadRecordingRequest(
        name: name,
        video: RecordingFile(
          filename: videoFile.uri.pathSegments.last,
          contentType: ContentType.mp4,
          sizeBytes: await videoFile.length(),
          timestamp: ts,
        ),
        sensors: const [],
        projectId: projectId == LocalMedia.defaultProjectId ? null : projectId,
        thumbnailContent: thumbnailExists ? ContentType.png : null,
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

      if (thumbnailExists && uploadResp.thumbnailUpload != null) {
        try {
          await s3Service.uploadFile(
            putUrl: uploadResp.thumbnailUpload!.uploadUrl,
            file: thumbnail,
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
        debugPrint("Error: $e");
      }
      return false;
    }
  }

  Future<DateTime> _fallbackTimestampUtc(File file) async {
    final stat = await file.stat();
    final modified = stat.modified.toUtc();
    final changed = stat.changed.toUtc();
    return changed.isBefore(modified) ? changed : modified;
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
