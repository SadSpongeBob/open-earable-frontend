import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import '../../../api/local_media.dart';


class RecordingController extends ChangeNotifier {
  RecordingController({
    required this.localMedia,
    this.initialCamera = CameraLensDirection.back,
  });

  final LocalMedia localMedia;
  final CameraLensDirection initialCamera;
  CameraController? cameraController;
  List<CameraDescription> cameras = [];
  CameraLensDirection currentLens = CameraLensDirection.back;
  bool isInitialized = false;
  bool isRecording = false;
  bool isPaused = false;
  String? error;
  Future<void> init() async {
    currentLens = initialCamera;

    cameras = await availableCameras();

    if (cameras.isEmpty) {
      error = "No cameras found";
      notifyListeners();
      return;
    }

    await _initCameraController(currentLens);
    notifyListeners();
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

    isInitialized = true;
    error = null;

    notifyListeners();
  }
  Future<void> startRecording() async {
    if (!isInitialized || isRecording) return;

    await cameraController!.startVideoRecording();

    isRecording = true;
    notifyListeners();
  }

  Future<String?> stopRecording() async {
    if (!isInitialized || !isRecording) return null;

    final file = await cameraController!.stopVideoRecording();

    isRecording = false;
    isPaused = false;

    notifyListeners();
    return await _saveVideo(file: file);
  }

  Future<String?> _saveVideo({required XFile file}) async {
    final recordingId = const Uuid().v4();

    final projectId = LocalMedia.defaultProjectId;

    final recordingDir = localMedia.recordingDir(projectId, recordingId);
    await recordingDir.create(recursive: true);

    final videoFile = localMedia.videoFile(projectId, recordingId);
    await File(file.path).copy(videoFile.path);
    final thumbData = await generateThumbnail(videoFile.path);

    if (thumbData != null) {
      final decoded = img.decodeImage(thumbData);

      if (decoded != null) {
        final thumbFile =
        localMedia.thumbnailFile(projectId, recordingId);

        await thumbFile.writeAsBytes(img.encodePng(decoded));
      }
    }
    final metaFile =
    localMedia.recordingMetaFile(projectId, recordingId);
    final meta = {
      "id": recordingId,
      "timestamp": DateTime.now().toUtc().toIso8601String(),
    };
    await metaFile.writeAsString(
      const JsonEncoder.withIndent("  ").convert(meta),
    );
    return recordingId;
  }

  Future<Uint8List?> generateThumbnail(String videoPath) async {
    return vt.VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: vt.ImageFormat.JPEG,
      maxWidth: 512,
      quality: 75,
    );
  }
  Future<void> toggleCamera() async {
    if (cameras.isEmpty) return;

    currentLens = currentLens == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    isInitialized = false;
    notifyListeners();

    await _initCameraController(currentLens);
  }
  Future<void> pauseRecording() async {
    if (!isInitialized || !isRecording || isPaused) return;

    await cameraController!.pauseVideoRecording();

    isPaused = true;
    notifyListeners();
  }

  Future<void> resumeRecording() async {
    if (!isInitialized || !isRecording || !isPaused) return;

    await cameraController!.resumeVideoRecording();

    isPaused = false;
    notifyListeners();
  }
  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }
}
