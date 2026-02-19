import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/app/utils/helpers.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import '../../../api/local_media.dart';

/// Provides a [RecordingController] instance for a specific initial camera lens.
///
/// This provider is auto-disposed when no longer used, but the controller itself
/// is kept alive during its lifecycle to maintain camera and recording state.
///
/// Parameters:
/// - [initial]: The initial [CameraLensDirection] to use.
final recordingControllerProvider =
    ChangeNotifierProvider.autoDispose
        .family<RecordingController, CameraLensDirection>((ref, initial) {
  final localMedia = ref.read(localMediaProvider);
  final controller = RecordingController(
    localMedia: localMedia,
    initialCamera: initial,
  );
  ref.keepAlive();
  ref.onDispose(controller.dispose);
  return controller;
});

/// Controller for handling video recording with a device camera.
///
/// This class manages:
/// - Camera initialization ([CameraController]) for front/back camera.
/// - Recording state ([isRecording], [isPaused]) and start/pause/resume/stop operations.
/// - Saving recordings to local storage with metadata and thumbnail generation.
/// - Switching cameras when not recording.
///
/// Important properties:
/// - [cameraController]: Current active camera controller.
/// - [cameras]: List of available device cameras.
/// - [currentLens]: Current lens direction (front/back).
/// - [isInitialized]: Whether the camera has been initialized.
/// - [isRecording]: Whether a recording is in progress.
/// - [isPaused]: Whether a recording is currently paused.
class RecordingController extends ChangeNotifier {
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

  /// Initializes the camera controller for the [initialCamera] or currently selected lens.
  ///
  /// - Fetches available cameras using [availableCameras].
  /// - Initializes [cameraController] for the selected lens.
  /// - Sets [isInitialized] to true.
  ///
  /// Throws:
  /// - [Exception] if no cameras are found on the device.
  Future<void> init() async {
    if (isInitialized) return;
    currentLens = initialCamera;
    cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception("No cameras found");
    await _initCameraController(currentLens);
    isInitialized = true;
  }

  /// Internal method to initialize [cameraController] for a specific [CameraLensDirection].
  ///
  /// - Disposes existing [cameraController] if present.
  /// - Creates a new [CameraController] with high resolution and audio enabled.
  /// - Handles errors during initialization by disposing partially initialized controller.
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

  /// Starts video recording.
  ///
  /// - Throws [Exception] if the camera is not initialized.
  /// - Records the start timestamp ([_recordingStartedAt]).
  /// - Updates [isRecording] and [isPaused] flags.
  /// - Calls [notifyListeners] to update UI.
  Future<void> startRecording() async {
    if (isRecording) return;
    if (cameraController == null || !cameraController!.value.isInitialized) {
      throw Exception("Camera not initialized");
    }

    _recordingStartedAt = DateTime.now().toUtc();
    await cameraController!.startVideoRecording();

    isRecording = true;
    isPaused = false;
    notifyListeners();
  }

  /// Stops video recording and saves the recording locally.
  ///
  /// - Returns a [Recording] object with metadata and thumbnail.
  /// - Throws [Exception] if the camera is not initialized.
  /// - Resets [isRecording] and [isPaused] flags.
  ///
  /// Parameters:
  /// - [projectId]: The ID of the project where the recording should be saved.
  Future<Recording?> stopRecording(String projectId) async {
    if (!isRecording) return null;
    if (cameraController == null || !cameraController!.value.isInitialized) {
      throw Exception("Camera not initialized");
    }

    final file = await cameraController!.stopVideoRecording();
    isRecording = false;
    isPaused = false;
    notifyListeners();

    final recordingId = await _saveVideo(file, projectId);
    _recordingStartedAt = null;
    return recordingId;
  }

  /// Pauses an ongoing recording.
  ///
  /// - Does nothing if not recording or already paused.
  /// - Updates [isPaused] and calls [notifyListeners].
  Future<void> pauseRecording() async {
    if (!isRecording || isPaused) return;

    await cameraController!.pauseVideoRecording();

    isPaused = true;

    notifyListeners();
  }

  /// Resumes a paused recording.
  ///
  /// - Does nothing if not recording or not paused.
  /// - Updates [isPaused] and calls [notifyListeners].
  Future<void> resumeRecording() async {
    if (!isRecording || !isPaused) return;

    await cameraController!.resumeVideoRecording();

    isPaused = false;

    notifyListeners();
  }

  /// Toggles the camera lens between front and back.
  ///
  /// - Only works when not recording.
  /// - Reinitializes the camera controller for the new lens.
  /// - Updates [currentLens] and [isInitialized].
  Future<void> toggleCamera() async {
    if (isRecording || cameras.isEmpty) return;

    currentLens = currentLens == CameraLensDirection.front
        ? CameraLensDirection.back
        : CameraLensDirection.front;

    isInitialized = false;

    await _initCameraController(currentLens);

    isInitialized = true;

    notifyListeners();
  }

  /// Saves the recorded video to local storage with metadata and thumbnail.
  ///
  /// - Creates project/recording directories if necessary.
  /// - Copies the video file to the local storage path.
  /// - Generates a thumbnail using [_generateThumbnail].
  /// - Writes metadata JSON file with timestamp and upload status.
  /// - Returns a [Recording] object pointing to local paths.
  ///
  /// Parameters:
  /// - [file]: The temporary video file recorded by the camera.
  /// - [projectId]: The project ID to associate the recording with.
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

  /// Generates a thumbnail image from the given video file.
  ///
  /// - Returns a [Uint8List] of JPEG data, or null if thumbnail generation fails.
  /// - Uses `video_thumbnail` package with a max width of 512 and quality 75.
  ///
  /// Parameters:
  /// - [videoPath]: Path to the video file.
  Future<Uint8List?> _generateThumbnail(String videoPath) {
    return vt.VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: vt.ImageFormat.JPEG,
      maxWidth: 512,
      quality: 75,
    );
  }

  @override
  Future<void> dispose() async {
    cameraController?.dispose();
    super.dispose();
  }
}
