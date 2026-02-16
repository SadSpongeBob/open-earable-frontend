import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/models/recording/sensor.dart';
import 'package:path/path.dart' as p;

import 'package:openearable/api/client_dio.dart';
import 'package:openearable/api/interceptors/map_response.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/models/recording/get_recording_response.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';
import 'package:openearable/api/models/recording/upload_recording_response.dart';
import 'package:openearable/api/services/recording/recording_endpoints.dart';

class RecordingService {
  RecordingService({required Dio dio, required LocalMedia localMedia})
    : _dio = dio,
      _localMedia = localMedia;

  final Dio _dio;
  final LocalMedia _localMedia;

  // =========================
  // Cloud
  // =========================

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

  Future<List<Recording>> getRecordings() async {
    final res = await _dio.get(RecordingEndpoints.base);
    final data = res.asList();
    return data.map((r) => Recording.fromJson(r)).toList();
  }

  Future<void> renameCloud({
    required String recordingId,
    required String name,
  }) async {
    await _dio.put(
      RecordingEndpoints.rename(recordingId),
      data: {'name': name},
    );
  }

  Future<void> deleteCloudRecording(String recordingId) async {
    await _dio.delete(RecordingEndpoints.deleteRecording(recordingId));
  }

  Future<List<Recording>> duplicateCloudRecordings({
    required List<String> recordingIds,
    String? projectId,
  }) async {
    final res = await _dio.post<dynamic>(
      '${RecordingEndpoints.base}/duplicate',
      data: {'recordingIds': recordingIds, 'projectId': ?projectId},
    );
    final list = res.asList();
    return list
        .map((e) => Recording.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // =========================
  // Local - Read
  // =========================

  Future<Recording> getLocalRecording(
    String projectId,
    String recordingId,
  ) async {
    final videoFile = _localMedia.videoFile(projectId, recordingId);
    if (!await videoFile.exists()) {
      throw FileSystemException(
        'Video file not found for recordingId=$recordingId',
        videoFile.path,
      );
    }

    final metaFile = _localMedia.recordingMetaFile(projectId, recordingId);
    if (!await metaFile.exists()) {
      throw FileSystemException(
        'Meta file not found for recordingId=$recordingId',
        metaFile.path,
      );
    }

    final meta = await _readJson(metaFile, recordingId);

    final name = (meta['name'] as String?)?.trim();
    final resolvedName = (name == null || name.isEmpty)
        ? 'Recording - $recordingId'
        : name;

    final timestamp = _readTimestampOrFallback(
      meta: meta,
      fallback: await videoFile.lastModified(),
    );

    final uploadStatusRaw = meta['uploadStatus'] as String?;
    final uploadStatus = uploadStatusRaw != null
        ? UploadStatus.fromString(uploadStatusRaw)
        : UploadStatus.pending;

    final thumbFile = _localMedia.thumbnailFile(projectId, recordingId);

    return Recording.local(
      id: recordingId,
      name: resolvedName,
      localVideoPath: videoFile.path,
      localThumbnailPath: await thumbFile.exists() ? thumbFile.path : null,
      videoTimestamp: timestamp,
      uploadStatus: uploadStatus,
      projectId: projectId == LocalMedia.defaultProjectId ? null : projectId,
    );
  }

  Future<List<Recording>> getLocalProjectRecordings(String projectId) async {
    final projectDir = _localMedia.projectDir(projectId);
    if (!await projectDir.exists()) return [];

    final entities = await projectDir.list(followLinks: false).toList();
    final recordingDirs = entities.whereType<Directory>();

    final recordings = <Recording>[];

    for (final dir in recordingDirs) {
      final recordingId = p.basename(dir.path);
      try {
        final rec = await getLocalRecording(projectId, recordingId);
        recordings.add(rec);
      } on FileSystemException catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to load local recording id=$recordingId: $e');
        }
      } on FormatException catch (e) {
        if (kDebugMode) {
          debugPrint('Corrupted meta for local recording id=$recordingId: $e');
        }
      }
    }

    recordings.sort((a, b) => b.videoTimestamp.compareTo(a.videoTimestamp));
    return recordings;
  }

  Future<List<Recording>> getLocalRecordings() async {
    return getLocalProjectRecordings(LocalMedia.defaultProjectId);
  }

  Future<List<Sensor>> getLocalRecordingSensors(
    String projectId,
    String recordingId,
  ) async {
    final directory = _localMedia.recordingDir(projectId, recordingId);
    final entities = await directory.list(followLinks: false).toList();
    final sensorDirs = entities.whereType<Directory>().toList()
      ..sort((a, b) => p.basename(a.path).compareTo(p.basename(b.path)));
    final sensors = <Sensor>[];
    int i = 0;
    for (final dir in sensorDirs) {
      final sensorFile = File(p.join(dir.path, LocalMedia.sensorDataName));
      if (!await sensorFile.exists()) continue;
      final json = await _readJson(sensorFile, recordingId);
      final name = (json['name'] as String?)?.trim();
      final tsRaw = json['timestamp'] as String?;
      final typeRaw = json['sensorType'] as String?;
      final DateTime timestamp = tsRaw == null
          ? (await sensorFile.lastModified()).toUtc()
          : DateTime.parse(tsRaw).toUtc();
      final SensorType sensorType;
      try {
        sensorType = SensorType.fromString(typeRaw ?? '');
      } catch (_) {
        continue;
      }
      sensors.add(
        Sensor(
          sensorIndex: i++,
          sensorId: p.basename(dir.path),
          name: (name == null || name.isEmpty) ? 'Sensor' : name,
          timeStamp: timestamp,
          sensorType: sensorType,
          localPath: sensorFile.path,
        ),
      );
    }
    return sensors;
  }

  // =========================
  // Local - Write
  // =========================

  Future<bool> deleteLocalRecording({
    required String projectId,
    required String recordingId,
  }) async {
    final dir = _localMedia.recordingDir(projectId, recordingId);
    if (!await dir.exists()) return false;
    await dir.delete(recursive: true);
    return true;
  }

  Future<void> renameLocal({
    required String projectId,
    required String recordingId,
    required String newName,
  }) async {
    final metaFile = _localMedia.recordingMetaFile(projectId, recordingId);
    if (!await metaFile.exists()) {
      throw FileSystemException('Meta file not found', metaFile.path);
    }

    final meta = await _readJson(metaFile, recordingId);
    meta['name'] = newName;

    await _atomicWriteJson(metaFile, meta);
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

    final decoded = await _readJson(metaFile, recordingId);

    decoded['uploadStatus'] = uploadStatus.json;

    await _atomicWriteJson(metaFile, decoded);
  }

  Future<bool> duplicateLocalRecording({
    required String projectId,
    required String sourceRecordingId,
    required String newRecordingId,
    required String newName,
  }) async {
    final srcDir = _localMedia.recordingDir(projectId, sourceRecordingId);
    if (!await srcDir.exists()) return false;

    final dstDir = _localMedia.recordingDir(projectId, newRecordingId);
    await dstDir.create(recursive: true);

    await _copyIfExists(
      _localMedia.videoFile(projectId, sourceRecordingId),
      _localMedia.videoFile(projectId, newRecordingId),
    );

    await _copyIfExists(
      _localMedia.thumbnailFile(projectId, sourceRecordingId),
      _localMedia.thumbnailFile(projectId, newRecordingId),
    );

    final srcMeta = _localMedia.recordingMetaFile(projectId, sourceRecordingId);
    final dstMeta = _localMedia.recordingMetaFile(projectId, newRecordingId);

    if (await srcMeta.exists()) {
      final meta = await _readJson(srcMeta, sourceRecordingId);
      meta['name'] = newName;
      await _atomicWriteJson(dstMeta, meta);
    }

    return true;
  }

  // =========================
  // Helpers
  // =========================

  Future<Map<String, dynamic>> _readJson(File file, String recordingId) async {
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException(
        'File is not a JSON object for recordingId=$recordingId',
      );
    }
    return decoded;
  }

  DateTime _readTimestampOrFallback({
    required Map<String, dynamic> meta,
    required DateTime fallback,
  }) {
    final raw = meta['timestamp'];
    if (raw is String) {
      try {
        return DateTime.parse(raw).toUtc();
      } catch (_) {}
    }
    return fallback.toUtc();
  }

  Future<void> _copyIfExists(File src, File dst) async {
    if (await src.exists()) {
      await src.copy(dst.path);
    }
  }

  Future<void> _atomicWriteJson(File file, Map<String, dynamic> json) async {
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(
      const JsonEncoder.withIndent('  ').convert(json),
      flush: true,
    );
    await tmp.rename(file.path);
  }
}

final recordingServiceProvider = Provider<RecordingService>((ref) {
  final dio = ref.read(apiDioProvider);
  final localMedia = ref.read(localMediaProvider);
  return RecordingService(dio: dio, localMedia: localMedia);
});
