
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;

class PlaybackController extends ChangeNotifier {
  VideoPlayerController? videoController;
  bool isMuted = false;
  double speed = 1.0;
  String speedString = "1.0x";
  String videoName = "recording_${DateTime.now().millisecondsSinceEpoch}";
  DateTime? recordingStartedAt;
  Future<void> loadVideo(String path) async {
    recordingStartedAt = DateTime.now().toUtc();
    if (path.isEmpty) return;
    await videoController?.dispose();
    final controller = VideoPlayerController.file(File(path));
    videoController = controller;
    await controller.initialize();
    controller.play();
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
  Future<void> exportVideoFolder({
    required String videoPath,
  }) async {
    try {
      final sourceVideo = File(videoPath);
      final sourceDir = sourceVideo.parent;

      // Zielordner in Pictures/OpenEarable
      final picturesDir = Directory('/storage/emulated/0/Pictures/OpenEarable');
      await picturesDir.create(recursive: true);

      // Neuer Ordnername = aktueller Zeitstempel
      final folderName = DateTime.now().millisecondsSinceEpoch.toString();
      final targetDir = Directory('${picturesDir.path}/$folderName');
      await targetDir.create(recursive: true);

      // Alle Dateien im Parent-Ordner kopieren
      await for (var entity in sourceDir.list()) {
        if (entity is File && entity.uri.pathSegments.last != "meta.txt") {
          final fileName = entity.uri.pathSegments.last;
          final targetFile = File('${targetDir.path}/$fileName');
          await entity.copy(targetFile.path);
          debugPrint('📄 Datei kopiert: $fileName');
        }
      }

      debugPrint('✅ Export abgeschlossen: ${targetDir.path}');
    } catch (e, stack) {
      debugPrint('❌ Fehler beim Exportieren: $e');
      debugPrintStack(stackTrace: stack);
    }
  }
  String getVideoName([String? path]) {

    return videoName;
  }
  Future<void> stopAndUpload({required RecordingService recordingService, Dio? dioClient, required String path, required String? projektId}) async {
    await uploadVideo(path, recordingService: recordingService, dioClient: dioClient, projektId: projektId);
    await deleteVideo(path);
  }
  Future<void> uploadVideo(
      String filePath, {
        required RecordingService recordingService,
        Dio? dioClient, String? projektId,
      }) async {
    try {
      final dio = dioClient ?? Dio();

      final videoFile = File(filePath);
      final Uint8List? thumbnailBytes = await generateThumbnail(filePath);
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
        projectId: projektId,
        thumbnailContent: thumbnailBytes != null ? 'JPEG' : null,
      );
      final uploadResp = await recordingService.startUpload(req);
      await _uploadFile(videoFile, uploadResp.videoUpload.uploadUrl, uploadResp.videoUpload.requiredHeaders, dio);
      if (uploadResp.thumbnailUpload != null && thumbnailFile != null) {
        await _uploadFile(thumbnailFile, uploadResp.thumbnailUpload!.uploadUrl, uploadResp.thumbnailUpload!.requiredHeaders, dio);
      }
      await recordingService.completeUpload(uploadResp.recordingId);
    } catch (e, s) {
      if (kDebugMode) {
        debugPrint(e.toString());
        debugPrint(s.toString());
      }
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
