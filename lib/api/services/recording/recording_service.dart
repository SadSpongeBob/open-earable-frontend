import 'dart:convert';
import 'dart:io';
import 'package:openearable/api/local_media.dart';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/api/interceptors/map_response.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/services/recording//recording_endpoints.dart';

class RecordingService {
  final Dio _dio;
  final LocalMedia _localMedia;

  RecordingService({required Dio dio, required LocalMedia localMedia})
    : _dio = dio,
      _localMedia = localMedia;

  Future<List<Recording>> getRecordings() async {
    final res = await _dio.get(RecordingEndpoints.baseUrl);
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

  Future<void> deleteCloudRecording(String recordingId) async {
    await _dio.delete('${RecordingEndpoints.baseUrl}/$recordingId/delete');
  }

  Future<List<Recording>> duplicateCloudRecordings({
    required List<String> recordingIds,
    String? projectId,
  }) async {
    final res = await _dio.post(
      '${RecordingEndpoints.baseUrl}/duplicate',
      data: {
        'recordingIds': recordingIds,
        if (projectId != null) 'projectId': projectId,
      },
    );

    final root = res.data;
    final data = root is Map<String, dynamic> ? root['data'] : root;

    if (data is! List) return const [];

    return data
        .map((e) => Recording.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final recordingServiceProvider = Provider<RecordingService>((ref) {
  final dio = ref.read(apiDioProvider);
  final localMedia = ref.read(localMediaProvider);
  return RecordingService(dio: dio, localMedia: localMedia);
});
