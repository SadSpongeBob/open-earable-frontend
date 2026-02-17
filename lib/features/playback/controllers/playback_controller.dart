import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/models/auth/auth_state.dart';
import 'package:openearable/api/models/project/project_role.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/services/project/project_service.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/services/s3/s3_service.dart';
import 'package:openearable/app/ui/toast_controller.dart';
import 'package:openearable/app/ui/toast_event.dart';
import 'package:openearable/features/auth/state/session_provider.dart';
import 'package:openearable/features/home/state/home_provider.dart';
import 'package:openearable/features/recordings/controllers/upload_controller.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

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

/// Lightweight descriptor used by UI/popup.
class SensorEntry {
  final String sensorId;
  final String name;
  final String? url; // if cloud

  SensorEntry({required this.sensorId, required this.name, this.url});
}

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

  Future<void> stopAndUpload(Recording rec) async {
    if (rec.isCloud) return;

    final projectId = rec.projectId ?? LocalMedia.defaultProjectId;

    uploadController.uploadAndForget(rec.id, projectId);
  }

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

  Future<void> exportVideoFolder(Recording rec) async {
    final exportDir = localMedia.recordingExportDir(rec.name);
    await exportDir.create(recursive: true);

    if (rec.source == RecordingSource.cloud) {
      final r = await recordingService.getRecording(rec.id);

      await s3Service.downloadToFile(
        getUrl: r.videoUrl,
        filePath: localMedia
            .videoExportFile(r.recordingId)
            .path,
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

  List<String> getAvailableSensors(Recording rec) {
    if (rec.isCloud) return [];

    final projectId = rec.projectId ?? LocalMedia.defaultProjectId;
    final recordingId = rec.id;

    final recordingDir = localMedia.recordingDir(projectId, recordingId);
    if (!recordingDir.existsSync()) return [];

    final sensorFiles = recordingDir
        .listSync(recursive: true)
        .whereType<File>()
    // Datei muss sensorDataName heißen
        .where((f) => p.basename(f.path) == LocalMedia.sensorDataName)
    // Parent Folder muss sns_xxx sein
        .where((f) => p.basename(f.parent.path).startsWith("sns_"))
        .toList();

    debugPrint("Found sensor files:");
    for (final f in sensorFiles) {
      debugPrint("  ${f.path}");
    }

    return sensorFiles
        .map((f) => p.basename(f.parent.path))
        .toList();
  }

  /// Fetch sensors for a recording (cloud or local) — returns detailed entries.
  Future<List<SensorEntry>> fetchAvailableSensors(Recording rec) async {
    if (rec.isCloud) {
      try {
        final r = await recordingService.getRecording(rec.id);
        return r.sensors
            .map((s) => SensorEntry(sensorId: s.sensorId, name: s.name, url: s.url))
            .toList();
      } catch (e) {
        if (kDebugMode) debugPrint('fetchAvailableSensors cloud failed: $e');
        return [];
      }
    }

    // local
    try {
      final projectId = rec.projectId ?? LocalMedia.defaultProjectId;
      final sensors = await recordingService.getLocalRecordingSensors(projectId, rec.id);
      return sensors.map((s) => SensorEntry(sensorId: s.sensorId, name: s.name, url: null)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('fetchAvailableSensors local failed: $e');
      return [];
    }
  }

  /// Downloads all sensors for a cloud recording into the app documents
  /// directory under OpenEarable/downloads/{recordingId}/ and returns a map
  /// sensorId -> downloaded file path. Local recordings are ignored.
  Future<Map<String, String>> downloadAllSensorsToAppDir(Recording rec) async {
    final result = <String, String>{};
    if (!rec.isCloud) return result;

    try {
      final remote = await recordingService.getRecording(rec.id);
      final appDir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory(p.join(appDir.path, 'OpenEarable', 'downloads', rec.id));
      await downloadDir.create(recursive: true);

      for (final s in remote.sensors) {
        final url = s.url; // non-nullable in model
        if (url.isEmpty) continue;
        final outPath = p.join(downloadDir.path, '${s.sensorId}.json');
        try {
          await s3Service.downloadToFile(getUrl: url, filePath: outPath);
          result[s.sensorId] = outPath;
        } catch (e) {
          if (kDebugMode) debugPrint('downloadAllSensors: failed ${s.sensorId} -> $e');
        }
      }
    } catch (e) {
      if (kDebugMode) debugPrint('downloadAllSensors: failed for recording ${rec.id}: $e');
    }

    return result;
  }

}
