
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

class PlaybackController extends ChangeNotifier {
  VideoPlayerController? videoController;

  bool isMuted = false;
  double speed = 1.0;
  String speedString = "1.0x";
  String videoName = const Uuid().v4();
  DateTime? recordingStartedAt;

  Future<Directory> _getRecordingDir(String recordingId) async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}/OpenEarable/default/$recordingId');
  }

  Future<File> _getVideoFile(String recordingId) async {
    final dir = await _getRecordingDir(recordingId);
    return File('${dir.path}/video.mp4');
  }

  Future<void> loadVideo(String recordingId) async {
    recordingStartedAt = DateTime.now().toUtc();
    final videoFile = await _getVideoFile(recordingId);
    if (!await videoFile.exists()) return;
    await videoController?.dispose();
    videoController = VideoPlayerController.file(videoFile);
    await videoController!.initialize();
    videoController!.play();
    notifyListeners();
  }

  void togglePlay() {
    if (videoController == null || !videoController!.value.isInitialized) return;
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

  Future<void> deleteVideo(String recordingId) async {
    final dir = await _getRecordingDir(recordingId);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> exportVideoFolder({
    required String recordingId,
  }) async {
    final sourceDir = await _getRecordingDir(recordingId);
    if (!await sourceDir.exists()) return;
    final picturesDir = Directory('/storage/emulated/0/Pictures/OpenEarable');
    await picturesDir.create(recursive: true);
    final targetDir = Directory('${picturesDir.path}/$recordingId');
    await targetDir.create(recursive: true);
    await for (var entity in sourceDir.list()) {
      if (entity is File && entity.uri.pathSegments.last != 'meta.txt') {
        final fileName = entity.uri.pathSegments.last;
        await entity.copy('${targetDir.path}/$fileName');
      }
    }
  }

  Future<void> stopAndUpload({
    required RecordingService recordingService,
    Dio? dioClient,
    required String recordingId,
    required String? projectId,
  }) async {
    await uploadVideo(
      recordingId,
      recordingService: recordingService,
      dioClient: dioClient,
      projectId: projectId,
    );
    await deleteVideo(recordingId);
  }

  Future<void> uploadVideo(
      String recordingId, {
        required RecordingService recordingService,
        Dio? dioClient,
        String? projectId,
      }) async {
    final dio = dioClient ?? Dio();
    final videoFile = await _getVideoFile(recordingId);
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
