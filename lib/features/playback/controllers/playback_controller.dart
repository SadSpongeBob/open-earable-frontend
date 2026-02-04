import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:openearable/api/local_media.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';

class PlaybackController extends ChangeNotifier {
  PlaybackController({required this.localMedia});

  final LocalMedia localMedia;

  VideoPlayerController? videoController;

  bool isMuted = false;
  double speed = 1.0;
  String speedString = "1.0x";

  String videoName = const Uuid().v4();
  DateTime? recordingStartedAt;

  File _getVideoFile(String recordingId) {
    return localMedia.videoFile(
      LocalMedia.defaultProjectId,
      recordingId,
    );
  }
  Directory _getRecordingDir(String recordingId) {
    return localMedia.recordingDir(
      LocalMedia.defaultProjectId,
      recordingId,
    );
  }
  Future<void> loadVideo(String? recordingId) async {
    recordingStartedAt = DateTime.now().toUtc();

    final videoFile = _getVideoFile(recordingId!);

    if (!await videoFile.exists()) return;

    await videoController?.dispose();

    videoController = VideoPlayerController.file(videoFile);

    await videoController!.initialize();
    videoController!.play();

    notifyListeners();
  }

  /// Toggle play/pause
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

  /// Toggle mute/unmute
  void toggleMute() {
    if (videoController == null) return;

    isMuted = !isMuted;
    videoController!.setVolume(isMuted ? 0 : 1);

    notifyListeners();
  }

  /// Change playback speed
  void setSpeed(double value) {
    final clamped = value.clamp(0.25, 2.0);

    speed = clamped;
    speedString = "${clamped}x";

    if (videoController?.value.isInitialized == true) {
      videoController!.setPlaybackSpeed(clamped);
    }

    notifyListeners();
  }

  /// Seek forward/backward
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
    final dir = _getRecordingDir(recordingId);

    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
  Future<void> exportVideoFolder({
    required String? recordingId,
  }) async {
    final sourceDir = _getRecordingDir(recordingId!);
    if (!await sourceDir.exists()) return;
    final exportDir = await localMedia.exportDir(videoName);
    await exportDir.create(recursive: true);
    await for (var entity in sourceDir.list()) {
      if (entity is File && entity.uri.pathSegments.last!="meta.json") {
        final fileName = entity.uri.pathSegments.last;
        await entity.copy('${exportDir .path}/$fileName');
      }
    }
  }

  Future<void> stopAndUpload({
    required RecordingService recordingService,
    Dio? dioClient,
    required String? recordingId,
    required String? projectId,
  }) async {
    await uploadVideo(
      recordingId!,
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

    final videoFile = _getVideoFile(recordingId);

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
