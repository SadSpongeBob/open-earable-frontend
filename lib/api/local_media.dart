import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class LocalMedia {
  static const videoName = 'video.mp4';
  static const thumbName = 'thumbnail.jpeg';
  static const metaName = 'meta.json';
  static const sensorDataName = 'sensors.json';
  static const defaultProjectId = 'default';

  final Directory baseDir;
  final Directory exportDir;
  final Directory tempDir;

  LocalMedia(this.baseDir, this.exportDir, this.tempDir);

  Directory defaultProjectDir() =>
      Directory(p.join(baseDir.path, defaultProjectId));

  Directory projectDir(String projectId) =>
      Directory(p.join(baseDir.path, projectId));

  File projectMetaFile(String projectId) =>
      File(p.join(baseDir.path, projectId, metaName));

  Directory recordingDir(String projectId, String recordingId) =>
      Directory(p.join(baseDir.path, projectId, recordingId));

  File videoFile(String projectId, String recordingId) =>
      File(p.join(baseDir.path, projectId, recordingId, videoName));

  File thumbnailFile(String projectId, String recordingId) =>
      File(p.join(baseDir.path, projectId, recordingId, thumbName));

  File recordingMetaFile(String projectId, String recordingId) =>
      File(p.join(baseDir.path, projectId, recordingId, metaName));

  File recordingSensors(
    String projectId,
    String recordingId,
    String sensorId,
  ) => File(
    p.join(baseDir.path, projectId, recordingId, sensorId, sensorDataName),
  );

  File recordingTempSensors(String sensorId) =>
      File(p.join(tempDir.path, sensorId));

  Directory recordingExportDir(String recordingId) =>
      Directory(p.join(exportDir.path, recordingId));

  File videoExportFile(String recordingId) =>
      File(p.join(exportDir.path, recordingId, videoName));

  File sensorExportFile(
    String recordingId,
    String sensorId,
    String sensorName,
  ) => File(p.join(exportDir.path, recordingId, sensorId, "$sensorName.json"));

  static Future<LocalMedia> initLocalMedia() async {
    final base = await getApplicationDocumentsDirectory();
    final baseDir = Directory(p.join(base.path, "OpenEarable"));
    final export = Directory("/storage/emulated/0/Download");
    final exportDir = Directory(p.join(export.path, "OpenEarable"));
    final temp = await getTemporaryDirectory();
    final tempDir = Directory(p.join(temp.path, "OpenEarable"));

    await baseDir.create(recursive: true);
    await exportDir.create(recursive: true);
    await tempDir.create(recursive: true);

    return LocalMedia(baseDir, exportDir, tempDir);
  }
}

final localMediaProvider = Provider<LocalMedia>((_) {
  throw UnimplementedError("localMediaProvider not overridden");
});
