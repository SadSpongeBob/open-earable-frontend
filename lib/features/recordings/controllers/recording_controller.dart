import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
///matmisi lahna chy 7achtiik b7aja goulili
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
        error = 'Keine Kameras verfügbar.';
        notifyListeners();
        return;
      }
      await _initCameraController(currentLens);
    } catch (e) {
      error = 'Fehler beim Laden der Kameras: $e';
      notifyListeners();
    }
  }

  Future<void> _initCameraController(CameraLensDirection lens) async {
    if (cameras.isEmpty) return;
    final camera = cameras.firstWhere((c) => c.lensDirection == lens, orElse: () => cameras.first);
    try {
      await cameraController?.dispose();
    } catch (_) {}

    cameraController = CameraController(camera, ResolutionPreset.high, enableAudio: true);

    try {
      await cameraController!.initialize();
      isInitialized = true;
      error = null;
      notifyListeners();
    } catch (e) {
      error = 'Fehler beim Initialisieren der Kamera: $e';
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
      error = 'Fehler beim Starten der Aufnahme: $e';
      notifyListeners();
    }
  }

  /// Stoppt die Aufnahme und speichert die Datei.normalemt fi pictures.
  Future<String?> stopRecording() async {
    if (!isInitialized || !isRecording || cameraController == null) return null;
    try {
      final XFile file = await cameraController!.stopVideoRecording();
      isRecording = false;
      isPaused = false; // reset
      notifyListeners();
      final saved = await _saveVideo(file);
      return saved;
    } catch (e) {
      error = 'Fehler beim Stoppen der Aufnahme: $e';
      notifyListeners();
      return null;
    }
  }

  Future<String?> _saveVideo(XFile file) async {
    try {
      final dir = Directory('/storage/emulated/0/Pictures/OpenEarable');
      await dir.create(recursive: true);
      final newPath = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.mp4';
      await File(file.path).copy(newPath);
      return newPath;
    } catch (e) {
      error = 'Fehler beim Speichern des Videos: $e';
      notifyListeners();
      return null;
    }
  }

  /// Wechselt die Kamera (Front <-> Back).
  Future<void> toggleCamera() async {
    if (cameras.isEmpty) return;
    final next = currentLens == CameraLensDirection.front ? CameraLensDirection.back : CameraLensDirection.front;
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
      error = 'Fehler beim Pausieren der Aufnahme: $e';
      notifyListeners();
    }
  }
  Future<void> resumeRecording() async {
    if (!isInitialized || !isRecording || !isPaused || cameraController == null)
      return;

    try {
      await cameraController!.resumeVideoRecording();
      isPaused = false;
      notifyListeners();
    } catch (e) {
      error = 'Fehler beim Fortsetzen der Aufnahme: $e';
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

