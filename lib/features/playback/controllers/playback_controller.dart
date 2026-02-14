import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/recordings/controllers/upload_controller.dart';
import 'package:video_player/video_player.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/services/s3/s3_service.dart';

final videoPlayerControllerProvider = FutureProvider.autoDispose
    .family<VideoPlayerController, Recording>((ref, recording) async {
      late final VideoPlayerController vc;

      if (recording.isCloud) {
        final recordingService = ref.read(recordingServiceProvider);
        final r = await recordingService.getRecording(recording.id);
        vc = VideoPlayerController.networkUrl(Uri.parse(r.videoUrl));
      } else {
        final path = recording.localVideoPath;
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

final playbackControllerProvider = Provider<PlaybackController>((ref) {
  final localMedia = ref.read(localMediaProvider);
  final recordingService = ref.read(recordingServiceProvider);
  final s3Service = ref.read(s3ServiceProvider);
  final uploadController = ref.read(uploadControllerProvider);
  final homeStateNotifier = ref.read(homeStateProvider.notifier);

  return PlaybackController(
    localMedia,
    recordingService,
    s3Service,
    uploadController,
    homeStateNotifier,
  );
});

class PlaybackController {
  final LocalMedia localMedia;
  final RecordingService recordingService;
  final S3Service s3Service;
  final UploadController uploadController;
  final HomeStateNotifier homeStateNotifier;

  PlaybackController(
    this.localMedia,
    this.recordingService,
    this.s3Service,
    this.uploadController,
    this.homeStateNotifier,
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
    homeStateNotifier.removeRecording(rec.id);
  }

  Future<void> stopAndUpload(Recording rec) async {
    if (rec.isCloud) return;

    final projectId = rec.projectId ?? LocalMedia.defaultProjectId;

    homeStateNotifier.updateRecording(
      id: rec.id,
      uploadStatus: UploadStatus.pending,
    );

    final ok = await uploadController.uploadRecording(
      recordingId: rec.id,
      projectId: projectId,
    );

    if (ok) {
      homeStateNotifier.updateRecording(
        id: rec.id,
        uploadStatus: UploadStatus.completed,
      );

      try {
        final dir = localMedia.recordingDir(projectId, rec.id);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      } catch (_) {
        if (kDebugMode) {
          debugPrint(
            "CLEANUP FAILED: recording with recordingId: ${rec.id}, (upload completed)",
          );
        }
        // TODO: Add meta.json status for late cleanup
      }
    } else {
      homeStateNotifier.updateRecording(
        id: rec.id,
        uploadStatus: UploadStatus.failed,
      );
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
    homeStateNotifier.updateRecording(id: rec.id, newName: newName);
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
