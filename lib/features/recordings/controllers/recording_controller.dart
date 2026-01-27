import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';


class RecordingController extends ChangeNotifier {
  RecordingController({this.initialCamera = CameraLensDirection.back});
  final CameraLensDirection initialCamera;

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
      return _saveVideo(file);
    }
    return null;
  }

  Future<String?> _saveVideo(XFile file) async {
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}/OpenEarable/${DateTime.now().millisecondsSinceEpoch}');
    await dir.create(recursive: true);
    final path = '${dir.path}/video.mp4';
    await File(file.path).copy(path);
    lastSavedPath = path;
    return path;
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