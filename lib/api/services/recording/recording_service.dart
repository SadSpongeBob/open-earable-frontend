import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:openearable/api/local_media.dart';
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
  Future<UploadRecordingResponse> startUpload(UploadRecordingRequest req) async {
    final res = await _dio.post(
      RecordingEndpoints.startUpload(),
      data: req.toJson(),
      options: Options(validateStatus: (status) => true),
    );
    final raw = res.asMap();
    return UploadRecordingResponse.fromJson(raw.containsKey('data') ? raw : {'data': raw});

  }
  Future<Recording> completeUpload(String recordingId) async {
    final res = await _dio.put(
      RecordingEndpoints.complete(recordingId),
      options: Options(validateStatus: (status) => true),
    );
    final raw = res.data;

    if (raw is Map<String, dynamic>) {
      if (raw.containsKey('data') && raw['data'] is Map<dynamic, dynamic>) {
        return Recording.fromJson(raw['data']);
      }
      try {
        return Recording.fromJson(raw);
      } catch (_) {
        throw Exception('completeUpload: unexpected data shape');
      }
    }

    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data') && decoded['data'] is Map<String, dynamic>) {
            return Recording.fromJson(decoded['data']);
          }
          return Recording.fromJson(decoded);
        }
      } catch (_) {
        throw Exception('completeUpload: failed to decode response');
      }
    }
    throw Exception('completeUpload: unexpected response type ${raw.runtimeType}');
  }

  Future<Recording> getRecording(String recordingId) async {
    final res = await _dio.get(RecordingEndpoints.recording(recordingId));
    return Recording.fromJson(res.data as Map<String, dynamic>);
  }
  Future<void> deleteRecording(String recordingId) async {
    await _dio.delete(RecordingEndpoints.deleteRecording(recordingId));
  }
  Future<void> rename(String recordingId, String name) async {
    await _dio.put(RecordingEndpoints.rename(recordingId), data: {'name': name});
    debugPrint('Renamed recording $recordingId to "$name"');
  }
  Future<void> duplicate(String recordingId) async {
    await _dio.post(RecordingEndpoints.duplicate(recordingId));
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

      final videoFile = _localMedia.videoFile(projectId, recordingId);
      if (!await videoFile.exists()) continue;

      final metaFile = _localMedia.recordingMetaFile(projectId, recordingId);
      if (!await metaFile.exists()) continue;

      Map<String, dynamic> meta;
      try {
        meta =
        jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
      } catch (_) {
        // corrupted metadata -> skip recording
        continue;
      }
      final name = meta['name'] as String? ?? 'Recording - $recordingId';
      final userId = meta['userId'] as String? ?? 'local';
      final timestampRaw = meta['timestamp'] as String?;
      final timestamp = timestampRaw != null
          ? DateTime.parse(timestampRaw).toUtc()
          : (await videoFile.lastModified()).toUtc();

      final thumbFile = _localMedia.thumbnailFile(projectId, recordingId);

      recordings.add(
        Recording.local(
          id: recordingId,
          name: name,
          localVideoPath: videoFile.path,
          localThumbnailPath: thumbFile.existsSync() ? thumbFile.path : null,
          videoTimestamp: timestamp,
          projectId: projectId == LocalMedia.defaultProjectId
              ? null
              : projectId,
          userId: userId,
        ),
      );
    }
    recordings.sort((a, b) => b.videoTimestamp.compareTo(a.videoTimestamp));
    return recordings;
  }

  Future<List<Recording>> getLocalRecordings() async {
    return getLocalProjectRecordings(LocalMedia.defaultProjectId);
  }
}

final recordingServiceProvider = Provider<RecordingService>((ref) {
  final dio = ref.read(apiDioProvider);
  final localMedia = ref.read(localMediaProvider);
  return RecordingService(dio: dio, localMedia: localMedia);
});
