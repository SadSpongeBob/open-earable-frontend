import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/models/recording/get_recording_response.dart';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/api/interceptors/map_response.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/services/recording//recording_endpoints.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';
import 'package:openearable/api/models/recording/upload_recording_response.dart';

class RecordingService {
  final Dio _dio;
  final LocalMedia _localMedia;

  RecordingService({required Dio dio, required LocalMedia localMedia})
    : _dio = dio,
      _localMedia = localMedia;

  Future<UploadRecordingResponse> startUpload(
    UploadRecordingRequest req,
  ) async {
    final res = await _dio.post(RecordingEndpoints.base, data: req.toJson());
    return UploadRecordingResponse.fromJson(res.asMap());
  }

  Future<Recording> completeUpload(String recordingId) async {
    final res = await _dio.put(RecordingEndpoints.complete(recordingId));
    return Recording.fromJson(res.asMap());
  }

  Future<GetRecordingResponse> getRecording(String recordingId) async {
    final res = await _dio.get(RecordingEndpoints.recording(recordingId));
    return GetRecordingResponse.fromJson(res.asMap());
  }

  Future<Recording> getLocalRecording(
    String projectId,
    String recordingId,
  ) async {
    final videoFile = _localMedia.videoFile(projectId, recordingId);
    if (!await videoFile.exists()) {
      throw FileSystemException(
        "Video file for recording with recordingId: $recordingId not found",
      );
    }

    final metaFile = _localMedia.recordingMetaFile(projectId, recordingId);
    if (!await metaFile.exists()) {
      throw FileSystemException(
        "Meta file for recording with recordingId: $recordingId not found",
      );
    }

    Map<String, dynamic> meta;
    try {
      meta = jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      // corrupted metadata
      throw FileSystemException(
        "Recording with recordingId: $recordingId not found",
      );
    }
    final name = meta['name'] as String? ?? 'Recording - $recordingId';
    final timestampRaw = meta['timestamp'] as String?;
    final timestamp = timestampRaw != null
        ? DateTime.parse(timestampRaw).toUtc()
        : (await videoFile.lastModified()).toUtc();
    final uploadStatusRaw = meta['uploadStatus'] as String?;
    final uploadStatus = uploadStatusRaw != null
        ? UploadStatus.fromString(uploadStatusRaw)
        : UploadStatus.pending;

    final thumbFile = _localMedia.thumbnailFile(projectId, recordingId);

    return Recording.local(
      id: recordingId,
      name: name,
      localVideoPath: videoFile.path,
      localThumbnailPath: thumbFile.existsSync() ? thumbFile.path : null,
      videoTimestamp: timestamp,
      uploadStatus: uploadStatus,
      projectId: projectId == LocalMedia.defaultProjectId ? null : projectId,
    );
  }

  Future<void> deleteRecording(String recordingId) async {
    await _dio.delete(RecordingEndpoints.deleteRecording(recordingId));
  }

  Future<void> deleteLocalRecording(String projectId, String recordingId) async {
    final dir = _localMedia.recordingDir(projectId, recordingId);
    if (!await dir.exists()) return;

    await dir.delete(recursive: true);
  }

  Future<void> rename(String recordingId, String name) async {
    await _dio.put(
      RecordingEndpoints.rename(recordingId),
      data: {'name': name},
    );
  }

  Future<void> renameLocal({
    required String projectId,
    required String recordingId,
    required String newName,
  }) async {
    final metaFile = _localMedia.recordingMetaFile(projectId, recordingId);
    if (!await metaFile.exists()) {
      throw FileSystemException("Meta file not found", metaFile.path);
    }

    final raw = await metaFile.readAsString();
    final dynamic decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException("Meta file is not a JSON object");
    }

    decoded['name'] = newName;

    final tmp = File('${metaFile.path}.tmp');
    await tmp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(decoded),
      flush: true,
    );
    await tmp.rename(metaFile.path);
  }

  Future<void> updateLocalUploadStatus(
    String projectId,
    String recordingId,
    UploadStatus uploadStatus,
  ) async {
    final metaFile = _localMedia.recordingMetaFile(projectId, recordingId);
    if (!await metaFile.exists()) {
      throw FileSystemException("Meta file not found", metaFile.path);
    }

    final raw = await metaFile.readAsString();
    final dynamic decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException("Meta file is not a JSON object");
    }

    decoded['uploadStatus'] = uploadStatus.json;

    final tmp = File('${metaFile.path}.tmp');
    await tmp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(decoded),
      flush: true,
    );
    await tmp.rename(metaFile.path);
  }

  Future<List<Recording>> getRecordings() async {
    final res = await _dio.get(RecordingEndpoints.base);
    final data = res.asList();

    return data.map((r) => Recording.fromJson(r)).toList();
  }

  Future<List<Recording>> getLocalProjectRecordings(String projectId) async {
    final projectDir = _localMedia.projectDir(projectId);

    if (!await projectDir.exists()) return [];

    final recordings = <Recording>[];

    final entities = await projectDir.list(followLinks: false).toList();
    final recordingDirs = entities.whereType<Directory>();

    for (final recDir in recordingDirs) {
      final recordingId = p.basename(recDir.path);

      final Recording recording;
      try {
        recording = await getLocalRecording(projectId, recordingId);
      } on FileSystemException catch (e) {
        if (kDebugMode) {
          debugPrint(
            "Exception occurred while loading recording with id $recordingId: $e",
          );
        }
        continue;
      }

      recordings.add(recording);
    }
    recordings.sort((a, b) => b.videoTimestamp.compareTo(a.videoTimestamp));
    return recordings;
  }
}

final recordingServiceProvider = Provider<RecordingService>((ref) {
  final dio = ref.read(apiDioProvider);
  final localMedia = ref.read(localMediaProvider);
  return RecordingService(dio: dio, localMedia: localMedia);
});
