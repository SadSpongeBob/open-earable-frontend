import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/models/auth/auth_state.dart';
import 'package:openearable/api/models/project/project_role.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/models/recording/sensor.dart';
import 'package:openearable/api/services/project/project_service.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/services/recording/sensor_repository.dart';
import 'package:openearable/api/services/s3/s3_service.dart';
import 'package:openearable/app/ui/toast_controller.dart';
import 'package:openearable/app/ui/toast_event.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/recordings/controllers/upload_controller.dart';
import 'package:video_player/video_player.dart';

import '../state/playback_state.dart';

/// Playback module for handling video and sensor playback in the OpenEarable app.
/// 
/// This file provides:
/// - [videoPlayerControllerProvider]: Initializes and manages video playback for recordings.
/// - [playbackControllerProvider]: Provides a singleton [PlaybackController] instance.
/// - [PlaybackController]: Handles playback operations, sensor management, video export,
///   renaming, and deletion of recordings.

/// Provides a [VideoPlayerController] for a specific [Recording].
///
/// Handles initialization of the video controller based on whether the recording is
/// local or in the cloud. Also loads associated sensor data for playback visualization.
/// Cleans up the controller and temporary sensor files on dispose.
///
/// Parameters:
/// - [recording]: The [Recording] to play.
///
/// Returns:
/// - A fully initialized [VideoPlayerController] ready for playback.
/// 
/// Throws:
/// - [Exception] if local video path is missing or file does not exist.
/// - Emits a toast if sensor initialization fails.
final videoPlayerControllerProvider = FutureProvider.autoDispose
    .family<VideoPlayerController, Recording>((ref, recording) async {
      late final VideoPlayerController vc;

      final sensors = <Sensor>[];

      final localMedia = ref.read(localMediaProvider);

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

      try {
        final playbackController = ref.read(playbackControllerProvider);
        sensors.addAll(await playbackController.getAvailableSensors(recording));

        ref
            .read(playbackProvider(recording.id).notifier)
            .setAvailableSensors(sensors);
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            "Sensor initialization failed for recordingId=${recording.id}, error=$e",
          );
        }
        emitToast(ref, ToastEvent.error("Sensors could not be initialized"));
      }

      await vc.play();

      ref.onDispose(() {
        // delete temp sensor files AFTER leaving the page
        if (recording.isCloud) {
          for (final sensor in sensors) {
            final f = localMedia.recordingTempSensors(sensor.sensorId);
            unawaited(SensorRepository.tryDeleteTempSensorFromPath(f.path));
          }
        }

        // controller cleanup (fire and forget)
        vc.pause().catchError((_) {});
        vc.dispose();
      });

      return vc;
    });

/// Provides a singleton [PlaybackController] for managing video playback and recording operations.
///
/// Dependencies injected:
/// - [LocalMedia] for file management
/// - [RecordingService] and [S3Service] for cloud/local recordings
/// - [UploadController] for handling uploads
/// - [HomeStateNotifier] for updating UI state
/// - [ProjectService] for project and permission management
/// - [AuthState] for user session and permissions
/// - [Toast] function for user feedback
final playbackControllerProvider = Provider<PlaybackController>((ref) {
  final localMedia = ref.read(localMediaProvider);
  final recordingService = ref.read(recordingServiceProvider);
  final s3Service = ref.read(s3ServiceProvider);
  final uploadController = ref.read(uploadControllerProvider);
  final homeStateNotifier = ref.read(homeStateProvider.notifier);

  final projectService = ref.read(projectServiceProvider);
  final authState = ref.watch(sessionProvider);
  void toast(ToastEvent e) => emitToast(ref, e);

  return PlaybackController(
    localMedia: localMedia,
    recordingService: recordingService,
    s3Service: s3Service,
    uploadController: uploadController,
    homeStateNotifier: homeStateNotifier,
    projectService: projectService,
    authState: authState,
    toast: toast,
  );
});

/// Manages playback operations for recordings including video control, sensor management,
/// exporting recordings, and recording CRUD operations.
///
/// Responsibilities:
/// - Toggle play/pause and seek video
/// - Load available sensors for playback visualization
/// - Check user permissions for managing recordings
/// - Delete or rename recordings (local and cloud)
/// - Export recordings and associated sensor files
///
/// Dependencies are injected via constructor.
class PlaybackController {
  PlaybackController({
    required this.localMedia,
    required this.recordingService,
    required this.s3Service,
    required this.uploadController,
    required this.homeStateNotifier,
    required ProjectService projectService,
    required AuthState authState,
    required void Function(ToastEvent) toast,
  })  : _projectService = projectService,
        _authState = authState,
        _toast = toast;

  final LocalMedia localMedia;
  final RecordingService recordingService;
  final S3Service s3Service;
  final UploadController uploadController;
  final HomeStateNotifier homeStateNotifier;

  final ProjectService _projectService;
  final AuthState _authState;
  final void Function(ToastEvent) _toast;

  /// Toggles playback state (play/pause) for a given [VideoPlayerController].
  void togglePlay(VideoPlayerController vc) {
    if (!vc.value.isInitialized) return;
    vc.value.isPlaying ? vc.pause() : vc.play();
  }

  /// Seeks the video by [seconds] relative to current position.
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

  Future<bool> _canManageRecording(Recording rec) async {
    final projectId = rec.projectId ?? LocalMedia.defaultProjectId;

    if (projectId == LocalMedia.defaultProjectId) return true;
    if (_authState.isGuest) return true;

    try {
      final users = await _projectService.getProjectUsers(projectId);
      final myId = _authState.user?.userId;
      if (myId == null) return false;

      final me = users.where((u) => u.userId == myId).toList();
      if (me.isEmpty) return false;

      final role = me.first.role;
      return role is Owner || role is Editor;
    } on DioException catch (e) {
      if (e.response?.statusCode == 403) return false;
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Deletes a recording if the current user has permission.
  /// - Local or cloud recording deletion handled automatically.
  Future<void> deleteRecording(Recording rec) async {
    final can = await _canManageRecording(rec);
    if (!can) {
      _toast(const ToastEvent.error('No permission'));
      return;
    }

    if (rec.isCloud) {
      await recordingService.deleteCloudRecording(rec.id);
    } else {
      await recordingService.deleteLocalRecording(
        projectId: rec.projectId ?? LocalMedia.defaultProjectId,
        recordingId: rec.id,
      );
    }
    homeStateNotifier.removeRecording(rec.id);
  }

  /// Renames a recording if the current user has permission.
  /// Updates home state after successful rename.
  Future<void> renameRecording(Recording rec, String newName) async {
    final can = await _canManageRecording(rec);
    if (!can) {
      _toast(const ToastEvent.error('No permission'));
      return;
    }

    if (rec.isCloud) {
      await recordingService.renameCloud(
        recordingId: rec.id,
        name: newName,
      );
    } else {
      await recordingService.renameLocal(
        projectId: rec.projectId ?? LocalMedia.defaultProjectId,
        recordingId: rec.id,
        newName: newName,
      );
    }

    homeStateNotifier.updateRecording(
      id: rec.id,
      newName: newName,
    );
  }

  /// Exports a recording folder to the local filesystem, including video and sensors.
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

  /// Retrieves a list of available sensors for a recording.
  Future<List<Sensor>> getAvailableSensors(Recording rec) async {
    if (rec.isCloud) {
      try {
        final r = await recordingService.getRecording(rec.id);
        final List<Sensor> out = [];
        for (final entry in r.sensors) {
          final outFile = localMedia.recordingTempSensors(entry.sensorId);
          try {
            await s3Service.downloadToFile(getUrl: entry.url, filePath: outFile.path);
          } catch (e) {
            if (kDebugMode) {
              debugPrint(
                "Sensor download failed for sensorName=${entry.name}, sensorId=${entry.sensorId}, error=$e",
              );
            }
            continue;
          }
          out.add(Sensor(
            sensorIndex: entry.sensorIndex,
            sensorId: entry.sensorId,
            name: entry.name,
            timeStamp: entry.timestamp,
            localPath: outFile.path,
          ));
        }
        return out;
      } catch (e) {
        return [];
      }
    }
    final projectId = rec.projectId ?? LocalMedia.defaultProjectId;
    final recordingId = rec.id;

    final sensors = await recordingService.getLocalRecordingSensors(
      projectId,
      recordingId,
    );

    return sensors;
  }
}
