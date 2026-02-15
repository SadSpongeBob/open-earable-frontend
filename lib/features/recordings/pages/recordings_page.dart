import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:openearable/app/constants/colors.dart';
import 'package:openearable/app/theme/text_styles.dart';
import 'package:openearable/api/models/recording/recording.dart';
import 'package:openearable/features/recordings/widgets/right_bar.dart';
import 'package:openearable/app/ui/device/devices_popup_controller.dart';
import 'package:openearable/app/widgets/devices_popup.dart';
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
  final DevicesPopupController _popupController = DevicesPopupController();
  final GlobalKey bluetoothKey = GlobalKey();

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

  @override
  void dispose() {
    _popupController.hide();
    super.dispose();
  }

  Future<void> _onShutterPressed() async {
    if (_busy) return;
    _busy = true;
    try {
      if (_controller.isRecording) {
        final recording = await _controller.stopRecording(
          ref.read(homeStateProvider).openProjectId,
        );
        if (recording != null && mounted) {
          ref.read(homeStateProvider.notifier).addRecording(recording);
          context.go(
            Routes.playback(recording.isCloud, recording.id),
            extra: recording,
          );
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
              color: AppColors.nineHundred,
              child: Stack(children: [ _buildCameraPreview() ]),
            ),
          ),
          HomeRecordingRightBar(
            onSettings: () {
              if (!_controller.isRecording) {
                context.go(Routes.settings);
              }
            },
            onWaveSound: () => context.go('${Routes.sensordata}?source=recording'),
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
