import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/features/recordings/widgets/right_bar.dart';
import 'package:openearable/app/widgets/devices_popup_overlay.dart';
import 'package:openearable/features/recordings/widgets/sensor_overlay.dart';
import 'package:openearable/features/sensors/state/recording_chart_provider.dart';
import '../../../app/routing/routes.dart';
import '../controllers/recording_controller.dart';
import '../widgets/left_bar.dart';

class RecordingPage extends StatefulWidget {
  const RecordingPage({
    super.key,
    this.onVideoRecorded,
    this.initialCamera = CameraLensDirection.back,
  });

  final void Function(String videoPath)? onVideoRecorded;
  final CameraLensDirection initialCamera;

  @override
  State<RecordingPage> createState() => _RecordingPageState();
}

class _RecordingPageState extends State<RecordingPage> {
  late final RecordingController _controller;

  final GlobalKey bluetoothKey = GlobalKey();
  

  @override
  void initState() {
    super.initState();
    _controller = RecordingController(initialCamera: widget.initialCamera)
      ..addListener(_onControllerChanged)
      ..init();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _onShutterPressed() async {
    if (_controller.isRecording) {
      final path = await _controller.stopRecording();
      if (path != null) widget.onVideoRecorded?.call(path);
    } else {
      await _controller.startRecording();
    }
  }

  Future<void> _onFlipOrPausePressed() async {
    if (!_controller.isRecording) {
      await _controller.toggleCamera();
    } else {
      if (_controller.isPaused) {
        await _controller.resumeRecording();
      } else {
        await _controller.pauseRecording();
      }
    }
  }

  void _navigateToHome() {
    context.go(Routes.home);
  }

  Widget _buildCameraPreview() {
    if (_controller.error != null) {
      return Center(
        child: Text(
          _controller.error!,
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    if (!_controller.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Positioned.fill(
      child: CameraPreview(_controller.cameraController!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        children: [
          RecordingLeftBar(onBackToProjects: _navigateToHome),
          Expanded(
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  _buildCameraPreview(),
                  const VideoSensorOverlay(),
                ]
              ),
            ),
          ),

          Consumer<RecordingChartProvider>(
            builder: (context, chartProvider, _) {
              return HomeRecordingRightBar(
                onSettings: () => context.go(Routes.settings),
                onWaveSound: () => context.go('${Routes.sensordata}?source=recording'),
                onWaveSoundLongPress: () {
                  chartProvider.toggleOverlayVisibility();
                },
                isWaveSoundActive: chartProvider.shouldShowOverlay,
                onShutter: _onShutterPressed,
                onFlipCamera: _onFlipOrPausePressed,
                onBluetooth: () {
                  showDevicesPopup(
                    context: context,
                    isSensorPage: false,
                  );
                },
                padding: const EdgeInsets.symmetric(vertical: 24),
                isRecording: _controller.isRecording,
                isPaused: _controller.isPaused,
                bluetoothKey: bluetoothKey,
              );
            },
          ),
        ],
      ),
    );
  }
}
