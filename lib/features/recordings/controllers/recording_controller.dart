import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:openearable/app/utils/helpers.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import '../../../api/local_media.dart';

final recordingControllerProvider = Provider<RecordingController>((ref) {
  final localMedia = ref.read(localMediaProvider);

  return RecordingController(localMedia: localMedia);
});

class RecordingController {
  RecordingController({
    required LocalMedia localMedia,
    this.initialCamera = CameraLensDirection.back,
  }) : _localMedia = localMedia;

  final LocalMedia _localMedia;
  final CameraLensDirection initialCamera;
  CameraController? cameraController;
  List<CameraDescription> cameras = [];
  CameraLensDirection currentLens = CameraLensDirection.back;
  DateTime? _recordingStartedAt;
  bool isInitialized = false;
  bool isRecording = false;
  bool isPaused = false;

  Future<void> init() async {
    currentLens = initialCamera;
    cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw Exception("No cameras found");
    }
    await _initCameraController(currentLens);
    isInitialized = true;
  }

  Future<void> _initCameraController(CameraLensDirection lens) async {
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == lens,
      orElse: () => cameras.first,
    );

    await cameraController?.dispose();

    cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    await cameraController!.initialize();
  }

  Future<void> startRecording() async {
    if (isRecording) return;
    if (cameraController == null || !cameraController!.value.isInitialized) {
      throw Exception("Camera not initialized");
    }

    await cameraController!.startVideoRecording();

    _recordingStartedAt = DateTime.now().toUtc();

    isRecording = true;
    isPaused = false;
  }

  Future<String?> stopRecording(String projectId) async {
    if (!isRecording) return null;
    if (cameraController == null || !cameraController!.value.isInitialized) {
      throw Exception("Camera not initialized");
    }

    final file = await cameraController!.stopVideoRecording();
    isRecording = false;
    isPaused = false;
    final recordingId = await _saveVideo(file, projectId);
    _recordingStartedAt = null;
    return recordingId;
  }

  Future<void> pauseRecording() async {
    if (!isRecording || isPaused) return;

    await cameraController!.pauseVideoRecording();

    isPaused = true;
  }

  Future<void> resumeRecording() async {
    if (!isRecording || !isPaused) return;

    await cameraController!.resumeVideoRecording();

    isPaused = false;
  }

  Future<void> toggleCamera() async {
    if (cameras.isEmpty) return;

    currentLens = currentLens == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    isInitialized = false;

    await _initCameraController(currentLens);

    isInitialized = true;
  }

  Future<String> _saveVideo(XFile file, String projectId) async {
    final recordingId = Helpers.getRecordingId();
    final dir = _localMedia.recordingDir(projectId, recordingId);
    await dir.create(recursive: true);

    final videoFile = _localMedia.videoFile(projectId, recordingId);
    await File(file.path).copy(videoFile.path);

    final thumbData = await generateThumbnail(videoFile.path);

    if (thumbData != null) {
      final decoded = img.decodeImage(thumbData);

      if (decoded != null) {
        final thumbFile = _localMedia.thumbnailFile(projectId, recordingId);

        await thumbFile.writeAsBytes(img.encodePng(decoded));
      }
    }

    final metaFile = _localMedia.recordingMetaFile(projectId, recordingId);

    final meta = {
      "name": recordingId,
      "timestamp": (_recordingStartedAt ?? DateTime.now().toUtc())
          .toIso8601String(),
    };

    await metaFile.writeAsString(
      const JsonEncoder.withIndent("  ").convert(meta),
    );

    return recordingId;
  }

  Future<Uint8List?> generateThumbnail(String videoPath) {
    return vt.VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: vt.ImageFormat.JPEG,
      maxWidth: 512,
      quality: 75,
    );
  }

  Future<void> dispose() async {
    await cameraController?.dispose();
  }
}
