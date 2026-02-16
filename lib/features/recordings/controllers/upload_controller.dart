import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/models/project/project_metadata.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/models/recording/sensor.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';
import 'package:openearable/api/models/recording/upload_recording_response.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/services/s3/s3_service.dart';
import 'package:openearable/api/services/user/user_preference_storage.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/home/state/network_status.dart';

class UploadController {
  final Ref ref;
  final LocalMedia localMedia;
  final RecordingService recordingService;
  final S3Service s3Service;
  final HomeStateNotifier homeStateNotifier;

  UploadController(
    this.ref,
    this.localMedia,
    this.recordingService,
    this.s3Service,
    this.homeStateNotifier,
  );

  Future<void> tryUploads() async {
    final projects = ref
        .read(homeStateProvider)
        .projects
        .where((p) => p.projectSource != ProjectSource.local)
        .toList();

    final recordingsByProject = await Future.wait(
      projects.map((p) async {
        final recs = await recordingService.getLocalProjectRecordings(p.id);
        return (projectId: p.id, recordings: recs);
      }),
    );

    for (final item in recordingsByProject) {
      for (final recording in item.recordings) {
        if (recording.isUploading || recording.isUploaded) continue;
        unawaited(uploadAndForget(recording.id, item.projectId));
      }
    }
  }

  Future<void> uploadAndForget(String recordingId, String projectId) async {
    final authState = ref.read(sessionProvider);
    if (authState.isGuest) return;

    ref.read(networkRefreshTriggerProvider.notifier).state++;
    final status = await waitForFirstData(
      ref,
      networkStatusProvider,
      useCache: false,
      timeout: const Duration(seconds: 2),
    ).catchError((_) => NetworkStatus.offline);

    if (status.isOffline ||
        !status.shouldUpload(
          await ref.read(userPreferenceStorage).isWifiOnly(),
        )) {
      return;
    }

    homeStateNotifier.updateRecording(
      id: recordingId,
      uploadStatus: UploadStatus.uploading,
    );

    final uploaded = await uploadRecording(
      recordingId: recordingId,
      projectId: projectId,
    );

    if (uploaded == null) {
      homeStateNotifier.updateRecording(
        id: recordingId,
        uploadStatus: UploadStatus.failed,
      );
      return;
    }

    homeStateNotifier.removeRecording(recordingId);

    homeStateNotifier.addRecording(uploaded);

    try {
      recordingService.deleteLocalRecording(
        projectId: projectId,
        recordingId: recordingId,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint("CLEANUP FAILED: recordingId: $recordingId, error: $e");
      }
      try {
        recordingService.updateLocalUploadStatus(
          projectId,
          recordingId,
          UploadStatus.failed,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            "UPDATE STATUS FAILED: recordingId: $recordingId, error: $e",
          );
        }
      }
    }
  }

  Future<Recording?> uploadRecording({
    required String recordingId,
    required String projectId,
    void Function(double progress)? onVideoProgress,
  }) async {
    final videoFile = localMedia.videoFile(projectId, recordingId);
    if (!await videoFile.exists()) return null;

    final metaFile = localMedia.recordingMetaFile(projectId, recordingId);
    if (!await metaFile.exists()) return null;

    late final Map<String, dynamic> meta;
    try {
      meta = jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }

    final name = meta['name'];
    final timestampRaw = meta['timestamp'];
    if (name is! String || timestampRaw is! String) return null;

    final ts =
        DateTime.tryParse(timestampRaw)?.toUtc() ??
        await _fallbackTimestampUtc(videoFile);

    String? recordingIdForLog;

    try {
      final thumbnail = localMedia.thumbnailFile(projectId, recordingId);
      final thumbnailExists = await thumbnail.exists();

      final sensors = await recordingService.getLocalRecordingSensors(
        projectId,
        recordingId,
      );

      final req = UploadRecordingRequest(
        name: name,
        video: RecordingFile(
          filename: videoFile.uri.pathSegments.last,
          contentType: ContentType.mp4,
          sizeBytes: await videoFile.length(),
          timestamp: ts,
        ),
        sensors: await sensors.map((s) => _mapToUpload(s)).wait,
        projectId: projectId == LocalMedia.defaultProjectId ? null : projectId,
        thumbnailContent: thumbnailExists ? ContentType.jpeg : null,
      );

      final uploadResp = await recordingService.startUpload(req);
      recordingIdForLog = uploadResp.recordingId;

      _uploadSensors(sensors, uploadResp.sensorUploads);

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
        _tryThumbnailUpload(
          thumbnail,
          uploadResp.thumbnailUpload!,
          recordingId,
          projectId,
          recordingIdForLog,
        );
      }

      return await recordingService.completeUpload(uploadResp.recordingId);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          "Upload failed local=$recordingId project=$projectId remote=$recordingIdForLog",
        );
        debugPrint("Status: ${e.response?.statusCode}");
        debugPrint("Body: ${e.response?.data}");
        debugPrint("Error: $e");
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          "Upload failed local=$recordingId project=$projectId remote=$recordingIdForLog",
        );
        debugPrint("Error: $e");
      }
      return null;
    }
  }

  Future<void> _uploadSensors(
    List<Sensor> sensors,
    List<SensorUploadInfo> sensorUploads,
  ) async {
    if (sensorUploads.length != sensors.length && kDebugMode) {
      throw StateError(
        "Sensor upload count mismatch local=${sensors.length} remote=${sensorUploads.length}",
      );
    }

    final Map<int, UploadInfo> lookup = {
      for (final u in sensorUploads) u.sensorIndex: u.sensor,
    };

    await Future.wait(
      sensors.map((s) async {
        final upload = lookup[s.sensorIndex];
        if (upload == null) {
          throw StateError(
            "Missing upload info for sensorIndex=${s.sensorIndex}",
          );
        }

        await s3Service.uploadFile(
          putUrl: upload.uploadUrl,
          file: File(s.localPath),
          headers: upload.requiredHeaders,
        );
      }),
    );
  }

  Future<void> _tryThumbnailUpload(
    File thumbnail,
    ThumbnailUploadInfo thumbnailUpload,
    String recordingId,
    String projectId,
    String recordingIdForLog,
  ) async {
    try {
      await s3Service.uploadFile(
        putUrl: thumbnailUpload.uploadUrl,
        file: thumbnail,
        headers: thumbnailUpload.requiredHeaders,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          "Thumbnail upload failed for local=$recordingId project=$projectId remote=$recordingIdForLog: $e",
        );
      }
    }
  }

  Future<DateTime> _fallbackTimestampUtc(File file) async {
    final stat = await file.stat();
    final modified = stat.modified.toUtc();
    final changed = stat.changed.toUtc();
    return changed.isBefore(modified) ? changed : modified;
  }

  Future<SensorUpload> _mapToUpload(Sensor sensor) async {
    final file = File(sensor.localPath);
    return SensorUpload(
      sensorIndex: sensor.sensorIndex,
      name: sensor.name,
      type: sensor.sensorType,
      file: RecordingFile(
        filename: file.uri.pathSegments.last,
        contentType: ContentType.json,
        sizeBytes: await file.length(),
        timestamp: sensor.timeStamp,
      ),
    );
  }
}

final uploadControllerProvider = Provider<UploadController>((ref) {
  final localMedia = ref.read(localMediaProvider);

  return UploadController(
    ref,
    localMedia,
    ref.read(recordingServiceProvider),
    ref.read(s3ServiceProvider),
    ref.read(homeStateProvider.notifier),
  );
});
