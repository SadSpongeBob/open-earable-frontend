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

/// Provides methods to upload recordings, their sensors, and thumbnails.
///
/// Properties:
/// - [ref]: Riverpod reference for accessing providers.
/// - [localMedia]: Access to local file storage for recordings and sensor data.
/// - [recordingService]: API service for interacting with the backend.
/// - [s3Service]: Handles direct S3 file uploads.
/// - [homeStateNotifier]: Notifies the app state about upload progress.
///
/// Usage:
/// - Call [tryUploads] to check for recordings that need uploading.
/// - Use [uploadAndForget] for background or fire-and-forget uploads.
/// - Use [uploadRecording] to perform a full upload and get a remote `Recording`.
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

  /// Checks all non-local projects for recordings that need to be uploaded.
  ///
  /// - Skips recordings that are already uploading or uploaded.
  /// - Initiates fire-and-forget uploads via [uploadAndForget] for each eligible recording.
  ///
  /// Side Effects:
  /// - Updates app state via [homeStateNotifier] to mark recordings as uploading.
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

  /// Uploads a single recording in a fire-and-forget manner.
  ///
  /// - Verifies the user is logged in (not a guest).
  /// - Checks network status and user preferences (Wi-Fi only uploads).
  /// - Marks recording as uploading in [homeStateNotifier].
  /// - Calls [uploadRecording] to perform the actual upload.
  /// - On success, replaces the local recording with the uploaded version.
  /// - Cleans up local files and handles errors by marking upload as failed.
  ///
  /// Parameters:
  /// - [recordingId]: The ID of the local recording.
  /// - [projectId]: The ID of the project containing the recording.
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

    homeStateNotifier.replaceRecording(
      oldId: recordingId,
      newRecording: uploaded,
    );

    try {
      await recordingService.deleteLocalRecording(
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

  /// Uploads a recording with its sensors and thumbnail.
  ///
  /// Parameters:
  /// - [recordingId]: Local recording ID.
  /// - [projectId]: Project ID containing the recording.
  /// - [onVideoProgress]: Optional callback to report video upload progress.
  ///
  /// Returns:
  /// - Remote [Recording] on success, null if upload fails or files are missing.
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

    final name = (meta['name'] as String?)?.trim();
    final timestampRaw = meta['timestamp'] as String?;
    if (name == null || name.isEmpty) return null;

    final ts =
        DateTime.tryParse(timestampRaw ?? '')?.toUtc() ??
            await _fallbackTimestampUtc(videoFile);

    String? recordingIdForLog;

    try {
      final sensors = await recordingService.getLocalRecordingSensors(
        projectId,
        recordingId,
      );

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
        sensors: await Future.wait(sensors.map(_mapToUpload)),
        projectId: projectId == LocalMedia.defaultProjectId ? null : projectId,
        thumbnailContent: thumbnailExists ? ContentType.jpeg : null,
      );

      final uploadResp = await recordingService.startUpload(req);
      recordingIdForLog = uploadResp.recordingId;

      await _uploadSensors(sensors, uploadResp.sensorUploads);

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
        await _tryThumbnailUpload(
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

  /// Returns a fallback UTC timestamp for a file based on its filesystem metadata.
  ///
  /// - Uses [FileStat.modified] and [FileStat.changed] and returns the earlier of the two.
  /// - Useful when the original video recording timestamp is missing or invalid.
  Future<DateTime> _fallbackTimestampUtc(File file) async {
    final stat = await file.stat();
    final modified = stat.modified.toUtc();
    final changed = stat.changed.toUtc();
    return changed.isBefore(modified) ? changed : modified;
  }

  /// Uploads all sensor data files associated with a recording.
  ///
  /// - Matches each local sensor with its upload info from the server.
  /// - Uploads files to S3 using [s3Service].
  /// - Throws a [StateError] if a file or upload info is missing.
  ///
  /// Parameters:
  /// - [sensors]: List of sensor objects with local paths.
  /// - [sensorUploads]: Corresponding upload information from the server.
  Future<void> _uploadSensors(
    List<Sensor> sensors,
    List<SensorUploadInfo> sensorUploads,
  ) async {
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

        final file = File(s.localPath);
        if (!await file.exists()) {
          throw StateError(
            "Missing sensor file for sensor with sensorId=${s.sensorId}, filePath=${s.localPath}",
          );
        }

        await s3Service.uploadFile(
          putUrl: upload.uploadUrl,
          file: file,
          headers: upload.requiredHeaders,
        );
      }),
    );
  }

  /// Attempts to upload the thumbnail image for a recording.
  ///
  /// - Uploads to S3 if a thumbnail exists and upload info is provided.
  /// - Logs errors in debug mode but does not throw.
  ///
  /// Parameters:
  /// - [thumbnail]: File object for the local thumbnail.
  /// - [thumbnailUpload]: Upload info from the server. 
  /// - [recordingId]: Local recording ID (for logging).
  /// - [projectId]: Project ID (for logging).
  /// - [recordingIdForLog]: Remote recording ID (optional, for logging).
  Future<void> _tryThumbnailUpload(
    File thumbnail,
    ThumbnailUploadInfo thumbnailUpload,
    String recordingId,
    String projectId,
    String? recordingIdForLog,
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

  /// Maps a local sensor file to a [SensorUpload] object for upload.
  ///
  /// - Reads local file size and timestamp.
  /// - Currently defaults sensor type to [SensorType.heartRate].
  /// - Returns a fully prepared [SensorUpload] object.
  ///
  /// Parameters:
  /// - [sensor]: Sensor object with local path and metadata.
  ///
  /// Returns:
  /// - [SensorUpload] ready to be sent to the server.
  Future<SensorUpload> _mapToUpload(Sensor sensor) async {
    final file = File(sensor.localPath);

    return SensorUpload(
      sensorIndex: sensor.sensorIndex,
      name: sensor.name,
      // no sensor type information provided -> setting heartRate as default
      type: SensorType.heartRate,
      file: RecordingFile(
        filename: file.uri.pathSegments.isNotEmpty
            ? file.uri.pathSegments.last
            : LocalMedia.sensorDataName,
        contentType: ContentType.json,
        sizeBytes: await file.length(),
        timestamp: sensor.timeStamp,
      ),
    );
  }
}

/// Provides a singleton instance of [UploadController] for the app.
///
/// Handles uploading recordings, sensors, and thumbnails to the cloud.
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
