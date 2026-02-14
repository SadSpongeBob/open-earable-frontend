import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/features/recordings/controllers/upload_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/services/s3/s3_service.dart';
import 'package:openearable/features/home/state/home_provider.dart';

final videoPlayerControllerByKeyProvider = FutureProvider.autoDispose
    .family<VideoPlayerController, String>((ref, key) async {
      final parts = key.split('|');
      final id = parts.isNotEmpty ? parts[0] : key;
      final sourceIndex = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
      final source = RecordingSource.values[sourceIndex];
      final home = ref.read(homeStateProvider);
      Recording rec = home.videos.firstWhere(
        (r) => r.id == id && r.source == source,
        orElse: () => Recording(
          id: id,
          name: 'Recording $id',
          source: source,
          videoTimestamp: DateTime.now().toUtc(),
          uploadStatus: UploadStatus.pending,
        ),
      );

      late final VideoPlayerController vc;

      if (rec.isCloud) {
        final recordingService = ref.read(recordingServiceProvider);
        final r = await recordingService.getRecording(rec.id);
        vc = VideoPlayerController.networkUrl(Uri.parse(r.videoUrl));
      } else {
        final path = rec.localVideoPath;
        if (path == null) throw Exception("Missing localVideoPath");
        final file = File(path);
        if (!await file.exists()) throw Exception("Local video file missing");
        vc = VideoPlayerController.file(file);
      }

      await vc.initialize();
      await vc.play();

      ref.onDispose(() async {
        try {
          await vc.pause();
        } catch (_) {}
        await vc.dispose();
      });

      return vc;
    });
final videoPlayerControllerProvider = videoPlayerControllerByKeyProvider;

final playbackControllerProvider = Provider<PlaybackController>((ref) {
  final localMedia = ref.read(localMediaProvider);
  final recordingService = ref.read(recordingServiceProvider);
  final s3Service = ref.read(s3ServiceProvider);
  final uploadController = ref.read(uploadControllerProvider);

  return PlaybackController(
    localMedia,
    recordingService,
    s3Service,
    uploadController,
  );
});

class PlaybackController {
  final LocalMedia localMedia;
  final RecordingService recordingService;
  final S3Service s3Service;
  final UploadController uploadController;

  PlaybackController(
    this.localMedia,
    this.recordingService,
    this.s3Service,
    this.uploadController,
  );

  void togglePlay(VideoPlayerController vc) {
    if (!vc.value.isInitialized) return;
    vc.value.isPlaying ? vc.pause() : vc.play();
  }

  void seekBySeconds(VideoPlayerController vc, int seconds) {
    if (!vc.value.isInitialized) return;
    final current = vc.value.position;
    final total = vc.value.duration;
    final newPos = current + Duration(seconds: seconds);
    final clamped = newPos < Duration.zero
        ? Duration.zero
        : (newPos > total ? total : newPos);
    vc.seekTo(clamped);
  }

  Future<void> deleteRecording(Recording rec) async {
    if (rec.isCloud) {
      await recordingService.deleteRecording(rec.id);
    } else {
      await recordingService.deleteLocalRecording(
        rec.projectId ?? LocalMedia.defaultProjectId,
        rec.id,
      );
    }
  }

  Future<void> stopAndUpload(Recording rec) async {
    if (rec.isCloud) return;

    final projectId = rec.projectId ?? LocalMedia.defaultProjectId;

    final ok = await uploadController.uploadRecording(
      recordingId: rec.id,
      projectId: projectId,
    );

    if (ok) {
      final dir = localMedia.recordingDir(projectId, rec.id);
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    }
  }

  Future<void> renameRecording(Recording rec, String newName) async {
    if (rec.isCloud) {
      await recordingService.rename(rec.id, newName);
    } else {
      await recordingService.renameLocal(
        projectId: rec.projectId ?? LocalMedia.defaultProjectId,
        recordingId: rec.id,
        newName: newName,
      );
    }
  }

  Future<void> exportVideoFolder(Recording rec) async {
    final exportDir = localMedia.recordingExportDir(rec.name);
    await exportDir.create(recursive: true);

    if (rec.source == RecordingSource.cloud) {
      final r = await recordingService.getRecording(rec.id);

      await s3Service.downloadToFile(
        getUrl: r.videoUrl,
        filePath: localMedia.videoExportFile(r.recordingId).path,
      );

      for (final sensor in r.sensors) {
        await s3Service.downloadToFile(
          getUrl: sensor.url,
          filePath: localMedia
              .sensorExportFile(r.recordingId, sensor.sensorId, sensor.name)
              .path,
        );
      }
    } else {
      final projectId = rec.projectId ?? LocalMedia.defaultProjectId;
      final sourceDir = localMedia.recordingDir(projectId, rec.id);
      if (!await sourceDir.exists()) return;

      await for (final entity in sourceDir.list()) {
        if (entity is File &&
            entity.uri.pathSegments.last != LocalMedia.metaName) {
          final fileName = entity.uri.pathSegments.last;
          await entity.copy("${exportDir.path}/$fileName");
        }
      }
    }
  }
}
