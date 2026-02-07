import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/services/s3/s3_service.dart';
import '../../home/state/home_provider.dart';
final playbackControllerProvider =
Provider.family<PlaybackController, PlaybackArgs>((ref, args) {
  final localMedia = ref.read(localMediaProvider);
  final recordingService = ref.read(recordingServiceProvider);
  return PlaybackController(
    localMedia: localMedia,
    recordingService: recordingService,
    recordingId: args.recordingId,
    cloudVideo: args.cloudVideo, ref: ref,
  );
});

class PlaybackArgs {
  final String recordingId;
  final bool cloudVideo;

  PlaybackArgs({
    required this.recordingId,
    required this.cloudVideo,
  });
}
class PlaybackController {
  PlaybackController({
    required this.localMedia,
    required this.recordingService,
    required this.recordingId,
    required this.cloudVideo,
    required this.ref,
  });
  final LocalMedia localMedia;
  final RecordingService recordingService;
  final String recordingId;
  final bool cloudVideo;

  VideoPlayerController? videoController;

  bool isMuted = false;
  double speed = 1.0;
  String speedString = "1.0x";

  String videoName = "";
  DateTime? recordingStartedAt;
  final Ref ref;

  File _getVideoFile() {
    return localMedia.videoFile(
      ref.read(homeStateProvider).openProjectId,
      recordingId,
    );
  }
  Directory _getRecordingDir() {
    return localMedia.recordingDir(
      ref.read(homeStateProvider).openProjectId,
      recordingId,
    );
  }
  Future<void> loadVideo() async {
    recordingStartedAt = DateTime.now().toUtc();
    if (cloudVideo) {
      final Recording rec = await recordingService.getRecording(recordingId);
      videoName = rec.name;
      videoController = VideoPlayerController.networkUrl(
        Uri.parse(rec.videoUrl!),
      );
    } else {
      videoName = recordingId;
      final file = _getVideoFile();
      if (!await file.exists()) return;
      videoController = VideoPlayerController.file(file);
    }
    await videoController!.initialize();
    await videoController!.play();
  }
  void togglePlay() {
    if (videoController?.value.isInitialized != true) return;
    if (videoController!.value.isPlaying) {
      videoController!.pause();
    } else {
      videoController!.play();
    }
  }
  void toggleMute() {
    if (videoController == null) return;
    isMuted = !isMuted;
    videoController!.setVolume(isMuted ? 0 : 1);
  }
  void setSpeed(double value) {
    final clamped = value.clamp(0.25, 2.0);
    speed = clamped;
    speedString = "${clamped}x";
    if (videoController?.value.isInitialized == true) {
      videoController!.setPlaybackSpeed(clamped);
    }
  }
  void seekBySeconds(int seconds) {
    if (videoController?.value.isInitialized != true) return;
    final current = videoController!.value.position;
    final total = videoController!.value.duration;
    final newPos = current + Duration(seconds: seconds);
    final clamped = newPos < Duration.zero
        ? Duration.zero
        : (newPos > total ? total : newPos);
    videoController!.seekTo(clamped);
  }

  Future<void> deleteVideo() async {
    if (cloudVideo) {
      await recordingService.deleteRecording(recordingId);
      return;
    }
    final dir = _getRecordingDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
  Future<void> exportVideoFolder() async {
    final s3 = ref.read(s3ServiceProvider);
    final exportDir = await localMedia.exportDir(videoName);
    await exportDir.create(recursive: true);
    if (cloudVideo) {
      final rec = await recordingService.getRecording(recordingId);
      await s3.downloadToFile(rec.videoUrl!, "${exportDir.path}/video.mp4");
      return;
    }
    final sourceDir = _getRecordingDir();
    if (!await sourceDir.exists()) return;
    await for (var entity in sourceDir.list()) {
      if (entity is File && entity.uri.pathSegments.last != "meta.json") {
        final fileName = entity.uri.pathSegments.last;
        await entity.copy("${exportDir.path}/$fileName");
      }
    }
  }
  Future<void> stopAndUpload({
    required String? projectId,
  }) async {
    if (cloudVideo) return;
    await uploadVideo(projectId: projectId);

    await deleteVideo();
  }

  Future<void> uploadVideo({
    String? projectId,
  }) async {
    final awsDio = ref.read(s3ServiceProvider);
    final videoFile = _getVideoFile();
    if (!await videoFile.exists()) return;
    final thumbBytes = await generateThumbnail(videoFile.path);
    File? thumbFile;
    if (thumbBytes != null) {
      final temp = await Directory.systemTemp.createTemp();
      thumbFile = File("${temp.path}/thumb.jpg");
      await thumbFile.writeAsBytes(thumbBytes);
    }
    final timestamp = recordingStartedAt ?? DateTime.now().toUtc();

    final req = UploadRecordingRequest(
      name: videoName,
      video: RecordingFile(
        filename: videoName,
        contentType: "MP4",
        sizeBytes: await videoFile.length(),
        timestamp: timestamp.toIso8601String(),
      ),
      sensors: const [],
      projectId: projectId == "default" ? null : projectId,
      thumbnailContent: thumbBytes != null ? "JPEG" : null,
    );

    final uploadResp = await recordingService.startUpload(req);
    final videoBytes = await videoFile.readAsBytes();
    await awsDio.put(
      uploadResp.videoUpload.uploadUrl,
      uploadResp.videoUpload.requiredHeaders,
      videoBytes,
    );

    if (uploadResp.thumbnailUpload != null && thumbFile != null) {
      final tbytes = await thumbFile.readAsBytes();
      await awsDio.put(
        uploadResp.thumbnailUpload!.uploadUrl,
        uploadResp.thumbnailUpload!.requiredHeaders,
        tbytes,
      );
    }
    await recordingService.completeUpload(uploadResp.recordingId);
  }

  Future<Uint8List?> generateThumbnail(String videoPath) {
    return vt.VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: vt.ImageFormat.JPEG,
      maxWidth: 512,
      quality: 75,
    );
  }

  Future<void> renameVideo(String newName) async {
    if (cloudVideo) {
      await recordingService.rename(recordingId, newName);
    }
    videoName = newName;
  }
  bool getVideoNamesInProject(String videoName) {
    final homeState = ref.read(homeStateProvider);
    final openProjectId = homeState.openProjectId == "default" ? null : homeState.openProjectId;

    if (homeState.videos
        .where((v) => v.projectId == openProjectId)
        .map((v) => v.name)
        .toList().contains(videoName)) {
      return true;
    }
    return false;
  }

  String getVideoName() => videoName;

  Future<void> dispose() async {
    await videoController?.dispose();
  }
}
