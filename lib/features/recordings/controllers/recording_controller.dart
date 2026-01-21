import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';



class RecordingController extends ChangeNotifier {
  RecordingController({this.initialCamera = CameraLensDirection.back});
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
    await _loadCameras();
  }

  Future<void> disposeController() async {
    try {
      await cameraController?.dispose();
    } catch (_) {}
    cameraController = null;
    isInitialized = false;
    isRecording = false;
    notifyListeners();
  }

  Future<void> _loadCameras() async {
    try {
      cameras = await availableCameras();
      if (cameras.isEmpty) {
        error = 'No cameras found on device.';
        notifyListeners();
        return;
      }
      await _initCameraController(currentLens);
    } catch (e) {
      error = 'Error loading cameras: $e';
      notifyListeners();
    }
  }

  Future<void> _initCameraController(CameraLensDirection lens) async {
    if (cameras.isEmpty) return;

    final camera = cameras.firstWhere(
          (c) => c.lensDirection == lens,
      orElse: () => cameras.first,
    );

    try {
      await cameraController?.dispose();
    } catch (_) {}

    cameraController = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      await cameraController!.initialize();
      isInitialized = true;
      error = null;
      notifyListeners();
    } catch (e) {
      error = 'Error initializing camera: $e';
      isInitialized = false;
      notifyListeners();
    }
  }

  Future<void> startRecording() async {
    if (!isInitialized || isRecording || cameraController == null) return;

    try {
      await cameraController!.startVideoRecording();
      isRecording = true;
      notifyListeners();
    } catch (e) {
      error = 'Error starting recording: $e';
      notifyListeners();
    }
  }

  Future<String?> stopRecording() async {
    if (!isInitialized || !isRecording || cameraController == null) return null;

    try {
      final XFile file = await cameraController!.stopVideoRecording();

      isRecording = false;
      isPaused = false;
      notifyListeners();

      final savedPath = await _saveVideo(file);
      return savedPath;
    } catch (e) {
      error = 'Error stopping recording: $e';
      notifyListeners();
      return null;
    }
  }
  Future<String?> _saveVideo(XFile file) async {
    try {
      final picturesDir = Directory('/storage/emulated/0/Pictures/OpenEarable');
      final folderName = DateTime.now().millisecondsSinceEpoch.toString();
      final recordingDir = Directory('${picturesDir.path}/$folderName');
      await recordingDir.create(recursive: true);
      final newPath = '${recordingDir.path}/video.mp4';
      await File(file.path).copy(newPath);
      return newPath;
    } catch (e) {
      error = 'Error saving video: $e';
      notifyListeners();
      return null;
    }
  }
  Future<void> toggleCamera() async {
    if (cameras.isEmpty) return;
    final next = currentLens == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    isInitialized = false;
    currentLens = next;
    notifyListeners();
    await _initCameraController(next);
  }

  Future<void> pauseRecording() async {
    if (!isInitialized || !isRecording || isPaused || cameraController == null) return;

    try {
      await cameraController!.pauseVideoRecording();
      isPaused = true;
      notifyListeners();
    } catch (e) {
      error = 'Error pausing recording: $e';
      notifyListeners();
    }
  }

  Future<void> resumeRecording() async {
    if (!isInitialized || !isRecording || !isPaused || cameraController == null) return;

    try {
      await cameraController!.resumeVideoRecording();
      isPaused = false;
      notifyListeners();
    } catch (e) {
      error = 'Error resuming recording: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    try {
      cameraController?.dispose();
    } catch (_) {}
    super.dispose();
  }
}


