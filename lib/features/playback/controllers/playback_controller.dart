import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:path/path.dart' as p;
import 'package:dio/dio.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';
import 'package:openearable/api/models/recording/recording_dto.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

class PlaybackController extends ChangeNotifier {
  VideoPlayerController? videoController;
  bool isMuted = false;
  double speed = 1.0;
  String speedString = "1.0x";
  String videoName = "video.mp4";
  Future<void> loadVideo(String path) async {
    if (path.isEmpty) return;
    await videoController?.dispose();
    final controller = VideoPlayerController.file(File(path));
    videoController = controller;
    await controller.initialize();
    controller.play();
    // set videoName from path
    videoName = File(path).uri.pathSegments.last.split('.').first;
    notifyListeners();
  }
  void togglePlay() {
    if (videoController == null || !videoController!.value.isInitialized) return;
    if (videoController!.value.isPlaying) {
      videoController?.pause();
    } else {
      videoController?.play();
    }
    notifyListeners();
  }

  void toggleMute() {
    if (videoController == null) return;
    isMuted = !isMuted;
    videoController?.setVolume(isMuted ? 0 : 1);
    notifyListeners();
  }

  void setSpeed(double value) {
    final clamped = value.clamp(0.25, 2.0);
    speed = clamped;
    speedString = "${clamped}x";
    if (videoController == null || !videoController!.value.isInitialized) {
      notifyListeners();
      return;
    }
    videoController?.setPlaybackSpeed(clamped);
    notifyListeners();
  }
  void seekBySeconds(int seconds) {
    if (videoController == null || !videoController!.value.isInitialized) return;
    final current = videoController?.value.position;
    final total = videoController?.value.duration;
    final newPos = current! + Duration(seconds: seconds);
    final clamped = newPos < Duration.zero
        ? Duration.zero
        : (newPos > total! ? total : newPos);
    videoController?.seekTo(clamped);
    notifyListeners();
  }
  Future<void> deleteVideo(String videoPath) async {
    final file = File(videoPath);
    final directory = file.parent;
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
  Future<void> exportVideoFolder(String videoPath) async {
    final file = File(videoPath);
    final sourceDir = file.parent;
    final picturesDir = Directory('/storage/emulated/0/Pictures/OpenEarable');
    await picturesDir.create(recursive: true);
    final folderName = p.basename(sourceDir.path);
    final targetDir = Directory('${picturesDir.path}/$folderName');
    await targetDir.create(recursive: true);
    for (var f in sourceDir.listSync()) {
      if (f is File) {
        await f.copy('${targetDir.path}/${p.basename(f.path)}');
      }
    }
  }
  String getVideoName([String? path]) {

    return videoName;
  }
  Future<String> stopAndUpload({required RecordingService recordingService, Dio? dioClient, required String path}) async {
    final res = await uploadVideo(path, recordingService: recordingService, dioClient: dioClient);
    if (res != null) return path;

    return 'error';
  }
  Future<RecordingDto?> uploadVideo(
      String filePath, {
        required RecordingService recordingService,
        Dio? dioClient,
      }) async {
    try {
      final dio = dioClient ?? Dio();
      final service = recordingService;
      final videoFile = File(filePath);
      final Uint8List? thumbnailBytes = await generateThumbnail(filePath);
      File? thumbnailFile;
      if (thumbnailBytes != null) {
        final tempDir = await Directory.systemTemp.createTemp();
        thumbnailFile = File('${tempDir.path}/thumbnail.jpg');
        await thumbnailFile.writeAsBytes(thumbnailBytes);
      }
      final req = UploadRecordingRequest(
        name: "recording_${DateTime.now().millisecondsSinceEpoch}",
        video: RecordingFile(
          filename: videoName,
          contentType: 'MP4',
          sizeBytes: await videoFile.length(),
          timestamp: DateTime.now().toUtc().subtract(const Duration(seconds: 5)).toIso8601String(),
        ),
        sensors: const [],
        projectId: null,
        thumbnailContent: thumbnailBytes != null ? 'JPEG' : null,
      );
      final uploadResp = await service.startUpload(req);
      await _uploadFile(videoFile, uploadResp.videoUpload.uploadUrl, uploadResp.videoUpload.requiredHeaders, dio);
      if (uploadResp.thumbnailUpload != null && thumbnailFile != null) {
        await _uploadFile(thumbnailFile, uploadResp.thumbnailUpload!.uploadUrl, uploadResp.thumbnailUpload!.requiredHeaders, dio);
      }

      return await service.completeUpload(uploadResp.recordingId);
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint(e.toString());
        debugPrint(s.toString());
      }
      return null;
    }
  }
  Future<Response> _uploadFile(File file, String url, Map<String, String> headers, Dio dio) async {
    final bytes = await file.readAsBytes();
    final resp = await dio.put(url, data: bytes, options: Options(headers: headers, validateStatus: (_) => true));
    return resp;
  }

  Future<Uint8List?> generateThumbnail(String videoPath) async {
    return vt.VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: vt.ImageFormat.JPEG,
      maxWidth: 512,
      quality: 75,
    );
  }
  Future<void > renameVideo(String newName) async {
    videoName = newName;
    notifyListeners();
  }

  @override
  void dispose() {
    videoController?.dispose();
    super.dispose();
  }
}
