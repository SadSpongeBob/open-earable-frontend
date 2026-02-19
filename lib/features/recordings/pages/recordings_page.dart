import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/features/recordings/widgets/right_bar.dart';
import 'package:openearable/features/recordings/widgets/sensor_overlay.dart';
import 'package:openearable/app/ui/device/devices_popup_controller.dart';
import 'package:openearable/features/home/state/wearables_state.dart';
import 'package:openearable/features/sensors/state/sensor_state.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:openearable/app/widgets/devices_popup.dart';
import '../../../app/routing/routes.dart';
import '../../home/state/home_provider.dart';
import '../controllers/recording_controller.dart';
import 'package:openearable/features/recordings/controllers/sensors_recording_controller.dart';
import '../widgets/left_bar.dart';

/// A page for capturing video and recording sensor data.
///
/// Parameters:
/// - [onVideoRecorded]: Optional callback invoked with the path of the recorded video when recording finishes.
/// - [initialCamera]: The initial camera to use ([CameraLensDirection.back] by default).
///
/// Behavior:
/// - Displays a live camera preview using [CameraController].
/// - Integrates with [SensorsRecordingController] to record wearable sensor data alongside video.
/// - Handles UI actions like shutter press, pause/resume, camera flip, and Bluetooth device management.
/// - Updates state in [homeStateProvider] to store new recordings.
class RecordingPage extends ConsumerStatefulWidget {
  const RecordingPage({
    super.key,
    this.onVideoRecorded,
    this.initialCamera = CameraLensDirection.back,
  });

  final void Function(String videoPath)? onVideoRecorded;
  final CameraLensDirection initialCamera;

  @override
  ConsumerState<RecordingPage> createState() => _RecordingPageState();
}

/// Provides a singleton [SensorsRecordingController] for managing wearable sensor recordings.
///
/// The provider is kept alive across widget rebuilds to maintain sensor state
/// even when the [RecordingPage] is temporarily removed from the widget tree.
final sensorsRecordingProvider =
    ChangeNotifierProvider<SensorsRecordingController>((ref) {
      final controller = SensorsRecordingController();
      ref.keepAlive(); // prevents automatic disposal
      return controller;
    });

class _RecordingPageState extends ConsumerState<RecordingPage> {
  late final RecordingController _controller;
  late final SensorsRecordingController _sensorsController;
  final DevicesPopupController _popupController = DevicesPopupController();

  bool _busy = false;

  final GlobalKey bluetoothKey = GlobalKey();

  DateTime? _videoStartEpoch;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(recordingControllerProvider(widget.initialCamera));
    _sensorsController = ref.read(sensorsRecordingProvider);
    _controller.init().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _popupController.hide();
    super.dispose();
  }

  /// Handles pressing the shutter button to start or stop recording.
  ///
  /// Behavior:
  /// - If currently recording:
  ///   - Stops video recording.
  ///   - Stops sensor recording if wearables are connected.
  ///   - Updates home state with the new recording.
  ///   - Navigates to the playback page for the recorded video.
  /// - If not recording:
  ///   - Starts sensor recording if wearables are connected.
  ///   - Starts video recording.
  /// - Prevents concurrent execution using [_busy] flag.
  Future<void> _onShutterPressed() async {
    if (_busy) return;
    _busy = true;

    try {
      final wearablesNotifier = ref.read(wearablesProvider);
      final hasSensors = wearablesNotifier.isConnected;

      if (_controller.isRecording) {
        final recording = await _controller.stopRecording(
          ref.read(homeStateProvider).openProjectId,
        );

        if (recording != null && mounted) {
          if (hasSensors) {
            try {
              await _sensorsController.stopRecording(
                videoStart: _videoStartEpoch!,
                recordingId: recording.id,
                projectId: ref.read(homeStateProvider).openProjectId,
                ref: ref,
              );
            } catch (e) {
              debugPrint("Sensor stop failed: $e");
            }

            wearablesNotifier.detachSensorsRecordingController();
          }
          ref.read(homeStateProvider.notifier).addRecording(recording);
          if (!mounted) return;
          context.go(
            Routes.playback(recording.isCloud, recording.id),
            extra: recording,
          );
        }
      } else {
        _videoStartEpoch = DateTime.now();
        if (hasSensors) {
          await _sensorsController.startRecording();
          wearablesNotifier.attachSensorsRecordingController(
            _sensorsController,
          );
        }
        await _controller.startRecording();
      }
    } finally {
      _busy = false;
    }

    if (!mounted) return;
  }

  /// Handles pressing the flip or pause button.
  ///
  /// Behavior:
  /// - If not recording, toggles camera direction.
  /// - If recording:
  ///   - Pauses recording if currently recording.
  ///   - Resumes recording if paused.
  /// - Pauses/resumes sensor recording in sync with video recording.
  /// - Prevents concurrent execution using [_busy] flag.
  Future<void> _onFlipOrPausePressed() async {
    final hasSensors = ref.read(wearablesProvider).isConnected;

    if (_busy) return;
    _busy = true;
    try {
      if (!_controller.isRecording) {
        await _controller.toggleCamera();
      } else {
        if (_controller.isPaused) {
          if (hasSensors) _sensorsController.resumeRecording();
          await _controller.resumeRecording();
        } else {
          await _controller.pauseRecording();
          if (hasSensors) _sensorsController.pauseRecording();
        }
      }
    } finally {
      _busy = false;
    }

    if (!mounted) return;
    setState(() {});
  }

  /// Navigates back to the home/projects page.
  void _navigateToHome() {
    context.go(Routes.home);
  }

  /// Builds the camera preview widget.
  ///
  /// Returns:
  /// - A [CameraPreview] if the controller is initialized.
  /// - A [CircularProgressIndicator] while the camera initializes.
  ///
  /// The preview is clipped and aligned to maintain aspect ratio.
  Widget _buildCameraPreview() {
    if (!_controller.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final cameraController = _controller.cameraController!;

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        child: AspectRatio(
          aspectRatio: cameraController.value.aspectRatio,
          child: CameraPreview(cameraController),
        ),
      ),
    );
  }

  /// Builds the full recording page layout.
  ///
  /// Layout:
  /// - Left: [RecordingLeftBar] with back button.
  /// - Center: camera preview with optional [VideoSensorOverlay].
  /// - Right: [HomeRecordingRightBar] with shutter, flip, Devices-Popup button, and sensor overlay controls.
  ///
  /// Notes:
  /// - Uses [ListenableBuilder] to rebuild when [RecordingController] state changes.
  /// - Sensor overlay visibility is controlled via [recordingChartProvider].
  @override
  Widget build(BuildContext context) {
    final chartProvider = ref.watch(recordingChartProvider);

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return SafeArea(
          child: Row(
            children: [
              RecordingLeftBar(onBackToProjects: _navigateToHome),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        // Show live camera preview
                        SizedBox(
                          width: constraints.maxWidth,
                          height: constraints.maxHeight,
                          child: _buildCameraPreview(),
                        ),
                        // Overlay sensor visualization if enabled
                        const VideoSensorOverlay(),
                      ],
                    );
                  },
                ),
              ),

              // Right bar actions: shutter, flip, Bluetooth, wave sound (sensors), etc.
              HomeRecordingRightBar(
                onSettings: () {
                  if (!_controller.isRecording) {
                    context.go(Routes.settings);
                  }
                },
                onWaveSound: () =>
                    context.go('${Routes.sensordata}?source=recording'),
                onWaveSoundLongPress: () {
                  ref.read(recordingChartProvider).toggleOverlayVisibility();
                },
                isWaveSoundActive: chartProvider.shouldShowOverlay,
                onShutter: _onShutterPressed,
                onFlipCamera: _onFlipOrPausePressed,
                onBluetooth: () {
                  _popupController.toggle(
                    context: context,
                    positionedPopup: const Positioned(
                      bottom: 30,
                      right: 165,
                      child: DevicesPopup(),
                    ),
                  );
                },
                padding: const EdgeInsets.symmetric(vertical: 24),
                isRecording: _controller.isRecording,
                isPaused: _controller.isPaused,
                bluetoothKey: bluetoothKey,
              ),
            ],
          ),
        );
      },
    );
  }
}
