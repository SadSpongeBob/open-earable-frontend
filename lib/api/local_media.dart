import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Manages local file storage for recordings, videos, thumbnails, metadata, 
/// and sensor data for the OpenEarable app.
///
/// Provides convenient methods to access files and directories for:
/// - Project-level storage
/// - Recording-specific storage
/// - Exported files
/// - Temporary sensor data
///
/// File naming conventions:
/// - Video: [videoName] ('video.mp4')
/// - Thumbnail: [thumbName] ('thumbnail.jpeg')
/// - Recording metadata: [metaName] ('meta.json')
/// - Sensor data: [sensorDataName] ('sensors.json')
class LocalMedia {
  /// Standard filenames for recordings.
  static const videoName = 'video.mp4';
  static const thumbName = 'thumbnail.jpeg';
  static const metaName = 'meta.json';
  static const sensorDataName = 'sensors.json';

  /// Default project identifier.
  static const defaultProjectId = 'default';

  /// Base directory for storing all app data.
  final Directory baseDir;

  /// Directory for exporting recordings or processed data.
  final Directory exportDir;

  /// Temporary directory for transient files, like sensor caches.
  final Directory tempDir;

  LocalMedia(this.baseDir, this.exportDir, this.tempDir);

  /// Returns the default project directory.
  Directory defaultProjectDir() =>
      Directory(p.join(baseDir.path, defaultProjectId));

  /// Returns the directory for a specific project.
  Directory projectDir(String projectId) =>
      Directory(p.join(baseDir.path, projectId));

  /// Returns the metadata file for a specific project.
  File projectMetaFile(String projectId) =>
      File(p.join(baseDir.path, projectId, metaName));

  /// Returns the directory for a specific recording under a project.
  Directory recordingDir(String projectId, String recordingId) =>
      Directory(p.join(baseDir.path, projectId, recordingId));

  /// Returns the video file for a specific recording.
  File videoFile(String projectId, String recordingId) =>
      File(p.join(baseDir.path, projectId, recordingId, videoName));

  /// Returns the thumbnail file for a specific recording.
  File thumbnailFile(String projectId, String recordingId) =>
      File(p.join(baseDir.path, projectId, recordingId, thumbName));

  /// Returns the metadata file for a specific recording.
  File recordingMetaFile(String projectId, String recordingId) =>
      File(p.join(baseDir.path, projectId, recordingId, metaName));

  /// Returns the sensor data file for a specific recording and sensor.
  File recordingSensors(
    String projectId,
    String recordingId,
    String sensorId,
  ) => File(
    p.join(baseDir.path, projectId, recordingId, sensorId, sensorDataName),
  );

  /// Returns a temporary sensor file for caching.
  File recordingTempSensors(String sensorId) =>
      File(p.join(tempDir.path, sensorId));

  /// Returns the export directory for a specific recording.
  Directory recordingExportDir(String recordingId) =>
      Directory(p.join(exportDir.path, recordingId));

  /// Returns the exported video file for a specific recording.
  File videoExportFile(String recordingId) =>
      File(p.join(exportDir.path, recordingId, videoName));

  /// Returns an exported sensor file for a specific recording and sensor.
  File sensorExportFile(
    String recordingId,
    String sensorName,
  ) => File(p.join(exportDir.path, recordingId,"$sensorName.json"));

  /// Initializes a [LocalMedia] instance with standard directories.
  /// Creates all directories if they do not exist.
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

/// Riverpod provider for [LocalMedia].
final localMediaProvider = Provider<LocalMedia>((_) {
  throw UnimplementedError("localMediaProvider not overridden");
});
