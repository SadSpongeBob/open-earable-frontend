
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

class LocalMedia {
  static const videoName = 'video.mp4';
  static const thumbName = 'thumbnail.png';
  static const metaName = 'meta.json';
  static const defaultProjectId = 'default';

  final Directory baseDir;

  LocalMedia(this.baseDir);

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
  Future<Directory> exportDir(String recordingId) async {
    final baseExportDir = Directory(
      p.join(
        "/storage/emulated/0/Download",
        "OpenEarable",
      ),
    );
    await baseExportDir.create(recursive: true);
    final targetDir = Directory(
      p.join(baseExportDir.path, recordingId),
    );
    await targetDir.create(recursive: true);
    return targetDir;
  }
  static Future<LocalMedia> initLocalMedia() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(
      p.join(base.path, "OpenEarable"),
    );

    await dir.create(recursive: true);

    return LocalMedia(dir);
  }
}

final localMediaProvider = Provider<LocalMedia>((_) {
  throw UnimplementedError("localMediaProvider not overridden");
});
