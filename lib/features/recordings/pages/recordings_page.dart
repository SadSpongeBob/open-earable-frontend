import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:openearable/features/recordings/widgets/right_bar.dart';
import '../../home/pages/home_page.dart';
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

class _RecordingPageState extends State<RecordingPage>
    with WidgetsBindingObserver {
  late final RecordingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RecordingController(
      initialCamera: widget.initialCamera,
    );
    _controller.addListener(_onControllerChanged);
    _controller.init();
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Row(
        children: [
          RecordingLeftBar(
            onBackToProjects: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const HomePage(),
                ),
              );
            },
          ),

          /// Kamera Vorschau
          Expanded(
            child: Container(
              color: Colors.black,
              child: Stack(
                children: [
                  if (_controller.error != null)
                    Center(
                      child: Text(
                        _controller.error!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    )
                  else if (!_controller.isInitialized)
                    const Center(child: CircularProgressIndicator())
                  else
                    Positioned.fill(
                      child: CameraPreview(
                        _controller.cameraController!,
                      ),
                    ),
                ],
              ),
            ),
          ),

          HomeRecordingRightBar(
            onSettings: () async {},
            onWaveSound: () {},

            /// Start / Stop
            onShutter: () async {
              if (_controller.isRecording) {
                final path = await _controller.stopRecording();
                if (path != null) {
                  widget.onVideoRecorded?.call(path);
                }
              } else {
                await _controller.startRecording();
              }
            },

            /// Flip / Pause / Resume
            onFlipCamera: () async {
              if (!_controller.isRecording) {
                await _controller.toggleCamera();
              } else {
                if (_controller.isPaused) {
                  await _controller.resumeRecording();
                } else {
                  await _controller.pauseRecording();
                }
              }
            },
            onBluetooth: () {},
            padding: const EdgeInsets.symmetric(vertical: 24),
            isRecording: _controller.isRecording,
            isPaused: _controller.isPaused,
          ),
        ],
      ),
    );
  }
}

