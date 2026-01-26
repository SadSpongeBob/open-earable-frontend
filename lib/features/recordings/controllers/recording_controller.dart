import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:openearable/api/services/recording/recording_service.dart';
import 'package:openearable/api/models/recording/upload_recording_request.dart';
import 'package:openearable/api/models/recording/recording_dto.dart';

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

  Future<bool> stopAndUpload({RecordingService? recordingService, Dio? dioClient}) async {
    try {
      final path = await stopRecording();
      if (path == null) return false;
      return await uploadVideo(path, recordingService: recordingService, dioClient: dioClient) != null;
    } catch (e) {
      error = 'stopAndUpload failed: $e';
      return false;
    }
  }

  Future<RecordingDto?> uploadVideo(String filePath, {RecordingService? recordingService, Dio? dioClient, String? thumbnailPath}) async {
    try {
      final file = File(filePath);
      final req = UploadRecordingRequest(
        name: "recording_${DateTime.now().millisecondsSinceEpoch}",
        video: RecordingFile(
          filename: 'video.mp4',
          contentType: 'MP4',
          sizeBytes: await file.length(),
          timestamp: DateTime.now().toUtc().subtract(const Duration(seconds: 5)).toIso8601String(),
        ),
        sensors: const [],
        projectId: null,
        thumbnailContent: null,
      );
      final service = recordingService ?? RecordingService(dioClient: dioClient ?? Dio());
      final uploadResp = await service.startUpload(req);

      await _uploadFile(file, uploadResp.videoUpload.uploadUrl, uploadResp.videoUpload.requiredHeaders, dioClient);
      if (uploadResp.thumbnailUpload != null && thumbnailPath != null) {
        await _uploadFile(File(thumbnailPath), uploadResp.thumbnailUpload!.uploadUrl, uploadResp.thumbnailUpload!.requiredHeaders, dioClient);
      }

      await service.completeUpload(uploadResp.recordingId);
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> _uploadFile(File file, String url, Map<String, String> headers, Dio? dioClient) async {
    await (dioClient ?? Dio()).put(url, data: await file.readAsBytes(), options: Options(headers: headers));
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }
}