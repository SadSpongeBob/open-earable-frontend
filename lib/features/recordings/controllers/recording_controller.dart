import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:uuid/uuid.dart';
import 'package:image/image.dart' as img;


class RecordingController extends ChangeNotifier {
  RecordingController({this.initialCamera = CameraLensDirection.back});
  final CameraLensDirection initialCamera;
  final recordingId = const Uuid().v4();

  CameraController? cameraController;
  List<CameraDescription> cameras = [];
  CameraLensDirection currentLens = CameraLensDirection.back;
  bool isInitialized = false, isRecording = false, isPaused = false;
  String? error, uploadingRecordingId, lastSavedPath;

  Future<void> init() async {
    currentLens = initialCamera;
    cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      await _initCameraController(currentLens);
    } else {
      error = 'No cameras found on device';
    }
    notifyListeners();
  }

  Future<void> disposeController() async {
    await cameraController?.dispose();
    cameraController = null;
    isInitialized = isRecording = false;
    notifyListeners();
  }

  Future<void> _initCameraController(CameraLensDirection lens) async {
    final camera = cameras.firstWhere((c) => c.lensDirection == lens, orElse: () => cameras.first);
    await cameraController?.dispose();
    cameraController = CameraController(camera, ResolutionPreset.high, enableAudio: true);
    await cameraController!.initialize();
    isInitialized = true;
    error = null;
    notifyListeners();
  }

  Future<void> startRecording() async {
    if (isInitialized && !isRecording) {
      await cameraController!.startVideoRecording();
      isRecording = true;
      notifyListeners();
    }
  }


  Future<String?> stopRecording() async {
    if (isInitialized && isRecording) {
      final file = await cameraController!.stopVideoRecording();
      isRecording = isPaused = false;
      notifyListeners();
      return _saveVideo(file: file);
    }
    return null;
  }

  Future<String?> _saveVideo({
    required XFile file,
  }) async {
    try {

      final appDir = await getApplicationDocumentsDirectory();
      final recordingId = const Uuid().v4();

      final dir = Directory(
        '${appDir.path}/OpenEarable/default/$recordingId',
      );
      await dir.create(recursive: true);
      final videoPath = '${dir.path}/video.mp4';
      await File(file.path).copy(videoPath);
      Uint8List? thumbData = await generateThumbnail(videoPath);

      if (thumbData != null) {
        final image = img.decodeImage(thumbData);
        if (image != null) {
          final thumbFile = File('${dir.path}/thumbnail.png');
          await thumbFile.writeAsBytes(img.encodePng(image));
        }
      }
      final metaFile = File('${dir.path}/meta.txt');
      final meta = {
        'name': "video.mp4",
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
      await metaFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(meta),
      );
      return videoPath;
    } catch (e, stack) {
      debugPrintStack(stackTrace: stack);
      return null;
    }
  }
  Future<Uint8List?> generateThumbnail(String videoPath) async {
    return vt.VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: vt.ImageFormat.JPEG,
      maxWidth: 512,
      quality: 75,
    );
  }
  Future<void> writeMeta({
    required String videoPath,
    required String name,
    required DateTime timestamp,
  }) async {
    final dir = Directory(File(videoPath).parent.path);
    final metaFile = File('${dir.path}/meta.txt');

    final meta = {
      'videoPath': videoPath,
      'name': name,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };

    await metaFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(meta),
    );

  }

  Future<void> toggleCamera() async {
    if (cameras.isNotEmpty) {
      currentLens = currentLens == CameraLensDirection.front ? CameraLensDirection.back : CameraLensDirection.front;
      isInitialized = false;
      notifyListeners();
      await _initCameraController(currentLens);
    }
  }

  Future<void> pauseRecording() async {
    if (isInitialized && isRecording && !isPaused) {
      await cameraController!.pauseVideoRecording();
      isPaused = true;
      notifyListeners();
    }
  }
  Future<void> resumeRecording() async {
    if (isInitialized && isRecording && isPaused) {
      await cameraController!.resumeVideoRecording();
      isPaused = false;
      notifyListeners();
    }
  }
  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }
}

