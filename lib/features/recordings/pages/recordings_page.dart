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

final sensorsRecordingProvider = ChangeNotifierProvider<SensorsRecordingController>((ref) {
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
                videoStartEpochMs: _videoStartEpochMs!,
                  recordingId : recording.id, projectId: ref.read(homeStateProvider).openProjectId, ref: ref

              );
            } catch (e) {
              debugPrint("Sensor stop failed: $e");
            }

            wearablesNotifier.detachSensorsRecordingController();
          }
          ref.read(homeStateProvider.notifier).addRecording(recording);

          context.go(
            Routes.playback(recording.isCloud, recording.id),
            extra: recording,
          );
        }
      } else {
        _videoStartEpochMs = DateTime.now().millisecondsSinceEpoch;
        await _controller.startRecording();
        if (hasSensors) {
          _sensorsController.startRecording();
          wearablesNotifier.attachSensorsRecordingController(_sensorsController);
        }
      }
    } finally {
      _busy = false;
    }

    if (!mounted) return;
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
                SizedBox(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  child: _buildCameraPreview(),
                ),
                const VideoSensorOverlay(),
              ],
            );
          },
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
      },
  );
  }
}
