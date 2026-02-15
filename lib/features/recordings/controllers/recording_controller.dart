import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/app/utils/helpers.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import '../../../api/local_media.dart';

final recordingControllerProvider = Provider.autoDispose
    .family<RecordingController, CameraLensDirection>((ref, initial) {
      final localMedia = ref.read(localMediaProvider);
      final controller = RecordingController(
        localMedia: localMedia,
        initialCamera: initial,
      );
      ref.onDispose(controller.dispose);
      return controller;
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
    if (isInitialized) return;
    currentLens = initialCamera;
    cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception("No cameras found");
    await _initCameraController(currentLens);
    isInitialized = true;
  }

  Future<void> _initCameraController(CameraLensDirection lens) async {
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == lens,
      orElse: () => cameras.first,
    );

    await cameraController?.dispose();

    final next = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      await next.initialize();
      cameraController = next;
    } catch (_) {
      await next.dispose();
      rethrow;
    }
  }

  Future<void> startRecording() async {
    if (isRecording) return;
    if (cameraController == null || !cameraController!.value.isInitialized) {
      throw Exception("Camera not initialized");
    }

    _recordingStartedAt = DateTime.now().toUtc();
    await cameraController!.startVideoRecording();

    isRecording = true;
    isPaused = false;
  }

  Future<Recording?> stopRecording(String projectId) async {
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
    if (isRecording || cameras.isEmpty) return;

    currentLens = currentLens == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    isInitialized = false;

    await _initCameraController(currentLens);

    isInitialized = true;
  }

  Future<Recording> _saveVideo(XFile file, String projectId) async {
    final recordingId = Helpers.getRecordingId();
    final dir = _localMedia.recordingDir(projectId, recordingId);
    await dir.create(recursive: true);

    final videoFile = _localMedia.videoFile(projectId, recordingId);
    await File(file.path).copy(videoFile.path);

    final thumbData = await _generateThumbnail(videoFile.path);
    if (thumbData != null) {
      final thumbFile = _localMedia.thumbnailFile(projectId, recordingId);
      await thumbFile.writeAsBytes(thumbData);
    }

    final metaFile = _localMedia.recordingMetaFile(projectId, recordingId);

    final timestamp = _recordingStartedAt ?? DateTime.now().toUtc();
    final meta = {
      "name": recordingId,
      "timestamp": (timestamp).toIso8601String(),
      "uploadStatus": UploadStatus.pending.json
    };

    await metaFile.writeAsString(
      const JsonEncoder.withIndent("  ").convert(meta),
    );

    return Recording.local(
      id: recordingId,
      name: recordingId,
      localThumbnailPath: _localMedia
          .thumbnailFile(projectId, recordingId)
          .path,
      localVideoPath: _localMedia.videoFile(projectId, recordingId).path,
      videoTimestamp: timestamp,
      projectId: projectId == LocalMedia.defaultProjectId ? null : projectId,
    );
  }

  Future<Uint8List?> _generateThumbnail(String videoPath) {
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
