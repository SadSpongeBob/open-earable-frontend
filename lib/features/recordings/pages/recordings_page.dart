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
import 'package:openearable/app/widgets/devices_popup.dart';
import '../../../app/routing/routes.dart';
import '../../home/state/home_provider.dart';
import '../controllers/recording_controller.dart';
import '../controllers/sensors_recording_controller.dart';
import '../widgets/left_bar.dart';

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

final sensorsRecordingProvider = Provider((ref) => SensorsRecordingController());

class _RecordingPageState extends ConsumerState<RecordingPage> {
  late final RecordingController _controller;
  late final SensorsRecordingController _sensorsController;
  final DevicesPopupController _popupController = DevicesPopupController();

  bool _busy = false;

  final GlobalKey bluetoothKey = GlobalKey();

  int? _videoStartEpochMs;
  
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

  Future<void> _onShutterPressed() async {
    final wearablesNotifier = ref.read(wearablesProvider);
    final hasSensors = wearablesNotifier.isConnected;

    if (_busy) return;
    _busy = true;
    try {
      if (_controller.isRecording) {
        final recording = await _controller.stopRecording(
          ref.read(homeStateProvider).openProjectId,
        );
        if (hasSensors && _videoStartEpochMs != null) {
          await _sensorsController.stopRecording(
            videoStartEpochMs: _videoStartEpochMs!,
          );
          wearablesNotifier.detachSensorsRecordingController();
        }
        if (recording != null && mounted) {
          ref.read(homeStateProvider.notifier).addRecording(recording);
          context.go(
            Routes.playback(recording.isCloud, recording.id),
            extra: recording,
          );
        }
      } else {
        await _controller.startRecording();
        _videoStartEpochMs = DateTime.now().millisecondsSinceEpoch;
        if (hasSensors) {
          _sensorsController.startRecording();
          wearablesNotifier.attachSensorsRecordingController(_sensorsController);
        }
      }
    } finally {
      _busy = false;
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _onFlipOrPausePressed() async {
    final hasSensors = ref.read(wearablesProvider).isConnected;

    if (_busy) return;
    _busy = true;
    try {
      if (!_controller.isRecording) {
        await _controller.toggleCamera();
      } else {
        if (_controller.isPaused) {
          await _controller.resumeRecording();
          if (hasSensors) _sensorsController.resumeRecording();
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

  void _navigateToHome() {
    context.go(Routes.home);
  }

  Widget _buildCameraPreview() {
    if (!_controller.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return CameraPreview(_controller.cameraController!);
  }

  @override
  Widget build(BuildContext context) {
    final chartProvider = ref.watch(recordingChartProvider);

    return SafeArea(
      child: Row(
        children: [
          RecordingLeftBar(onBackToProjects: _navigateToHome),
          Expanded(
            child: Stack(
                  children: [
                    Positioned.fill(
                      child: _buildCameraPreview(),
                    ),
                    Positioned.fill(
                      child: VideoSensorOverlay()
                    ),
                  ],
            ),
          ),

          HomeRecordingRightBar(
            onSettings: () {
              if (!_controller.isRecording) {
                context.go(Routes.settings);
              }
            },
            onWaveSound: () => context.go('${Routes.sensordata}?source=recording'),
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
  }
}
