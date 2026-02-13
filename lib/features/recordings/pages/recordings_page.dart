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
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(recordingControllerProvider(widget.initialCamera));
    _controller.init().then((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> _onShutterPressed() async {
    if (_busy) return;
    _busy = true;
    try {
      if (_controller.isRecording) {
        final id = await _controller.stopRecording(
          ref.read(homeStateProvider).openProjectId,
        );
        if (id != null && mounted) {
          context.go('${Routes.playback}/local/$id');
        }
      } else {
        await _controller.startRecording();
      }
    } finally {
      _busy = false;
    }

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _onFlipOrPausePressed() async {
    if (_busy) return;
    _busy = true;
    try {
      if (!_controller.isRecording) {
        await _controller.toggleCamera();
      } else {
        _controller.isPaused
            ? await _controller.resumeRecording()
            : await _controller.pauseRecording();
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

    return Positioned.fill(child: CameraPreview(_controller.cameraController!));
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
              child: Stack(children: [_buildCameraPreview()]),
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
