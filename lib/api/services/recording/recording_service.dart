import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/client_dio.dart';
import 'package:openearable/api/interceptors/map_response.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/services/recording//recording_endpoints.dart';

class RecordingService {
  final Dio _dio;
  final Directory _baseDir;
  static const unassignedProjectId = 'default';

  RecordingService({required Dio dio, Directory? baseDir})
    : _dio = dio,
      _baseDir =
          baseDir ?? Directory('/storage/emulated/0/Pictures/OpenEarable');

  Future<List<Recording>> getRecordings() async {
    final res = await _dio.get(RecordingEndpoints.baseUrl);
    final data = res.asList();

    return data.map((r) => Recording.fromJson(r)).toList();
  }

  Future<List<Recording>> getLocalProjectRecordings(String projectId) async {
    final projectDir = Directory(p.join(_baseDir.path, projectId));

    if (!await projectDir.exists()) return [];

    final recordings = <Recording>[];

    final entities = await projectDir.list(followLinks: false).toList();
    final recordingDirs = entities.whereType<Directory>();

    for (final recDir in recordingDirs) {
      final recordingId = p.basename(recDir.path);

      final videoFile = File(p.join(recDir.path, 'video.mp4'));
      if (!videoFile.existsSync()) continue;

      final metaFile = File(p.join(recDir.path, 'meta.json'));
      if (!metaFile.existsSync()) continue;

      Map<String, dynamic> meta;
      try {
        meta = jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
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

      final thumbFile = File(p.join(recDir.path, 'thumbnail.png'));

      recordings.add(
        Recording.local(
          id: recordingId,
          name: name,
          localVideoPath: videoFile.path,
          localThumbnailPath: thumbFile.existsSync() ? thumbFile.path : null,
          videoTimestamp: timestamp,
          projectId: projectId == unassignedProjectId ? null : projectId,
          userId: userId,
        ),
      );
    }
    recordings.sort((a, b) => b.videoTimestamp.compareTo(a.videoTimestamp));
    return recordings;
  }

  Future<List<Recording>> getLocalRecordings() async {
    return getLocalProjectRecordings(unassignedProjectId);
  }
}

final recordingServiceProvider = Provider<RecordingService>((ref) {
  final dio = ref.read(apiDioProvider);
  return RecordingService(dio: dio);
});
