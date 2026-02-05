import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';

class PlaybackController extends ChangeNotifier {
  PlaybackController({required this.localMedia, required this.recordingService, required this.recordingId, required this.cloudVideo});

  final LocalMedia localMedia;

  VideoPlayerController? videoController;

  bool isMuted = false;
  double speed = 1.0;
  String speedString = "1.0x";

  String videoName = "";
  DateTime? recordingStartedAt;
  final String recordingId;

  final RecordingService recordingService;

  final bool cloudVideo;

  File _getVideoFile() {
    return localMedia.videoFile(
      LocalMedia.defaultProjectId,
      recordingId,
    );
  }
  Directory _getRecordingDir() {
    return localMedia.recordingDir(
      LocalMedia.defaultProjectId,
      recordingId,
    );
  }
  Future<void> loadVideo() async {
    recordingStartedAt = DateTime.now().toUtc();
    if (cloudVideo) {
      Recording rec = await recordingService.getRecording(recordingId);
      videoName = rec.name;

      videoController = VideoPlayerController.networkUrl(
        Uri.parse(rec.videoUrl!),
      );
    } else {
      /// das ist nicht schön aber habe keine bessere id bitte zeige mich nicht an
      videoName = recordingId;
      final videoFile = _getVideoFile();
      if (!await videoFile.exists()) return;

      videoController = VideoPlayerController.file(videoFile);
    }
    await videoController!.initialize();
    videoController!.play();
    notifyListeners();
  }

  void togglePlay() {
    if (videoController == null ||
        !videoController!.value.isInitialized) return;

    if (videoController!.value.isPlaying) {
      videoController!.pause();
    } else {
      videoController!.play();
    }

    notifyListeners();
  }

  void toggleMute() {
    if (videoController == null) return;

    isMuted = !isMuted;
    videoController!.setVolume(isMuted ? 0 : 1);

    notifyListeners();
  }
  void setSpeed(double value) {
    final clamped = value.clamp(0.25, 2.0);

    speed = clamped;
    speedString = "${clamped}x";

    if (videoController?.value.isInitialized == true) {
      videoController!.setPlaybackSpeed(clamped);
    }

    notifyListeners();
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

    notifyListeners();
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
    final dio = Dio();
    final exportDir = await localMedia.exportDir(videoName);
    await exportDir.create(recursive: true);
    if (cloudVideo) {
      Recording rec = await recordingService.getRecording(recordingId);
      final String videoUrl = rec.videoUrl!;
      final videoFilePath = "${exportDir.path}/video.mp4";
      await dio.download(
        videoUrl,
        videoFilePath,
      );
      return;
    }
    final sourceDir = _getRecordingDir();
    if (!await sourceDir.exists()) return;
    await for (var entity in sourceDir.list()) {
      if (entity is File && entity.uri.pathSegments.last != "meta.json") {
        final fileName = entity.uri.pathSegments.last;
        await entity.copy('${exportDir.path}/$fileName');
      }
    }
  }


  Future<void> stopAndUpload({
    Dio? dioClient,
    required String? projectId,
  }) async {
    if (cloudVideo) return;
    await uploadVideo(

      dioClient: dioClient,
      projectId: projectId,
    );

    await deleteVideo();
  }

  Future<void> uploadVideo( {
        Dio? dioClient,
        String? projectId,
      }) async {
    final dio = dioClient ?? Dio();

    final videoFile = _getVideoFile();

    if (!await videoFile.exists()) return;
    final Uint8List? thumbnailBytes =
    await generateThumbnail(videoFile.path);

    File? thumbnailFile;

    if (thumbnailBytes != null) {
      final tempDir = await Directory.systemTemp.createTemp();
      thumbnailFile = File('${tempDir.path}/thumbnail.jpg');
      await thumbnailFile.writeAsBytes(thumbnailBytes);
    }

    final timestamp = recordingStartedAt ?? DateTime.now().toUtc();
    final req = UploadRecordingRequest(
      name: videoName,
      video: RecordingFile(
        filename: videoName,
        contentType: 'MP4',
        sizeBytes: await videoFile.length(),
        timestamp: timestamp.toIso8601String(),
      ),
      sensors: const [],
      projectId: projectId == 'default' ? null : projectId,
      thumbnailContent: thumbnailBytes != null ? 'JPEG' : null,
    );
    final uploadResp = await recordingService.startUpload(req);
    await _uploadFile(
      videoFile,
      uploadResp.videoUpload.uploadUrl,
      uploadResp.videoUpload.requiredHeaders,
      dio,
    );

    if (uploadResp.thumbnailUpload != null && thumbnailFile != null) {
      await _uploadFile(
        thumbnailFile,
        uploadResp.thumbnailUpload!.uploadUrl,
        uploadResp.thumbnailUpload!.requiredHeaders,
        dio,
      );
    }

    await recordingService.completeUpload(uploadResp.recordingId);
  }
  Future<Response> _uploadFile(
      File file,
      String url,
      Map<String, String> headers,
      Dio dio,
      ) async {
    final bytes = await file.readAsBytes();

    return dio.put(
      url,
      data: bytes,
      options: Options(
        headers: headers,
        validateStatus: (_) => true,
      ),
    );
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
    notifyListeners();

  }

  String getVideoName() => videoName;

  @override
  void dispose() {
    videoController?.dispose();
    super.dispose();
  }
}
