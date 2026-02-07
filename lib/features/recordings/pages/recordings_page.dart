import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/features/recordings/widgets/right_bar.dart';
import '../../../app/routing/routes.dart';
import '../../home/state/home_provider.dart';
import '../controllers/recording_controller.dart';
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

class _RecordingPageState extends ConsumerState<RecordingPage> {
  late final RecordingController _controller;

  @override
  void initState() {
    super.initState();

    _controller = ref.read(recordingControllerProvider);
    _controller.init().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  Future<void> _onShutterPressed() async {
    if (_controller.isRecording) {
      final path = await _controller.stopRecording(ref.read(homeStateProvider).openProjectId);

      if (path != null) {
        _navigateToPlayBack(path);
      }
    } else {
      await _controller.startRecording();
    }

    setState(() {});
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

    setState(() {});
  }
  void _navigateToPlayBack(String recordingId) {
    context.go('${Routes.playback}/$recordingId');
  }

  void _navigateToHome() {
    context.go(Routes.home);
  }

  Widget _buildCameraPreview() {
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
          RecordingLeftBar(
            onBackToProjects: _navigateToHome,
          ),
          Expanded(
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  _buildCameraPreview(),
                ],
              ),
            ),
          ),
          HomeRecordingRightBar(
            onSettings: () {
              if (!_controller.isRecording) {
                context.go(Routes.settings);
              }
            },
            onWaveSound: () {
              // TODO sensors page
            },
            onShutter: _onShutterPressed,
            onFlipCamera: _onFlipOrPausePressed,
            onBluetooth: () {
              // TODO bluetooth popup
            },
            padding: const EdgeInsets.symmetric(vertical: 24),
            isRecording: _controller.isRecording,
            isPaused: _controller.isPaused,
          ),
        ],
      ),
    );
  }
}
